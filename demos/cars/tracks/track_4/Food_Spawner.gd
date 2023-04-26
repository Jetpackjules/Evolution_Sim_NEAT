extends Node2D

var Food = load("res://demos/cars/tracks/track_4/Food.tscn")

export (int) var spawn_range = 100
export (int) var max_attempts = 10

var rng = RandomNumberGenerator.new()

func _ready():
	rng.seed = 42
	spawn_food(5)

func spawn_food(amount):
#	print("CHILDREN: ", str(self.get_children()), " LENGTH: ", len(self.get_children()))
	for child in get_children():
#		print("RENEWING: ", str(child), " for ", amount)
		renew(child, amount)
		
func renew(location: Node2D, amount: int = 1):
	for _i in range(amount):
		var attempts = 0
		var position_found = false
		var new_position = Vector2()
		var circle_shape = null
		var Food_Instance = null
		
		while attempts < max_attempts and not position_found:
			new_position = location.global_position + Vector2(rng.randf_range(-spawn_range, spawn_range), rng.randf_range(-spawn_range, spawn_range))
			Food_Instance = Food.instance()
			circle_shape = Food_Instance.get_node("CollisionShape2D").shape
			position_found = check_collision_free(new_position, circle_shape)
			attempts += 1

		if position_found:
			Food_Instance.global_position = new_position
			get_tree().get_root().add_child(Food_Instance)
		else:
#			print("no pos found")
			pass

func check_collision_free(new_position, shape):
	var space_state = get_world_2d().direct_space_state
	var query = Physics2DShapeQueryParameters.new()
	
	query.transform = Transform2D(0, new_position)
	query.shape_rid = shape.get_rid()
	query.collision_layer = 1
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var result = space_state.intersect_shape(query, 2)
	return result.empty()
