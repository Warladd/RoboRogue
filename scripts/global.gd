extends Node

var player : Player

func change_scene(scene):
	get_tree().change_scene_to_file("res://scenes/screens/%s.tscn" % scene)
	

