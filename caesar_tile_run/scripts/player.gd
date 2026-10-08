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

const ANIM_IDLE: String = "idle_anim/mixamo_com"
const ANIM_RUN: String = "run_anim/mixamo_com"
const ANIM_JUMP: String = "jump_anim/mixamo_com"

var spawn_position: Vector3 = Vector3(0, 1.5, 0)
var is_diving: bool = false
var was_airborne_dive: bool = false
var dive_cooldown: float = 0.0
var dive_slide_timer: float = 0.0

# Coyote time & Jump buffer
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Spectator camera mode
var is_spectating: bool = false
var spectator_target: Node3D = null

# Victory celebration state
var is_triumph: bool = false

var footstep_cooldown: float = 0.0
var was_on_floor: bool = true

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var visual_mesh: Node3D = $Visuals
@onready var soldier_model: Node3D = $Visuals/Model
@onready var anim_player: AnimationPlayer = $Visuals/Model/AnimationPlayer2
@onready var ground_aura: MeshInstance3D = $Visuals/GroundAura
@onready var name_label: Label3D = $NameLabel

var trauma: float = 0.0
var intro_cinematic_timer: float = 2.2
var sound_fx: Node

# Synchronized properties for multiplayer
@export var sync_pos: Vector3 = Vector3.ZERO
@export var sync_rot_y: float = 0.0

func _ready() -> void:
	add_to_group("player")
	update_player_appearance()
	if visual_mesh:
		visual_mesh.rotation.y = 0.0
	
	if is_inside_tree() and get_tree().root:
		var m = get_tree().root.get_node_or_null("Main")
		if m and "sound_fx" in m:
			sound_fx = m.sound_fx
	
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	if camera:
		camera.current = is_local

func add_screen_shake(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func add_trauma(amount: float) -> void:
	add_screen_shake(amount)

func update_player_appearance() -> void:
	if not is_inside_tree():
		return

	var is_caesar = (player_id == 1 or player_id <= 1)
	
	# Name label & colors
	if name_label:
		if is_caesar:
			name_label.text = "Caesar (Player 1)"
			name_label.modulate = Color(1.0, 0.85, 0.2)
		else:
			name_label.text = "Centurion (Player 2)"
			name_label.modulate = Color(0.4, 0.8, 1.0)
			
	# Ground aura styling
	if ground_aura:
		var aura_mat = StandardMaterial3D.new()
		aura_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		if is_caesar:
			aura_mat.albedo_color = Color(0.95, 0.8, 0.2, 0.5)
			aura_mat.emission_enabled = true
			aura_mat.emission = Color(0.95, 0.8, 0.2)
			aura_mat.emission_energy_multiplier = 1.3
		else:
			aura_mat.albedo_color = Color(0.2, 0.6, 1.0, 0.5)
			aura_mat.emission_enabled = true
			aura_mat.emission = Color(0.2, 0.6, 1.0)
			aura_mat.emission_energy_multiplier = 1.3
		ground_aura.material_override = aura_mat

	# Tint soldier meshes to reflect Roman faction
	if soldier_model:
		var tint_color = Color(1.0, 0.88, 0.75) if is_caesar else Color(0.85, 0.92, 1.0)
		_apply_team_tint(soldier_model, tint_color)

func _apply_team_tint(node: Node, tint: Color) -> void:
	if node is MeshInstance3D:
		for i in range(node.get_surface_override_material_count()):
			var mat = node.get_active_material(i)
			if mat is StandardMaterial3D:
				var new_mat = mat.duplicate()
				new_mat.albedo_color = new_mat.albedo_color * tint
				node.set_surface_override_material(i, new_mat)
	for child in node.get_children():
		_apply_team_tint(child, tint)

func start_spectating(target: Node3D) -> void:
	is_spectating = true
	spectator_target = target
	velocity = Vector3.ZERO

func stop_spectating() -> void:
	is_spectating = false
	spectator_target = null
	if camera_pivot:
		camera_pivot.position = Vector3(0, 1.45, 0)

func set_triumph(active: bool) -> void:
	is_triumph = active
	if visual_mesh:
		visual_mesh.position = Vector3.ZERO
		visual_mesh.rotation.x = 0.0
	if is_triumph:
		if anim_player:
			anim_player.play(ANIM_JUMP, 0.2, 0.8)
	else:
		if anim_player:
			anim_player.play(ANIM_IDLE, 0.2)

func _unhandled_input(event: InputEvent) -> void:
	var is_local = (multiplayer.multiplayer_peer == null) or is_multiplayer_authority()
	if not is_local:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_spectating:
			return
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		if camera_pivot:
			camera_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		if spring_arm:
			spring_arm.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
			spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-65.0), deg_to_rad(25.0))

func _physics_process(delta: float) -> void:
	# Intro Cinematic Camera Sweep
	if intro_cinematic_timer > 0.0:
		intro_cinematic_timer -= delta
		var t = clampf(1.0 - (intro_cinematic_timer / 2.2), 0.0, 1.0)
		var ease_t = 1.0 - pow(1.0 - t, 3.0)
		if spring_arm:
			spring_arm.spring_length = lerpf(9.5, 4.6, ease_t)
			spring_arm.rotation.x = lerpf(deg_to_rad(-45.0), deg_to_rad(-12.0), ease_t)

	# Dynamic Camera Trauma & FOV Punch
	if trauma > 0.0:
		trauma = maxf(0.0, trauma - delta * 1.6)
		var shake = trauma * trauma
		if camera:
			camera.h_offset = randf_range(-0.16, 0.16) * shake
			camera.v_offset = randf_range(-0.16, 0.16) * shake
			camera.fov = 75.0 + (shake * 8.0)
	elif camera and camera.fov != 75.0:
		camera.h_offset = 0.0
		camera.v_offset = 0.0
		camera.fov = move_toward(camera.fov, 75.0, delta * 30.0)

	# Detect dive floor impact
	if is_diving and not is_on_floor():
		was_airborne_dive = true
	elif is_diving and is_on_floor() and was_airborne_dive:
		was_airborne_dive = false
		spawn_dive_impact_dust()
	elif not is_diving:
		was_airborne_dive = false

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

	# Triumph Celebration State
	if is_triumph:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		velocity.z = move_toward(velocity.z, 0.0, FRICTION * delta)
		if not is_on_floor():
			velocity.y -= FALL_GRAVITY * delta
		else:
			velocity.y = 0.0
		if visual_mesh:
			visual_mesh.position.y = 0.0
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
		if sound_fx and sound_fx.has_method("play_jump"):
			sound_fx.play_jump()

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
			visual_mesh.rotation.x = deg_to_rad(-45.0)

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

	# Soldier Animation Playback
	var horiz_speed = Vector2(velocity.x, velocity.z).length()
	if anim_player:
		if not is_on_floor():
			if anim_player.current_animation != ANIM_JUMP:
				anim_player.play(ANIM_JUMP, 0.12, 1.3)
		elif is_diving:
			if anim_player.current_animation != ANIM_JUMP:
				anim_player.play(ANIM_JUMP, 0.1, 1.6)
		elif horiz_speed > 0.5:
			var speed_factor = clampf(horiz_speed / RUN_SPEED, 0.65, 1.25)
			if anim_player.current_animation != ANIM_RUN:
				anim_player.play(ANIM_RUN, 0.15, speed_factor)
			else:
				anim_player.speed_scale = speed_factor
			
			if footstep_cooldown <= 0.0:
				if sound_fx and sound_fx.has_method("play_footstep"):
					sound_fx.play_footstep()
				footstep_cooldown = 0.32
		else:
			if anim_player.current_animation != ANIM_IDLE:
				anim_player.play(ANIM_IDLE, 0.2, 1.0)

	move_and_slide()

	# Subterranean pit fall respawn
	if global_position.y < -2.8:
		respawn()

	# Multiplayer sync
	sync_pos = global_position
	if visual_mesh:
		sync_rot_y = visual_mesh.rotation.y

func respawn() -> void:
	velocity = Vector3.ZERO
	global_position = spawn_position
	is_diving = false
	is_triumph = false
	if visual_mesh:
		visual_mesh.position = Vector3.ZERO
		visual_mesh.rotation = Vector3.ZERO
	add_screen_shake(0.35)
	if sound_fx and sound_fx.has_method("play_tile_crumble"):
		sound_fx.play_tile_crumble()
	spawn_dive_impact_dust()

func spawn_dive_impact_dust() -> void:
	var particles = CPUParticles3D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = 18
	particles.lifetime = 0.45
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 75.0
	particles.initial_velocity_min = 2.5
	particles.initial_velocity_max = 4.5
	
	var mesh = SphereMesh.new()
	mesh.radius = 0.08
	mesh.height = 0.16
	particles.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.75, 0.60, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	particles.material_override = mat
	
	get_parent().add_child(particles)
	particles.global_position = global_position + Vector3(0, 0.15, 0)
	particles.emitting = true
	
	get_tree().create_timer(0.6).timeout.connect(particles.queue_free)
