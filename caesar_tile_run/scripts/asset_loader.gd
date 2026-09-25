extends Node
class_name AssetLoader

# Automatically integrates downloaded Sketchfab .glb models into the scene

func _ready() -> void:
	await get_tree().process_frame
	load_all_sketchfab_assets()

func load_all_sketchfab_assets() -> void:
	print("--- ASSET LOADER: Building Colosseum Arena Base ---")
	
	var main_node = get_tree().root.get_node_or_null("Main")
	if not main_node:
		return

	# Hide old basic placeholder background boxes
	var old_ruins = main_node.get_node_or_null("BackgroundRuins")
	if old_ruins:
		old_ruins.visible = false

	# 1. BUILD THE COLOSSEUM ARENA BASE (Surrounds the whole game!)
	var colosseum_path = "res://assets/models/colosseum.glb"
	if ResourceLoader.exists(colosseum_path):
		var res = load(colosseum_path)
		if res is PackedScene:
			var arena_parent = Node3D.new()
			arena_parent.name = "ColosseumArenaBase"
			main_node.add_child(arena_parent)

			# NORTH WALL (Behind Finish Arch - Visible directly in front of the player!)
			var col_north = res.instantiate()
			col_north.name = "Colosseum_North"
			col_north.position = Vector3(0, -1.5, 48.0)
			col_north.rotation_degrees = Vector3(0, 180, 0)
			col_north.scale = Vector3(2.2, 2.2, 2.2)
			arena_parent.add_child(col_north)

			# SOUTH WALL (Behind Start Platform & Temple)
			var col_south = res.instantiate()
			col_south.name = "Colosseum_South"
			col_south.position = Vector3(0, -1.5, -22.0)
			col_south.rotation_degrees = Vector3(0, 0, 0)
			col_south.scale = Vector3(2.2, 2.2, 2.2)
			arena_parent.add_child(col_south)

			# WEST WALL (Left side of the tile track)
			var col_west = res.instantiate()
			col_west.name = "Colosseum_West"
			col_west.position = Vector3(-24.0, -1.5, 14.0)
			col_west.rotation_degrees = Vector3(0, -90, 0)
			col_west.scale = Vector3(2.0, 2.2, 2.0)
			arena_parent.add_child(col_west)

			# EAST WALL (Right side of the tile track)
			var col_east = res.instantiate()
			col_east.name = "Colosseum_East"
			col_east.position = Vector3(24.0, -1.5, 14.0)
			col_east.rotation_degrees = Vector3(0, 90, 0)
			col_east.scale = Vector3(2.0, 2.2, 2.0)
			arena_parent.add_child(col_east)

			print("-> Colosseum 360-degree Arena successfully created as the base!")

	# 2. ROMAN TEMPLE (Positioned in the Colosseum Forum behind start platform)
	var temple_path = "res://assets/models/temple.glb"
	if ResourceLoader.exists(temple_path):
		var res_temple = load(temple_path)
		if res_temple is PackedScene:
			var temple = res_temple.instantiate()
			temple.name = "SketchfabTemple"
			temple.position = Vector3(0, 0.0, -14.0)
			temple.scale = Vector3(0.55, 0.55, 0.55)
			main_node.add_child(temple)
			print("-> Roman Temple positioned on the arena forum!")

	# 3. HEROIC GUARDIAN GLADIATORS (Flanking the Start Gateway)
	var gladiator_path = "res://assets/models/gladiator.glb"
	if ResourceLoader.exists(gladiator_path):
		var res_glad = load(gladiator_path)
		if res_glad is PackedScene:
			var g1 = res_glad.instantiate()
			g1.name = "GuardianGladiatorLeft"
			g1.position = Vector3(-5.5, 0.0, 4.5)
			g1.rotation_degrees = Vector3(0, 45, 0)
			g1.scale = Vector3(0.28, 0.28, 0.28)
			main_node.add_child(g1)
			
			var g2 = res_glad.instantiate()
			g2.name = "GuardianGladiatorRight"
			g2.position = Vector3(5.5, 0.0, 4.5)
			g2.rotation_degrees = Vector3(0, -45, 0)
			g2.scale = Vector3(0.28, 0.28, 0.28)
			main_node.add_child(g2)
			print("-> Guardian Gladiators placed at arena gates!")
