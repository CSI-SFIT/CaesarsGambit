
extends AnimatableBody3D

@export var move_distance: float = 14.8
@export var move_speed: float = 3.0

var start_position: Vector3
var end_position: Vector3
var is_moving: bool = false
var at_end: bool = false


func _ready() -> void:
	start_position = global_position
	end_position = start_position + Vector3(0, 0, -move_distance)


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


#func move_to_end() -> void:
	#if is_moving or at_end:
		#return
#
	#is_moving = true
	#at_end = true
#
#
#func move_to_start() -> void:
	#if is_moving or not at_end:
		#return
#
	#is_moving = true
	#at_end = false


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
