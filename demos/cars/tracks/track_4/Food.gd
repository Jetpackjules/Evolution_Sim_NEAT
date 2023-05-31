extends Area2D

onready var timer = $Timer
onready var animation_player = $AnimationPlayer

func _ready() -> void:
#	connect("body_entered", self, "touched")
	animation_player.play("ColorChange")

func chow(body) -> void:
	if body.is_in_group("booger"):
#		if !body.is_in_group("predator"):
		body.food_score += 1
		body.energy += ((1)/2) + ((2)/2)*abs(clamp(body.purity, 0, 1))


#		else:
#			body.food_score += 0.25
#			body.energy += 0.25
		queue_free()


func _on_Timer_timeout():
	queue_free()
