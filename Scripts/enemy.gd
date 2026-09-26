extends CharacterBody3D

@export var moveSpeed: float = 4.0
@export var chaseSpeed: float = 5.0
@export var maxWaitTime: float = 1.5
@export var maxChaseTime: float = 1.0

var timer: float = 0.0
var startTimer = false

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var Player:CharacterBody3D

var is_waiting: bool = false
var is_playerDetected: bool = false

func _ready() -> void:
	timer = 0.0
	#print(GameManager.spawnPoints)
	# NavigationServer needs one physics frame to synchronize before queries work
	await get_tree().physics_frame
	set_target_position(get_random_position())

func set_target_position(target: Vector3) -> void:
	nav_agent.target_position = target

func get_random_position() -> Vector3:
	# Get the active navigation map RID
	var map_rid = nav_agent.get_navigation_map()
	
	# Fetch a truly random point on the baked navigation mesh
	var random_point = NavigationServer3D.map_get_random_point(map_rid, 1, false)
	return random_point

func _process(delta: float) -> void:
	if(startTimer):
		timer+=delta
	
	if(timer >= maxChaseTime):
		timer=0
		#print(str(GameManager.SpawnPointNames.Church))
		Player.global_position = GameManager.getSpawnPointPosition(GameManager.SpawnPointNames.Church)

func _physics_process(delta: float) -> void:
	# If paused between patrol points, just apply gravity
	
	if is_playerDetected:
		set_target_position(Player.global_position)
	else:
		if is_waiting:
			if not is_on_floor():
				velocity.y -= 9.8 * delta
				move_and_slide()
			return

		# If the destination is reached, wait cleanly before picking a new point
		if nav_agent.is_navigation_finished():
			velocity.x = move_toward(velocity.x, 0, moveSpeed)
			velocity.z = move_toward(velocity.z, 0, moveSpeed)
			move_and_slide()
			_wait_and_pick_next()
			return

	# Get the next intermediate waypoint calculated by the navigation mesh
	var next_path_pos: Vector3 = nav_agent.get_next_path_position()
	var current_pos: Vector3 = global_position

	# Calculate direction toward the intermediate waypoint (navigates around walls)
	var dir: Vector3 = (next_path_pos - current_pos).normalized()
	velocity.x = dir.x * moveSpeed
	velocity.z = dir.z * moveSpeed

	# Apply gravity if not on the floor
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	# Look in movement direction (avoid zero-vector crash)
	var horizontal_dir = Vector3(velocity.x, 0, velocity.z)
	if horizontal_dir.length_squared() > 0.01:
		var look_target = current_pos + horizontal_dir
		look_at(look_target, Vector3.UP)

	move_and_slide()

func _wait_and_pick_next() -> void:
	is_waiting = true
	await get_tree().create_timer(maxWaitTime).timeout
	set_target_position(get_random_position())
	is_waiting = false


func _on_eyesight_body_entered(body: CharacterBody3D) -> void:
	if(body.get_groups().has("PlayerGroup")):
		is_playerDetected=true
		startTimer=true
		Player=body
		print("hello")


func _on_eyesight_body_exited(body: CharacterBody3D) -> void:
	if(body.get_groups().has("PlayerGroup")):
		is_playerDetected=false
		startTimer=false
		Player=null
		print("bye")
