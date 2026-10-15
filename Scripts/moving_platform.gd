extends AnimatableBody3D

@export var move_speed: float = 3.0

# Using Node3D covers CSGBox3D, Marker3D, or any other 3D reference node
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
	# Fallback to nodepaths if not assigned via Inspector
	if not point_a:
		point_a = get_node_or_null("../pointA")
	if not point_b:
		point_b = get_node_or_null("../pointB")

	if point_a and point_b:
		# Use point positions instead of calculated offset
		if not opp_dir:
			start_position = point_a.global_position
			end_position = point_b.global_position
		else:
			start_position = point_b.global_position
			end_position = point_a.global_position

		# Align the platform to the initial starting point
		global_position = start_position
	else:
		push_warning("Point A or Point B is not assigned!")
		start_position = global_position
		end_position = global_position

func _physics_process(delta: float) -> void:
	if not is_moving:
		return

	var destination: Vector3 = end_position if at_end else start_position

	global_position = global_position.move_toward(
		destination,
		move_speed * delta
	)

	if global_position.distance_to(destination) < 0.02:
		global_position = destination
		is_moving = false

func reverse_direction() -> void:
	at_end = not at_end
	is_moving = true

func reset_platform() -> void:
	is_moving = false
	at_end = false
	global_position = start_position

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			reverse_direction()
