extends StaticBody2D

onready var timer = $Timer
onready var anim_sprite = $AnimatedSprite

var elapsed_time


func _ready():
	anim_sprite.speed_scale = 1/(timer.time_left/6)
	anim_sprite.play()
#
#func _process(delta):
#	pass
#	elapsed_time += delta
#	var anim_length = anim_sprite.frames.get_frame_count(anim_sprite.animation)
#	var frame_time = timer.wait_time
#	var current_frame = int(elapsed_time / frame_time)
#	anim_sprite.frame = current_frame
#

func _on_Timer_timeout():
	queue_free()
