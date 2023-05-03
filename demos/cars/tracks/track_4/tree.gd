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

var scroll_container


func _ready():
	get_tree().get_root().set_transparent_background(true)
#	Initialize the panel
	panel = $CanvasLayer/Control/FamilyTreeWindow/FamilyTreeScrollContainer/Control/Panel
	panel_parent = $CanvasLayer/Control/FamilyTreeWindow/FamilyTreeScrollContainer/Control
	panel_parent_OG_size = panel_parent.rect_size
	scroll_container = panel_parent.get_parent()

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

			# Get the current mouse position
			var mouse_position = get_global_mouse_position()

			# Calculate the local mouse position relative to the panel_parent
			var local_mouse_position = mouse_position - panel_parent.rect_global_position

			# Get the current scroll
			var current_scroll = Vector2(scroll_container.scroll_horizontal, scroll_container.scroll_vertical)

			# Calculate the scroll relative to the mouse position
			var scroll_before_zoom = local_mouse_position + current_scroll

			# Update the zoom level
			panel.rect_scale = Vector2(zoom_level, zoom_level)
			panel_parent.rect_min_size = panel_parent_OG_size * zoom_level

			# Calculate the new scroll position
			var scroll_after_zoom = scroll_before_zoom * (zoom_level / prev_zoom_level) - local_mouse_position

			# Update the scroll_container properties
			scroll_container.scroll_horizontal = scroll_after_zoom.x
			scroll_container.scroll_vertical = scroll_after_zoom.y







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

func cycle(species):

	if $CanvasLayer/Control/FamilyTreeWindow.visible == false:
		$CanvasLayer/Control/FamilyTreeWindow.popup_centered()
		panel_parent_OG_size = panel_parent.rect_size

		panel.draw_species_map(species)

	else:
		$CanvasLayer/Control/FamilyTreeWindow.visible = false


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
