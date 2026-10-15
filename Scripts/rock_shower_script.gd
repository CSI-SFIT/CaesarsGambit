extends Node3D

@onready var rock_scene: PackedScene = preload("res://Scenes/falling_rock.tscn")

var timer: float = 0.0
var rockFallInterval: float = 3.0

func _ready() -> void:
	# Disable processing completely if this peer is not the server
	if not multiplayer.is_server():
		set_process(false)
		set_physics_process(false)

func _process(delta: float) -> void:
	# Secondary safety check
	if not multiplayer.is_server():
		return

	timer += delta
	if timer >= rockFallInterval:
		timer = 0.0
		spawnRock()

func spawnRock() -> void:
	var rock = rock_scene.instantiate()
	# Pass true to enforce matching node names across all peers
	add_child(rock, true)
