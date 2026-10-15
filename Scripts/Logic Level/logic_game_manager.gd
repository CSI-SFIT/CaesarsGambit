extends Node3D

@export_group("Level Components")
@export var gates: Array[Node3D] 
@export var boulder: RigidBody3D
@export var gate_lower_distance: float = 10.0

@export_group("Puzzle Clues")
## Put your AND, OR, and NOT images here in order (0, 1, 2)
@export var clue_images: Array[Texture2D]

# UI References
@onready var puzzle_ui: CanvasLayer = $PuzzleUI
@onready var terminal_bg: Control = $PuzzleUI/TerminalBackground
@onready var clue_image_rect: TextureRect = $PuzzleUI/TerminalBackground/ClueImage
@onready var input_field: LineEdit = $PuzzleUI/TerminalBackground/InputField

# The exact text answers expected for Wall 1, Wall 2, and Wall 3
var target_answers: Array[String] = ["0", "1", "10", "-1"] 

# Tracks which puzzles have already been completed
var solved_puzzles: Array[bool] = [false, false, false]

# -1 means not interacting; otherwise index of current puzzle open
var current_active_puzzle: int = -1

# -1 means player is not inside any wall's Area3D
var nearby_wall_index: int = -1

# Runtime UI Labels
var prompt_label: Label
var notification_label: Label
var notification_tween: Tween

func _ready() -> void:
	terminal_bg.hide()
	puzzle_ui.show()
	_setup_runtime_labels()

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(boulder):
		return
		
	var roll_sound: AudioStreamPlayer3D = boulder.get_node_or_null("BoulderRollSound")
	if not roll_sound:
		return

	# If the boulder is moving down the ramp (speed > 0.5 m/s)
	if boulder.linear_velocity.length() > 0.5:
		if not roll_sound.playing:
			roll_sound.play()
	else:
		# If the boulder has stopped against a closed gate or door
		if roll_sound.playing:
			roll_sound.stop()

func _setup_runtime_labels() -> void:
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
	puzzle_ui.add_child(prompt_label)

	notification_label = Label.new()
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notification_label.add_theme_font_size_override("font_size", 28)
	notification_label.modulate = Color(1, 1, 1, 0)
	notification_label.anchor_left = 0.0
	notification_label.anchor_right = 1.0
	notification_label.anchor_top = 0.15
	notification_label.anchor_bottom = 0.22
	puzzle_ui.add_child(notification_label)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			# If terminal is open, close it
			if current_active_puzzle != -1:
				close_terminal()
				get_viewport().set_input_as_handled()
				return

			# If player is inside an unsolved wall Area3D, open terminal
			if nearby_wall_index != -1 and not solved_puzzles[nearby_wall_index]:
				get_viewport().set_input_as_handled()
				open_terminal(nearby_wall_index)

# --- AREA3D SIGNAL HANDLERS ---

func _handle_wall_entered(body: Node3D, wall_idx: int) -> void:
	# Ignore non-players or remote proxy puppets
	if not body.is_in_group("PlayerGroup") or not body.is_multiplayer_authority():
		return
		
	# Ignore already solved puzzles
	if solved_puzzles[wall_idx]:
		return

	nearby_wall_index = wall_idx
	if current_active_puzzle == -1:
		prompt_label.text = "[E] Decipher Wall " + str(wall_idx + 1)
		prompt_label.visible = true

func _handle_wall_exited(body: Node3D, wall_idx: int) -> void:
	if not body.is_in_group("PlayerGroup") or not body.is_multiplayer_authority():
		return

	if nearby_wall_index == wall_idx:
		nearby_wall_index = -1
		prompt_label.visible = false
		# Close terminal if the player walks out while reading
		if current_active_puzzle == wall_idx:
			close_terminal()

# Connect these to your Area3D nodes in the editor or via code:
func _on_st_wall_1_body_entered(body: Node3D) -> void:
	_handle_wall_entered(body, 0)

func _on_st_wall_1_body_exited(body: Node3D) -> void:
	_handle_wall_exited(body, 0)

func _on_st_wall_2_body_entered(body: Node3D) -> void:
	_handle_wall_entered(body, 1)

func _on_st_wall_2_body_exited(body: Node3D) -> void:
	_handle_wall_exited(body, 1)

func _on_st_wall_3_body_entered(body: Node3D) -> void:
	_handle_wall_entered(body, 2)

func _on_st_wall_3_body_exited(body: Node3D) -> void:
	_handle_wall_exited(body, 2)

# --- UI DISPLAY LOGIC ---

func open_terminal(puzzle_index: int) -> void:
	current_active_puzzle = puzzle_index
	prompt_label.visible = false
	
	if puzzle_index < clue_images.size():
		clue_image_rect.texture = clue_images[puzzle_index]
	
	input_field.text = ""
	terminal_bg.show()
	input_field.call_deferred("grab_focus")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_terminal() -> void:
	current_active_puzzle = -1
	terminal_bg.hide()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Restore the prompt if still inside an unsolved trigger area
	if nearby_wall_index != -1 and not solved_puzzles[nearby_wall_index]:
		prompt_label.text = "[E] Decipher Wall " + str(nearby_wall_index + 1)
		prompt_label.visible = true

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
		
	var player_text: String = input_field.text.strip_edges().replace(" ", "")
	var correct_answer: String = target_answers[current_active_puzzle]
	
	if player_text == correct_answer:
		var solved_idx: int = current_active_puzzle
		solved_puzzles[solved_idx] = true
		
		open_gate(gates[solved_idx])
		close_terminal()
		show_notification("Gate " + str(solved_idx + 1) + " Unlocked!")
	else:
		input_field.text = ""

# --- GATE LOGIC ---

func open_gate(gate: Node3D) -> void:
	if gate:
		var tween: Tween = create_tween()
		tween.tween_property(gate, "position:y", gate.position.y - gate_lower_distance, 1.5).set_trans(Tween.TRANS_SINE)
		
		if boulder:
			boulder.sleeping = false # Waking the boulder lets it roll, which triggers the sound!
			
		await get_tree().create_timer(1.0).timeout
		gate.queue_free()
