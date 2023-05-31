extends Area2D

var toggle_input := "press"
var is_hidden := false


#func _ready():
#	toggle_input = ""

func _input(event):
	if event.is_action_pressed(toggle_input):
		toggle_visibility_and_collision()



func toggle_visibility_and_collision():
	is_hidden = !is_hidden
	self.visible = !is_hidden
	if is_hidden:
		self.set_collision_layer_bit(0, false)
		self.set_collision_mask_bit(0, false)
	else:
		self.set_collision_layer_bit(0, true)
		self.set_collision_mask_bit(0, true)
