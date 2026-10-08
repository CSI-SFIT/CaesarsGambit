extends CharacterBody3D

@export var walk_speed = 5.0
@export var sprint_speed = 9.0
@export var jump_velocity = 4.5
@export var SENSITIVITY = 0.003
@export var gravity = 9.8

# Type your exact animation names in the Inspector!
@export var idle_anim_name: String = "idle_anim/mixamo.com"
@export var walk_anim_name: String = "walk_anim/mixamo.com"
@export var run_anim_name: String = "run_anim/mixamo.com"

@onready var head = $head
@onready var camera = $head/Camera3D
@onready var anim_player = $Model/AnimationPlayer2

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	play_anim(idle_anim_name)

func _input(event):
	# F12 to quit so Escape can be used for UI
	if event is InputEventKey and event.keycode == KEY_F12 and event.pressed:
		get_tree().quit()

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate the whole body left/right
		rotate_y(-event.relative.x * SENSITIVITY)
		# Rotate only the head up/down
		if head:
			head.rotate_x(-event.relative.y * SENSITIVITY)
			head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	# Apply Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Sprinting
	var current_speed = sprint_speed if Input.is_key_pressed(KEY_SHIFT) else walk_speed

	# Movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
		
		# ANIMATION: Walking or Running
		if is_on_floor():
			if current_speed == sprint_speed:
				play_anim(run_anim_name)
			else:
				play_anim(walk_anim_name)
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		
		# ANIMATION: Idle
		if is_on_floor():
			play_anim(idle_anim_name)
	
	move_and_slide()

# Safe animation player function
func play_anim(anim_name: String):
	if anim_player and anim_player.has_animation(anim_name):
		if anim_player.current_animation != anim_name:
			anim_player.play(anim_name)
