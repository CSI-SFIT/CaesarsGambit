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

var original_pos: Vector3
var is_crumbling: bool = false
var crumble_timer: float = 2.4

func _ready() -> void:
	original_pos = position
	if step_detector:
		step_detector.body_entered.connect(_on_body_entered)

func configure(r: int, c: int, l: String, safe: bool) -> void:
	row_index = r
	col_index = c
	letter = l
	is_safe_tile = safe
	is_active = true
	is_crumbling = false
	crumble_timer = 2.4
	
	if letter_label:
		letter_label.text = letter
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.82, 0.75)
	mat.roughness = 0.7
	if mesh_instance:
		mesh_instance.material_override = mat
	if omni_light:
		omni_light.visible = false

func _process(delta: float) -> void:
	if is_crumbling and is_active:
		position.x = original_pos.x + randf_range(-0.06, 0.06)
		position.z = original_pos.z + randf_range(-0.06, 0.06)
		crumble_timer -= delta
		if crumble_timer <= 0.0:
			trigger_crumble()

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if body is RomanPlayer:
		tile_stepped.emit(row_index, col_index, is_safe_tile)
		if is_safe_tile:
			reveal_safe()
			is_crumbling = true
		else:
			trigger_crumble()

func reveal_safe() -> void:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.75, 0.35)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 0.3)
	mat.emission_energy_multiplier = 2.0
	if mesh_instance:
		mesh_instance.material_override = mat
	if omni_light:
		omni_light.visible = true

func trigger_crumble() -> void:
	if not is_active:
		return
	is_active = false
	is_crumbling = false
	
	if omni_light:
		omni_light.visible = false
		
	spawn_dust_particles()
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.15, 0.15)
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
