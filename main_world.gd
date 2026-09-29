extends Node3D

@onready var camera = $Camera3D
@onready var boulder = $Boulder
@onready var door = $Door
@onready var puzzle_ui = $PuzzleUI
@onready var level_passed_label = $PuzzleUI.get_node_or_null("LevelPassedLabel")

# Camera transform coordinates
var cam_start_pos = Vector3(0, 15, 75)
var cam_start_rot = Vector3(-5, 0, 0)

var cam_mid_pos = Vector3(0, 4, 30)

var cam_final_pos = Vector3(0, 2.5, 18)
var cam_final_rot = Vector3(-2, 0, 0)

# Waypoints for linear roll down the slope
var target_positions = [
	Vector3(0, 4.8, -12),  # Top of slope
	Vector3(0, 3.0, -4),   # Step 1
	Vector3(0, 1.2, 4),    # Step 2
	Vector3(0, -0.6, 12),  # Step 3 at door threshold
	Vector3(0, -0.6, 28)   # Final position into Colosseum arena
]

var solved_count: int = 0
var is_moving: bool = false
var target_pos: Vector3

func _ready():
	target_pos = boulder.position
	puzzle_ui.problem_solved.connect(_on_problem_solved)
	
	_play_intro_camera_sequence()

func _play_intro_camera_sequence():
	# Frame 1: Full wide view of Colosseum exterior
	camera.position = cam_start_pos
	camera.rotation_degrees = cam_start_rot
	
	# Create single tween sequence for camera movement
	var tween = create_tween()
	
	# Flight Segment 1: Travel from wide exterior to entrance archway
	tween.tween_property(camera, "position", cam_mid_pos, 2.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	# Flight Segment 2: Move inside and tilt to frame slope view
	tween.chain().tween_property(camera, "position", cam_final_pos, 2.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var rot_tween = create_tween()
	rot_tween.tween_interval(2.5) # Wait for Segment 1 to finish
	rot_tween.tween_property(camera, "rotation_degrees", cam_final_rot, 2.0)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Show Question 1 ONLY when camera zoom is 100% finished
	rot_tween.finished.connect(func():
		puzzle_ui.display_current_question()
	)

func _process(delta):
	if is_moving:
		var move_speed = 10.0 if solved_count == 4 else 7.0
		
		# Smooth linear trajectory without slope clipping
		boulder.position = boulder.position.move_toward(target_pos, move_speed * delta)
		boulder.rotate_x(move_speed * delta * 0.6)
		
		if boulder.position.distance_to(target_pos) < 0.05:
			boulder.position = target_pos
			is_moving = false
			
			if solved_count < 3:
				puzzle_ui.display_current_question()
			elif solved_count == 3:
				_break_door()
			elif solved_count == 4:
				_show_level_passed()

func _on_problem_solved():
	solved_count += 1
	if solved_count < target_positions.size():
		target_pos = target_positions[solved_count]
		is_moving = true

func _break_door():
	if door:
		var collision_shape = door.get_node_or_null("CollisionShape3D")
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		
		var door_tween = create_tween()
		door_tween.set_trans(Tween.TRANS_QUAD)
		door_tween.set_ease(Tween.EASE_IN_OUT)
		door_tween.tween_property(door, "position:y", door.position.y - 10.0, 1.8)
		
		solved_count = 4
		target_pos = target_positions[4]
		is_moving = true

func _show_level_passed():
	puzzle_ui.hide()
	if level_passed_label:
		level_passed_label.visible = true
	else:
		print("LEVEL PASSED!")
