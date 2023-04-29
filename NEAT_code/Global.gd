extends Node

#class_name Global

var track_scene = preload("res://demos/boogers/tracks/track_4/Track_4.tscn")
var track_instance = null

func _ready():
	track_instance = track_scene.instance()
#	get_tree().get_root().add_child(track_instance)
