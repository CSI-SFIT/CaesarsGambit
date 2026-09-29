extends Node
class_name AssetLoader

# Automatically integrates downloaded Sketchfab .glb models into the scene

func _ready() -> void:
	await get_tree().process_frame
	load_all_sketchfab_assets()

func load_all_sketchfab_assets() -> void:
	print("--- ASSET LOADER: Grounding Colosseum Arena Base (Optimized 60 FPS) ---")
	
	var main_node = get_tree().root.get_node_or_null("Main")
	if not main_node:
		return

	# 1. GROUNDED COLOSSEUM AMPHITHEATER AS THE MAIN PLAYABLE BASE
	# Scaled 6.5x and rotated 90 degrees so the entire tile run (Start -> Tiles -> Finish)
	# is played directly inside the Colosseum's inner arena oval!
	var colosseum_path = "res://assets/models/colosseum.glb"
	if ResourceLoader.exists(colosseum_path) and not main_node.has_node("SketchfabColosseum"):
		var res = load(colosseum_path)
		if res is PackedScene:
			var col = res.instantiate()
			col.name = "SketchfabColosseum"
			# Positioned so the arena oval floor is right at the game base (Y = -1.2)
			# and the towering tiered Colosseum walls encircle the entire game 360 degrees
			col.position = Vector3(0, -1.8, 16.0)
			col.rotation_degrees = Vector3(0, 90, 0)
			col.scale = Vector3(6.5, 6.5, 6.5)
			main_node.add_child(col)
			print("-> Colosseum Amphitheater successfully grounded as the playable arena!")

	# 2. ROMAN TEMPLE (Positioned on the starting forum)
	var temple_path = "res://assets/models/temple.glb"
	if ResourceLoader.exists(temple_path):
		var res_temple = load(temple_path)
		if res_temple is PackedScene:
			var temple = res_temple.instantiate()
			temple.name = "SketchfabTemple"
			temple.position = Vector3(0, -0.6, -14.0)
			temple.scale = Vector3(0.55, 0.55, 0.55)
			main_node.add_child(temple)
			print("-> Roman Temple positioned on the starting forum!")

	# 3. HEROIC GUARDIAN GLADIATORS (Flanking the Finish Arch Gateway)
	var gladiator_path = "res://assets/models/gladiator.glb"
	if ResourceLoader.exists(gladiator_path) and not main_node.has_node("GuardianGladiatorLeft"):
		var res_glad = load(gladiator_path)
		if res_glad is PackedScene:
			var g1 = res_glad.instantiate()
			g1.name = "GuardianGladiatorLeft"
			g1.position = Vector3(-4.8, 0.0, 29.0)
			g1.rotation_degrees = Vector3(0, -150, 0)
			g1.scale = Vector3(0.28, 0.28, 0.28)
			
			var col_body1 = StaticBody3D.new()
			var col_shape1 = CollisionShape3D.new()
			var cyl1 = CylinderShape3D.new()
			cyl1.radius = 0.6
			cyl1.height = 1.8
			col_shape1.shape = cyl1
			col_shape1.position = Vector3(0, 0.9, 0)
			col_body1.add_child(col_shape1)
			g1.add_child(col_body1)
			main_node.add_child(g1)
			
			var g2 = res_glad.instantiate()
			g2.name = "GuardianGladiatorRight"
			g2.position = Vector3(4.8, 0.0, 29.0)
			g2.rotation_degrees = Vector3(0, 150, 0)
			g2.scale = Vector3(0.28, 0.28, 0.28)
			
			var col_body2 = StaticBody3D.new()
			var col_shape2 = CollisionShape3D.new()
			var cyl2 = CylinderShape3D.new()
			cyl2.radius = 0.6
			cyl2.height = 1.8
			col_shape2.shape = cyl2
			col_shape2.position = Vector3(0, 0.9, 0)
			col_body2.add_child(col_shape2)
			g2.add_child(col_body2)
			main_node.add_child(g2)
			print("-> Guardian Gladiators placed at finish arena gates!")
