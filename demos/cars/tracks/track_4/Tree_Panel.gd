extends Panel

var species_dict = {}
var radius_increment = 50
var angle_multiplier = 0.0
var font = load("res://NEAT_usability/fonts/dynamics/roboto-bold.tres")
# Add this at the top of your script
onready var tree_container = $TreeContainer

func draw_species_map(species_array_input):
	species_dict.clear()
	for species in species_array_input:
		species_dict[species.species_id] = species
	update()
func _draw():
	print("DRAW!")
	var map_size = get_parent().rect_size
	if species_dict.empty():
		return
	var center = map_size/2
	print(map_size)
	var max_generations = 0
	for species in species_dict.values():
		max_generations = max(max_generations, species.generation)
	var draw_radius = 0
	var big_circle_color = Color(1, 0, 0)
	for gen_radius in range(radius_increment*2, (max_generations + 1) * radius_increment, radius_increment):
		draw_circle(center, gen_radius, big_circle_color)
	var tree_size = Vector2.ZERO
	var tree_position = Vector2.ZERO
	
	var tree_min = Vector2.INF
	var tree_max = -Vector2.INF
	
	for generation in range(1, max_generations + 1):
		if generation == 1:
			draw_radius += radius_increment*2
		else:
			draw_radius += radius_increment
		var species_in_generation = []
		for species in species_dict.values():
			if species.generation == generation:
				species_in_generation.append(species)
		species_in_generation.sort_custom(self, "sort_by_ID")
		for index in range(species_in_generation.size()):
			var species = species_in_generation[index]
			var parent_species = species_dict.get(species.parent_id, null)
			var parent_angle = 0.0
			if parent_species:
				parent_angle = parent_species.angle
			var total_children = species_in_generation.size()
			var siblings_index = get_sibling_index(species.species_id)
			var siblings = count_siblings(species.species_id)
			var angle
			if parent_species:
				angle = calculate_angle(parent_angle, generation, index, total_children, siblings, siblings_index, species.parent_id, draw_radius)
			else:
				angle = calculate_angle(0, generation, index, total_children, 0, 0, species.parent_id, draw_radius)
			species.angle = angle
			angle *= (PI/180)
			var pos = center + Vector2(cos(angle), sin(angle)) * draw_radius
			tree_min.x = min(tree_min.x, pos.x)
			tree_min.y = min(tree_min.y, pos.y)
			tree_max.x = max(tree_max.x, pos.x)
			tree_max.y = max(tree_max.y, pos.y)
			tree_size.x = max(tree_size.x, pos.x)
			tree_size.y = max(tree_size.y, pos.y)
			
			
			tree_position += pos
			var text = str(stepify(species.best_ever_fitness, 0.1))
			var new_col = draw_circle(pos, 10, species.color, 2.0, true, species.obliterate, text, species)
			if parent_species:
				parent_angle *= (PI/180)
				var parent_pos = center + Vector2(cos(parent_angle), sin(parent_angle)) * (draw_radius - radius_increment)
				var parent_to_child = (pos - parent_pos).normalized()
				var parent_intersection = parent_pos + parent_to_child * 10
				var child_intersection = pos - parent_to_child * 10
				var new_color = species.color
				if species.obliterate:
					new_color.a = 0.2
				draw_line(parent_intersection, child_intersection, new_color, 2.0)
	tree_position = (tree_min + tree_max) / 2
	tree_size = tree_max - tree_min
	tree_container.rect_min_size = tree_size
	tree_container.rect_position = tree_position - tree_size / 2
	
	
#	tree_position /= species_dict.size()
#	tree_container.rect_min_size = tree_size * 2
#	tree_container.rect_position = tree_position - tree_size

#func _draw():
#	print("DRAW!")
#	var map_size = get_parent().rect_size
#	if species_dict.empty():
#		return
#	var center = map_size/2
#	print(map_size)
#	var max_generations = 0
#	for species in species_dict.values():
#		max_generations = max(max_generations, species.generation)
#	var draw_radius = 0
#	var big_circle_color = Color(1, 0, 0)
#	for gen_radius in range(radius_increment*2, (max_generations + 1) * radius_increment, radius_increment):
#		draw_circle(center, gen_radius, big_circle_color)
#	for generation in range(1, max_generations + 1):
#		if generation == 1:
#			draw_radius += radius_increment*2
#		else:
#			draw_radius += radius_increment
#		var species_in_generation = []
#		for species in species_dict.values():
#			if species.generation == generation:
#				species_in_generation.append(species)
#		species_in_generation.sort_custom(self, "sort_by_ID")
#		for index in range(species_in_generation.size()):
#			var species = species_in_generation[index]
#			var parent_species = species_dict.get(species.parent_id, null)
#
#			var parent_angle = 0.0
#			if parent_species:
#				parent_angle = parent_species.angle
#			var total_children = species_in_generation.size()
#			var siblings_index = get_sibling_index(species.species_id)
#			var siblings = count_siblings(species.species_id)
#			var angle
#			if parent_species:
#				angle = calculate_angle(parent_angle, generation, index, total_children, siblings, siblings_index, species.parent_id, draw_radius)
#			else:
#				angle = calculate_angle(0, generation, index, total_children, 0, 0, species.parent_id, draw_radius)
#			species.angle = angle
#			angle *= (PI/180)
#			var pos = center + Vector2(cos(angle), sin(angle)) * draw_radius
#			var text = str(stepify(species.best_ever_fitness, 0.1))
#			var new_col = draw_circle(pos, 10, species.color, 2.0, true, species.obliterate, text, species)
#			if parent_species:
#				parent_angle *= (PI/180)
#				var parent_pos = center + Vector2(cos(parent_angle), sin(parent_angle)) * (draw_radius - radius_increment)
#				var parent_to_child = (pos - parent_pos).normalized()
#				var parent_intersection = parent_pos + parent_to_child * 10
#				var child_intersection = pos - parent_to_child * 10
#				var new_color = species.color
#				if species.obliterate:
#					new_color.a = 0.2
#				draw_line(parent_intersection, child_intersection, new_color, 2.0)

func get_species_by_id(species_id):
	return species_dict.get(species_id, null)

func sort_by_ID(species1, species2):
	return int(species1.species_id) < int(species2.species_id)

func count_siblings(species_id):
	var target_species = get_species_by_id(species_id)
	if not target_species:
		return 0
	var parent_id = target_species["parent_id"]
	var generation = target_species["generation"]
	var sibling_count = 0
	if target_species["parent_id"] != "":
		for species in species_dict.values():
			if species["parent_id"] == parent_id and species["species_id"] != species_id and species["generation"] == generation:
				sibling_count += 1
	return sibling_count

func get_sibling_index(species_id):
	var target_species = get_species_by_id(species_id)
	if not target_species:
		return 0
	var parent_id = target_species["parent_id"]
	var siblings = []
	for species in species_dict.values():
		if species["parent_id"] == parent_id:
			siblings.append(species)
	return siblings.find(target_species)

func calculate_angle(parent_angle, generation, index, total_children, siblings, siblings_index, parent_id, circle_radius):
	var angle_offset = 360.0 / total_children
	if generation == 1:
		return angle_offset * index
	else:
		var sibling_angle_range = calculate_required_angle(siblings, circle_radius)
		var start_angle = parent_angle - (sibling_angle_range / 2.0)
		var angle
		if siblings != 0:
			angle = start_angle + (siblings_index * (sibling_angle_range / (siblings)))
		else:
			angle = parent_angle
		var adjusted_angle = angle
		return fmod(adjusted_angle, 360)

func calculate_required_angle(siblings, circle_radius):
	if siblings == 0:
		return 0
	var indicator_radius = 10.0
	var max_indicator_width = (indicator_radius * 2) / circle_radius
	var required_angle = 360 * max_indicator_width
	return required_angle

func draw_circle(position, radius, color, width = 2.0, is_filled = false, extinct = false, text="TREE", species = null):
	var num_segments = 32
	var angle_increment = 2 * PI / num_segments
	if extinct:
		radius = 7
		color.a = 0.2
	var prev_point = position + Vector2(cos(0), sin(0)) * radius
	if is_filled:
		var filled_color = Color(0,0,0,1)
		for segment in range(1, num_segments + 1):
			var angle = segment * angle_increment
			var point = position + Vector2(cos(angle), sin(angle)) * radius
			draw_colored_polygon([position, prev_point, point], filled_color)
			prev_point = point
	if species:
		if species.predator:
			color.r = 1
			color.g = 0
			color.b = 0
	for segment in range(1, num_segments + 1):
		var angle = segment * angle_increment
		var point = position + Vector2(cos(angle), sin(angle)) * radius
		draw_line(prev_point, point, color, width)
		prev_point = point
	var text_width = font.get_string_size(text).x
	font.size = (10)
	draw_string(font, position - Vector2(text_width/2, -5), text, color, 160)

func _input(event):
	if event.is_action_pressed("ui_left"):
		angle_multiplier -= 0.01
		update()
	elif event.is_action_pressed("ui_right"):
		angle_multiplier += 0.01
		update()
