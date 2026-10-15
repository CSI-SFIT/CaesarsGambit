extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	# Listen for when video reaches the end
	video_player.finished.connect(_on_cutscene_finished)
	video_player.play()

func _on_cutscene_finished() -> void:
	# Reset multiplayer session state if returning to the main menu
	_cleanup_multiplayer()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	# Optional: Allow skipping the cutscene
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
		_on_cutscene_finished()

func _cleanup_multiplayer() -> void:
	# Disconnect peer so players can host/join fresh games later
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
