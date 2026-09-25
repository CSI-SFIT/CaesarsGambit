extends CSGBox3D

@export var secret_word: String = "LEGION" # 6-letter word for the Roman theme

# A dictionary mapping English letters to "Ancient/Roman" looking symbols.
const CIPHER_KEY: Dictionary = {
	"A": "Δ", "B": "Β", "C": "Γ", "D": "∇", "E": "Σ", "F": "Ζ",
	"G": "Η", "H": "Θ", "I": "Ι", "J": "Κ", "K": "Λ", "L": "Μ",
	"M": "Ν", "N": "Ξ", "O": "Ο", "P": "Π", "Q": "Ρ", "R": "Φ",
	"S": "Τ", "T": "Υ", "U": "Ψ", "V": "Χ", "W": "Ω", "X": "☧",
	"Y": "☩", "Z": "☫"
}

@onready var ui_panel = $"../UI/Panel"
@onready var line_edit = $"../UI/Panel/LineEdit"
@onready var symbol_wall = $"../SymbollWall"

# Audio nodes for Karen
@onready var fail_sound = $FailSound
@onready var door_open_sound = $DoorOpenSound

var player_near = false
var is_open = false

func _ready():
	# 1. Generate the symbols for the wall based on the secret word
	var displayed_symbols = ""
	var word_upper = secret_word.to_upper()
	
	for i in range(word_upper.length()):
		var letter = word_upper[i]
		if CIPHER_KEY.has(letter):
			displayed_symbols += CIPHER_KEY[letter]
		else:
			displayed_symbols += letter # Fallback just in case
			
		# Add nice spacing between the symbols
		if i < word_upper.length() - 1:
			displayed_symbols += "  -  "
			
	# Update the Label3D in the world
	if symbol_wall:
		symbol_wall.text = displayed_symbols
		
	# 2. Print the Cipher Key to the console for Camron/Aaron!
	print("--- CAESAR'S GAMBIT: LEVEL A CIPHER KEY ---")
	print("'Paper':")
	for key in CIPHER_KEY.keys():
		print(key + " = " + CIPHER_KEY[key])
	print("-------------------------------------------")

# Signals from InteractZone
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
			if $"../UI".visible:
				close_ui()
			else:
				open_ui()

func open_ui():
	$"../UI".show()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	line_edit.text = "" # Clear previous input
	line_edit.grab_focus()

func close_ui():
	$"../UI".hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Signal from the UI Button
func _on_button_pressed():
	if line_edit.text.to_upper() == secret_word.to_upper():
		close_ui()
		open_door()
	else:
		# Wrong attempt - clear text to try again
		line_edit.text = ""
		print("Incorrect code!")
		if fail_sound:
			fail_sound.play() # Karen's sound will play here

func _on_line_edit_text_submitted(_new_text: String) -> void:
	_on_button_pressed()

func open_door():
	is_open = true
	player_near = false
	
	if door_open_sound:
		door_open_sound.play() # Karen's sound will play here
	
	# Slide the door up to reveal the path to the meeting point
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y + 4.0, 1.5).set_trans(Tween.TRANS_SINE)
