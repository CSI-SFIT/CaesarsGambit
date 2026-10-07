extends Node3D
class_name CatapultStrike

# Roman Colosseum Catapult Fireball Strike with 1.5s Telegraph Warning

var target_position: Vector3
var warning_duration: float = 1.5
var blast_radius: float = 3.6
var knockback_power: float = 19.0

var target_ring: MeshInstance3D
var crosshair_lines: Node3D
var fireball: MeshInstance3D
var blast_ring: MeshInstance3D
var sound_fx: Node

func _ready() -> void:
	sound_fx = get_node_or_null("/root/Main/SoundEffects")
	if not sound_fx:
		var main = get_tree().root.get_node_or_null("Main")
		if main and "sound_fx" in main:
			sound_fx = main.sound_fx
			
	if target_position != Vector3.ZERO:
		launch(target_position)

func launch(target: Vector3) -> void:
	target_position = target
	global_position = target_position
	
	# 1. Telegraph Warning Ring on the targeted tile
	target_ring = MeshInstance3D.new()
	var ring_mesh = CylinderMesh.new()
	ring_mesh.top_radius = 1.7
	ring_mesh.bottom_radius = 1.7
	ring_mesh.height = 0.04
	target_ring.mesh = ring_mesh
	
	var ring_mat = StandardMaterial3D.new()
	ring_mat.albedo_color = Color(1.0, 0.15, 0.1, 0.75)
	ring_mat.emission_enabled = true
	ring_mat.emission = Color(1.0, 0.25, 0.05)
	ring_mat.emission_energy_multiplier = 3.5
	ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	target_ring.material_override = ring_mat
	target_ring.position = Vector3(0, 0.06, 0)
	add_child(target_ring)
	
	# Pulsating warning animation
	var ring_tween = create_tween()
	ring_tween.set_loops(4)
	ring_tween.tween_property(target_ring, "scale", Vector3(1.2, 1.0, 1.2), 0.18)
	ring_tween.tween_property(target_ring, "scale", Vector3(0.85, 1.0, 0.85), 0.18)
	
	# 2. Incoming Fiery Boulder dropped from Colosseum stands
	fireball = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.1
	fireball.mesh = sphere
	
	var fire_mat = StandardMaterial3D.new()
	fire_mat.albedo_color = Color(0.95, 0.35, 0.05)
	fire_mat.emission_enabled = true
	fire_mat.emission = Color(1.0, 0.55, 0.1)
	fire_mat.emission_energy_multiplier = 5.0
	fire_mat.roughness = 0.3
	fireball.material_override = fire_mat
	
	var launch_offset = Vector3(randf_range(-6.0, 6.0), 30.0, randf_range(-5.0, 5.0))
	fireball.position = launch_offset
	add_child(fireball)
	
	# Animate projectile drop timed with warning duration
	var drop_tween = create_tween()
	drop_tween.tween_property(fireball, "position", Vector3(0, 0.25, 0), warning_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop_tween.tween_callback(detonate)

func detonate() -> void:
	if fireball:
		fireball.visible = false
	if target_ring:
		target_ring.visible = false
		
	if sound_fx and sound_fx.has_method("play_explosion"):
		sound_fx.play_explosion()
		
	# Spawn shockwave blast ring
	blast_ring = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.5
	b_mesh.bottom_radius = 0.5
	b_mesh.height = 0.1
	blast_ring.mesh = b_mesh
	
	var b_mat = StandardMaterial3D.new()
	b_mat.albedo_color = Color(1.0, 0.45, 0.1, 0.85)
	b_mat.emission_enabled = true
	b_mat.emission = Color(1.0, 0.65, 0.1)
	b_mat.emission_energy_multiplier = 5.0
	b_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	blast_ring.material_override = b_mat
	blast_ring.position = Vector3(0, 0.12, 0)
	add_child(blast_ring)
	
	var blast_tween = create_tween()
	blast_tween.tween_property(blast_ring, "scale", Vector3(blast_radius * 2.2, 1.0, blast_radius * 2.2), 0.35)
	blast_tween.parallel().tween_property(b_mat, "albedo_color:a", 0.0, 0.35)
	
	# Impact on players & tiles in radius
	var main = get_tree().root.get_node_or_null("Main")
	if main:
		var players_container = main.get_node_or_null("PlayersContainer")
		if players_container:
			for player in players_container.get_children():
				if player is CharacterBody3D:
					var dist = player.global_position.distance_to(global_position)
					if dist <= blast_radius:
						var blast_dir = (player.global_position - global_position).normalized()
						blast_dir.y = 0.7
						player.velocity += blast_dir * knockback_power
						

						
	get_tree().create_timer(0.6).timeout.connect(queue_free)
