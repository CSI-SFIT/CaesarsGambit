extends CharacterBody3D
class_name RomanPlayer

signal reached_finish_line(player_id: int)

@export var player_id: int = 1:
	set(value):
		player_id = value
		if is_node_ready():
			update_player_appearance()

const SPEED: float = 7.5
const JUMP_VELOCITY: float = 9.0
const DIVE_FORWARD_BOOST: float = 8.0
const DIVE_UP_BOOST: float = 4.0
const MOUSE_SENSITIVITY: float = 0.003

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 22.0)
var spawn_position: Vector3 = Vector3(0, 2, 0)
var is_diving: bool = false
var dive_cooldown: float = 0.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visual_mesh: Node3D = $Visuals
@onready var tunic_mesh: MeshInstance3D = $Visuals/Tunic
@onready var cape_mesh: MeshInstance3D = $Visuals/Cape
@onready var shield_mesh: MeshInstance3D = $Visuals/Shield
@onready var helmet_crest: MeshInstance3D = $Visuals/Helmet/Crest
@onready var name_label: Label3D = $NameLabel

# Synchronized properties for multiplayer
@export var sync_pos: Vector3 = Vector3.ZERO
@export var sync_rot_y: float = 0.0

func _enter_tree() -> void:
	pass

func _ready() -> void:
	spawn_position = global_position
	update_player_appearance()
	
	# Only enable camera for local player
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	if camera:
		camera.current = is_local
	
	if is_local:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_player_appearance() -> void:
	if not tunic_mesh:
		return
		
	var mat_tunic = StandardMaterial3D.new()
	var mat_fabric = StandardMaterial3D.new()
	var mat_crest = StandardMaterial3D.new()
	
	if player_id == 1 or player_id <= 1:
		# Player 1: Royal Roman Crimson & Gold
		mat_tunic.albedo_color = Color(0.78, 0.12, 0.12)
		mat_fabric.albedo_color = Color(0.72, 0.12, 0.12)
		mat_crest.albedo_color = Color(0.95, 0.75, 0.1)
		mat_crest.emission_enabled = true
		mat_crest.emission = Color(0.9, 0.7, 0.1)
		if name_label:
			name_label.text = "Player 1 (Caesar)"
			name_label.modulate = Color(1.0, 0.85, 0.2)
	else:
		# Player 2: Roman Praetorian Azure & Silver
		mat_tunic.albedo_color = Color(0.15, 0.35, 0.8)
		mat_fabric.albedo_color = Color(0.12, 0.3, 0.75)
		mat_crest.albedo_color = Color(0.3, 0.6, 0.95)
		mat_crest.emission_enabled = true
		mat_crest.emission = Color(0.2, 0.5, 0.9)
		if name_label:
			name_label.text = "Player 2 (Centurion)"
			name_label.modulate = Color(0.4, 0.8, 1.0)
			
	tunic_mesh.material_override = mat_tunic
	if cape_mesh:
		cape_mesh.material_override = mat_fabric
	if shield_mesh:
		shield_mesh.material_override = mat_fabric
	if helmet_crest:
		helmet_crest.material_override = mat_crest

func _input(event: InputEvent) -> void:
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	if not is_local:
		return
		
	# Click anywhere in the game to capture mouse
	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Mouse look (when captured OR when holding right-click)
	if event is InputEventMouseMotion:
		var can_rotate = (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		if can_rotate and camera_pivot and spring_arm:
			camera_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
			spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, -PI / 3.0, PI / 6.0)
		
	# Escape to toggle mouse capture
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

var screen_shake_intensity: float = 0.0

func add_screen_shake(amount: float) -> void:
	screen_shake_intensity = amount

func _process(delta: float) -> void:
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	if not is_local:
		return
		
	# Screen shake decay
	if camera:
		if screen_shake_intensity > 0.0:
			camera.h_offset = randf_range(-screen_shake_intensity, screen_shake_intensity)
			camera.v_offset = randf_range(-screen_shake_intensity, screen_shake_intensity)
			screen_shake_intensity = move_toward(screen_shake_intensity, 0.0, 4.0 * delta)
		else:
			camera.h_offset = 0.0
			camera.v_offset = 0.0

	# Keyboard camera rotation (Q/E or Arrow Left/Right)
	var cam_turn: float = 0.0
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_Q):
		cam_turn += 2.2 * delta
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_E):
		cam_turn -= 2.2 * delta
	if cam_turn != 0.0 and camera_pivot:
		camera_pivot.rotate_y(cam_turn)

func _physics_process(delta: float) -> void:
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	
	if not is_local:
		# Smooth remote client interpolation
		global_position = global_position.lerp(sync_pos, 25.0 * delta)
		if visual_mesh:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, sync_rot_y, 20.0 * delta)
		return

	# Decrement dive cooldown
	if dive_cooldown > 0.0:
		dive_cooldown -= delta
	if is_diving and is_on_floor():
		is_diving = false

	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Fall Guys Style Dive (gives forward boost and can tackle opponents!)
	if Input.is_action_just_pressed("dive") and not is_diving and dive_cooldown <= 0.0:
		is_diving = true
		dive_cooldown = 0.8
		velocity.y = DIVE_UP_BOOST
		var forward = -camera_pivot.global_transform.basis.z
		velocity.x = forward.x * DIVE_FORWARD_BOOST
		velocity.z = forward.z * DIVE_FORWARD_BOOST

	# Movement direction relative to camera
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var cam_basis: Basis = camera_pivot.global_transform.basis
	var forward: Vector3 = -cam_basis.z
	var right: Vector3 = cam_basis.x
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()

	var direction: Vector3 = (right * input_dir.x + forward * -input_dir.y).normalized()

	if not is_diving:
		if direction:
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
			# Rotate character towards movement
			if visual_mesh:
				var target_angle = atan2(-direction.x, -direction.z)
				visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_angle, 15.0 * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED * 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0, SPEED * 8.0 * delta)

	move_and_slide()

	# Fall Guys Player-to-Player Bumping & Tackling
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider is CharacterBody3D and collider != self:
			var push_dir = (collider.global_position - global_position).normalized()
			push_dir.y = 0.4
			var push_power = 15.0 if is_diving else 6.0
			collider.velocity += push_dir * push_power

	# Fall check / Respawn with screen shake
	if global_position.y < -12.0:
		add_screen_shake(0.3)
		respawn()

	# Update network sync variables
	sync_pos = global_position
	if visual_mesh:
		sync_rot_y = visual_mesh.rotation.y

func respawn() -> void:
	global_position = spawn_position + Vector3(randf_range(-1, 1), 1.0, randf_range(-1, 1))
	velocity = Vector3.ZERO
	is_diving = false
