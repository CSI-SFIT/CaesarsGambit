extends Node3D
class_name CaesarPillar

@onready var title_label: Label3D = $Tablet/TitleLabel
@onready var cipher_label: Label3D = $Tablet/CipherLabel
@onready var shift_label: Label3D = $Tablet/ShiftLabel
@onready var hint_label: Label3D = $Tablet/HintLabel
@onready var rotating_eagle: Node3D = $PillarTop/Eagle

func _process(delta: float) -> void:
	if rotating_eagle:
		rotating_eagle.rotate_y(delta * 0.8)

func set_puzzle_info(cipher_word: String, shift: int, plain_word: String) -> void:
	if cipher_label:
		cipher_label.text = "ENCRYPTED: %s" % cipher_word
	if shift_label:
		shift_label.text = "CAESAR SHIFT: -%d" % shift
	if hint_label:
		hint_label.text = "SECRET WORD: %s" % plain_word
