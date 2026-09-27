extends CharacterBody3D
class_name RomanPlayer

signal reached_finish_line(player_id: int)

@export var player_id: int = 1:
	set(value):
		player_id = value
		if is_node_ready():
			update_player_appearance()

# Snappy Fall Guys platformer constants
const RUN_SPEED: float = 8.5
const ACCELERATION: float = 38.0
const FRICTION: float = 30.0

const JUMP_VELOCITY: float = 11.5
const JUMP_GRAVITY: float = 28.0
const FALL_GRAVITY: float = 42.0
const TERMINAL_VELOCITY: float = -35.0

const DIVE_FORWARD_BOOST: float = 13.0
const DIVE_UP_BOOST: float = 3.2
const MOUSE_SENSITIVITY: float = 0.004

var spawn_position: Vector3 = Vector3(0, 2, 0)
var is_diving: bool = false
var dive_cooldown: float = 0.0
var dive_slide_timer: float = 0.0

# Coyote time & Jump buffer
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Spectator camera mode
var is_spectating: bool = false
var spectator_target: Node3D = null

# Procedural limb animation variables
var foot_anim_time: float = 0.0
var footstep_cooldown: float = 0.0
var was_on_floor: bool = true

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visual_mesh: Node3D = $Visuals
@onready var tunic_mesh: MeshInstance3D = $Visuals/Tunic
@onready var cape_mesh: MeshInstance3D = $Visuals/Cape
@onready var shield_mesh: MeshInstance3D = $Visuals/Shield
@onready var helmet_crest: MeshInstance3D = $Visuals/Helmet/Crest
@onready var foot_left: MeshInstance3D = $Visuals/FootLeft
@onready var foot_right: MeshInstance3D = $Visuals/FootRight
@onready var arm_right: MeshInstance3D = $Visuals/ArmRight
@onready var name_label: Label3D = $NameLabel

var sound_fx: Node

# Synchronized properties for multiplayer
@export var sync_pos: Vector3 = Vector3.ZERO
@export var sync_rot_y: float = 0.0

func _ready() -> void:
	update_player_appearance()
	
	sound_fx = get_node_or_null("/root/Main/SoundEffects")
	if not sound_fx:
		var m = get_tree().root.get_node_or_null("Main")
		if m and "sound_fx" in m:
			sound_fx = m.sound_fx
	
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	if camera:
		camera.current = is_local

func update_player_appearance() -> void:
	if not tunic_mesh or not visual_mesh:
		return
		
	var mat_tunic = StandardMaterial3D.new()
	var mat_fabric = StandardMaterial3D.new()
	var mat_crest = StandardMaterial3D.new()
	var mat_armor = StandardMaterial3D.new()
	
	if player_id == 1 or player_id <= 1:
		# Player 1: Royal Crimson & Gold Imperial Caesar
		mat_tunic.albedo_color = Color(0.78, 0.12, 0.12)
		mat_fabric.albedo_color = Color(0.72, 0.10, 0.10)
		mat_crest.albedo_color = Color(0.98, 0.82, 0.15)
		mat_crest.emission_enabled = true
		mat_crest.emission = Color(0.95, 0.75, 0.1)
		mat_crest.emission_energy_multiplier = 2.5
		
		mat_armor.albedo_color = Color(0.92, 0.75, 0.22)
		mat_armor.metallic = 0.88
		mat_armor.roughness = 0.25
		
		if name_label:
			name_label.text = "Caesar (Player 1)"
			name_label.modulate = Color(1.0, 0.85, 0.2)
	else:
		# Player 2: Cobalt Blue & Silver Steel Centurion
		mat_tunic.albedo_color = Color(0.12, 0.35, 0.82)
		mat_fabric.albedo_color = Color(0.10, 0.30, 0.78)
		mat_crest.albedo_color = Color(0.35, 0.70, 1.0)
		mat_crest.emission_enabled = true
		mat_crest.emission = Color(0.25, 0.60, 0.95)
		mat_crest.emission_energy_multiplier = 2.5
		
		mat_armor.albedo_color = Color(0.85, 0.88, 0.92)
		mat_armor.metallic = 0.95
		mat_armor.roughness = 0.20
		
		if name_label:
			name_label.text = "Centurion (Player 2)"
			name_label.modulate = Color(0.4, 0.8, 1.0)
			
	tunic_mesh.material_override = mat_tunic
	if cape_mesh:
		cape_mesh.material_override = mat_fabric
	if shield_mesh:
		shield_mesh.material_override = mat_fabric
	if helmet_crest:
		helmet_crest.material_override = mat_crest
		
	var cuirass = visual_mesh.get_node_or_null("Cuirass")
	if cuirass is MeshInstance3D:
		cuirass.material_override = mat_armor
	var dome = visual_mesh.get_node_or_null("Helmet/Dome")
	if dome is MeshInstance3D:
		dome.material_override = mat_armor
	var s_left = visual_mesh.get_node_or_null("ShoulderLeft")
	if s_left is MeshInstance3D:
		s_left.material_override = mat_armor
	var s_right = visual_mesh.get_node_or_null("ShoulderRight")
	if s_right is MeshInstance3D:
		s_right.material_override = mat_armor

func start_spectating(target: Node3D) -> void:
	is_spectating = true
	spectator_target = target
	velocity = Vector3.ZERO

func stop_spectating() -> void:
	is_spectating = false
	spectator_target = null
	if camera_pivot:
		camera_pivot.position = Vector3(0, 1.45, 0)

func _unhandled_input(event: InputEvent) -> void:
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	if not is_local:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not is_spectating:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	if not is_local:
		return

	var can_rotate = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or is_spectating
	if event is InputEventMouseMotion and can_rotate and camera_pivot and spring_arm:
		camera_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		spring_arm.rotation.x = clampf(spring_arm.rotation.x, deg_to_rad(-60.0), deg_to_rad(30.0))

func _physics_process(delta: float) -> void:
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	
	if not is_local:
		global_position = global_position.lerp(sync_pos, 25.0 * delta)
		if visual_mesh:
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, sync_rot_y, 20.0 * delta)
		return

	# Spectator Mode Camera Tracking
	if is_spectating:
		if is_instance_valid(spectator_target):
			var target_cam_pos = spectator_target.global_position + Vector3(0, 1.45, 0)
			camera_pivot.global_position = camera_pivot.global_position.lerp(target_cam_pos, delta * 8.0)
		velocity = Vector3.ZERO
		move_and_slide()
		return

	# Decrement cooldowns
	if dive_cooldown > 0.0:
		dive_cooldown -= delta
	if dive_slide_timer > 0.0:
		dive_slide_timer -= delta
		if dive_slide_timer <= 0.0 and is_diving:
			is_diving = false
			if visual_mesh:
				visual_mesh.rotation.x = 0.0
	if footstep_cooldown > 0.0:
		footstep_cooldown -= delta

	# Coyote Time & Jump Buffer
	if is_on_floor():
		coyote_timer = 0.15
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.12
	else:
		jump_buffer_timer -= delta

	# Landing thud sound
	if is_on_floor() and not was_on_floor:
		if sound_fx and sound_fx.has_method("play_landing"):
			sound_fx.play_landing()
	was_on_floor = is_on_floor()

	# Dual-stage gravity
	if not is_on_floor():
		var current_gravity = JUMP_GRAVITY if velocity.y > 0.0 else FALL_GRAVITY
		velocity.y -= current_gravity * delta
		velocity.y = maxf(velocity.y, TERMINAL_VELOCITY)
	else:
		velocity.y = 0.0

	# Jump execution
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0 and not is_diving:
		velocity.y = JUMP_VELOCITY
		jump_buffer_timer = 0.0
		coyote_timer = 0.0

	# Fall Guys Belly-Flop Dive
	if Input.is_action_just_pressed("dive") and not is_diving and dive_cooldown <= 0.0:
		is_diving = true
		dive_cooldown = 0.8
		dive_slide_timer = 0.45
		var forward_dir = -camera_pivot.global_transform.basis.z
		forward_dir.y = 0.0
		forward_dir = forward_dir.normalized()
		velocity.x = forward_dir.x * DIVE_FORWARD_BOOST
		velocity.z = forward_dir.z * DIVE_FORWARD_BOOST
		velocity.y = DIVE_UP_BOOST
		if visual_mesh:
			visual_mesh.rotation.x = deg_to_rad(-60.0)

	# Movement direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var cam_basis: Basis = camera_pivot.global_transform.basis
	var move_direction = (cam_basis.x * input_dir.x + cam_basis.z * input_dir.y)
	move_direction.y = 0.0
	move_direction = move_direction.normalized()

	# Keyboard camera turn
	if InputMap.has_action("camera_right") and InputMap.has_action("camera_left"):
		var cam_turn = Input.get_axis("camera_right", "camera_left") * 2.8 * delta
		if cam_turn != 0.0 and camera_pivot:
			camera_pivot.rotate_y(cam_turn)

	# Movement physics & acceleration
	var current_accel = ACCELERATION if is_on_floor() else (ACCELERATION * 0.45)
	var current_friction = FRICTION if is_on_floor() else (FRICTION * 0.15)
	
	if is_diving:
		velocity.x = move_toward(velocity.x, 0.0, current_friction * 0.4 * delta)
		velocity.z = move_toward(velocity.z, 0.0, current_friction * 0.4 * delta)
	elif move_direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, move_direction.x * RUN_SPEED, current_accel * delta)
		velocity.z = move_toward(velocity.z, move_direction.z * RUN_SPEED, current_accel * delta)
		if visual_mesh and not is_diving:
			var target_angle = atan2(move_direction.x, move_direction.z)
			visual_mesh.rotation.y = lerp_angle(visual_mesh.rotation.y, target_angle, 18.0 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_friction * delta)
		velocity.z = move_toward(velocity.z, 0.0, current_friction * delta)

	# -------------------------------------------------------------
	# Procedural Limb & Character Animation
	# -------------------------------------------------------------
	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	if is_diving:
		# Superhero belly flop dive pose
		if foot_left:
			foot_left.position = Vector3(-0.22, 0.28, -0.32)
		if foot_right:
			foot_right.position = Vector3(0.22, 0.28, -0.32)
		if arm_right:
			arm_right.rotation.x = deg_to_rad(-75.0)
		if cape_mesh:
			cape_mesh.rotation.x = deg_to_rad(45.0)
	elif horiz_speed > 0.5 and is_on_floor():
		# Snappy running foot pitter-patter & arm pump
		foot_anim_time += delta * horiz_speed * 1.7
		var step_l = sin(foot_anim_time)
		var step_r = -step_l
		
		if foot_left:
			foot_left.position.z = step_l * 0.24
			foot_left.position.y = 0.12 + maxf(0.0, step_l * 0.14)
		if foot_right:
			foot_right.position.z = step_r * 0.24
			foot_right.position.y = 0.12 + maxf(0.0, step_r * 0.14)
		if arm_right:
			arm_right.rotation.x = -step_l * 0.48
		if cape_mesh:
			cape_mesh.rotation.x = deg_to_rad(12.0 + (horiz_speed / RUN_SPEED) * 26.0 + sin(foot_anim_time * 2.0) * 4.0)
			
		# Step audio rhythm
		if step_l > 0.85 and footstep_cooldown <= 0.0:
			if sound_fx and sound_fx.has_method("play_footstep"):
				sound_fx.play_footstep()
			footstep_cooldown = 0.24
	else:
		# Idle gentle breathing bob
		var idle_t = Time.get_ticks_msec() * 0.003
		if visual_mesh:
			visual_mesh.position.y = sin(idle_t) * 0.025
		if foot_left:
			foot_left.position = Vector3(-0.22, 0.12, 0.05)
		if foot_right:
			foot_right.position = Vector3(0.22, 0.12, 0.05)
		if arm_right:
			arm_right.rotation.x = lerp_angle(arm_right.rotation.x, 0.0, 10.0 * delta)
		if cape_mesh:
			cape_mesh.rotation.x = deg_to_rad(10.0 + sin(idle_t * 1.5) * 2.5)

	move_and_slide()

	# Void fall respawn
	if global_position.y < -8.0:
		respawn()

	# Multiplayer sync
	if multiplayer.multiplayer_peer != null:
		sync_pos = global_position
		if visual_mesh:
			sync_rot_y = visual_mesh.rotation.y

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	is_diving = false
	if visual_mesh:
		visual_mesh.rotation.x = 0.0
