extends Node3D

@onready var fire_light: OmniLight3D = $FireLight
@onready var flame_mesh: MeshInstance3D = $Flame

var noise_time: float = 0.0
var base_energy: float = 3.5

func _ready() -> void:
	# Procedural Olympic ember particles
	var particles = CPUParticles3D.new()
	particles.name = "EmberParticles"
	particles.amount = 14
	particles.lifetime = 0.75
	particles.speed_scale = 1.2
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.25
	particles.direction = Vector3(0, 1, 0)
	particles.spread = 22.0
	particles.gravity = Vector3(0, 4.0, 0)
	particles.initial_velocity_min = 1.2
	particles.initial_velocity_max = 2.4
	
	var p_mesh = SphereMesh.new()
	p_mesh.radius = 0.04
	p_mesh.height = 0.08
	particles.mesh = p_mesh
	
	var p_mat = StandardMaterial3D.new()
	p_mat.albedo_color = Color(1.0, 0.6, 0.1)
	p_mat.emission_enabled = true
	p_mat.emission = Color(1.0, 0.5, 0.1)
	p_mat.emission_energy_multiplier = 4.0
	particles.material_override = p_mat
	
	particles.position = Vector3(0, 2.1, 0)
	add_child(particles)

func _process(delta: float) -> void:
	noise_time += delta * 12.0
	if fire_light:
		fire_light.light_energy = base_energy + sin(noise_time) * 0.4 + sin(noise_time * 2.3) * 0.25
	if flame_mesh:
		flame_mesh.scale = Vector3(
			1.0 + sin(noise_time * 1.5) * 0.08,
			1.0 + sin(noise_time * 2.0) * 0.12,
			1.0 + cos(noise_time * 1.5) * 0.08
		)
