extends CharacterBody3D

var walk_speed = 5.0
var sprint_speed = 9.0
var jump_velocity = 4.5 # JUMP ADDED
var SENSITIVITY = 0.003
var gravity = 9.8 

var camera: Camera3D

func _ready():
	camera = find_child("Camera3D", true, false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Changed to F12 so Escape can be used to close UI menus!
	if event is InputEventKey and event.keycode == KEY_F12 and event.pressed:
		get_tree().quit()

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSITIVITY)
		if camera:
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	# Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Sprinting
	var current_speed = sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed

	# Movement (ui_up/down/left/right automatically supports WASD and Arrows!)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()
