extends Node3D
class_name PendulumBlade

@export var swing_speed: float = 2.5
@export var max_angle: float = 68.0
@export var knockback_force: float = 19.0

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
		var swing_dir = Vector3(cos(time), 0.45, 0).normalized()
		body.velocity = swing_dir * knockback_force + Vector3(0, 8.5, 0)
		if body.has_method("add_screen_shake"):
			body.add_screen_shake(0.45)
		var main = get_tree().root.get_node_or_null("Main")
		if main and "sound_fx" in main and main.sound_fx:
			main.sound_fx.play_whack()
