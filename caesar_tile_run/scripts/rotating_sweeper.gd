extends Node3D
class_name RotatingSweeper

@export var rotation_speed: float = 1.8
@export var sweep_force: float = 15.0

@onready var spinner: Node3D = $Spinner
@onready var hit_area_1: Area3D = $Spinner/Arm1/Area3D
@onready var hit_area_2: Area3D = $Spinner/Arm2/Area3D

func _ready() -> void:
	if hit_area_1:
		hit_area_1.body_entered.connect(_on_body_hit)
	if hit_area_2:
		hit_area_2.body_entered.connect(_on_body_hit)

func _physics_process(delta: float) -> void:
	if spinner:
		spinner.rotate_y(rotation_speed * delta)

func _on_body_hit(body: Node3D) -> void:
	if body is CharacterBody3D and "velocity" in body:
		var push_dir = spinner.global_transform.basis.x.normalized()
		body.velocity = push_dir * sweep_force + Vector3(0, 6.0, 0)
