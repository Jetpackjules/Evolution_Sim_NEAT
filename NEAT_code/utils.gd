extends Node

"""
Singleton that provides useful functionality to the rest of the code.
"""

var rng = RandomNumberGenerator.new()

func random_f() -> float:
	"""Randomizes and returns float
	"""
	rng.randomize()
	return rng.randf() 


func random_f_range(start: float, end: float) -> float:
	"""Randomizes and returns float in a given range.
	"""
	rng.randomize()
	return rng.randf_range(start, end) 


func random_i_range(start: int, end: int) -> int:
	"""Randomizes and returns float in a given range.
	"""
	rng.randomize()
	return rng.randi_range(start, end) 


func random_choice(arr: Array):
	"""Picks random choice from an array. No guarantees about the type.
	"""
	var pick_index = random_i_range(0, (arr.size() - 1))
	return arr[pick_index]


func gauss(deviation) -> float:
	"""Returns a random float from a normal distribution
	"""
	rng.randomize()
	return rng.randfn(0.0, deviation)



static func merge_dicts(dict1: Dictionary, dict2: Dictionary) -> Dictionary:
	"""Merges 2 dicts. duh.
	"""
	var new_dict = dict1.duplicate(true)
	for key in dict2.keys():
		if not new_dict.has(key):
			new_dict[key] = dict2[key]
	return new_dict


static func sort_and_remove_duplicates(arr: Array) -> Array:
	"""sorts an array and removes duplicates.
	"""
	arr.sort()
	var new_array = []
	var last_value
	for value in arr:
		if not last_value == value:
			new_array.append(value)
		last_value = value
	return new_array


#func check_collision_free(collision_node: Node, new_position, shape):
#	var space_state = collision_node.get_world_2d().direct_space_state
#	var query = Physics2DShapeQueryParameters.new()
#
#	query.transform = Transform2D(0, new_position)
#	query.shape_rid = shape.get_rid()
#	query.collision_layer = 1
#	query.collide_with_bodies = true
#	query.collide_with_areas = true
#
#	var result = space_state.intersect_shape(query, 2)
#	return result.empty()


func check_collision_free(collision_node, new_position, shape):
	var space_state = get_tree().get_root().get_world_2d().direct_space_state
	var query = Physics2DShapeQueryParameters.new()
	
	query.transform = Transform2D(0, new_position)
	query.shape_rid = shape.get_rid()
	query.collision_layer = 1
	query.collide_with_bodies = true
	query.collide_with_areas = true

	var result = space_state.intersect_shape(query, 2)
	return result.empty()
