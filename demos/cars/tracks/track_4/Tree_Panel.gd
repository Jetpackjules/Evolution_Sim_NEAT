extends Panel


var species_array = []
var radius_increment = 50

# Use a fixed size for the map, but you can modify this according to your needs

var angle_multiplier = 0.0
var sorted_species_array = []

var font = load("res://NEAT_usability/fonts/dynamics/roboto-bold.tres")




func draw_species_map(species_array_input):
#	species_array.clear()
	species_array = species_array_input.duplicate(true)

	# Set the size of the control
#	rect_min_size = map_size


#	rect_size = map_size



	# Trigger a redraw
	update()


func _draw():
	print("DRAW!")
	var map_size = get_parent().rect_size

	# Return early if no species array is set
	if species_array.empty():
		return

	# Set the center of the map
	var center = map_size/2
	print(map_size)
	
	# Calculate the maximum number of generations
	var max_generations = 0
	for species in species_array:
		max_generations = max(max_generations, species.generation)

	# Sort species by generation
	species_array.sort_custom(self, "sort_by_ID")

	# Draw the species on the map
	var draw_radius = 0

	var big_circle_color = Color(1, 0, 0)  # Red color
	for gen_radius in range(radius_increment*2, (max_generations + 1) * radius_increment, radius_increment):
		draw_circle(center, gen_radius, big_circle_color)

	for generation in range(1, max_generations + 1):
		if generation == 1:
			draw_radius += radius_increment*2
		else:
			draw_radius += radius_increment

		var species_in_generation = []
		for species in species_array:
			if species.generation == generation:
				species_in_generation.append(species)




		for index in range(species_in_generation.size()):
			var species = species_in_generation[index]
			var parent_species = get_species_by_id(species.parent_id)
			var parent_angle = 0.0

			if parent_species:
				parent_angle = parent_species.angle

			var total_children = species_in_generation.size()
			var angle
			var siblings_index = get_sibling_index(species.species_id)
			var siblings = count_siblings(species.species_id)
			if parent_species:
#				angle = calculate_angle(parent_angle, generation, index, total_children, siblings, siblings_index)
				angle = calculate_angle(parent_angle, generation, index, total_children, siblings, siblings_index, species.parent_id, draw_radius)
			else:
				angle = calculate_angle(0, generation, index, total_children, 0, 0, species.parent_id, draw_radius)

			species.angle = angle
#			Turning into radians:

			angle *= (PI/180)
			var pos = center + Vector2(cos(angle), sin(angle)) * draw_radius


			var text = str(stepify(species.best_ever_fitness, 0.1))
			var new_col = draw_circle(pos, 10, species.color, 2.0, true, species.obliterate, text, species)

			# Draw lines connecting species to their ancestor
			if parent_species:
				parent_angle *= (PI/180)
				var parent_pos = center + Vector2(cos(parent_angle), sin(parent_angle)) * (draw_radius - radius_increment)
				# Calculate intersection points between parent and child circles
				var parent_to_child = (pos - parent_pos).normalized()
				var parent_intersection = parent_pos + parent_to_child * 10
				var child_intersection = pos - parent_to_child * 10

				var new_color = species.color
				if species.obliterate:
#					pass
					new_color.a = 0.2

				draw_line(parent_intersection, child_intersection, new_color, 2.0)


func calculate_required_angle(siblings, circle_radius):
	if siblings == 0:
		return 0

	var indicator_radius = 10.0
	var max_indicator_width = (indicator_radius * 2) / circle_radius
	var required_angle = 360 * max_indicator_width

	return required_angle



func get_species_by_id(species_id):
	for species in species_array:
		if species.species_id == species_id:
			return species
	return null

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
		for species in species_array:
			if species["parent_id"] == parent_id and species["species_id"] != species_id and species["generation"] == generation:
				sibling_count += 1

	return sibling_count

func get_species_count_by_generation(generation):
	var count = 0
	for species in species_array:
		if species.age == generation:
			count += 1
	return count

func get_sibling_index(species_id):
	var target_species = get_species_by_id(species_id)
	if not target_species:
		return 0

	var parent_id = target_species["parent_id"]
	var siblings = []

	for species in species_array:
		if species["parent_id"] == parent_id:
			siblings.append(species)

	return siblings.find(target_species)


##OG WORKING WITH SLIGHT CROSS-PARENT OVERLAP:
func calculate_angle(parent_angle, generation, index, total_children, siblings, siblings_index, parent_id, circle_radius):
	var angle_offset = 360.0 / total_children

	if generation == 1:
		return angle_offset * index
	else:
		# Calculate the angle range for the siblings
		var sibling_angle_range = calculate_required_angle(siblings, circle_radius)

		# Calculate the starting angle for the siblings
		var start_angle = parent_angle - (sibling_angle_range / 2.0)

		# Calculate the angle for the current sibling within the range
		var angle
		if siblings != 0:
			angle = start_angle + (siblings_index * (sibling_angle_range / (siblings)))
		else:
			angle = parent_angle

		# Adjust the angle based on the parent's angle
		var adjusted_angle = angle

		return fmod(adjusted_angle, 360)






func draw_circle(position, radius, color, width = 2.0, is_filled = false, extinct = false, text="TREE", species = null):
	var num_segments = 32
	var angle_increment = 2 * PI / num_segments

	if extinct:
		radius = 7
		color.a = 0.2


	var prev_point = position + Vector2(cos(0), sin(0)) * radius

	if is_filled:
#		var filled_color = Color(color.r, color.g, color.b, fill_alpha)
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

