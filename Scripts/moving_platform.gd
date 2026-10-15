extends AnimatableBody3D

@export var move_speed: float = 3.0

@export var point_a: Node3D
@export var point_b: Node3D

var start_position: Vector3
var end_position: Vector3
var is_moving: bool = false
var at_end: bool = false
var opp_dir: bool = false

func setdir(dir: bool) -> void:
	opp_dir = dir

func _ready() -> void:
	if not point_a:
		point_a = get_node_or_null("../pointA")
	if not point_b:
		point_b = get_node_or_null("../pointB")

	if point_a and point_b:
		if not opp_dir:
			start_position = point_a.global_position
			end_position = point_b.global_position
		else:
			start_position = point_b.global_position
			end_position = point_a.global_position
		global_position = start_position
	else:
		push_warning("Point A or Point B is not assigned!")
		start_position = global_position
		end_position = global_position

func _physics_process(delta: float) -> void:
	if not is_moving:
		return

	var destination: Vector3 = end_position if at_end else start_position
	global_position = global_position.move_toward(destination, move_speed * delta)

	if global_position.distance_to(destination) < 0.02:
		global_position = destination
		is_moving = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			# Request direction toggle from the server
			request_toggle.rpc_id(1)

# Any peer can request the server to reverse the platform
@rpc("any_peer", "call_local", "reliable")
func request_toggle() -> void:
	# Only the host/server decides when to trigger the movement
	if not multiplayer.is_server():
		return
	# Broadcast the command to all peers (including the server itself)
	sync_reverse_direction.rpc(not at_end)

# All peers run the movement simultaneously
@rpc("call_local", "reliable")
func sync_reverse_direction(target_at_end: bool) -> void:
	at_end = target_at_end
	is_moving = true
	
	
## Called locally by levers, triggers, or keypresses
func reverse_direction() -> void:
	# Ask the server to toggle the direction for everyone
	request_toggle.rpc_id(1)
