extends Node2D



# Sample creatures array

#onready var Main_Overseer = preload("res://demos/cars/CarMain.tscn")

# Family tree nodes
var tree_nodes = {}
var orphan_nodes = {}

# UI elements
var panel
var panel_parent
var panel_parent_OG_size
	# Use the example creatures array
class Creature:
	var id
	var parent1_id
	var parent2_id

	func _init(_id, parent1_id2, parent2_id2):
		id = _id
		parent1_id = parent1_id2
		parent2_id = parent2_id2


func generate_family(x):
	var creatures = []
	creatures.append(Creature.new(1, 0, 0))
	creatures.append(Creature.new(2, 0, 0))
	for i in range(3, x + 1):
		var parent1_id = randi() % (i - 1) + 1
		var parent2_id = randi() % (i - 1) + 1
		creatures.append(Creature.new(i, parent1_id, parent2_id))
	return creatures



func _ready():
	get_tree().get_root().set_transparent_background(true)
#	Initialize the panel
	panel = $CanvasLayer/Control/FamilyTreeWindow/FamilyTreeScrollContainer/Control/Panel
	panel_parent = $CanvasLayer/Control/FamilyTreeWindow/FamilyTreeScrollContainer/Control
	panel_parent_OG_size = panel_parent.rect_size

var zoom_level: float = 1.0
var zoom_speed: float = 0.1
var min_zoom: float = -10.0
var max_zoom: float = 100.0

func _input(event):
	if event is InputEventKey:
		if event.pressed:
			var prev_zoom_level = zoom_level

			if event.is_action_pressed("zoom_in"):
				print("ZOOMING IN")
				zoom_level += zoom_speed
			elif event.is_action_pressed("zoom_out"):
				print("ZOOMING OUT")
				zoom_level -= zoom_speed

#			zoom_level = clamp(zoom_level, min_zoom, max_zoom)

			var scroll_container = panel_parent.get_parent()
			var zoom_factor = zoom_level / prev_zoom_level


			panel.rect_scale = Vector2(zoom_level, zoom_level)
			panel_parent.rect_min_size = panel_parent_OG_size*zoom_level

			scroll_container.scroll_horizontal *= zoom_factor
			scroll_container.scroll_vertical *= zoom_factor

func clear_family_tree():
	for node in tree_nodes.values():
		node.queue_free()

	for node in orphan_nodes.values():
		node.queue_free()

	for child in panel.get_children():  # Loop through all panel children
		if child is Line2D:  # Check if the child is a Line2D node
			child.queue_free()  # Free the Line2D node

	tree_nodes.clear()
	orphan_nodes.clear()

#func generate_family_tree(creatures):
#	clear_family_tree()
#	var creatures_dict = {}
#
#	creatures = generate_family(300)
#	save_creatures_to_gedcom(creatures)
#
#	# Create nodes for all creatures
#	for creature in creatures:
#		var node = Node2D.new()
#		node.z_index = 1
#		node.name = "Creature_" + str(creature.id)
#		node.position = Vector2(0, 0)
#
#		var label = Label.new()
#		label.text = str(creature.id)
#		label.modulate = Color.black
#		node.add_child(label)
#
#		tree_nodes[creature.id] = node
#		creatures_dict[creature.id] = creature
#
#		# Add the node as a child of the panel
#		panel.add_child(node)
#
#	# Calculate positions of tree nodes
#	var generation_spacing = 50
#	var sibling_spacing = 300
#	var x_offset = 300
#	var y_offset = sibling_spacing * 2
#
#	# Create a dictionary to store the order of nodes within each generation
#	var generation_order = {}
#
#	# Explicitly set the position for the first two nodes
#	tree_nodes[1].position = Vector2(x_offset, y_offset)
#	tree_nodes[2].position = Vector2(x_offset + sibling_spacing, y_offset)
#
#	for creature in creatures:
#		if creature.parent1_id != 0 or creature.parent2_id != 0:
#			var node = tree_nodes[creature.id]
#
#			# Calculate the generation number (depth in the tree)
#			var generation = 1
#			var current_creature = creature
#			while current_creature.parent1_id != 0 or current_creature.parent2_id != 0:
#				generation += 1
#				current_creature = creatures_dict[current_creature.parent1_id]
#
#			# Update the order within the generation
#			if not generation in generation_order:
#				generation_order[generation] = 1
#			else:
#				generation_order[generation] += 1
#
#			# Calculate the position based on the generation number and order within the generation
#			if generation > 1:
#				node.position.x = x_offset + (generation - 1) * generation_spacing
#				node.position.y = y_offset + (generation_order[generation] * 2 - generation) * sibling_spacing / 2
#
#	# Draw connections between parents and children
#	draw_connections(creatures_dict)
#
#	# Setup zoom
#	var max_x = 0
#	var max_y = 0
#
#	for node_id in tree_nodes:
#		max_x = max(max_x, tree_nodes[node_id].position.x)
#		max_y = max(max_y, tree_nodes[node_id].position.y)
#
#	max_x += sibling_spacing + x_offset
#	max_y += generation_spacing + y_offset
#	print("SECOND Down-right-most node location: ", Vector2(max_x, max_y))
#
#	panel_parent.rect_min_size = Vector2(max_x, max_y + 50)
#	panel.rect_size = Vector2(max_x, max_y + 50)
#
#func draw_connections(creatures_dict):  # Modify the parameter
#	var line = Line2D.new()
#	line.z_index = 0
#	line.width = 1
#	line.default_color = Color.white
#	var material = SpatialMaterial.new()
#	material.albedo_color = Color.blue
#	line.material = material
#	panel.add_child(line)
#
#	for creature_id in tree_nodes.keys():
#		var creature = creatures_dict[creature_id]  # Change this line
#		if creature.parent1_id != 0 and creature.parent1_id in tree_nodes:
#			line.add_point(tree_nodes[creature.parent1_id].position)
#			line.add_point(tree_nodes[creature.id].position)
#
#		if creature.parent2_id != 0 and creature.parent2_id in tree_nodes:
#			line.add_point(tree_nodes[creature.parent2_id].position)
#			line.add_point(tree_nodes[creature.id].position)


func cycle(creatures):
	print("CYCLE!")
	if $CanvasLayer/Control/FamilyTreeWindow.visible == false:
		$CanvasLayer/Control/FamilyTreeWindow.popup_centered()
		panel_parent_OG_size = panel_parent.rect_size
#		clear_family_tree()
		panel.draw_family_tree(creatures)
	else:
		$CanvasLayer/Control/FamilyTreeWindow.visible = false
	print("------")
	print($CanvasLayer/Control/FamilyTreeWindow/FamilyTreeScrollContainer/Control.rect_min_size)
	print($CanvasLayer/Control/FamilyTreeWindow/FamilyTreeScrollContainer/Control/Panel.rect_min_size)
	print("----------")



##FOR PYTHON EXPORT:
#func save_creatures_to_gedcom(creatures):
#	var file = File.new()
#	var file_path = "res://creatures.ged"
#
#	var gedcom_lines = ["0 HEAD", "1 SOUR YourProjectName", "1 GEDC", "2 VERS 5.5.1", "2 FORM LINEAGE-LINKED", "1 CHAR UTF-8", "0 @U1@ SUBM", "1 NAME YourName", "1 ADDR YourAddress", "0 TRLR"]
#
#	for creature in creatures:
#		gedcom_lines.append("0 @I" + str(creature.id) + "@ INDI")
#		gedcom_lines.append("1 NAME Creature_" + str(creature.id))
#		gedcom_lines.append("1 SEX U")  # Set to "M" or "F" if you have gender information
#		if creature.parent1_id != 0:
#			gedcom_lines.append("1 FAMC @F" + str(creature.parent1_id) + "_" + str(creature.parent2_id) + "@")
#		if creature.parent2_id != 0:
#			gedcom_lines.append("1 FAMC @F" + str(creature.parent1_id) + "_" + str(creature.parent2_id) + "@")
#
#		if creature.parent1_id != 0 and creature.parent2_id != 0:
#			gedcom_lines.append("0 @F" + str(creature.parent1_id) + "_" + str(creature.parent2_id) + "@ FAM")
#			gedcom_lines.append("1 HUSB @I" + str(creature.parent1_id) + "@")
#			gedcom_lines.append("1 WIFE @I" + str(creature.parent2_id) + "@")
#			gedcom_lines.append("1 CHIL @I" + str(creature.id) + "@")
#
#	var gedcom_string = "\n".join(gedcom_lines)
#
#	if file.open(file_path, File.WRITE):
#		print("Failed to open file for writing:", file_path)
#		return
#
#	file.store_string(gedcom_string)
#	file.close()
#	print("Creatures saved to:", file_path)
