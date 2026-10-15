extends Node3D

var is_player_in_range: bool = false
var is_pressed: bool = false
var door_sound_played: bool = false
var door_left_finalpos: Vector3

@onready var label: Label3D = $Label3D
@onready var door_right = get_node_or_null("../doors/CSGBox3D")
@onready var door_left = get_node_or_null("../doors/CSGBox3D2")
@onready var door_slide_sound = get_node_or_null("../doors/DoorSlideSound")
@onready var button_sound = get_node_or_null("ButtonSound")

func _ready() -> void:
	if door_left:
		door_left_finalpos = door_left.global_position + Vector3(0, 25, 0)

func _process(delta: float) -> void:
	if is_pressed:
		openDoors(delta)	
		return
		
	if is_player_in_range:
		label.visible = true
		if Input.is_key_pressed(KEY_E):
			print("Open Door")
			is_pressed = true
			label.visible = false
			
			# 1. Play button click sound
			if button_sound:
				button_sound.play()
			elif has_node("ButtonSound"):
				$ButtonSound.play()

			# 2. Play heavy door sliding sound
			if door_slide_sound and not door_sound_played:
				door_slide_sound.play()
				door_sound_played = true
	else:
		label.visible = false

func openDoors(delta: float) -> void:
	if door_left and door_right:
		if door_left.global_position.y <= door_left_finalpos.y:
			door_left.global_position += Vector3(0, 2 * delta, 0)
			door_right.global_position += Vector3(0, 2 * delta, 0)
		else:
			# Doors have reached the top -> stop the sliding sound
			if door_slide_sound and door_slide_sound.playing:
				door_slide_sound.stop()
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("PlayerGroup") and body.is_multiplayer_authority():
		print("player near button")
		is_player_in_range = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("PlayerGroup") and body.is_multiplayer_authority():
		print("player far button")
		is_player_in_range = false
