extends KinematicBody2D

export var speed = 115.0
export var wander_speed = 100.0
export var wander_update_interval = 3.1

onready var boogers_in_range = []
onready var area = get_parent().get_node("Area")
onready var wander_timer = Timer.new()
onready var animated_sprite = get_node("AnimatedSprite")

var current_direction = Vector2.ZERO
var velocity = Vector2.ZERO
var start_pos
var out = false
func _ready():
	add_child(wander_timer)
	wander_timer.set_wait_time(wander_update_interval)
	wander_timer.set_one_shot(false)
	wander_timer.connect("timeout", self, "_on_WanderTimer_timeout")
	wander_timer.start()
	start_pos = global_position

func _physics_process(delta):
	
	if !Geometry.is_point_in_polygon(global_position, area.get_node("CollisionPolygon2D").polygon):
		out = true
	
	if out:
		$AnimatedSprite.modulate = Color(0.7,0.7,0.7,1)
		current_direction = (start_pos - global_position).normalized()
		velocity = current_direction * wander_speed
		animated_sprite.play("walk_r")
		
		if (global_position.x - start_pos.x <= 10) and (global_position.y - start_pos.y <= 10):
			out = false
	else:
		$AnimatedSprite.modulate = Color(1,1,1,1)
		if boogers_in_range:
			var target = boogers_in_range[0].global_position
			current_direction = (target - global_position).normalized()
			velocity = current_direction * speed
			animated_sprite.play("ATTACK")
		else:
			velocity = current_direction * wander_speed
			animated_sprite.play("walk_r")
	animated_sprite.flip_h = current_direction.x < 0

	velocity = move_and_slide(velocity)
	animated_sprite.flip_h = current_direction.x < 0

func _on_DetectionArea_body_entered(body):
	if body.is_in_group("booger") or body.is_in_group("predator"):
		boogers_in_range.append(body)

func _on_DetectionArea_body_exited(body):
	if body.is_in_group("booger") or body.is_in_group("predator"):
		boogers_in_range.erase(body)

func _on_WanderTimer_timeout():
	if not boogers_in_range and not out:
		var new_position = Vector2(3000,3000)
		var angle = rand_range(0, 2 * PI)
		current_direction = Vector2(cos(angle), sin(angle)).normalized()
		new_position = global_position + current_direction * wander_speed * wander_update_interval


func _on_ContactArea_body_entered(body):
	if body.is_in_group("booger") or body.is_in_group("predator"):
		body.die()

func _on_Area_body_exited(body):
	out = true
