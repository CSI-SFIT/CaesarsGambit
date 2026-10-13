extends Node3D

@export_group("Level Components")
@export var gates: Array[Node3D] 
@export var boulder: RigidBody3D
@export var gate_lower_distance: float = 10.0

@export_group("Puzzle Clues")
## Put your AND, OR, and NOT images here in order (0, 1, 2)
@export var clue_images: Array[Texture2D]

# Interaction distance threshold (in meters)
@export var interaction_distance: float = 4.0

# Scene References
@onready var player: Node3D = $Player
@onready var walls: Array[Node3D] = [
	$straight_wall,
	$straight_wall2,
	$straight_wall3
]

# UI References
@onready var puzzle_ui = $PuzzleUI
@onready var terminal_bg = $PuzzleUI/TerminalBackground
@onready var clue_image_rect = $PuzzleUI/TerminalBackground/ClueImage
@onready var input_field = $PuzzleUI/TerminalBackground/InputField

# The exact text answers expected for Wall 1, Wall 2, and Wall 3
var target_answers: Array[String] = ["0", "1", "10","-1"] 

# Tracks which puzzles have already been completed
var solved_puzzles: Array[bool] = [false, false, false]

# Tracks which wall the player is currently looking at (-1 means none)
var current_active_puzzle: int = -1

# Runtime UI Labels
var prompt_label: Label
var notification_label: Label
var notification_tween: Tween

func _ready() -> void:
	# Ensure the terminal box itself starts hidden
	terminal_bg.hide()
	puzzle_ui.show() # Keep the CanvasLayer active so prompts/toasts can render
	_setup_runtime_labels()

func _setup_runtime_labels() -> void:
	# Interaction prompt ("[E] Decipher Wall")
	prompt_label = Label.new()
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.add_theme_font_size_override("font_size", 22)
	prompt_label.anchor_left = 0.0
	prompt_label.anchor_right = 1.0
	prompt_label.anchor_top = 0.72
	prompt_label.anchor_bottom = 0.78
	prompt_label.text = "[E] Decipher Wall"
	prompt_label.visible = false
	$PuzzleUI.add_child(prompt_label)

	# Gate unlocked toast notification
	notification_label = Label.new()
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 28)
	notification_label.modulate = Color(1, 1, 1, 0)
	notification_label.anchor_left = 0.0
	notification_label.anchor_right = 1.0
	notification_label.anchor_top = 0.15
	notification_label.anchor_bottom = 0.22
	$PuzzleUI.add_child(notification_label)

func _process(_delta: float) -> void:
	# Don't show the interaction prompt if the terminal UI is open
	if current_active_puzzle != -1:
		prompt_label.visible = false
		return

	var nearby_unsolved_wall: int = _get_nearby_unsolved_wall_index()
	if nearby_unsolved_wall != -1:
		prompt_label.text = "[E] Decipher Wall " + str(nearby_unsolved_wall + 1)
		prompt_label.visible = true
	else:
		prompt_label.visible = false

func _get_nearby_unsolved_wall_index() -> int:
	if not player:
		return -1

	var p_pos = Vector2(player.global_position.x, player.global_position.z)
	for i in range(walls.size()):
		var wall = walls[i]
		if wall and not solved_puzzles[i]:
			var w_pos = Vector2(wall.global_position.x, wall.global_position.z)
			if p_pos.distance_to(w_pos) <= interaction_distance:
				return i
	return -1

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			# If terminal is open, close it on E
			if current_active_puzzle != -1:
				close_terminal()
				get_viewport().set_input_as_handled()
				return

			# If player is near an unsolved wall, open the terminal
			var nearby_wall = _get_nearby_unsolved_wall_index()
			if nearby_wall != -1:
				get_viewport().set_input_as_handled() # Consume 'E' so it doesn't type into the box
				open_terminal(nearby_wall)

# --- UI DISPLAY LOGIC ---
func open_terminal(puzzle_index: int) -> void:
	current_active_puzzle = puzzle_index
	prompt_label.visible = false
	
	if puzzle_index < clue_images.size():
		clue_image_rect.texture = clue_images[puzzle_index]
	
	input_field.text = ""
	terminal_bg.show()
	
	# Defer focus to the next frame to guarantee the 'E' keystroke isn't typed
	input_field.call_deferred("grab_focus")
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_terminal() -> void:
	current_active_puzzle = -1
	terminal_bg.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func show_notification(message: String) -> void:
	notification_label.text = message
	
	if notification_tween and notification_tween.is_valid():
		notification_tween.kill()
		
	notification_tween = create_tween()
	notification_tween.tween_property(notification_label, "modulate:a", 1.0, 0.3)
	notification_tween.tween_interval(2.0)
	notification_tween.tween_property(notification_label, "modulate:a", 0.0, 0.5)

# --- BUTTON PRESSES ---
func _on_close_button_pressed() -> void:
	close_terminal()

func _on_submit_button_pressed() -> void:
	if current_active_puzzle == -1:
		return
		
	var player_text = input_field.text.strip_edges().replace(" ", "")
	var correct_answer = target_answers[current_active_puzzle]
	
	if player_text == correct_answer:
		var solved_idx = current_active_puzzle
		solved_puzzles[solved_idx] = true
		
		open_gate(gates[solved_idx])
		close_terminal()
		show_notification("Gate " + str(solved_idx + 1) + " Unlocked!")
	else:
		input_field.text = ""

# --- GATE LOGIC ---
func open_gate(gate: Node3D) -> void:
	if gate:
		var tween = create_tween()
		tween.tween_property(gate, "position:y", gate.position.y - gate_lower_distance, 1.5).set_trans(Tween.TRANS_SINE)
		
		if boulder:
			boulder.sleeping = false
		await get_tree().create_timer(1).timeout
		gate.queue_free()
		
