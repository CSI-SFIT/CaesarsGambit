extends StaticBody3D
class_name RomanTile

signal tile_stepped(row: int, col: int, is_safe: bool)

@export var is_safe: bool = false
@export var row: int = 0
@export var col: int = 0
@export var letter: String = "A"

var is_revealed: bool = false
var is_active: bool = true
var initial_pos: Vector3
var initial_rot: Vector3

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label_3d: Label3D = $Label3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var area_trigger: Area3D = $Area3D
@onready var omni_light: OmniLight3D = $OmniLight3D

# Materials for visual states
var stone_mat: StandardMaterial3D
var gold_safe_mat: StandardMaterial3D
var crumble_warn_mat: StandardMaterial3D

func _ready() -> void:
	initial_pos = position
	initial_rot = rotation
	setup_materials()
	update_visuals()
	
	if area_trigger:
		area_trigger.body_entered.connect(_on_body_entered)

func setup_materials() -> void:
	# Roman Travertine / Marble stone material
	stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.82, 0.78, 0.72) # Travertine cream/sand
	stone_mat.roughness = 0.8
	
	# Golden laurel revealed material
	gold_safe_mat = StandardMaterial3D.new()
	gold_safe_mat.albedo_color = Color(0.95, 0.78, 0.25)
	gold_safe_mat.emission_enabled = true
	gold_safe_mat.emission = Color(1.0, 0.84, 0.2)
	gold_safe_mat.emission_energy_multiplier = 2.0
	gold_safe_mat.roughness = 0.3
	gold_safe_mat.metallic = 0.4
	
	# Cracking danger material
	crumble_warn_mat = StandardMaterial3D.new()
	crumble_warn_mat.albedo_color = Color(0.85, 0.25, 0.2)
	crumble_warn_mat.emission_enabled = true
	crumble_warn_mat.emission = Color(0.9, 0.2, 0.1)
	crumble_warn_mat.emission_energy_multiplier = 1.5

func configure(r: int, c: int, char_val: String, safe_val: bool) -> void:
	row = r
	col = c
	letter = char_val
	is_safe = safe_val
	is_revealed = false
	is_active = true
	update_visuals()

func update_visuals() -> void:
	if label_3d:
		label_3d.text = letter
		if is_revealed and is_safe:
			label_3d.modulate = Color(1.0, 0.95, 0.6)
		else:
			label_3d.modulate = Color(0.2, 0.15, 0.1)
			
	if mesh_instance:
		if is_revealed and is_safe:
			mesh_instance.material_override = gold_safe_mat
			if omni_light:
				omni_light.visible = true
				omni_light.light_color = Color(1.0, 0.85, 0.3)
		else:
			mesh_instance.material_override = stone_mat
			if omni_light:
				omni_light.visible = false

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if body is CharacterBody3D:
		step_on()

func step_on() -> void:
	if not is_active:
		return
		
	tile_stepped.emit(row, col, is_safe)
	
	if is_safe:
		reveal_safe()
	else:
		trigger_crumble()

func reveal_safe() -> void:
	is_revealed = true
	update_visuals()
	
	# Gentle celebratory bounce
	var tween = create_tween()
	tween.tween_property(self, "position:y", initial_pos.y - 0.1, 0.08)
	tween.tween_property(self, "position:y", initial_pos.y, 0.12)

func trigger_crumble() -> void:
	if not is_active:
		return
	is_active = false
	
	# Flash red warning
	if mesh_instance:
		mesh_instance.material_override = crumble_warn_mat
	
	# Shake effect
	var tween = create_tween()
	for i in range(4):
		var shake_offset = Vector3(randf_range(-0.1, 0.1), 0, randf_range(-0.1, 0.1))
		tween.tween_property(self, "position", initial_pos + shake_offset, 0.05)
	
	# Tilt and drop down
	tween.tween_property(self, "position:y", initial_pos.y - 12.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "rotation_degrees:x", randf_range(-45, 45), 0.6)
	tween.parallel().tween_property(self, "rotation_degrees:z", randf_range(-45, 45), 0.6)
	
	# Disable collision when dropping
	tween.tween_callback(func():
		collision_shape.disabled = true
	)
	
	# Reset tile after 3 seconds so players can re-test or play again
	get_tree().create_timer(3.0).timeout.connect(reset_tile)

func reset_tile() -> void:
	is_active = true
	collision_shape.disabled = false
	rotation = initial_rot
	position = initial_pos
	update_visuals()
