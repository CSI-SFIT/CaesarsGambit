extends CanvasGroup


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_host_button_pressed() -> void:
	EventBus.selected_role = EventBus.Role.HOST
	#on_Host_Pressed.emit()
	print("Global role set to: ", EventBus.selected_role)
	load_main_scene()


func _on_join_button_pressed() -> void:
	EventBus.selected_role = EventBus.Role.CLIENT
	print("Global role set to: ", EventBus.selected_role)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
"res://Scenes/main.tscn"

func load_main_scene() -> void:
	# Replaces current scene with the new scene file
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
