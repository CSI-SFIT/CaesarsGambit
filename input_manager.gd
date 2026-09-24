extends Node3D

signal leftKeyPressed
signal rightKeyPressed
signal jumpKeyPressed
signal forwardKeyPressed
signal backwardKeyPressed

signal leftKeyReleased
signal rightKeyReleased
#signal jumpKeyReleased
signal forwardKeyReleased
signal backwardKeyReleased
#signal leftKeyPressed
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		emit_signal("leftKeyPressed")
		
	if event.is_action_pressed("move_right"):
		emit_signal("rightKeyPressed")
		
	if Input.is_action_just_pressed("jump"):
		emit_signal("jumpKeyPressed")
		
	if event.is_action_pressed("move_forward"):
		emit_signal("forwardKeyPressed")
		
	if event.is_action_pressed("move_backward"):
		emit_signal("backwardKeyPressed")
	
	
	
	if event.is_action_released("move_left"):
		emit_signal("leftKeyReleased")
		
	if event.is_action_released("move_right"):
		emit_signal("rightKeyReleased")
		
	if event.is_action_released("move_forward"):
		emit_signal("forwardKeyReleased")
		
	if event.is_action_released("move_backward"):
		emit_signal("backwardKeyReleased")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
