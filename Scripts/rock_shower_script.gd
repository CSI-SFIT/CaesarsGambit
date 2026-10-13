extends Node3D
@onready var rock_scene: = preload("res://Scenes/falling_rock.tscn")

var timer:=0.0
var rockFallInterval = 1.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer+=delta
	if(timer >= rockFallInterval):
		timer=0.0
		spawnRock()
		#print("Spawned")
		

func spawnRock():
	var rock = rock_scene.instantiate()
	add_child(rock)
	#rock = transform.global_position
	
	
