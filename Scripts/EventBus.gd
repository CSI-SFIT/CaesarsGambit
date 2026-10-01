extends Node

signal on_Host_Pressed
signal on_Join_Pressed


func _on_host_button_pressed() -> void:
	print("HostPressed")
	on_Host_Pressed.emit()
	load_main_scene()


func _on_join_button_pressed() -> void:
	print("JoinPressed")
	on_Join_Pressed.emit()
	load_main_scene()


func load_main_scene() -> void:
	# Replaces current scene with the new scene file
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")
