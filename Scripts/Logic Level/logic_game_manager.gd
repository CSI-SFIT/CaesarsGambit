extends Node3D

@export_group("Level Components")
## Assign Gate1, Gate2, and Gate3 here in the Inspector
@export var gates: Array[AnimatableBody3D] 
## How far down the gates should sink when opened (in meters)
@export var gate_lower_distance: float = 10.0

var puzzles_solved: int = 0
var switch_1_pressed: bool = false
var switch_2_pressed: bool = false
var switch_3_pressed: bool = false

func puzzle_solved() -> void:
	if puzzles_solved < gates.size():
		open_gate(gates[puzzles_solved])
		puzzles_solved += 1

func open_gate(gate: AnimatableBody3D) -> void:
	if gate:
		var tween = create_tween()
		# Smoothly lowers the gate by the distance set in the Inspector over 1.5 seconds
		tween.tween_property(gate, "position:y", gate.position.y - gate_lower_distance, 1.5).set_trans(Tween.TRANS_SINE)

func _on_switch_1_body_entered(body: Node3D) -> void:
	if not switch_1_pressed:
		switch_1_pressed = true
		puzzle_solved()

func _on_switch_2_body_entered(body: Node3D) -> void:
	if not switch_2_pressed:
		switch_2_pressed = true
		puzzle_solved()

func _on_switch_3_body_entered(body: Node3D) -> void:
	if not switch_3_pressed:
		switch_3_pressed = true
		puzzle_solved()
