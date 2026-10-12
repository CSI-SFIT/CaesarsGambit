extends Node3D

var is_player_in_range = false
var is_pressed=false
var door_left_finalpos
@onready var label:Label3D = $Label3D


@onready var door_right = $"../doors/CSGBox3D"
@onready var door_left = $"../doors/CSGBox3D2"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	door_left_finalpos = door_left.global_position + Vector3(0,0,5)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	if(is_pressed):
		openDoors(delta)	
		return
		
	if(is_player_in_range):
		label.visible = true
		if(Input.is_key_pressed(KEY_E)):
			print("Open Door")
			is_pressed=true
			#is_pressable=false
			
	else:
		label.visible = false
		
	

func openDoors(delta):
	
	#var right_door_initial = door_right.global_position
	
	if(door_left.global_position.z <= door_left_finalpos.z):
		door_left.global_position += Vector3(0,0,2*delta)
		door_right.global_position -= Vector3(0,0,2*delta)
	else:
		print("DOORS OPENED!")


func _on_area_3d_body_entered(body: Node3D) -> void:
	if(body.is_in_group("PlayerGroup")):
		print("player near button")
		is_player_in_range=true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if(body.is_in_group("PlayerGroup")):
		print("player far button")
		is_player_in_range=false
