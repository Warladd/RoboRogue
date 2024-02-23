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

# Movement
var direction
var saved_dir
var input_dir
var dashing : bool = false
var can_dash : bool = true
var dash_speed : float = speed * 3

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
var hud_item = preload("res://scripts/hud_item.gd")

# Nodes
@export_group("Nodes")
@export var camera : Camera3D
# Timers
@export var coyote_timer : Timer
@export var battery_timer : Timer
@export var dash_timer : Timer
@export var can_dash_timer : Timer
# HUD Nodes
@export var hud_updates : Control
@export var hud_overlay : ColorRect
@export var health_val : Label
@export var battery_val : ProgressBar
@export var battery_label : Label
@export var pause_menu : VBoxContainer

func _ready() -> void:
	pause_menu.hide()
	# Making player accessible to other scripts
	Global.player = self
	# Makes mouse invisible
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event) -> void:
	# Rotates the view of the camera with the mouse
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * look_sensitivity)
		camera.rotate_x(-event.relative.y * look_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func _physics_process(delta) -> void:
	# Movement and Gravity
	if !dashing:
		input_dir = Input.get_vector("left", "right", "up", "down")
		direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if direction:
			saved_dir = direction
	
	if Input.is_action_just_pressed("dash"):
		if can_dash:
			dashing = true
			can_dash = false
			lose_battery(base_battery_drain_speed * 10)
			dash_timer.start()
		
	if is_on_floor() or (!coyote_timer.is_stopped() and velocity.y <= 0) and !dashing:
		if direction:
			battery_drain_speed = base_battery_drain_speed * 3
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		elif !direction:
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
		#if position.y >= max_fall_distance:
			#get_tree().reload_current_scene()
	
	if dashing:
		if !direction:
			direction = saved_dir
		if is_on_floor():
			velocity = lerp(velocity, velocity * dash_speed, 10 * delta)
			velocity.y = 0
		elif !is_on_floor():
			velocity = lerp(velocity, velocity * dash_speed, 0.2 * delta)
			velocity.y = 0
	
	# Head Bob
	if !dashing:
		t_bob += delta * velocity.length() * float(is_on_floor())
		camera.transform.origin = headbob(t_bob)
	
	# Changes the fov based on speed
	var velocity_clamped = clamp(velocity.length(), 0.5, speed * 2)
	var target_fov = BASE_FOV + FOV_CHANGE + velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
	
	# Checks if the player is on the ground.
	var was_on_floor = is_on_floor()
	
	move_and_slide()
	
	# If the player was on the ground and is no longer on the ground it starts the coyote jump timer.
	if was_on_floor and !is_on_floor():
		coyote_timer.start()

func _input(event) -> void:
	# Escape key pauses the game.
	if Input.is_action_just_pressed("esc"):
		pause()

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
	health_val.text = " " + str(health) + "%"
	battery_val.value = battery_life
	battery_label.text = " " + str(battery_life)
	
	if health > 60:
		health_val.modulate = Color("007305")
	elif health > 35:
		health_val.modulate = Color("989a21")
	elif health <= 35:
		health_val.modulate = Color("7c120f")

func add_hud_update(qty,text,color) -> void:
	var lab = hud_item.instantiate()
	lab.text = str(qty) + " " + text
	lab.set_modulate(color)
	hud_updates.add_child(lab)
	
func screen_glow(color):
	var tween = get_tree().create_tween()
	tween.tween_property(hud_overlay, "color", color, 0.1)
	tween.tween_property(hud_overlay, "color", Color(1,0,0,0), 0.7)

func _on_dash_timer_timeout():
	dashing = false
	can_dash_timer.start()

func _on_can_dash_timer_timeout():
	can_dash = true
	
func pause() -> void:
	pause_menu.visible = !pause_menu.visible
	if pause_menu.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif !pause_menu.visible:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var tree = get_tree()
	if tree == null:
		return
	tree.paused = pause_menu.visible

func _on_quit_desk_button_pressed():
	get_tree().quit(0)

func _on_resume_button_pressed():
	pause()
