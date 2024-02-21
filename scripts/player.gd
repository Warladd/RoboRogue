class_name Player extends CharacterBody3D

# Bobbing 
const BOB_FREQ = 2.0 # Default: 2.0
const BOB_AMP = 0.08 # Default: 0.08
var t_bob = 0.0

# Player
@export_group("Player")
@export var health : int = 100
@export var speed : float = 12.0
@export var jump_velocity : float = 8.5
@export var max_fall_distance : int = 8
var gravity = 11


# Battery
@export_group("Battery")
@export var battery_life : float = 100.0
@export var base_battery_drain_speed : float = 1.0
var battery_drain_speed : float = 1.0

# FOV Variables
const BASE_FOV = 75.0
const FOV_CHANGE = 1.5
var look_sensitivity = ProjectSettings.get_setting("player/look_sensitivity")

# HUD
@onready var health_val := $MarginContainer/VBoxContainer/HBoxContainer/health
@onready var battery_val := $MarginContainer/VBoxContainer/HBoxContainer2/battery
var hud_item = preload("res://scripts/hud_item.gd")

# Nodes
@export_group("Nodes")
@export var camera : Camera3D
@export var coyote_timer : Timer
@export var battery_timer : Timer
@export var hud_updates : Control
@export var hud_overlay : ColorRect

func _ready() -> void:
	# Making player accessible to other scripts
	Global.player = self
	# Makes mouse invisible
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * look_sensitivity)
		camera.rotate_x(-event.relative.y * look_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		update_hud()

func _physics_process(delta) -> void:
	# Movement and Gravity
	var horizontal_velocity = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(horizontal_velocity.x, 0, horizontal_velocity.y)).normalized()
	if is_on_floor() or (!coyote_timer.is_stopped() and velocity.y <= 0):
		if direction:
			battery_drain_speed = base_battery_drain_speed * 3
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			battery_drain_speed = base_battery_drain_speed
			velocity.x = 0.0
			velocity.z = 0.0
		velocity.y = 0
		if Input.is_action_just_pressed("jump"): 
			lose_battery(base_battery_drain_speed * 5)
			velocity.y = jump_velocity
	else:
		# Inertia
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		# Gravity
		velocity.y -= gravity * delta
		if position.z >= max_fall_distance:
			get_tree().reload_current_scene()
	
	# Head Bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = headbob(t_bob)
	
	# Changes the fov based on speed
	var velocity_clamped = clamp(velocity.length(), 0.5, speed * 2)
	var target_fov = BASE_FOV + FOV_CHANGE + velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# Escape key quits the game.
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
	
	# Checks if the player is on the ground.
	var was_on_floor = is_on_floor()
	
	move_and_slide()
	
	# If the player was on the ground and is no longer on the ground it starts the coyote jump timer.
	if was_on_floor and !is_on_floor():
		coyote_timer.start()

func headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time* BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func _on_battery_timer_timeout() -> void:
	lose_battery(battery_drain_speed)
	
func lose_battery(amount : float):
	battery_life -= amount
	battery_life = snappedf(battery_life, 0.1)
	update_hud()

func update_hud() -> void:
	health_val.text = " " + str(health)
	battery_val.text = " " + str(battery_life) + "%"

func add_hud_update(qty,text,color) -> void:
	var lab = hud_item.instantiate()
	lab.text = str(qty) + " " + text
	lab.set_modulate(color)
	hud_updates.add_child(lab)
	
func screen_glow(color):
	var tween = get_tree().create_tween()
	tween.tween_property(hud_overlay, "color", color, 0.1)
	tween.tween_property(hud_overlay, "color", Color(1,0,0,0), 0.7)
