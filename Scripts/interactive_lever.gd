
extends Node3D

@export var platform: Node3D

# 0 = move platform to the opposite end
# 1 = move platform back to the starting end
@export_enum("Move To End", "Move To Start")
var lever_action: int = 0

var players_in_range: Array[Node3D] = []


func _ready() -> void:
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if players_in_range.is_empty():
		return

	if Input.is_action_just_pressed("interact"):
		pull_lever()


#func _on_body_entered(body: Node3D) -> void:
	#if body.is_in_group("players"):
		#if not players_in_range.has(body):
			#players_in_range.append(body)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		if not players_in_range.has(body):
			players_in_range.append(body)


func _on_body_exited(body: Node3D) -> void:
	players_in_range.erase(body)


#func pull_lever() -> void:
	#if platform == null:
		#push_warning("Moving platform has not been assigned!")
		#return
#
	#if platform.is_moving:
		#return
#
	#if platform.at_end:
		#platform.call("move_to_start")
	#else:
		#platform.call("move_to_end")
		

func pull_lever() -> void:
	if platform == null:
		push_warning("Moving platform has not been assigned!")
		return

	platform.call("reverse_direction")
