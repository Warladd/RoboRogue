extends CharacterBody3D

@export var speed = 10.0
@export var jump_velocity = 4.5
@export var max_fall_distance : int = 8

var look_sensitivity = ProjectSettings.get_setting("player/look_sensitivity")
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var velocity_y = 0

@export_group("Nodes")
@export var camera : Camera3D
@export var coyote_timer : Timer

func _physics_process(delta) -> void:
	var horizontal_velocity = Input.get_vector("left", "right", "up", "down").normalized() #* delta
	velocity = horizontal_velocity.x * global_transform.basis.x + horizontal_velocity.y * global_transform.basis.z * speed
	if is_on_floor() or (!coyote_timer.is_stopped() and velocity_y <= 0):
		velocity_y = 0
		if Input.is_action_just_pressed("jump"): velocity_y = jump_velocity
	elif !is_on_floor():
		velocity_y -= gravity * delta
		if position.y >= max_fall_distance:
			get_tree().reload_current_scene()
	velocity.y = velocity_y
	
	var was_on_floor = is_on_floor()
	
	move_and_slide()
	
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
		
	if was_on_floor and !is_on_floor():
		coyote_timer.start()

func _input(event) -> void:
	if event is InputEventMouseMotion:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		rotate_y(-event.relative.x * look_sensitivity)
		camera.rotate_x(-event.relative.y * look_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
