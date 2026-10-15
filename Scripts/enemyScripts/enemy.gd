extends CharacterBody3D

enum State { PATROL, CHASE, INVESTIGATE, LUNGE }
var current_state: State = State.PATROL

@export_group("Speeds")
@export var moveSpeed: float = 4.0
@export var chaseSpeed: float = 6.2
@export var patrol_speed: float = 3.5
@export var investigate_speed: float = 4.5
@export var lunge_speed: float = 14.0

@export_group("Patrol Settings")
@export var patrol_radius: float = 14.0
@export var min_patrol_distance: float = 3.5

@export_group("Chase & Teleport Timers")
@export var maxChaseTime: float = 6.0
@export var maxWaitTime: float = 1.5
@export var maxInvestigateWait: float = 2.0
@export var investigate_timeout: float = 6.0
@export var arrival_tolerance: float = 1.2

@export_group("Combat & Lunge")
@export var lunge_range: float = 3.8
@export var lunge_cooldown_time: float = 3.5
@export var lunge_duration: float = 0.35
@export var attack_damage: int = 25

@export_group("Search & Intercept")
@export var search_radius: float = 5.0
@export var sub_search_points: int = 2
@export var prediction_lead_time: float = 0.45

# Node References
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var los_ray: RayCast3D = $LineOfSightRay
@onready var hitbox: Area3D = $AttackHitbox

# State & Tracking Variables
var Player: CharacterBody3D = null
var player_lastPosition: Vector3 = Vector3.ZERO
var last_seen_position: Vector3 = Vector3.ZERO
var home_position: Vector3 = Vector3.ZERO

var timer: float = 0.0
var startTimer: bool = false
var is_playerDetected: bool = false
var is_waiting: bool = false

var search_points_remaining: int = 0
var investigate_timer: float = 0.0
var lunge_cooldown_timer: float = 0.0

func _ready() -> void:
	randomize()
	timer = 0.0
	startTimer = false
	is_playerDetected = false
	home_position = global_position

	# Setup tolerances to avoid micro-jitter at destination points
	nav_agent.target_desired_distance = 1.2
	nav_agent.path_desired_distance = 1.0

	# Wait for NavigationServer synchronization
	await get_tree().physics_frame
	
	# Desync the first path query so all enemies don't pathfind simultaneously on spawn
	await get_tree().create_timer(randf_range(0.05, 0.45)).timeout
	_set_random_patrol_target()

func _process(delta: float) -> void:
	if startTimer:
		timer += delta
	
	# If chase exceeds max duration, teleport the player and reset
	if timer >= maxChaseTime:
		timer = 0.0
		startTimer = false
		is_playerDetected = false
		
		if is_instance_valid(Player):
			var spawn_pos: Vector3 = GameManager.getSpawnPointPosition(GameManager.SpawnPointNames.PlayerSpawnPoint_Church)
			
			if Player.has_method("teleport_to"):
				Player.teleport_to(spawn_pos)
			else:
				Player.global_position = spawn_pos
				Player.velocity = Vector3.ZERO
			
			Player = null
		
		# Return enemy to patrol
		current_state = State.PATROL
		_set_random_patrol_target()

	# If sight is lost before the timer expires, reset timer
	elif not is_playerDetected:
		timer = 0.0
		startTimer = false

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Track attack cooldown
	if lunge_cooldown_timer > 0.0:
		lunge_cooldown_timer -= delta

	# State execution
	match current_state:
		State.LUNGE:
			pass
		State.CHASE:
			_process_chase()
		State.INVESTIGATE:
			_process_investigate(delta)
		State.PATROL:
			_process_patrol()

	move_and_slide()

# --- State Handlers ---

func _process_chase() -> void:
	if not is_instance_valid(Player):
		_begin_investigation(last_seen_position)
		return

	# Confirm unobstructed sightline through walls
	if has_line_of_sight(Player):
		last_seen_position = Player.global_position
		player_lastPosition = Player.global_position

		# Check lunge distance
		var distance_to_player := global_position.distance_to(Player.global_position)
		if distance_to_player <= lunge_range and lunge_cooldown_timer <= 0.0:
			_trigger_lunge()
			return

		# Predictive trajectory targeting
		var map_rid := nav_agent.get_navigation_map()
		var predicted_point := Player.global_position + (Player.velocity * prediction_lead_time)
		nav_agent.target_position = NavigationServer3D.map_get_closest_point(map_rid, predicted_point)
		
		_move_along_path(chaseSpeed)
	else:
		_begin_investigation(last_seen_position)

func _process_investigate(delta: float) -> void:
	if is_waiting:
		_apply_friction(investigate_speed)
		return

	investigate_timer += delta

	var horizontal_dist := Vector2(
		global_position.x - last_seen_position.x,
		global_position.z - last_seen_position.z
	).length()

	# Arrived at point or timed out
	if nav_agent.is_navigation_finished() or horizontal_dist <= arrival_tolerance or investigate_timer >= investigate_timeout:
		investigate_timer = 0.0
		_search_next_or_patrol()
	else:
		_move_along_path(investigate_speed)

func _process_patrol() -> void:
	if is_waiting:
		_apply_friction(patrol_speed)
		return

	if nav_agent.is_navigation_finished():
		_wait_and_pick_next_patrol()
	else:
		_move_along_path(patrol_speed)

# --- Line of Sight & Combat Mechanics ---

func has_line_of_sight(target: CharacterBody3D) -> bool:
	if not is_instance_valid(los_ray):
		return true

	var eye_height := global_position + Vector3(0, 1.4, 0)
	var target_chest := target.global_position + Vector3(0, 1.0, 0)
	
	los_ray.global_position = eye_height
	los_ray.target_position = los_ray.to_local(target_chest)
	los_ray.force_raycast_update()

	if los_ray.is_colliding():
		return los_ray.get_collider() == target
	return false

func _trigger_lunge() -> void:
	current_state = State.LUNGE
	lunge_cooldown_timer = lunge_cooldown_time

	var lunge_dir := (Player.global_position - global_position)
	lunge_dir.y = 0.0
	lunge_dir = lunge_dir.normalized()

	if lunge_dir.length_squared() > 0.01:
		look_at(global_position + lunge_dir, Vector3.UP)

	velocity = lunge_dir * lunge_speed

	await get_tree().create_timer(lunge_duration).timeout

	if is_instance_valid(Player) and has_line_of_sight(Player):
		current_state = State.CHASE
	else:
		_begin_investigation(last_seen_position)

# --- Navigation & Transitions ---

func _begin_investigation(target_spot: Vector3) -> void:
	current_state = State.INVESTIGATE
	search_points_remaining = sub_search_points
	investigate_timer = 0.0
	is_waiting = false

	var map_rid := nav_agent.get_navigation_map()
	last_seen_position = NavigationServer3D.map_get_closest_point(map_rid, target_spot)
	player_lastPosition = last_seen_position
	nav_agent.target_position = last_seen_position

func _search_next_or_patrol() -> void:
	if search_points_remaining > 0:
		search_points_remaining -= 1
		is_waiting = true
		await get_tree().create_timer(maxInvestigateWait).timeout
		is_waiting = false

		if current_state == State.INVESTIGATE:
			var map_rid := nav_agent.get_navigation_map()
			var angle := randf_range(0.0, TAU)
			var offset := Vector3(cos(angle), 0, sin(angle)) * randf_range(2.0, search_radius)
			last_seen_position = NavigationServer3D.map_get_closest_point(map_rid, last_seen_position + offset)
			nav_agent.target_position = last_seen_position
	else:
		is_waiting = true
		await get_tree().create_timer(maxInvestigateWait).timeout
		is_waiting = false
		if current_state == State.INVESTIGATE:
			current_state = State.PATROL
			_set_random_patrol_target()

func _move_along_path(speed: float) -> void:
	var next_path_pos: Vector3 = nav_agent.get_next_path_position()
	var current_pos: Vector3 = global_position
	var dir: Vector3 = (next_path_pos - current_pos).normalized()

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	var horizontal_dir := Vector3(velocity.x, 0, velocity.z)
	if horizontal_dir.length_squared() > 0.01:
		look_at(current_pos + horizontal_dir, Vector3.UP)

func _apply_friction(speed: float) -> void:
	velocity.x = move_toward(velocity.x, 0, speed)
	velocity.z = move_toward(velocity.z, 0, speed)

func _set_random_patrol_target() -> void:
	var map_rid := nav_agent.get_navigation_map()

	# Generate random angle and distance around the enemy's local origin
	var random_angle := randf_range(0.0, TAU)
	var random_dist := randf_range(min_patrol_distance, patrol_radius)
	var offset := Vector3(cos(random_angle), 0.0, sin(random_angle)) * random_dist

	# Project point onto the nearest valid NavMesh polygon
	var candidate_pos: Vector3 = home_position + offset
	var valid_point: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, candidate_pos)

	nav_agent.target_position = valid_point

func _wait_and_pick_next_patrol() -> void:
	is_waiting = true
	# Randomize pause between 50% and 150% of maxWaitTime to desynchronize pacing
	var staggered_wait := randf_range(maxWaitTime * 0.5, maxWaitTime * 1.5)
	await get_tree().create_timer(staggered_wait).timeout
	is_waiting = false

	if current_state == State.PATROL:
		_set_random_patrol_target()

# --- Eyesight & Attack Signals ---

func _on_eyesight_body_entered(body: Object) -> void:
	if body.is_in_group("PlayerGroup") and body is CharacterBody3D:
		Player = body
		is_playerDetected = true
		startTimer = true
		timer = 0.0
		last_seen_position = body.global_position
		player_lastPosition = body.global_position
		current_state = State.CHASE
		is_waiting = false

func _on_eyesight_body_exited(body: Object) -> void:
	if body == Player:
		is_playerDetected = false
		startTimer = false
		timer = 0.0
		
		var raw_exit_pos := Player.global_position
		Player = null
		_begin_investigation(raw_exit_pos)

func _on_attack_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("PlayerGroup") and body.has_method("take_damage"):
		body.take_damage(attack_damage)

# --- Public Queries ---

func isPlayerDetected() -> bool:
	return is_playerDetected

func isEnemyWaiting() -> bool:
	return is_waiting
