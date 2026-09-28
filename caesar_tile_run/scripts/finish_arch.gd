extends Node3D

signal player_arrived(player_id: int)

@onready var finish_area: Area3D = $FinishArea
@onready var portal_glow: OmniLight3D = $PortalGlow
@onready var victory_label: Label3D = $VictoryLabel

var players_reached: Array[int] = []
var celebration_particles: CPUParticles3D

func _ready() -> void:
	if finish_area:
		finish_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and "player_id" in body:
		var pid = body.player_id
		if not players_reached.has(pid):
			players_reached.append(pid)
			player_arrived.emit(pid)
			celebrate_player(pid)

func celebrate_player(pid: int) -> void:
	if portal_glow:
		portal_glow.light_energy = 5.5
	if victory_label:
		victory_label.text = "GLADIATOR %d ARRIVED!" % pid
		victory_label.visible = true

func trigger_grand_victory_shower() -> void:
	if celebration_particles:
		celebration_particles.emitting = true
		return
		
	# Golden Laurel & Confetti Shower from Arch of Constantine
	celebration_particles = CPUParticles3D.new()
	celebration_particles.name = "LaurelConfettiShower"
	celebration_particles.amount = 55
	celebration_particles.lifetime = 2.4
	celebration_particles.speed_scale = 1.0
	celebration_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	celebration_particles.emission_box_extents = Vector3(4.0, 0.4, 2.0)
	celebration_particles.direction = Vector3(0, -1, 0)
	celebration_particles.spread = 25.0
	celebration_particles.gravity = Vector3(0, -2.5, 0)
	celebration_particles.initial_velocity_min = 1.2
	celebration_particles.initial_velocity_max = 2.8
	
	# Flat confetti & laurel leaf quad
	var quad = QuadMesh.new()
	quad.size = Vector2(0.24, 0.16)
	celebration_particles.mesh = quad
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.22)
	mat.metallic = 0.8
	mat.roughness = 0.3
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	celebration_particles.material_override = mat
	
	celebration_particles.position = Vector3(0, 6.8, 0)
	add_child(celebration_particles)
