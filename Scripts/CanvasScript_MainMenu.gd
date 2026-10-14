extends CanvasGroup
@onready var line_edit: LineEdit = $Control/VBoxContainer_inputIP/LineEdit
@onready var v_box_container: VBoxContainer = $Control/VBoxContainer
@onready var v_box_container_input_ip: VBoxContainer = $Control/VBoxContainer_inputIP


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	v_box_container.show()
	v_box_container_input_ip.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_host_button_pressed() -> void:
	EventBus.selected_role = EventBus.Role.HOST
	#on_Host_Pressed.emit()
	print("Global role set to: ", EventBus.selected_role)
	load_main_scene()


func _on_join_button_pressed() -> void:
	
	v_box_container.hide()
	v_box_container_input_ip.show()

func load_main_scene() -> void:
	# Replaces current scene with the new scene file
	get_tree().change_scene_to_file("res://Scenes/main.tscn")


func _on_join_ip_pressed() -> void:
	var host_ip = line_edit.text.strip_edges()
	if host_ip.is_empty():
		host_ip = EventBus.DEFAULT_IP
	
	EventBus.setHostIp(host_ip)
	
	EventBus.selected_role = EventBus.Role.CLIENT
	print("Global role set to: ", EventBus.selected_role)
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
	
	v_box_container.hide()
	v_box_container_input_ip.hide()
