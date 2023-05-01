extends Area2D

onready var timer = $Timer
onready var animation_player = $AnimationPlayer

func _ready() -> void:
	connect("body_entered", self, "touched")
	animation_player.play("ColorChange")

func touched(body) -> void:
	if "Food" in name:
		body.food_score += 0.5
		body.energy += 1
		
#		var sprite = body.get_node("Sprite")
#		var new_size = max(body.energy*(0.058125/5), 0.093)
#		if sprite:
#			sprite.scale = Vector2(new_size, new_size)
			
	queue_free()


func _on_Timer_timeout():
	queue_free()
