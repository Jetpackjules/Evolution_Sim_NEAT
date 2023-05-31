extends ColorRect

func _gui_input(event):
	if event is InputEventMouseButton or event is InputEventMouseMotion:
		get_node("../../ZoomPanCam")._unhandled_input(event)
