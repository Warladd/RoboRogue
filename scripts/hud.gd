extends Control

# HUD
var hud_item = preload("res://scripts/hud_item.gd")

# Nodes
@onready var hud_updates := $HudUpdates
@onready var hud_overlay := $Overlay
@onready var health_val := $MarginContainer/VBoxContainer/HBoxContainer/health
@onready var battery_val := $MarginContainer/VBoxContainer/HBoxContainer2/battery

func update_hud() -> void:
	health_val.text = " " + str(Global.player.health)
	battery_val.text = " " + str(Global.player.battery_life) + "%"

func add_hud_update(qty,text,color) -> void:
	var lab = hud_item.instantiate()
	lab.text = str(qty) + " " + text
	lab.set_modulate(color)
	hud_updates.add_child(lab)
	
func screen_glow(color):
	var tween = get_tree().create_tween()
	tween.tween_property(hud_overlay, "color", color, 0.1)
	tween.tween_property(hud_overlay, "color", Color(1,0,0,0), 0.7)
	
func _process(delta) -> void:
	update_hud()
