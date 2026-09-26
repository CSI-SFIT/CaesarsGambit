# ProtoController v1.0 by Brackeys
# CC0 License
# Modified for third-person play:
#   - Mouse orbits the camera (yaw + pitch) independently of the body.
#   - WASD moves relative to the camera's facing, not the body's.
#   - The body smoothly rotates to face the direction you're moving.

extends CharacterBody3D

## Can we move around?
@export var can_move : bool = true
## Are we affected by gravity?
@export var has_gravity : bool = true
## Can we press to jump?
@export var can_jump : bool = true
## Can we hold to run?
@export var can_sprint : bool = false
## Can we press to enter freefly mode (noclip)?
@export var can_freefly : bool = false

@export_group("Speeds")
## Look around rotation speed.
@export var look_speed : float = 0.002
## How fast the body turns to face the movement direction.
@export var rotation_speed : float = 12.0
## Normal speed.
var base_speed : float
## Normal speed.
@export var on_ground_speed : float = 7.0
## In Air speed.
@export var in_air_speed : float = on_ground_speed * .6
## Speed of jump.
@export var jump_velocity : float = 4.5
## How fast do we run?
@export var sprint_speed : float = 10.0
## How fast do we freefly?
@export var freefly_speed : float = 25.0

@export_group("Camera")
## Lowest the camera can pitch (looking down), in degrees.
@export var min_pitch_deg : float = -40.0
## Highest the camera can pitch (looking up), in degrees.
@export var max_pitch_deg : float = 75.0

@export_group("Model")
## Turn on if your character mesh was modeled facing +Z instead of Godot's
## default -Z forward, and appears to walk backwards.
@export var model_faces_backwards : bool = false

@export_group("Input Actions")
## Name of Input Action to move Left.
@export var input_left : String = "move_left"
## Name of Input Action to move Right.
@export var input_right : String = "move_right"
## Name of Input Action to move Forward.
@export var input_forward : String = "move_forward"
## Name of Input Action to move Backward.
@export var input_back : String = "move_backward"
## Name of Input Action to Jump.
@export var input_jump : String = "jump"
## Name of Input Action to Sprint.
@export var input_sprint : String = "sprint"
## Name of Input Action to toggle freefly mode.
@export var input_freefly : String = "freefly"

var mouse_captured : bool = false
var look_rotation : Vector2  # x = pitch, y = yaw (camera only, world-space)
var move_speed : float = 0.0
var freeflying : bool = false
var head_local_offset : Vector3  # head's original position relative to the body (e.g. eye/chest height)

## IMPORTANT REFERENCES
@onready var head: Node3D = $head
@onready var collider: CollisionShape3D = $Collider

func _ready() -> void:
	check_input_mappings()
	# Start the camera's yaw matching the body's current facing.
	look_rotation.y = rotation.y
	look_rotation.x = head.rotation.x
	head_local_offset = head.position  # remember its height BEFORE going top_level
	head.top_level = true  # camera pivot ignores the body's rotation entirely
	head.global_transform.origin = global_transform.origin + head_local_offset
	base_speed = on_ground_speed

func _unhandled_input(event: InputEvent) -> void:
	# Mouse capturing
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		capture_mouse()
	if Input.is_key_pressed(KEY_ESCAPE):
		release_mouse()
	
	# Look around (mouse orbits the camera, independent of body facing)
	if mouse_captured and event is InputEventMouseMotion:
		rotate_look(event.relative)
	
	# Toggle freefly mode
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		if not freeflying:
			enable_freefly()
		else:
			disable_freefly()

func _physics_process(delta: float) -> void:
	# Keep the (top_level) camera pivot following the body's position each frame,
	# since top_level means it no longer inherits position automatically.
	head.global_transform.origin = global_transform.origin + head_local_offset

	# If freeflying, handle freefly and nothing else
	if can_freefly and freeflying:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var motion := (head.global_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		motion *= freefly_speed * delta
		move_and_collide(motion)
		return
	
	# Apply gravity to velocity
	if has_gravity:
		if not is_on_floor():
			velocity += get_gravity() * 2 * delta

	# Apply jumping
	if can_jump:
		if Input.is_action_just_pressed(input_jump) and is_on_floor():
			velocity.y = jump_velocity
			
	# Modifying Base Speed
	if !is_on_floor():
		base_speed = in_air_speed
	else:
		base_speed = on_ground_speed

	# Modify speed based on sprinting
	if can_sprint and Input.is_action_pressed(input_sprint):
		move_speed = sprint_speed
	else:
		move_speed = base_speed

	# Apply desired movement, relative to camera yaw (not body facing)
	if can_move:
		var input_dir := Input.get_vector(input_left, input_right, input_forward, input_back)
		var yaw_basis := Basis(Vector3.UP, look_rotation.y)
		var direction := (yaw_basis * Vector3(input_dir.x, 0, input_dir.y))
		if direction.length() > 0.01:
			direction = direction.normalized()
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			# Smoothly turn the body to face the direction we're moving
			var face_dir := direction if model_faces_backwards else -direction
			var target_basis := Basis.looking_at(face_dir, Vector3.UP)
			transform.basis = Basis(transform.basis.get_rotation_quaternion().slerp(
				target_basis.get_rotation_quaternion(), clamp(rotation_speed * delta, 0, 1)))
		else:
			velocity.x = move_toward(velocity.x, 0, move_speed)
			velocity.z = move_toward(velocity.z, 0, move_speed)
	else:
		velocity.x = 0
		velocity.y = 0
	
	# Use velocity to actually move
	move_and_slide()


## Orbit the camera pivot (head) around the player, in world space.
## This is fully independent of the body's own rotation.
func rotate_look(rot_input : Vector2):
	look_rotation.x -= rot_input.y * look_speed
	look_rotation.x = clamp(look_rotation.x, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
	look_rotation.y -= rot_input.x * look_speed
	head.global_rotation = Vector3(look_rotation.x, look_rotation.y, 0)


func enable_freefly():
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func disable_freefly():
	collider.disabled = false
	freeflying = false


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false


## Checks if some Input Actions haven't been created.
## Disables functionality accordingly.
func check_input_mappings():
	if can_move and not InputMap.has_action(input_left):
		push_error("Movement disabled. No InputAction found for input_left: " + input_left)
		can_move = false
	if can_move and not InputMap.has_action(input_right):
		push_error("Movement disabled. No InputAction found for input_right: " + input_right)
		can_move = false
	if can_move and not InputMap.has_action(input_forward):
		push_error("Movement disabled. No InputAction found for input_forward: " + input_forward)
		can_move = false
	if can_move and not InputMap.has_action(input_back):
		push_error("Movement disabled. No InputAction found for input_back: " + input_back)
		can_move = false
	if can_jump and not InputMap.has_action(input_jump):
		push_error("Jumping disabled. No InputAction found for input_jump: " + input_jump)
		can_jump = false
	if can_sprint and not InputMap.has_action(input_sprint):
		push_error("Sprinting disabled. No InputAction found for input_sprint: " + input_sprint)
		can_sprint = false
	if can_freefly and not InputMap.has_action(input_freefly):
		push_error("Freefly disabled. No InputAction found for input_freefly: " + input_freefly)
		can_freefly = false
