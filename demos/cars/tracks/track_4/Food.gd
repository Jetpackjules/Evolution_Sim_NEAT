extends Area2D

func _ready() -> void:
	connect("body_entered", self, "touched")


func touched(body) -> void:
	"""
	Based on the name of the node, it is determined what to do with the collision. This way, i can attatch this script to all objects!
	"""
	if "Food" in name:
		body.food_score += 0.5
		body.hunger -= 1
		
		var sprite = body.get_node("Sprite")  # Access the Sprite child node
		var hunger = -body.hunger+body.starvation_threshold
		var new_size = max(hunger*(0.058125/5), 0.093)
		if sprite:
			sprite.scale = Vector2(new_size, new_size)  # Scale up the sprite by 10%
			
	queue_free()
