extends Node2D

var Food = load("res://demos/cars/tracks/track_4/Food.tscn")

export (int) var spawn_range = 100
export (int) var max_attempts = 10

export (float) var time_interval = 10
export (float) var bush_spawn = 1
export (float) var area_spawn = 11

var rng = RandomNumberGenerator.new()

func _ready():
	rng.seed = 42
#	bush_grow(20, spawn_range)
	renew(200, 3000)

var time_passed = 0
func _physics_process(delta) -> void:
	time_passed += delta
	if time_passed > 1:
		renew(area_spawn, 3000)
#		bush_grow(bush_spawn, spawn_range)
		time_passed = 0



func bush_grow(amount, area):
	for child in get_children():
		if "Bush" in str(child.name):
			renew(amount, area, child)
		
func get_safe_spawn_points(amount: int, area: int, location: Node = self):
	var spawn_points = []
	var circle_shape = null
	var new_position = Vector2()

	var Food_Instance = Food.instance()
	circle_shape = Food_Instance.get_node("CollisionShape2D").shape
		
	for _i in range(amount):
		var attempts = 0
		var position_found = false
		new_position = Vector2()
			
		while attempts < max_attempts and not position_found:
			new_position = location.position + Vector2(rng.randf_range(-area, area), rng.randf_range(-area, area))

			position_found = Utils.check_collision_free(location, new_position, circle_shape)
			attempts += 1

		if position_found:
			spawn_points.append(new_position - location.position)

#	Removing sample food instance:
	Food_Instance.queue_free()
	
	return spawn_points

func spawn_food_at_points(points, location):  # Add location as an argument
	for point in points:
		var Food_Instance = Food.instance()
		Food_Instance.position = point
		location.add_child(Food_Instance)  # Add Food_Instance as a child of location


func renew(amount: int = 1, area: int = 100, location: Node = $Natural_food):
	rng.randomize()
	var safe_spawn_points = get_safe_spawn_points(amount, area, location)
	spawn_food_at_points(safe_spawn_points, location)  # Pass location as an argument

