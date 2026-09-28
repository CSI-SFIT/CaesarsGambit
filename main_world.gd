extends Node3D

@onready var boulder = $Boulder
@onready var door = $Door
@onready var puzzle_ui = $PuzzleUI

# Node path for the Level Passed text overlay
@onready var level_passed_label = $PuzzleUI.get_node_or_null("LevelPassedLabel")

# Trajectory points for the boulder down the ramp:
# [0] Start at top, [1] Step 1, [2] Step 2, [3] Impact at door, [4] Past doorway into Colosseum
var target_positions = [
	Vector3(0, 4.6, -12),  # Starting position (Top)
	Vector3(0, 2.6, -4),   # Position after Problem 1
	Vector3(0, 0.6, 4),    # Position after Problem 2
	Vector3(0, -1.3, 11),  # Impact position at door threshold
	Vector3(0, -2.5, 18)   # Final position rolling through open gateway
]

var solved_count: int = 0
var is_moving: bool = false
var target_pos: Vector3

func _ready():
	target_pos = boulder.position
	# Connect the UI signal to trigger boulder movement
	puzzle_ui.problem_solved.connect(_on_problem_solved)

func _process(delta):
	if is_moving:
		# Smoothly move boulder toward current step target
		boulder.position = boulder.position.move_toward(target_pos, 8.0 * delta)
		# Roll the boulder mesh forward along X axis while moving
		boulder.rotate_x(5.0 * delta)
		
		# Check if boulder reached the step target
		if boulder.position.distance_to(target_pos) < 0.1:
			is_moving = false
			# Trigger opening sequence on final puzzle impact
			if solved_count == 3:
				_break_door()
			# Trigger Level Passed UI when boulder reaches the final target beyond the door
			elif solved_count == 4:
				_show_level_passed()

func _on_problem_solved():
	solved_count += 1
	if solved_count < target_positions.size():
		target_pos = target_positions[solved_count]
		is_moving = true

func _break_door():
	if door:
		# Disable door collision so boulder passes through freely
		var collision_shape = door.get_node_or_null("CollisionShape3D")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		
		# Lower the entire door node completely into the ground
		var door_tween = create_tween()
		door_tween.set_trans(Tween.TRANS_QUAD)
		door_tween.set_ease(Tween.EASE_IN_OUT)
		door_tween.tween_property(door, "position:y", door.position.y - 10.0, 1.8)
		
		# Advance boulder to target_positions[4] (rolling through open doorway)
		solved_count = 4
		target_pos = target_positions[4]
		is_moving = true

func _show_level_passed():
	if level_passed_label:
		level_passed_label.visible = true
	else:
		print("LEVEL PASSED!")
