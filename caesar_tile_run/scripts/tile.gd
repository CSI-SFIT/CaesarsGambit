extends StaticBody3D
class_name RomanTile

signal tile_stepped(row: int, col: int, is_safe: bool)

@export var is_safe: bool = false
@export var row: int = 0
@export var col: int = 0
@export var letter: String = "A"

var is_revealed: bool = false
var is_active: bool = true
var is_standing_on: bool = false
var stand_timer: float = 0.0
const STAND_TIME_LIMIT: float = 2.4 # Time before safe tile collapses under weight!

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
		area_trigger.body_exited.connect(_on_body_exited)

func setup_materials() -> void:
	# Roman Travertine / Marble stone material
	stone_mat = StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.84, 0.80, 0.74)
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
	crumble_warn_mat.albedo_color = Color(0.9, 0.2, 0.15)
	crumble_warn_mat.emission_enabled = true
	crumble_warn_mat.emission = Color(1.0, 0.25, 0.1)
	crumble_warn_mat.emission_energy_multiplier = 2.5

func configure(r: int, c: int, char_val: String, safe_val: bool) -> void:
	row = r
	col = c
	letter = char_val
	is_safe = safe_val
	is_revealed = false
	is_active = true
	is_standing_on = false
	stand_timer = 0.0
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

func _process(delta: float) -> void:
	# Timed Tile Crumble: Safe tiles collapse if a player lingers/camps too long!
	if is_active and is_revealed and is_safe and is_standing_on:
		stand_timer += delta
		
		# Warning phase (after 1.3s of standing)
		if stand_timer > 1.3:
			var pulse = sin(stand_timer * 22.0) * 0.5 + 0.5
			if mesh_instance and mesh_instance.material_override:
				mesh_instance.material_override.emission = Color(1.0, 0.84, 0.2).lerp(Color(1.0, 0.15, 0.1), pulse)
				mesh_instance.material_override.emission_energy_multiplier = 2.0 + pulse * 2.0
			# Structural jitter
			position = initial_pos + Vector3(randf_range(-0.035, 0.035), 0, randf_range(-0.035, 0.035))
			
		# Collapse threshold
		if stand_timer >= STAND_TIME_LIMIT:
			is_standing_on = false
			stand_timer = 0.0
			trigger_crumble()

func _on_body_entered(body: Node3D) -> void:
	if not is_active:
		return
	if body is CharacterBody3D:
		is_standing_on = true
		step_on()

func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_standing_on = false
		stand_timer = 0.0
		position = initial_pos
		update_visuals()

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
	is_standing_on = false
	stand_timer = 0.0
	
	# Flash red warning
	if mesh_instance:
		mesh_instance.material_override = crumble_warn_mat
	
	# Shake effect
	var tween = create_tween()
	for i in range(4):
		var shake_offset = Vector3(randf_range(-0.1, 0.1), 0, randf_range(-0.1, 0.1))
		tween.tween_property(self, "position", initial_pos + shake_offset, 0.05)
	
	# Tilt and drop down into the hypogeum pit
	tween.tween_property(self, "position:y", initial_pos.y - 14.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "rotation_degrees:x", randf_range(-45, 45), 0.55)
	tween.parallel().tween_property(self, "rotation_degrees:z", randf_range(-45, 45), 0.55)
	
	# Disable collision when dropping
	tween.tween_callback(func():
		collision_shape.disabled = true
	)
	
	# Reset tile after 3.5 seconds
	get_tree().create_timer(3.5).timeout.connect(reset_tile)

func reset_tile() -> void:
	is_active = true
	is_standing_on = false
	stand_timer = 0.0
	collision_shape.disabled = false
	rotation = initial_rot
	position = initial_pos
	update_visuals()
