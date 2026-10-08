extends Node3D

const CaesarCipherScript = preload("res://scripts/caesar_cipher.gd")
const RomanTileScript = preload("res://scripts/tile.gd")
const RomanPlayerScript = preload("res://scripts/player.gd")
const CaesarPillarScript = preload("res://scripts/caesar_pillar.gd")
const FinishArchScript = preload("res://scripts/finish_arch.gd")
const GameUIScript = preload("res://scripts/ui.gd")
const PendulumBladeScene = preload("res://scenes/pendulum_blade.tscn")
const RotatingSweeperScene = preload("res://scenes/rotating_sweeper.tscn")
const CatapultStrikeScene = preload("res://scripts/catapult_strike.gd")

const PORT: int = 7777
const GRID_ROWS: int = 8
const GRID_COLS: int = 5
const TILE_SPACING_X: float = 3.2
const TILE_SPACING_Z: float = 3.4

@export var tile_scene: PackedScene = preload("res://scenes/tile.tscn")
@export var player_scene: PackedScene = preload("res://scenes/player.tscn")

@onready var tiles_container: Node3D = $TilesContainer
@onready var players_container: Node3D = $PlayersContainer
@onready var caesar_pillar: Node3D = $CaesarPillar
@onready var finish_arch: Node3D = $FinishArch
@onready var ui: Control = $UI

var puzzle_data: Dictionary = {}
var tiles_grid: Array = []
var players_at_finish: Array[int] = []
var sound_fx = preload("res://scripts/sound_effects.gd").new()
var hazards_container: Node3D
var catapult_timer: float = 0.0
const CATAPULT_INTERVAL: float = 7.5
const ROUND_TIME: float = 45.0
var round_timer: float = ROUND_TIME
var game_active: bool = false
var coop_finish_countdown: float = 0.0
var is_waiting_for_coop_partner: bool = false

# Tournament statistics
var round_start_time: float = 0.0
var initial_sun_rotation: Vector3 = Vector3(-45.0, 30.0, 0.0)
var total_steps: int = 0
var safe_steps: int = 0
var my_player_role: int = 1
var is_solo_mode: bool = false
var current_highest_row: int = 0
var milestone_halfway_played: bool = false
var milestone_final_played: bool = false
var row_markers_container: Node3D

# Broadcast camera mode

func _ready() -> void:
	sound_fx.name = "SoundEffects"
	add_child(sound_fx)
	
	hazards_container = Node3D.new()
	hazards_container.name = "HazardsContainer"
	add_child(hazards_container)
	
	var colosseum = get_node_or_null("SketchfabColosseum")
	if colosseum:
		_disable_shadows_recursive(colosseum)
	row_markers_container = Node3D.new()
	row_markers_container.name = "RowMarkers"
	add_child(row_markers_container)
	var sun_node = get_node_or_null("DirectionalLight3D")
	if sun_node:
		initial_sun_rotation = sun_node.rotation_degrees
	
	# Connect UI signals
	if ui:
		ui.host_pressed.connect(_on_host_pressed)
		ui.join_pressed.connect(_on_join_pressed)
		ui.solo_pressed.connect(_on_solo_pressed)
		if ui.has_signal("play_again_pressed"):
			ui.play_again_pressed.connect(_on_play_again_pressed)
		
	if finish_arch:
		finish_arch.player_arrived.connect(_on_player_arrived_at_finish)
		
	# Multiplayer signals
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)

func _on_host_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, 2)
	if err != OK:
		print("Failed to host server: ", err)
		return
	multiplayer.multiplayer_peer = peer
	print("Hosting server on port ", PORT)
	
	my_player_role = 1
	is_solo_mode = false
	game_active = false
	
	puzzle_data = CaesarCipherScript.generate_puzzle(GRID_ROWS, GRID_COLS)
	setup_grid_from_puzzle(puzzle_data)
	spawn_player(1)
	
	if ui:
		if ui.has_method("start_game_ui"):
			ui.start_game_ui()
		ui.update_cipher_display_split(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word, 1, false)
		ui.update_player_badges(true, false)
		ui.update_timer(int(ROUND_TIME))
		ui.show_spectator_banner("WAITING FOR PLAYER 2 (CENTURION) TO JOIN...")

func _on_join_pressed(ip: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		print("Failed to connect to ", ip, ": ", err)
		return
	multiplayer.multiplayer_peer = peer
	my_player_role = 2
	is_solo_mode = false
	game_active = false
	print("Connecting to host at ", ip)
	if ui:
		if ui.has_method("start_game_ui"):
			ui.start_game_ui()
		ui.update_player_badges(true, false)
		ui.update_timer(int(ROUND_TIME))
		ui.show_spectator_banner("CONNECTING TO HOST SERVER...")

func _on_solo_pressed() -> void:
	my_player_role = 1
	is_solo_mode = true
	puzzle_data = CaesarCipherScript.generate_puzzle(GRID_ROWS, GRID_COLS)
	setup_grid_from_puzzle(puzzle_data)
	spawn_player(1)
	game_active = true
	round_timer = ROUND_TIME
	round_start_time = Time.get_ticks_msec() / 1000.0
	
	if ui:
		if ui.has_method("start_game_ui"):
			ui.start_game_ui()
		ui.hide_spectator_banner()
		ui.update_cipher_display_split(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word, 1, true)
		ui.update_player_badges(true, true)
		ui.update_timer(int(ROUND_TIME))

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	if multiplayer.is_server():
		spawn_player(id)
		rpc_id(id, "sync_puzzle_to_client", puzzle_data)
		start_coop_match()

func start_coop_match() -> void:
	game_active = true
	round_timer = ROUND_TIME
	round_start_time = Time.get_ticks_msec() / 1000.0
	sound_fx.play_safe()
	if ui:
		ui.hide_spectator_banner()
		ui.update_player_badges(true, true)
		ui.update_timer(int(ROUND_TIME))
		ui.update_cipher_display_split(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word, 1, false)
	if multiplayer.is_server():
		rpc("rpc_start_coop_match")

@rpc("authority", "call_remote", "reliable")
func rpc_start_coop_match() -> void:
	game_active = true
	round_timer = ROUND_TIME
	round_start_time = Time.get_ticks_msec() / 1000.0
	sound_fx.play_safe()
	if ui:
		ui.hide_spectator_banner()
		ui.update_player_badges(true, true)
		ui.update_timer(int(ROUND_TIME))
		if puzzle_data.has("cipher_word"):
			ui.update_cipher_display_split(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word, 2, false)

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	var p = players_container.get_node_or_null(str(id))
	if p:
		p.queue_free()
	game_active = false
	if ui:
		ui.update_player_badges(true, false)
		ui.show_spectator_banner("PARTNER DISCONNECTED - WAITING FOR RECONNECT...")

func _on_connected_to_server() -> void:
	print("Connected to host server as Centurion (Player 2)!")
	if ui:
		ui.update_player_badges(true, true)

func _on_connection_failed() -> void:
	print("Connection failed!")

@rpc("authority", "call_remote", "reliable")
func sync_puzzle_to_client(data: Dictionary) -> void:
	puzzle_data = data
	setup_grid_from_puzzle(puzzle_data)
	
	# Spawn both players on client machine
	spawn_player(1)
	spawn_player(multiplayer.get_unique_id())
	
	if ui:
		if ui.has_method("start_game_ui"):
			ui.start_game_ui()
		ui.update_cipher_display_split(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word, 2, false)
		ui.update_player_badges(true, true)

func _process(delta: float) -> void:
	if not game_active:
		return
		
	if round_timer > 0.0:
		var prev_sec = int(round_timer)
		round_timer -= delta
		var curr_sec = int(round_timer)
		
		# Dynamic Roman sunset under 15 seconds
		if curr_sec <= 15:
			update_sunset_sky(round_timer / 15.0)

		# Heartbeat audio under 15 seconds
		if curr_sec < prev_sec:
			if curr_sec <= 15 and curr_sec > 0:
				sound_fx.play_heartbeat()
			elif curr_sec <= 25 and curr_sec > 0:
				sound_fx.play_tick()
				
		if ui and ui.has_method("update_timer"):
			ui.update_timer(int(round_timer))
		if round_timer <= 0.0:
			trigger_timeout_reset()
			
		# Periodic Roman Catapult Fireball strikes
		catapult_timer += delta
		if catapult_timer >= CATAPULT_INTERVAL:
			catapult_timer = 0.0
			trigger_catapult_strike()

		# Co-op Finish Grace Countdown (when 1 player has reached)
		if is_waiting_for_coop_partner and game_active:
			coop_finish_countdown -= delta
			var sec_left = max(1, int(ceil(coop_finish_countdown)))
			var local_role = 1 if (multiplayer.multiplayer_peer == null or multiplayer.is_server()) else 2
			var first_arrived_pid = players_at_finish[0] if players_at_finish.size() > 0 else 1
			if ui and ui.has_method("show_spectator_banner"):
				if local_role == first_arrived_pid:
					ui.show_spectator_banner("GLADIATOR %d ARRIVED! Partner has %ds to reach..." % [first_arrived_pid, sec_left])
				else:
					ui.show_spectator_banner("PARTNER FINISHED! %ds to reach the arch for S-Rank!" % sec_left)
			if coop_finish_countdown <= 0.0:
				is_waiting_for_coop_partner = false
				if multiplayer.multiplayer_peer != null:
					if multiplayer.is_server():
						rpc("rpc_trigger_victory")
				else:
					trigger_victory_ui()



func trigger_timeout_reset() -> void:
	if players_at_finish.size() > 0:
		if multiplayer.multiplayer_peer != null:
			if multiplayer.is_server():
				rpc("rpc_trigger_victory")
		else:
			trigger_victory_ui()
		return
		
	round_timer = ROUND_TIME
	sound_fx.play_crumble()
	reset_player_positions()
	if multiplayer.is_server() or multiplayer.multiplayer_peer == null:
		puzzle_data = CaesarCipherScript.generate_puzzle(GRID_ROWS, GRID_COLS)
		setup_grid_from_puzzle(puzzle_data)
		if multiplayer.multiplayer_peer != null:
			rpc("sync_puzzle_to_client", puzzle_data)

func setup_grid_from_puzzle(data: Dictionary) -> void:
	if not tiles_container:
		tiles_container = get_node_or_null("Tiles")
	if tiles_container:
		for child in tiles_container.get_children():
			child.queue_free()
	tiles_grid.clear()
	
	if caesar_pillar and caesar_pillar.has_method("set_puzzle_info"):
		caesar_pillar.set_puzzle_info(data.cipher_word, data.shift, data.plain_word)

	var path_cols: Array = data.path_cols
	var grid_letters: Array = data.grid_letters

	var offset_x = -((GRID_COLS - 1) * TILE_SPACING_X) / 2.0
	var start_z = 6.0

	for r in range(GRID_ROWS):
		var row_tiles: Array = []
		var target_col = path_cols[r]
		for c in range(GRID_COLS):
			var tile = tile_scene.instantiate()
			tiles_container.add_child(tile)
			
			var pos = Vector3(
				offset_x + (c * TILE_SPACING_X),
				0.0,
				start_z + (r * TILE_SPACING_Z)
			)
			tile.position = pos
			
			var is_safe = (c == target_col)
			var letter = grid_letters[r][c]
			if tile.has_method("configure"):
				tile.configure(r, c, letter, is_safe)
			
			if tile.has_signal("tile_stepped"):
				tile.tile_stepped.connect(_on_tile_stepped)
			row_tiles.append(tile)
		tiles_grid.append(row_tiles)

		# Spawn Roman row numerals (I to VIII) along the course edges
	if row_markers_container:
		for child in row_markers_container.get_children():
			child.queue_free()
		var roman_nums = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
		for r in range(min(GRID_ROWS, roman_nums.size())):
			var z_pos = start_z + (r * TILE_SPACING_Z)
			for x_pos in [-8.6, 8.6]:
				var marker = Node3D.new()
				marker.position = Vector3(x_pos, 0.0, z_pos)
				
				# Carved travertine stone pedestal
				var pedestal = MeshInstance3D.new()
				var box = BoxMesh.new()
				box.size = Vector3(0.65, 0.3, 0.5)
				pedestal.mesh = box
				var stone_mat = StandardMaterial3D.new()
				stone_mat.albedo_color = Color(0.82, 0.78, 0.70)
				stone_mat.roughness = 0.85
				pedestal.material_override = stone_mat
				pedestal.position = Vector3(0, 0.15, 0)
				marker.add_child(pedestal)
				
				# Glowing Roman Numeral Label (Billboard enabled for clear readability)
				var lbl = Label3D.new()
				lbl.text = roman_nums[r]
				lbl.font_size = 48
				lbl.modulate = Color(1.0, 0.86, 0.3)
				lbl.outline_size = 10
				lbl.outline_modulate = Color(0.22, 0.10, 0.04)
				lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
				lbl.position = Vector3(0, 0.82, 0)
				marker.add_child(lbl)
				
				row_markers_container.add_child(marker)

	# Spawn hazards (Pendulum Blades & Rotating Sweeper)
	if hazards_container:
		for child in hazards_container.get_children():
			child.queue_free()
			
		var p1 = PendulumBladeScene.instantiate()
		p1.position = Vector3(0, 7.2, start_z + (2 * TILE_SPACING_Z))
		p1.swing_speed = 2.4
		hazards_container.add_child(p1)
		
		var sw = RotatingSweeperScene.instantiate()
		sw.position = Vector3(0, 0.0, start_z + (4 * TILE_SPACING_Z))
		sw.rotation_speed = 1.6
		hazards_container.add_child(sw)
		
		var p2 = PendulumBladeScene.instantiate()
		p2.position = Vector3(0, 7.2, start_z + (6 * TILE_SPACING_Z))
		p2.swing_speed = 2.8
		hazards_container.add_child(p2)



	round_timer = ROUND_TIME
	round_start_time = Time.get_ticks_msec() / 1000.0
	total_steps = 0
	safe_steps = 0
	current_highest_row = 0
	milestone_halfway_played = false
	milestone_final_played = false
	reset_sky_to_afternoon()
	players_at_finish.clear()
	if ui:
		if ui.has_method("reset_round_ui"):
			ui.reset_round_ui()
		if ui.has_method("update_word_tracker"):
			ui.update_word_tracker("", puzzle_data.get("plain_word", "ROMA").length())
		if ui.has_method("update_cipher_display_split") and my_player_role > 0 and puzzle_data.has("cipher_word"):
			ui.update_cipher_display_split(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word, my_player_role, is_solo_mode)

func _on_tile_stepped(row: int, col: int, is_safe: bool) -> void:
	if not game_active:
		return
	total_steps += 1
	if is_safe:
		safe_steps += 1
		if sound_fx and sound_fx.has_method("play_chime"):
			sound_fx.play_chime()
		# War drum cadence on halfway (Row 4) and final stretch (Row 8)
		if row >= 3 and not milestone_halfway_played:
			milestone_halfway_played = true
			if sound_fx and sound_fx.has_method("play_wardrum_cadence"):
				sound_fx.play_wardrum_cadence()
			elif sound_fx and sound_fx.has_method("play_wardrum"):
				sound_fx.play_wardrum()
		elif row >= 7 and not milestone_final_played:
			milestone_final_played = true
			if sound_fx and sound_fx.has_method("play_wardrum_cadence"):
				sound_fx.play_wardrum_cadence()
			elif sound_fx and sound_fx.has_method("play_wardrum"):
				sound_fx.play_wardrum()

		sound_fx.play_safe()
		if row >= current_highest_row:
			current_highest_row = row + 1
			var plain = puzzle_data.get("plain_word", "ROMA")
			var revealed = plain.substr(0, current_highest_row)
			if ui and ui.has_method("update_word_tracker"):
				ui.update_word_tracker(revealed, plain.length())
			if multiplayer.multiplayer_peer != null:
				rpc("rpc_sync_word_progress", revealed, plain.length())
	else:
		sound_fx.play_crumble()
		
	if multiplayer.multiplayer_peer != null:
		rpc("rpc_sync_tile_stepped", row, col, is_safe)

@rpc("any_peer", "call_local", "reliable")
func rpc_sync_word_progress(revealed: String, total_len: int) -> void:
	if ui and ui.has_method("update_word_tracker"):
		ui.update_word_tracker(revealed, total_len)

@rpc("any_peer", "call_local", "reliable")
func rpc_sync_tile_stepped(row: int, col: int, is_safe: bool) -> void:
	if row < tiles_grid.size() and col < tiles_grid[row].size():
		var tile = tiles_grid[row][col]
		if tile:
			if is_safe and tile.has_method("reveal_safe"):
				tile.reveal_safe()
			elif not is_safe and tile.has_method("trigger_crumble"):
				tile.trigger_crumble()

func spawn_player(id: int) -> void:
	if not players_container:
		players_container = get_node_or_null("PlayersContainer")
	if not players_container:
		return
	var existing = players_container.get_node_or_null(str(id))
	if existing:
		return
		
	var player = player_scene.instantiate()
	player.name = str(id)
	player.player_id = 1 if (id == 1 or id <= 1) else 2
	
	var x_offset = -1.5 if (player.player_id == 1) else 1.5
	var spawn_pos = Vector3(x_offset, 1.5, 0.0)
	player.position = spawn_pos
	player.spawn_position = spawn_pos
	
	# Set multiplayer authority BEFORE add_child so _ready() configures correctly
	if multiplayer.multiplayer_peer != null:
		player.set_multiplayer_authority(id)
		
	players_container.add_child(player)
	
	# Ensure camera is current for the local player authority
	var is_local = (multiplayer.multiplayer_peer == null) or (multiplayer.get_unique_id() == id)
	if player.has_node("CameraPivot/SpringArm3D/Camera3D"):
		var cam = player.get_node("CameraPivot/SpringArm3D/Camera3D")
		if is_local:
			cam.current = true
			cam.make_current()
		else:
			cam.current = false

func get_local_player() -> RomanPlayer:
	if not players_container:
		return null
	var local_id = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	return players_container.get_node_or_null(str(local_id)) as RomanPlayer

func get_other_player() -> RomanPlayer:
	if not players_container:
		return null
	var local_id = multiplayer.get_unique_id() if multiplayer.multiplayer_peer != null else 1
	for child in players_container.get_children():
		if child is RomanPlayer and child.name != str(local_id):
			return child
	return null

func _on_player_arrived_at_finish(player_id: int) -> void:
	if not players_at_finish.has(player_id):
		players_at_finish.append(player_id)
		
	if multiplayer.multiplayer_peer != null:
		rpc("rpc_player_arrived", player_id)
	else:
		handle_player_arrival(player_id)

@rpc("any_peer", "call_local", "reliable")
func rpc_player_arrived(arrived_id: int) -> void:
	if not players_at_finish.has(arrived_id):
		players_at_finish.append(arrived_id)
	handle_player_arrival(arrived_id)

@rpc("any_peer", "call_local", "reliable")
func rpc_trigger_victory() -> void:
	trigger_victory_ui()

func handle_player_arrival(arrived_id: int) -> void:
	# Trigger celebration animation on the gladiator who arrived
	for child in players_container.get_children():
		if child is RomanPlayer and child.player_id == arrived_id:
			if child.has_method("set_triumph"):
				child.set_triumph(true)
				
	if finish_arch and finish_arch.has_method("celebrate_player"):
		finish_arch.celebrate_player(arrived_id)
		
	var is_solo = (multiplayer.multiplayer_peer == null) or is_solo_mode
	if is_solo:
		trigger_victory_ui()
		return
		
	if players_at_finish.size() == 1:
		# First player in co-op arrived!
		is_waiting_for_coop_partner = true
		coop_finish_countdown = 15.0
		
		var local_role = 1 if multiplayer.is_server() else 2
		if arrived_id == local_role:
			var local_player = get_local_player()
			var teammate = get_other_player()
			if local_player and teammate and local_player.has_method("start_spectating"):
				local_player.start_spectating(teammate)
			if ui:
				ui.show_spectator_banner("GLADIATOR %d ARRIVED! Waiting for partner (15s)..." % arrived_id)
		else:
			sound_fx.play_safe()
			if ui:
				ui.show_spectator_banner("PARTNER FINISHED! Reach the arch within 15s for S-Rank!")
		return
		
	# Both players reached!
	is_waiting_for_coop_partner = false
	if ui and ui.has_method("hide_spectator_banner"):
		ui.hide_spectator_banner()
	if multiplayer.multiplayer_peer != null:
		if multiplayer.is_server():
			rpc("rpc_trigger_victory")
	else:
		trigger_victory_ui()

func trigger_victory_ui() -> void:
	if not game_active:
		return
	game_active = false
	is_waiting_for_coop_partner = false
	sound_fx.play_victory()
	
	# Trigger Golden Laurel Confetti Shower from Arch of Constantine
	if finish_arch and finish_arch.has_method("trigger_grand_victory_shower"):
		finish_arch.trigger_grand_victory_shower()
		
	# Trigger all players celebratory triumph pose
	for p in players_container.get_children():
		if p is RomanPlayer and p.has_method("set_triumph"):
			p.set_triumph(true)
	
	var clear_time = maxf(1.0, (Time.get_ticks_msec() / 1000.0) - round_start_time)
	var accuracy = 100.0 if total_steps == 0 else (float(safe_steps) / float(total_steps) * 100.0)
	
	var is_solo = (multiplayer.multiplayer_peer == null) or is_solo_mode
	var rank = "S - IMPERATOR"
	if is_solo:
		if clear_time > 36.0 or accuracy < 75.0:
			rank = "B - LEGIONNAIRE"
		elif clear_time > 26.0 or accuracy < 88.0:
			rank = "A - CENTURION"
		if accuracy < 60.0:
			rank = "C - GLADIATOR"
	else:
		if players_at_finish.size() >= 2:
			rank = "S - VICTORIA TANDEM"
		else:
			rank = "A - GLADIATOR CLEAR (Solo Arrival)"
		
	# Penalty check: if hint was opened, disqualify S rank
	if ui and "hint_penalty_used" in ui and ui.hint_penalty_used and rank.begins_with("S"):
		rank = "A - CENTURION (Hint Used)"
		
	var word = puzzle_data.get("plain_word", "ROMA")
	save_tournament_run(clear_time, accuracy, rank, word)
	
	if ui and ui.has_method("show_tournament_victory"):
		ui.show_tournament_victory(clear_time, accuracy, rank, word)

func save_tournament_run(clear_time: float, accuracy: float, rank: String, word: String) -> void:
	var mode_name = "Solo Practice" if is_solo_mode or (multiplayer.multiplayer_peer == null) else "2-Player Co-op LAN"
	var entry = {
		"timestamp": Time.get_datetime_string_from_system(),
		"word": word,
		"clear_time_sec": snappedf(clear_time, 0.1),
		"accuracy_pct": snappedf(accuracy, 0.1),
		"rank": rank,
		"mode": mode_name
	}
	
	var save_path = "user://tournament_results.json"
	var runs: Array = []
	if FileAccess.file_exists(save_path):
		var file_read = FileAccess.open(save_path, FileAccess.READ)
		if file_read:
			var existing = JSON.parse_string(file_read.get_as_text())
			if existing is Array:
				runs = existing
			file_read.close()
			
	runs.append(entry)
	var file_write = FileAccess.open(save_path, FileAccess.WRITE)
	if file_write:
		file_write.store_string(JSON.stringify(runs, "\t"))
		file_write.close()
		print("[TOURNAMENT LOGGED] Clear: ", clear_time, "s | Acc: ", accuracy, "% | Rank: ", rank, " -> ", save_path)

func _on_play_again_pressed() -> void:
	if multiplayer.multiplayer_peer != null and not multiplayer.is_server():
		return
		
	reset_round()
	if multiplayer.multiplayer_peer != null:
		rpc("rpc_sync_reset_round", puzzle_data)

@rpc("authority", "call_remote", "reliable")
func rpc_sync_reset_round(data: Dictionary) -> void:
	puzzle_data = data
	setup_grid_from_puzzle(puzzle_data)
	reset_player_positions()
	players_at_finish.clear()
	is_waiting_for_coop_partner = false
	coop_finish_countdown = 0.0
	game_active = true
	round_timer = ROUND_TIME
	if finish_arch and finish_arch.has_method("reset"):
		finish_arch.reset()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if ui:
		ui.victory_panel.visible = false
		ui.hide_spectator_banner()
		ui.reset_round_ui()
		ui.update_cipher_display_split(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word, 2, false)

func reset_round() -> void:
	puzzle_data = CaesarCipherScript.generate_puzzle(GRID_ROWS, GRID_COLS)
	setup_grid_from_puzzle(puzzle_data)
	reset_player_positions()
	players_at_finish.clear()
	is_waiting_for_coop_partner = false
	coop_finish_countdown = 0.0
	game_active = true
	round_timer = ROUND_TIME
	if finish_arch and finish_arch.has_method("reset"):
		finish_arch.reset()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if ui:
		ui.victory_panel.visible = false
		ui.hide_spectator_banner()
		ui.reset_round_ui()
		var role = 1
		ui.update_cipher_display_split(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word, role, is_solo_mode)

func reset_player_positions() -> void:
	for child in players_container.get_children():
		if child is RomanPlayer:
			if child.has_method("set_triumph"):
				child.set_triumph(false)
			if child.has_method("stop_spectating"):
				child.stop_spectating()
			child.respawn()



func update_sunset_sky(ratio: float) -> void:
	var t = clampf(1.0 - ratio, 0.0, 1.0) # 0.0 at 15s (afternoon), 1.0 at 0s (dramatic dusk)
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node and env_node.environment and env_node.environment.sky:
		var sky_mat = env_node.environment.sky.sky_material
		if sky_mat is ProceduralSkyMaterial:
			sky_mat.sky_top_color = lerp(Color(0.24, 0.35, 0.62), Color(0.16, 0.05, 0.26), t)
			sky_mat.sky_horizon_color = lerp(Color(0.98, 0.68, 0.38), Color(0.98, 0.16, 0.08), t)
			sky_mat.ground_horizon_color = lerp(Color(0.85, 0.52, 0.32), Color(0.82, 0.14, 0.06), t)
			env_node.environment.fog_light_color = lerp(Color(0.82, 0.58, 0.38), Color(0.94, 0.22, 0.12), t)
	var sun = get_node_or_null("DirectionalLight3D")
	if sun:
		sun.light_color = lerp(Color(1.0, 0.92, 0.82), Color(1.0, 0.42, 0.16), t)
		sun.light_energy = lerp(1.7, 2.4, t)
		sun.rotation_degrees.x = lerp(initial_sun_rotation.x, -16.0, t)

func reset_sky_to_afternoon() -> void:
	var env_node = get_node_or_null("WorldEnvironment")
	if env_node and env_node.environment and env_node.environment.sky:
		var sky_mat = env_node.environment.sky.sky_material
		if sky_mat is ProceduralSkyMaterial:
			sky_mat.sky_top_color = Color(0.24, 0.35, 0.62)
			sky_mat.sky_horizon_color = Color(0.98, 0.68, 0.38)
			sky_mat.ground_horizon_color = Color(0.85, 0.52, 0.32)
			env_node.environment.fog_light_color = Color(0.82, 0.58, 0.38)
	var sun = get_node_or_null("DirectionalLight3D")
	if sun:
		sun.light_color = Color(1.0, 0.92, 0.82)
		sun.light_energy = 1.7
		sun.rotation_degrees = initial_sun_rotation




func trigger_catapult_strike() -> void:
	if not game_active:
		return
	var target_row = randi_range(1, GRID_ROWS - 1)
	var target_col = randi() % GRID_COLS
	var offset_x = -((GRID_COLS - 1) * TILE_SPACING_X) / 2.0
	var start_z = 6.0
	var target_pos = Vector3(offset_x + (target_col * TILE_SPACING_X), 0.0, start_z + (target_row * TILE_SPACING_Z))
	
	var strike = CatapultStrikeScene.new()
	strike.name = "CatapultStrike"
	strike.target_position = target_pos
	add_child(strike)

func _disable_shadows_recursive(node: Node) -> void:
	if node is GeometryInstance3D:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for child in node.get_children():
		_disable_shadows_recursive(child)
