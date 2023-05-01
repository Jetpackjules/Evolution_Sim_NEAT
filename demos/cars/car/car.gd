extends RigidBody2D

"""Credit for the original version of this script goes to Ivan Skodje. This is a
modified version of his top_down_vehicle.gd script, which can be found at:
github.com/ivanskodje-godotengine/Vehicle-Controller-2D

The script overrides the behavior of a rigidbody to produce an arcade style top-down
car that can also drift. I have changed the parameters to allow very sharp turns and
high acceleration. All steering happens during the act() method.
"""

# Driving Properties
var energy_consumption_multiplier = 1
var acceleration = 15
var max_forward_velocity = 1500
var steering_torque = 5 # Affects turning speed


# Vehicle velocity and angular velocity. Override rigidbody velocity in physics process
var _velocity = Vector2()
var _angular_velocity = 0

# vehicle forward speed
var speed: int

# hold a specified num of raycasts in an array to sense the environment
var raycasters = []
var sight_range = 350
var num_casts = 16

var food_score = 0.0
var life_score = 0.0

var energy = 0.0

#var starvation_threshold = 5.0/3.0 # Set your desired threshold here (in secondsk)

var dead = false

var eat_radius = 50


#onready var center = get_node("../../Center")
#onready var start = get_node("../../Start")
onready var flash_timer = get_node("Timer")
# signal that let's the controlling agent know it just died
signal death


func _ready() -> void:
	"""Connect the car to the bounds of the track, receive a signal when (any) car
	collides with the bounds. Generate raycasts to measure the distance to the bounds.
	"""
	get_child(5).highlighter_radius = eat_radius
	# connect a signal from track bounds, to detect when a crash occurs
	get_node("../../Bounds").connect("body_entered", self, "crash")
	# Top Down Physics
	set_gravity_scale(0.0)
	food_score = 0.0
	energy = 2.5
	life_score = 0.0
	energy_consumption_multiplier = 1.0
	# Generate specified number of raycasts 
	var cast_angle = 0
	var cast_arc = TAU / num_casts
	for _new_caster in num_casts:
		var caster = RayCast2D.new()
		var cast_point = Vector2(0, -sight_range).rotated(cast_angle)
		caster.enabled = false
		caster.cast_to = cast_point
		caster.collide_with_areas = true
		caster.collide_with_bodies = true
		add_child(caster)
		raycasters.append(caster)
		cast_angle += cast_arc
	flash_timer.connect("timeout", self, "_on_flash_timer_timeout")
	
	

func _physics_process(_delta) -> void:
	"""This script overrides the behavior of a rigidbody (Not my idea, but it works).
	"""
	# Show energy:
	$Sprite/Label.text = str(stepify(energy, 0.1))


	# Add drift to velocity
	_velocity = get_up_velocity() + (get_right_velocity())

	# Override Rigidbody movement
	set_linear_velocity(_velocity)
	set_angular_velocity(_angular_velocity)
	
	
	# Update the forward speed
	speed = -get_up_velocity().dot(transform.y)
	
	energy -= (_delta/6.0)*energy_consumption_multiplier
	starve()
	life_score += _delta
	


func get_up_velocity() -> Vector2:
	# Returns the vehicle's forward velocity
	return -transform.y * _velocity.dot(-transform.y)


func get_right_velocity() -> Vector2:
	# Returns the vehicle's sidewards velocity
	return -transform.x * _velocity.dot(-transform.x)


#NEW SENSE FUNCTION:
func sense() -> Array:
	var senses = []
	# get the distance to the nearest obstacles
	for caster in raycasters:
		# this performs a raycast even though the caster is disabled
		caster.force_raycast_update()
		if caster.is_colliding():
			var collision = caster.get_collision_point()
			var distance = (collision - global_position).length()
			var relative_distance = range_lerp(distance, 0, sight_range, 0, 2)
			senses.append(relative_distance)
			# Check for the type of collided object
			var collided_object = caster.get_collider()
			if collided_object.is_in_group("food"):
				senses.append(1)  # 1 represents food
			elif collided_object.is_in_group("danger"):
				senses.append(-1)  # -1 represents danger
			elif collided_object.is_in_group("booger") and collided_object != self:
				if collided_object.is_in_group("predator"):
#					print("SEEN PREDATOR!")
					senses.append(-2)  # -2 represents predator boogers
				else:
					senses.append(2)  # 2 represents other boogers (potential prey)
			else:
				senses.append(0)  # 0 for other objects
		else:
			senses.append(1)  # No collision
			senses.append(0)  # No object type
	var rel_speed = range_lerp(speed, -max_forward_velocity, max_forward_velocity, 0, 2)
	# Append relative speed, angular_velocity and _drift_factor to the cars senses
	senses.append(rel_speed)
	senses.append(energy)
	return senses


func act(actions: Array) -> void:
	"""Use the networks output to control the creature's movement.
	"""
	var torque = steering_torque
	# accelerate
	if actions[0] > 0.0:
		_velocity = -transform.y * acceleration * 15
	# break & reverse
	elif actions[1] > 0.0:
		_velocity = transform.y * acceleration * 15
	else:
		_velocity = Vector2(0, 0)

	# steer right
	if actions[2] > 0.0:
#		_angular_velocity = range_lerp(actions[2], 0.2, 1, 0, 1) * torque
		_angular_velocity = actions[2] * torque
	# steer left
	elif actions[3] > 0.0:
#		_angular_velocity = range_lerp(actions[3], 0.2, 1, 0, 1) * -torque
		_angular_velocity = actions[3] * -torque
	else:
		_angular_velocity = 0

	# eat other boogers
	if actions[4] > 0.5:
		add_to_group("predator")

		var prey = get_preys_in_range(eat_radius)  #Eat nearest prey in the radius
		if prey:
			eat(prey)
			
		flash_red_sprite()
		if get_node("Sprite").scale != Vector2(0.3, 0.3):
			get_node("Sprite").scale = Vector2(0.3, 0.3)
			get_node("Sprite").texture = load("res://demos/cars/car/Cannibal_Booger.png")

		

		energy -= 0.45

	# Prevent exceeding max velocity
	var max_speed = (Vector2(0, -1) * max_forward_velocity).rotated(rotation)
	var x = clamp(_velocity.x, -abs(max_speed.x), abs(max_speed.x))
	var y = clamp(_velocity.y, -abs(max_speed.y), abs(max_speed.y))
	_velocity = Vector2(x, y)

func get_preys_in_range(area: float) -> Node:
	var prey = null
	var min_distance = area
	for booger in get_tree().get_nodes_in_group("booger"):
		if booger != self:
			var distance = global_position.distance_to(booger.global_position)
			if distance < min_distance:
				min_distance = distance
				prey = booger
	return prey


func get_fitness() -> float:
	life_score = life_score/10
	return food_score + life_score

func eat(prey):
	energy += 3  # Predator gains 50% of prey's energy4
	prey.die()

	# Make the sprite flash red

	

func flash_red_sprite() -> void:
#	get_node("Sprite").self_modulate = Color(1, 0, 0)  # Change the sprite color to red
	get_child(5).visible = true #show area of attack using highlighter
	flash_timer.start()  # Start the timer to revert the color after half a second

func _on_flash_timer_timeout() -> void:
	get_child(5).visible = false
#	get_node("Sprite").self_modulate = Color(1, 1, 1)  # Revert the sprite color back to normal

# ---------- CRASHING

func die() -> void:
	if is_in_group("booger"):
		remove_from_group("booger")
		set_linear_velocity(Vector2(0,0))
		set_physics_process(false)
		$Explosion.show(); $Explosion.play()
		$Sprite.hide()
		dead = true
		emit_signal("death")
	




func crash(body) -> void:
	"""Check if the body that collided with the bounds is self. If so, show an explosion
	and emit the death signal, causing the fitness to be evaluated by the ga node.
	JUSTIFICATION: Using a signal from the track and then checking every car if it was the
	one that crashed is apparently a lot more efficient than providing every car with
	it's own collider.
	"""
	if body == self:
		food_score = food_score*0.5
		die()


func starve() -> void:
	if energy < 0:
		die()


func _on_Explosion_animation_finished() -> void:
	$Explosion.stop(); hide()


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.is_action_pressed("cycle_labels"):
				$Sprite/Label.visible = !$Sprite/Label.visible
