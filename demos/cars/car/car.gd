extends RigidBody2D

"""Credit for the original version of this script goes to Ivan Skodje. This is a
modified version of his top_down_vehicle.gd script, which can be found at:
github.com/ivanskodje-godotengine/Vehicle-Controller-2D

The script overrides the behavior of a rigidbody to produce an arcade style top-down
car that can also drift. I have changed the parameters to allow very sharp turns and
high acceleration. All steering happens during the act() method.
"""

# Driving Properties
var hunger_multiplier = 0
var acceleration = 15
var max_forward_velocity = 1000
var drag_coefficient = 0.99 # Recommended: 0.99 - Affects how fast you slow down
var steering_torque = 30 # Affects turning speed
var steering_damp = 7 # 7 - Affects how fast the torque slows down

# Drifting & Tire Friction
var can_drift = false
var wheel_grip_sticky = 0.85 # Default drift coef (will stick to road, most of the time)
var wheel_grip_slippery = 0.99 # Affects how much you "slide"
var drift_extremum = 250 # Right velocity higher than this will cause you to slide
var drift_asymptote = 20 # During a slide you need to reduce right velocity to this to gain control
var _drift_factor = wheel_grip_sticky # Determines how much (or little) your vehicle drifts

# Vehicle velocity and angular velocity. Override rigidbody velocity in physics process
var _velocity = Vector2()
var _angular_velocity = 0

# vehicle forward speed
var speed: int

# hold a specified num of raycasts in an array to sense the environment
var raycasters = []
var sight_range = 350
var num_casts = 8

var food_score = 0.0
var life_score = 0.0

var hunger = 0.0

var starvation_threshold = 5.0/3.0 # Set your desired threshold here (in secondsk)

var dead = false

onready var center = get_node("../../Center")
onready var start = get_node("../../Start")

# signal that let's the controlling agent know it just died
signal death

func _ready() -> void:
	"""Connect the car to the bounds of the track, receive a signal when (any) car
	collides with the bounds. Generate raycasts to measure the distance to the bounds.
	"""
	

	# connect a signal from track bounds, to detect when a crash occurs
	get_node("../../Bounds").connect("body_entered", self, "crash")
	
	# Top Down Physics
	set_gravity_scale(0.0)
	food_score = 0.0
	hunger = 0.0
	life_score = 0.0
	hunger_multiplier = 1.0
	# Generate specified number of raycasts 
	var cast_angle = 0
	var cast_arc = TAU / num_casts
	for _new_caster in num_casts:
		var caster = RayCast2D.new()
		var cast_point = Vector2(0, -sight_range).rotated(cast_angle)
		caster.enabled = false
		caster.cast_to = cast_point
		caster.collide_with_areas = true
		caster.collide_with_bodies = false
		add_child(caster)
		raycasters.append(caster)
		cast_angle += cast_arc
	# Added steering_damp since it may not be obvious at first glance that
	# you can simply change angular_damp to get the same effect
#	set_angular_damp(steering_damp)


func _physics_process(_delta) -> void:
	"""This script overrides the behavior of a rigidbody (Not my idea, but it works).
	"""
	# Show hunger:
	$Sprite/Label.text = str(stepify(-hunger+starvation_threshold, 0.1))
#	showing position instead:
#	$Sprite/Label.text = str(global_position)
#	$Sprite/Label2.text = str(position)



	#-------------------	
#	_velocity *= drag_coefficient
	
	# Add drift to velocity
	_velocity = get_up_velocity() + (get_right_velocity() * _drift_factor)

	# Override Rigidbody movement
	set_linear_velocity(_velocity)
	set_angular_velocity(_angular_velocity)
	
	
	# Update the forward speed
	speed = -get_up_velocity().dot(transform.y)
	
	hunger += (_delta/6.0)*hunger_multiplier
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
			else:
				senses.append(0)  # 0 for other objects
		else:
			senses.append(1)  # No collision
			senses.append(0)  # No object type
	var rel_speed = range_lerp(speed, -max_forward_velocity, max_forward_velocity, 0, 2)
	# Append relative speed, angular_velocity and _drift_factor to the cars senses
	senses.append(rel_speed)
	senses.append(-hunger+starvation_threshold)
	return senses


func act(actions: Array) -> void:
	"""Use the networks output to control the cars steering.
	"""
	# Torque depends that the vehicle is moving
	var torque = lerp(0, steering_torque, _velocity.length() / max_forward_velocity)
#	var torque = 1
	# accelerate
	if actions[0] > 0.3:
		_velocity = -transform.y * acceleration * 15
	# break & reverse
	elif actions[1] > 0.3:
		_velocity = transform.y * acceleration * 15
	else:
		_velocity = transform.y * 0

	# steer right
	if actions[2] > 0.2:
		_angular_velocity = range_lerp(actions[2], 0.2, 1, 0, 1) * torque * sign(speed)
	# steer left
	elif actions[3] > 0.2:
		_angular_velocity = range_lerp(actions[3], 0.2, 1, 0, 1) * -torque * sign(speed)
	else:
		_angular_velocity = 0
	# Prevent exceeding max velocity
	var max_speed = (Vector2(0, -1) * max_forward_velocity).rotated(rotation)
	var x = clamp(_velocity.x, -abs(max_speed.x), abs(max_speed.x))
	var y = clamp(_velocity.y, -abs(max_speed.y), abs(max_speed.y))
	_velocity = Vector2(x, y)


func get_fitness() -> float:
	life_score = life_score/10
	return food_score + life_score


# ---------- CRASHING

func crash(body) -> void:
	"""Check if the body that collided with the bounds is self. If so, show an explosion
	and emit the death signal, causing the fitness to be evaluated by the ga node.
	JUSTIFICATION: Using a signal from the track and then checking every car if it was the
	one that crashed is apparently a lot more efficient than providing every car with
	it's own collider.
	"""
	if body == self:
		$Explosion.show(); $Explosion.play()
		$Sprite.hide()
		food_score = food_score*0.5
		dead = true
		emit_signal("death")


func starve() -> void:
	if hunger > starvation_threshold:
#		print("STARVED")
		# trigger the crash effect
		$Explosion.show(); $Explosion.play()
		$Sprite.hide()
		dead = true
		emit_signal("death")
		
func _on_Explosion_animation_finished() -> void:
	$Explosion.stop(); hide()

#hiding labels:
#func _unhandled_input(event):
#	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
#
##		get_tree().paused = !get_tree().paused
#	pass

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.is_action_pressed("cycle_labels"):
				$Sprite/Label.visible = !$Sprite/Label.visible
