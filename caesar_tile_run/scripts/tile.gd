extends StaticBody3D
class_name RomanTile

signal tile_stepped(row: int, col: int, is_safe: bool)

@export var row_index: int = 0
@export var col_index: int = 0
@export var letter: String = "A"
@export var is_safe_tile: bool = false
@export var is_active: bool = true

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var letter_label: Label3D = $Label3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var step_detector: Area3D = $Area3D
@onready var omni_light: OmniLight3D = $OmniLight3D
@onready var carved_ring: MeshInstance3D = get_node_or_null("CarvedRing")

var is_crumbling: bool = false
var crumble_timer: float = 2.4
const TOTAL_CRUMBLE_TIME: float = 2.4

func _ensure_nodes() -> void:
	if not mesh_instance:
		mesh_instance = get_node_or_null("MeshInstance3D")
	if not letter_label:
		letter_label = get_node_or_null("Label3D")
	if not collision_shape:
		collision_shape = get_node_or_null("CollisionShape3D")
	if not step_detector:
		step_detector = get_node_or_null("Area3D")
	if not omni_light:
		omni_light = get_node_or_null("OmniLight3D")
	if not carved_ring:
		carved_ring = get_node_or_null("CarvedRing")

func _ready() -> void:
	_ensure_nodes()
	if step_detector and not step_detector.body_entered.is_connected(_on_body_entered):
		step_detector.body_entered.connect(_on_body_entered)

func configure(r: int, c: int, l: String, safe: bool) -> void:
	_ensure_nodes()
	row_index = r
	col_index = c
	letter = l
	is_safe_tile = safe
	is_active = true
	is_crumbling = false
	crumble_timer = TOTAL_CRUMBLE_TIME
	
	if letter_label:
		letter_label.text = letter
		letter_label.modulate = Color(0.24, 0.20, 0.16)
		letter_label.position = Vector3(0, 0.22, 0)
	
	if mesh_instance:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.58, 0.52, 0.44)
		mat.roughness = 0.82
		mesh_instance.material_override = mat
		mesh_instance.position = Vector3.ZERO
		
	if carved_ring:
		carved_ring.position = Vector3(0, 0.205, 0)
		
	if omni_light:
		omni_light.visible = false

func _process(delta: float) -> void:
	if is_crumbling and is_active:
		crumble_timer -= delta
		
		# Visual countdown vibration: urgency intensifies in final 0.8 seconds
		var shake_mag = 0.05
		if crumble_timer <= 0.8:
			shake_mag = 0.09
			if omni_light:
				omni_light.light_energy = 4.5 if (fmod(crumble_timer, 0.16) < 0.08) else 1.5
				
		var sx = randf_range(-shake_mag, shake_mag)
		var sz = randf_range(-shake_mag, shake_mag)
		
		# Shake the visual meshes without moving the physics collision under the gladiator
		if mesh_instance:
			mesh_instance.position.x = sx
			mesh_instance.position.z = sz
		if letter_label:
			letter_label.position.x = sx
			letter_label.position.z = sz
		if carved_ring:
			carved_ring.position.x = sx
			carved_ring.position.z = sz
			
		if crumble_timer <= 0.0:
			trigger_crumble()

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if body is RomanPlayer or body.is_in_group("player") or body.name == "1" or body.name == "2" or body.has_method("spawn_dive_impact_dust"):
		tile_stepped.emit(row_index, col_index, is_safe_tile)
		if is_safe_tile:
			reveal_safe()
		else:
			trigger_crumble()

func reveal_safe() -> void:
	if not is_active or is_crumbling:
		return
	_ensure_nodes()
	is_crumbling = true
	crumble_timer = TOTAL_CRUMBLE_TIME
	
	# Radiant emerald marble slab
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.82, 0.32)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.95, 0.35)
	mat.emission_energy_multiplier = 2.8
	if mesh_instance:
		mesh_instance.material_override = mat
		
	# Glowing carved gold ring
	if carved_ring:
		var ring_mat = StandardMaterial3D.new()
		ring_mat.albedo_color = Color(0.9, 0.85, 0.3)
		ring_mat.emission_enabled = true
		ring_mat.emission = Color(0.85, 0.9, 0.25)
		ring_mat.emission_energy_multiplier = 2.0
		carved_ring.material_override = ring_mat
		
	# Glowing green letter
	if letter_label:
		letter_label.modulate = Color(0.35, 1.0, 0.45)
		
	# Emerald omni light
	if omni_light:
		omni_light.light_color = Color(0.25, 1.0, 0.4)
		omni_light.light_energy = 3.5
		omni_light.omni_range = 4.5
		omni_light.visible = true
		
	spawn_sunburst_ripple()

func trigger_crumble() -> void:
	if not is_active:
		return
	_ensure_nodes()
	is_active = false
	is_crumbling = false
	
	if omni_light:
		omni_light.visible = false
		
	spawn_dust_particles()
	spawn_shatter_chunks()
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.15, 0.15)
	if mesh_instance:
		mesh_instance.material_override = mat
		
	var tween = create_tween()
	tween.tween_property(self, "position:y", -14.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "rotation_degrees:x", randf_range(-40.0, 40.0), 0.7)
	tween.parallel().tween_property(self, "rotation_degrees:z", randf_range(-40.0, 40.0), 0.7)

func spawn_dust_particles() -> void:
	var p = CPUParticles3D.new()
	p.name = "CrumbleDust"
	p.amount = 14
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.85
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(1.0, 0.1, 1.0)
	p.direction = Vector3(0, 1, 0)
	p.spread = 45.0
	p.gravity = Vector3(0, -3.0, 0)
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.5
	
	var m = SphereMesh.new()
	m.radius = 0.08
	m.height = 0.16
	p.mesh = m
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.76, 0.65, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	p.material_override = mat
	
	p.position = Vector3(0, 0.2, 0)
	add_child(p)

func spawn_sunburst_ripple() -> void:
	var ripple = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.5
	cylinder.bottom_radius = 0.5
	cylinder.height = 0.04
	ripple.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.88, 0.25, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.2)
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ripple.material_override = mat
	ripple.position = Vector3(0, 0.16, 0)
	add_child(ripple)
	
	var tw = create_tween()
	tw.tween_property(ripple, "scale", Vector3(3.2, 1.0, 3.2), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.42)
	tw.tween_callback(ripple.queue_free)

func spawn_shatter_chunks() -> void:
	var chunks = CPUParticles3D.new()
	chunks.name = "ShatterChunks"
	chunks.amount = 12
	chunks.lifetime = 0.85
	chunks.one_shot = true
	chunks.explosiveness = 0.92
	chunks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	chunks.emission_box_extents = Vector3(0.9, 0.1, 0.9)
	chunks.direction = Vector3(0, 1, 0)
	chunks.spread = 55.0
	chunks.gravity = Vector3(0, -9.8, 0)
	chunks.initial_velocity_min = 2.0
	chunks.initial_velocity_max = 4.2
	
	var cube = BoxMesh.new()
	cube.size = Vector3(0.18, 0.12, 0.18)
	chunks.mesh = cube
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.68, 0.62, 0.55)
	mat.roughness = 0.9
	chunks.material_override = mat
	
	chunks.position = Vector3(0, 0.2, 0)
	add_child(chunks)
