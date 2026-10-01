extends CharacterBody3D

const SPEED = 5.0
const SENSITIVITY = 0.003

# Get the gravity from Godot's built-in settings so we can walk down stairs!
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var camera: Camera3D

func _ready():
	# Dynamically find whatever camera the proto_controller uses
	camera = find_child("Camera3D", true, false)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Only allow looking around if the UI is closed (mouse is captured)
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * SENSITIVITY)
		if camera:
			camera.rotate_x(-event.relative.y * SENSITIVITY)
			camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	# Apply Gravity so we don't float over the stairs
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Use the default UI inputs that are already set up in your project.godot file
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
