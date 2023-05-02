extends ColorRect

class_name FamilyTreeNode

var node_data = null
var connected_lines = []

func _init(_node_data):
	node_data = _node_data

func _input(event):
	if event is InputEventMouseMotion:
		var rect = get_rect()
		var mouse_position = event.position
		if rect.has_point(mouse_position):
			for line in connected_lines:
				line.default_color = Color(1, 0, 0)
				line.update()
		else:
			for line in connected_lines:
				line.default_color = Color(0.2, 0.5, 1)
				line.update()
