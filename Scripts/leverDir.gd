extends Node3D

@export var opp_dir = false
@onready var moving_platform: AnimatableBody3D = $MovingPlatform

func _ready() -> void:
	moving_platform.setdir(opp_dir)
