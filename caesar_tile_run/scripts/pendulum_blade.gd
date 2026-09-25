extends Node3D
class_name PendulumBlade

@export var swing_speed: float = 2.2
@export var max_angle: float = 65.0
@export var knockback_force: float = 16.0

@onready var arm: Node3D = $Arm
@onready var blade_area: Area3D = $Arm/Blade/Area3D

var time: float = 0.0

func _ready() -> void:
	if blade_area:
		blade_area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	time += delta * swing_speed
	var current_angle = sin(time) * deg_to_rad(max_angle)
	if arm:
		arm.rotation.z = current_angle

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and "velocity" in body:
		# Calculate knockback direction away from blade
		var swing_dir = Vector3(cos(time), 0.5, 0).normalized()
		body.velocity = swing_dir * knockback_force + Vector3(0, 7.0, 0)
