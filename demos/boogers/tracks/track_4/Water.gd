extends Area2D

var bodies = {}
var thirst_per_second = 0.01

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", self, "on_body_entered")
	connect("body_exited", self, "on_body_exited")
	set_process(true)

func _process(delta: float) -> void:
	if "Water" in name:
#		print("DRINKING!")
		for body in bodies.keys():
			bodies[body] += delta
			var thirst_to_add = bodies[body] * thirst_per_second
			body.thirst -= thirst_to_add if thirst_to_add <= thirst_per_second else thirst_per_second
			if bodies[body] >= 1 / thirst_per_second:
				bodies[body] = 0
				body.water_score += 1

func on_body_entered(body) -> void:
	bodies[body] = 0

func on_body_exited(body) -> void:
	bodies.erase(body)
