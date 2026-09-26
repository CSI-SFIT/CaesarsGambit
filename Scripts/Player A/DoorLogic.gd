extends CSGBox3D

@export var secret_word: String = "LEGION"
@export var symbol_wall: Label3D
@export var ui_layer: CanvasLayer

const CIPHER_KEY: Dictionary = {
	"A": "Δ", "B": "Β", "C": "Γ", "D": "∇", "E": "Σ", "F": "Ζ",
	"G": "Η", "H": "Θ", "I": "Ι", "J": "Κ", "K": "Λ", "L": "Μ",
	"M": "Ν", "N": "Ξ", "O": "Ο", "P": "Π", "Q": "Ρ", "R": "Φ",
	"S": "Τ", "T": "Υ", "U": "Ψ", "V": "Χ", "W": "Ω", "X": "☧",
	"Y": "☩", "Z": "☫"
}

@onready var fail_sound = $FailSound
@onready var door_open_sound = $DoorOpenSound

var player_near = false
var is_open = false

func _ready():
	if not ui_layer or not symbol_wall:
		push_error("ERROR: Please assign the UI Layer and Symbol Wall in the Inspector for ", name)
		return
		
	# Connect UI signals dynamically so duplicated rooms don't conflict
	var line_edit = ui_layer.get_node("Panel/LineEdit")
	var button = ui_layer.get_node("Panel/Button")
	line_edit.text_submitted.connect(_on_line_edit_text_submitted)
	button.pressed.connect(_on_button_pressed)
	
	close_ui()
	
	# Generate the symbols for the wall
	var displayed_symbols = ""
	var word_upper = secret_word.to_upper()
	
	for i in range(word_upper.length()):
		var letter = word_upper[i]
		if CIPHER_KEY.has(letter):
			displayed_symbols += CIPHER_KEY[letter]
		else:
			displayed_symbols += letter
			
		if i < word_upper.length() - 1:
			displayed_symbols += "  -  "
			
	symbol_wall.text = displayed_symbols

func _on_interact_zone_body_entered(body):
	if body.is_in_group("player") and not is_open:
		player_near = true

func _on_interact_zone_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		close_ui()

func _unhandled_input(event):
	if event.is_action_pressed("interact"):
		if player_near and not is_open:
			if ui_layer.visible:
				close_ui()
			else:
				open_ui()

func open_ui():
	ui_layer.show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var line_edit = ui_layer.get_node("Panel/LineEdit")
	line_edit.text = ""
	line_edit.grab_focus()

func close_ui():
	ui_layer.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_button_pressed():
	var line_edit = ui_layer.get_node("Panel/LineEdit")
	if line_edit.text.to_upper() == secret_word.to_upper():
		close_ui()
		open_door()
	else:
		line_edit.text = ""
		print("Incorrect code!")
		if fail_sound:
			fail_sound.play()

func _on_line_edit_text_submitted(_new_text: String) -> void:
	_on_button_pressed()

func open_door():
	is_open = true
	player_near = false
	
	if door_open_sound:
		door_open_sound.play()
	
	# Slide the door up
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 4.0, 1.5).set_trans(Tween.TRANS_SINE)
