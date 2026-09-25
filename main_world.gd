extends Node3D

@onready var boulder = $Boulder
@onready var door = $Door
@onready var puzzle_ui = $PuzzleUI

# Positions for the boulder down the slope:
# [0] Start at top, [1] Step 1, [2] Step 2, [3] Bottom impact at door
var target_positions = [
	Vector3(0, 4, -12),  # Starting position (Top)
	Vector3(0, 2, -4),   # Position after Problem 1
	Vector3(0, 0, 4),    # Position after Problem 2
	Vector3(0, -2, 11)   # Bottom impact position (Door)
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
		# Smoothly move boulder toward target position
		boulder.position = boulder.position.move_toward(target_pos, 8.0 * delta)
		# Roll the boulder mesh forward along X axis while moving
		boulder.rotate_x(5.0 * delta)
		
		# Check if boulder reached the step target
		if boulder.position.distance_to(target_pos) < 0.1:
			is_moving = false
			if solved_count == 3:
				_break_door()

func _on_problem_solved():
	solved_count += 1
	if solved_count < target_positions.size():
		target_pos = target_positions[solved_count]
		is_moving = true

func _break_door():
	# Removes the door node to open the pathway
	if door:
		door.queue_free()
	print("Door destroyed! Path to next stage is open!")
