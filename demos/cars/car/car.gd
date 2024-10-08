extends RigidBody2D

"""Credit for the original version of this script goes to Ivan Skodje. This is a
modified version of his top_down_vehicle.gd script, which can be found at:
github.com/ivanskodje-godotengine/Vehicle-Controller-2D

The script overrides the behavior of a rigidbody to produce an arcade style top-down
car that can also drift. I have changed the parameters to allow very sharp turns and
high acceleration. All steering happens during the act() method.
"""
onready var sprite = get_node("Sprite")
# Driving Properties
var actions_list := []
var times_attacked := 0
var energy_consumption_multiplier := 1.0
var acceleration := 15
var max_forward_velocity := 200
var steering_torque := 8 # Affects turning speed

var outline := false

# Vehicle velocity and angular velocity. Override rigidbody velocity in physics process
var _velocity := Vector2()
var _angular_velocity := 0.0

# vehicle forward speed
var speed: int
var last_position := Vector2()
var actual_velocity := Vector2()
# hold a specified num of raycasts in an array to sense the environment
var raycasters := []
var sight_range: = 250
var num_casts := 16

var food_score := 0.0
var life_score := 0.0

var energy := 0.0

#var starvation_threshold = 5.0/3.0 # Set your desired threshold here (in secondsk)

var dead := false

var eat_radius := 50
var tick := 0.0

onready var center = get_node("../../Center")
#onready var start = get_node("../../Start")
onready var flash_timer = get_node("Timer")
# signal that let's the controlling agent know it just died
signal death

var age := 0

var purity := 0.0

onready var brick = load("res://demos/cars/car/Brick/Brick.tscn")
var paused := false

var speed_penalty := false
var creatures_eaten := 0

func _ready() -> void:
	"""Connect the car to the bounds of the track, receive a signal when (any) car
	collides with the bounds. Generate raycasts to measure the distance to the bounds.
	"""
#	connect("input_event", self, "_on_creature_input")

	last_position = position
	
	get_child(5).highlighter_radius = eat_radius
	# connect a signal from track bounds, to detect when a crash occurs
	get_node("../../Toggleable_bound").connect("body_entered", self, "crash")
	get_node("../../Toggleable_bound2").connect("body_entered", self, "crash")
	get_node("../../Toggleable_bound3").connect("body_entered", self, "crash")
	get_node("../../Toggleable_bound4").connect("body_entered", self, "crash")
	get_node("../../Bounds").connect("body_entered", self, "crash")
	# Top Down Physics
	set_gravity_scale(0.0)
	food_score = 0.0
	energy = 2.5
	life_score = 0.0
	energy_consumption_multiplier = 1.0
	age = 0
	# Generate specified number of raycasts 
	var cast_angle := 0.0
	var cast_arc := TAU / num_casts
	for _new_caster in num_casts:
		var caster := RayCast2D.new()
		var cast_point := Vector2(0, -sight_range).rotated(cast_angle)
		caster.enabled = false
		caster.cast_to = cast_point
		caster.collide_with_areas = true
		caster.collide_with_bodies = true
		add_child(caster)
		raycasters.append(caster)
		cast_angle += cast_arc
	flash_timer.connect("timeout", self, "_on_flash_timer_timeout")
	
	
func _on_creature_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		$InfoScreen.visible = !$InfoScreen.visible
		outline = !outline
		if outline:
			$Sprite.material.set_shader_param("line_width", 50.0)
		else:
			$Sprite.material.set_shader_param("line_width", 0.0)
		$InfoScreen.offset = Vector2(OS.get_window_size().x-$InfoScreen/Panel.rect_size.x-10, 10)
		update_info_screen()

var agent_message: int
func update_info_screen():
	var actions_labels := ["Speed", "Turn", "Attack", "Munch"]
	var actions_str := ""
#	for i in range(len(actions_list)):
#		actions_str += "%s: %s\n" % [actions_labels[i], str(actions_list[i])]
#	var agent = get_parent().get_parent().get_parent().print_tree_pretty()
	
	$InfoScreen/Panel/Label.text = "Purity: %s\nEnergy: %s\nEaten_score: %s\nRel Speed: %s\nFood Score: %s\nAge: %s\n Actual Sped: %s\n, Agnt Msg: %s\n, Angular Velocity: %s\nLinear Velocity: %s\nActions:\n%s" % [str(purity), str(stepify(energy, 0.1)), str(creatures_eaten*6), str(rel_speed), str(food_score), str(age), str(speed), str(agent_message), str(_angular_velocity), str(_velocity), actions_str]
	


	
	

func _physics_process(_delta) -> void:
	"""This script overrides the behavior of a rigidbody (Not my idea, but it works).
	"""
#	checking to see if purity is working...
#	var test = get_diet_purity(food_score, creatures_eaten*6)
#	if test != 1 and test != 0 and test != -1:
##		breakpoint

	purity = get_diet_purity(food_score, creatures_eaten*6)
	
	actual_velocity = (position - last_position) / _delta
	last_position = position
	
	if $InfoScreen.visible:
		update_info_screen()
	if !paused:
		

		
		# Show energy:
		$Sprite/Label.text = str(stepify(energy, 0.1))

		if !speed_penalty:
			_velocity = get_up_velocity() + (get_right_velocity())

		else:
			tick += _delta
			_velocity = get_up_velocity()/2 + (get_right_velocity()/2)
			if tick >= 2:
				speed_penalty = false
				tick = 0





		# Override Rigidbody movement
		set_linear_velocity(_velocity)
		set_angular_velocity(_angular_velocity)
		
		

#		speed = -get_up_velocity().dot(transform.y)

		speed = actual_velocity.dot(transform.y)
		
		
		energy -= (_delta/6.0)*energy_consumption_multiplier
		starve()
		life_score += _delta
		

			
		if age >= 1:
		

			if is_in_group("predator"): # make into predator booger:
				sprite.texture = load("res://demos/cars/car/Cannibal_Booger.png")
				sprite.scale = Vector2(0.3, 0.3)
	#			$CarCollider.shape.radius = 27.0

#
#		elif age >= 1:
			else:
				sprite.texture = load("res://demos/cars/car/booger_adult.png")
				sprite.scale = Vector2(0.201, 0.201)
				
			


#		BABY SIZE: 0.126

func get_up_velocity() -> Vector2:
	# Returns the vehicle's forward velocity
	return -transform.y * _velocity.dot(-transform.y)


func get_right_velocity() -> Vector2:
	# Returns the vehicle's sidewards velocity
	return -transform.x * _velocity.dot(-transform.x)

var rel_speed := 0.0

#NEW SENSE FUNCTION:
func sense() -> Array:
	var senses := []
	# get the distance to the nearest obstacles
	for caster in raycasters:
		# this performs a raycast even though the caster is disabled
		caster.force_raycast_update()
		if caster.is_colliding():
			var collision = caster.get_collision_point()
			var distance: float = (collision - global_position).length()
			var relative_distance := range_lerp(distance, 0, sight_range, 0, 2)
			senses.append(relative_distance)
			# Check for the type of collided object
			var collided_object = caster.get_collider()
			if collided_object.is_in_group("food"):
				senses.append(1)  # 1 represents food
			elif collided_object.is_in_group("booger") and collided_object != self:
				if collided_object.is_in_group("predator"):
					senses.append(-2)  # -2 represents predator boogers
				elif ((collided_object.age == 0) and (age != 0)) or ((collided_object.age != 0) and (age == 0)):
					senses.append(3) # 3 for child boogers that don't yield energy...
				else:
					senses.append(2)  # 2 represents other boogers (potential prey)
			elif collided_object.is_in_group("danger"):
				senses.append(-1)  # -1 represents danger
			
			elif collided_object.is_in_group("brick"):
				senses.append(-3)  # -1 represents danger
			
			else:
				senses.append(0)  # 0 for other objects
		else:
			senses.append(1)  # No collision
			senses.append(0)  # No object type
	rel_speed = range_lerp(speed, -max_forward_velocity, max_forward_velocity, -1, 1)
	# Append relative speed, angular_velocity and _drift_factor to the cars senses
	
	senses.append(bool_to_scaled_int(is_in_group("predator")))
	senses.append(purity)
	senses.append(rel_speed)
	senses.append(energy)
	
	return senses

func bool_to_scaled_int(input_bool: bool) -> int:
	if input_bool:
		return -1
	else:
		return 1
		
		
var act_times := 0
func act(actions: Array) -> void:
	"""Use the networks output to control the creature's movement.
	"""
	act_times += 1
	actions_list = actions

	_velocity = -transform.y * acceleration * 15 * actions[0]


#	MOVEMENT ENERGY COST!!

#	energy -= (abs(actions[0])/180)
#	energy -= (abs(actions[1])/900)
	
	# steer right
	_angular_velocity = actions[1] * steering_torque


	# eat other boogers
	if actions[2] > 0.5:
		var prey = get_preys_in_range(eat_radius)  #Eat nearest prey in the radius
		if prey:
			eat(prey)
			add_to_group("predator")
		
		
		flash_red_sprite()
		
#		creatures_eaten += 1
		energy -= 0.5

	if actions[3] > 0.5:
		var food = get_food_in_range(eat_radius)  #Eat nearest prey in the radius
		if food:
			food.chow(self)
#		energy -= (0.5/150)
		flash_green_sprite()
		
	if actions[4] > 0.5:
		energy -= 1
		lay_brick()

	# Prevent exceeding max velocity
	var max_speed := (Vector2(0, -1) * max_forward_velocity).rotated(rotation)
	var x := clamp(_velocity.x, -abs(max_speed.x), abs(max_speed.x))
	var y := clamp(_velocity.y, -abs(max_speed.y), abs(max_speed.y))
	_velocity = Vector2(x, y)



func get_preys_in_range(area: float) -> Node:
	var prey = null
	for booger in get_tree().get_nodes_in_group("booger"):
		if booger != self:
			var distance = global_position.distance_to(booger.global_position)
			if distance < area:
				area = distance
				prey = booger
	return prey


func get_food_in_range(area: float) -> Node:
	var food = null
	for food_thing in get_tree().get_nodes_in_group("food"):
		var distance := global_position.distance_to(food_thing.global_position)
		if distance < area:
			area = distance
			food = food_thing
	return food


func get_fitness() -> float:
#	var total_fitness: float = food_score + min(life_score/12, 3) + creatures_eaten*6
#	return total_fitness*(0.5+abs(purity))
	
	return min(life_score/12, 3) + energy
	
func get_diet_purity(plants_eaten: float, meat_eaten: float) -> float:
	var total_food := plants_eaten + meat_eaten
	if total_food == 0:
		return 0.0
	var diet_purity: float = (plants_eaten - meat_eaten) / total_food
	return diet_purity
	
func eat(prey):
	if !prey.dead:
		if ((age == 0) and prey.age == 0) or ((prey.age != 0) and age != 0):
			energy += ((20)/2) + ((24)/2)*abs(clamp(purity, -1, 0))  # Predator gains 3 energy, unless child, in which case nothing...
		
		creatures_eaten += 1
#		speed_penalty = true
		prey.die()

	# Make the sprite flash red

	
func get_behind_position() -> Vector2:
	# Get the forward direction of the creature
	var forward_direction := -transform.y

	# Get the position exactly 12 pixels behind the creature
	var behind_position := global_position - forward_direction * 12

	return behind_position


func flash_green_sprite() -> void:
	get_child(5).color = Color(0, 1, 0)  # Change the sprite color to red
#	if get_child(5).visible == true:
#		get_child(5).visible = false #show area of attack using highlighter
#	flash_timer.start()  # Start the timer to revert the color after half a second

func flash_red_sprite() -> void:
	get_child(5).color = Color(1, 0, 0)
	get_child(5).visible = true #show area of attack using highlighter
	flash_timer.start()  # Start the timer to revert the color after half a second
	
func _on_flash_timer_timeout() -> void:
	get_child(5).color = Color(0, 0, 0)
	get_child(5).visible = false
#	get_node("Sprite").self_modulate = Color(1, 1, 1)  # Revert the sprite color back to normal

# ---------- CRASHING

func die() -> void:
#	if is_in_group("booger"):
#		remove_from_group("booger")
	$CarCollider.set_deferred("disabled", true)
	set_linear_velocity(Vector2(0,0))
	set_angular_velocity(0)
	paused = true
#	set_collision_layer_bit(1, false)
	
#	set_physics_process(false)

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
#		food_score = food_score*0.5
		die()


func starve() -> void:
	if energy < 0:
		die()
#		food_score *= 0.7
		


func _on_Explosion_animation_finished() -> void:
	$Explosion.stop(); hide()


func _input(event):
	if event is InputEventKey:
		if event.pressed:
			if event.is_action_pressed("cycle_labels"):
				$Sprite/Label.visible = !$Sprite/Label.visible
				$InfoScreen.visible = false
			if event.is_action_pressed("freeze"):
				paused = !paused
				set_linear_velocity(Vector2(0,0))
				set_angular_velocity(0)

func lay_brick():
	var brick_instance = brick.instance()
	brick_instance.position = get_behind_position()
	center.add_child(brick_instance)
	
	
	


func _on_Car_input_event(viewport, event, shape_idx):
	_on_creature_input(event)
