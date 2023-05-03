extends Panel
#
var species_array = []
var radius_increment = 50

# Use a fixed size for the map, but you can modify this according to your needs
var map_size = Vector2(1000, 1000)
var angle_multiplier = 0.0
var sorted_species_array = []

var font = load("res://NEAT_usability/fonts/dynamics/roboto-bold.tres")



func _ready():
	pass

func draw_species_map(species_array):
	var sample_species = [
		{ "species_id": 1, "parent_id": null, "generation": 1, "color": Color(1, 0, 0), "angle": null },
		{ "species_id": 2, "parent_id": null, "generation": 1, "color": Color(0, 1, 0), "angle": null },
		{ "species_id": 3, "parent_id": null, "generation": 1, "color": Color(0, 0, 1), "angle": null },
		{ "species_id": 4, "parent_id": null, "generation": 1, "color": Color(1, 1, 0), "angle": null },
		{ "species_id": 5, "parent_id": null, "generation": 1, "color": Color(0, 1, 1), "angle": null },
		{ "species_id": 6, "parent_id": null, "generation": 1, "color": Color(1, 0, 1), "angle": null },
		{ "species_id": 7, "parent_id": null, "generation": 1, "color": Color(0.5, 0.5, 0.5), "angle": null },
		{ "species_id": 8, "parent_id": null, "generation": 1, "color": Color(0.5, 0, 0), "angle": null },
		{ "species_id": 9, "parent_id": null, "generation": 1, "color": Color(0, 0.5, 0), "angle": null },
		{ "species_id": 10, "parent_id": null, "generation": 1, "color": Color(0, 0, 0.5), "angle": null },

		{ "species_id": 11, "parent_id": 1, "generation": 2, "color": Color(1, 0.5, 0), "angle": null },
		{ "species_id": 12, "parent_id": 1, "generation": 2, "color": Color(0.5, 1, 0), "angle": null },
		{ "species_id": 13, "parent_id": 3, "generation": 2, "color": Color(0, 0.5, 1), "angle": null },
		{ "species_id": 14, "parent_id": 4, "generation": 2, "color": Color(1, 1, 0.5), "angle": null },
		{ "species_id": 15, "parent_id": 5, "generation": 2, "color": Color(0.5, 1, 1), "angle": null },
		{ "species_id": 16, "parent_id": 10, "generation": 2, "color": Color(1, 0.5, 1), "angle": null },
		{ "species_id": 17, "parent_id": 7, "generation": 2, "color": Color(0.5, 0.5, 0.5), "angle": null },
		{ "species_id": 18, "parent_id": 10, "generation": 2, "color": Color(1, 0, 0.5), "angle": null },
		{ "species_id": 19, "parent_id": 9, "generation": 2, "color": Color(0.5, 1, 0), "angle": null },
		{ "species_id": 20, "parent_id": 10, "generation": 2, "color": Color(0, 0.5, 0.5), "angle": null },

		{ "species_id": 21, "parent_id": 11, "generation": 3, "color": Color(1, 0.75, 0), "angle": null },
		{ "species_id": 22, "parent_id": 12, "generation": 3, "color": Color(0.75, 1, 0), "angle": null },
		{ "species_id": 23, "parent_id": 13, "generation": 3, "color": Color(0, 0.75, 1), "angle": null },
		{ "species_id": 24, "parent_id": 14, "generation": 3, "color": Color(1, 1, 0.75), "angle": null },
		{ "species_id": 25, "parent_id": 15, "generation": 3, "color": Color(0.75, 1, 1), "angle": null },
		{ "species_id": 26, "parent_id": 16, "generation": 3, "color": Color(1, 0.75, 1), "angle": null },
		{ "species_id": 27, "parent_id": 17, "generation": 3, "color": Color(0.75, 0.75, 0.75), "angle": null },
		{ "species_id": 28, "parent_id": 18, "generation": 3, "color": Color(1, 0, 0.75), "angle": null },
		{ "species_id": 29, "parent_id": 19, "generation": 3, "color": Color(0.75, 1, 0), "angle": null },
		{ "species_id": 30, "parent_id": 20, "generation": 3, "color": Color(0, 0.75, 0.75), "angle": null }
	]

	
#	species_array = sample_species
	self.species_array = species_array
	# Set the size of the control
#	rect_min_size = map_size
	rect_size = map_size

	# Trigger a redraw
	update()


func _draw():
	


	# Return early if no species array is set
	if species_array.empty():
		return

	# Set the center of the map
	var center = map_size / 2

	# Calculate the maximum number of generations
	var max_generations = 0
	for species in species_array:
		max_generations = max(max_generations, species.generation)

	# Sort species by generation
	species_array.sort_custom(self, "sort_by_generation")

	# Draw the species on the map
	var draw_radius = 0
	for generation in range(max_generations + 1):
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
			if parent_species:
				angle = calculate_angle(parent_angle, generation, index, total_children)
			else:
				angle = calculate_angle(0, generation, index, total_children)

			species.angle = angle
			var pos = center + Vector2(cos(angle), sin(angle)) * draw_radius

			draw_circle(pos, 10, species.color)
			draw_string(font, pos - Vector2(5, -5), str(species.generation), species.color, 16)


			# Draw lines connecting species to their ancestor
			if parent_species:
				var parent_pos = center + Vector2(cos(parent_angle), sin(parent_angle)) * (draw_radius - radius_increment)
				draw_line(pos, parent_pos, species.color, 2.0)

func get_species_by_id(species_id):
	for species in species_array:
		if species.species_id == species_id:
			return species
	return null

func sort_by_generation(species1, species2):
	return species1.generation < species2.generation


func get_species_count_by_generation(generation):
	var count = 0
	for species in species_array:
		if species.age == generation:
			count += 1
	return count


func calculate_angle(parent_angle, generation, index, total_children):
#	print("CALCULATING ANGLE!")
#	parent_angle
	var angle_offset = (360.0 / (total_children*(total_children+30)))
	if index == 0:
		print("ooo")
	print(index)
	if generation == 1:
		return angle_offset * index
	else:
		return fmod((parent_angle + (angle_offset + angle_multiplier) * index), 360)




func draw_circle(position, radius, color):
	var num_segments = 32
	var angle_increment = 2 * PI / num_segments
	var prev_point = position + Vector2(cos(0), sin(0)) * radius
	for segment in range(1, num_segments + 1):
		var angle = segment * angle_increment
		var point = position + Vector2(cos(angle), sin(angle)) * radius
		draw_line(prev_point, point, color, 2.0)
		prev_point = point


func _input(event):
	if event.is_action_pressed("ui_left"):
		angle_multiplier -= 0.01
		update()
	elif event.is_action_pressed("ui_right"):
		angle_multiplier += 0.01
		update()

