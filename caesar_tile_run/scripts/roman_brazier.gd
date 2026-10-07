extends Node3D

@onready var fire_light: OmniLight3D = $FireLight
@onready var flame_mesh: MeshInstance3D = $Flame

func _ready() -> void:
	if fire_light:
		fire_light.light_energy = 3.0
	set_process(false)
