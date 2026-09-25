extends Node3D

const CaesarCipherScript = preload("res://scripts/caesar_cipher.gd")
const RomanTileScript = preload("res://scripts/tile.gd")
const RomanPlayerScript = preload("res://scripts/player.gd")
const CaesarPillarScript = preload("res://scripts/caesar_pillar.gd")
const FinishArchScript = preload("res://scripts/finish_arch.gd")
const GameUIScript = preload("res://scripts/ui.gd")
const PendulumBladeScene = preload("res://scenes/pendulum_blade.tscn")
const RotatingSweeperScene = preload("res://scenes/rotating_sweeper.tscn")
const AssetLoaderScript = preload("res://scripts/asset_loader.gd")

const PORT: int = 7777
const GRID_ROWS: int = 8
const GRID_COLS: int = 5
const TILE_SPACING_X: float = 2.6
const TILE_SPACING_Z: float = 2.6

@export var tile_scene: PackedScene = preload("res://scenes/tile.tscn")
@export var player_scene: PackedScene = preload("res://scenes/player.tscn")

@onready var tiles_container: Node3D = $TilesContainer
@onready var players_container: Node3D = $PlayersContainer
@onready var caesar_pillar: Node3D = $CaesarPillar
@onready var finish_arch: Node3D = $FinishArch
@onready var ui: Control = $UI

var puzzle_data: Dictionary = {}
var tiles_grid: Array = [] # 2D array [row][col]
var players_at_finish: Array[int] = []
var sound_fx = preload("res://scripts/sound_effects.gd").new()
var hazards_container: Node3D
var round_timer: float = 90.0
var game_active: bool = false

func _ready() -> void:
	add_child(sound_fx)
	hazards_container = Node3D.new()
	hazards_container.name = "HazardsContainer"
	add_child(hazards_container)
	add_child(AssetLoaderScript.new())
	setup_milestone_labels()
	# Connect UI signals
	if ui:
		ui.host_pressed.connect(_on_host_pressed)
		ui.join_pressed.connect(_on_join_pressed)
		ui.solo_pressed.connect(_on_solo_pressed)
		
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
	
	# Server generates puzzle
	puzzle_data = CaesarCipherScript.generate_puzzle(GRID_ROWS, GRID_COLS)
	setup_grid_from_puzzle(puzzle_data)
	spawn_player(1)
	
	if ui:
		ui.update_cipher_display(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word)
		ui.update_player_badges(true, false)

func _on_join_pressed(ip: String) -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(ip, PORT)
	if err != OK:
		print("Failed to connect to ", ip, ": ", err)
		return
	multiplayer.multiplayer_peer = peer
	print("Connecting to host at ", ip)

func _on_solo_pressed() -> void:
	# Local practice mode without networking
	puzzle_data = CaesarCipherScript.generate_puzzle(GRID_ROWS, GRID_COLS)
	setup_grid_from_puzzle(puzzle_data)
	spawn_player(1)
	
	if ui:
		ui.update_cipher_display(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word)
		ui.update_player_badges(true, true)

func _on_peer_connected(id: int) -> void:
	print("Peer connected: ", id)
	if multiplayer.is_server():
		# Spawn Player 2
		spawn_player(id)
		# Send current puzzle state to connected client
		rpc_id(id, "sync_puzzle_to_client", puzzle_data)
		if ui:
			ui.update_player_badges(true, true)

func _on_peer_disconnected(id: int) -> void:
	print("Peer disconnected: ", id)
	var p = players_container.get_node_or_null(str(id))
	if p:
		p.queue_free()
	if ui:
		ui.update_player_badges(true, false)

func _on_connected_to_server() -> void:
	print("Connected to host server!")
	if ui:
		ui.update_player_badges(true, true)

func _on_connection_failed() -> void:
	print("Connection failed!")

@rpc("authority", "call_remote", "reliable")
func sync_puzzle_to_client(data: Dictionary) -> void:
	puzzle_data = data
	setup_grid_from_puzzle(puzzle_data)
	if ui:
		ui.update_cipher_display(puzzle_data.cipher_word, puzzle_data.shift, puzzle_data.plain_word)
func _process(delta: float) -> void:
	if game_active and round_timer > 0.0:
		round_timer -= delta
		if ui and ui.has_method("update_timer"):
			ui.update_timer(int(round_timer))
		if round_timer <= 0.0:
			trigger_timeout_reset()

func trigger_timeout_reset() -> void:
	round_timer = 90.0
	sound_fx.play_crumble()
	if multiplayer.is_server() or multiplayer.multiplayer_peer == null:
		puzzle_data = CaesarCipherScript.generate_puzzle(GRID_ROWS, GRID_COLS)
		setup_grid_from_puzzle(puzzle_data)
		if multiplayer.multiplayer_peer != null:
			rpc("sync_puzzle_to_client", puzzle_data)

func setup_grid_from_puzzle(data: Dictionary) -> void:
	# Clear existing tiles
	for child in tiles_container.get_children():
		child.queue_free()
	tiles_grid.clear()
	
	# Update Caesar Pillar 3D labels
	if caesar_pillar and caesar_pillar.has_method("set_puzzle_info"):
		caesar_pillar.set_puzzle_info(data.cipher_word, data.shift, data.plain_word)

	var path_cols: Array = data.path_cols
	var grid_letters: Array = data.grid_letters

	var offset_x = -((GRID_COLS - 1) * TILE_SPACING_X) / 2.0
	var start_z = 6.0 # Distance from starting platform

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

	# Spawn dynamic swinging blades and sweeper hazards!
	if hazards_container:
		for child in hazards_container.get_children():
			child.queue_free()
			
		# Pendulum 1 at row 2
		var p1 = PendulumBladeScene.instantiate()
		p1.position = Vector3(0, 7.2, start_z + (2 * TILE_SPACING_Z))
		p1.swing_speed = 2.4
		hazards_container.add_child(p1)
		
		# Rotating Sweeper at row 4
		var sw = RotatingSweeperScene.instantiate()
		sw.position = Vector3(0, 0.0, start_z + (4 * TILE_SPACING_Z))
		sw.rotation_speed = 1.6
		hazards_container.add_child(sw)
		
		# Pendulum 2 at row 6
		var p2 = PendulumBladeScene.instantiate()
		p2.position = Vector3(0, 7.2, start_z + (6 * TILE_SPACING_Z))
		p2.swing_speed = 2.8
		hazards_container.add_child(p2)

	round_timer = 90.0
	game_active = true

func _on_tile_stepped(row: int, col: int, is_safe: bool) -> void:
	if is_safe:
		sound_fx.play_safe()
	else:
		sound_fx.play_crumble()
		
	if multiplayer.multiplayer_peer != null:
		rpc("rpc_sync_tile_stepped", row, col, is_safe)

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
	var existing = players_container.get_node_or_null(str(id))
	if existing:
		return
		
	var player = player_scene.instantiate()
	player.name = str(id)
	player.player_id = 1 if (id == 1 or id <= 1) else 2
	
	# Spawn offset for 2 players
	var x_offset = -1.5 if (player.player_id == 1) else 1.5
	var spawn_pos = Vector3(x_offset, 1.5, 0.0)
	player.position = spawn_pos
	player.spawn_position = spawn_pos
	
	players_container.add_child(player)
	
	if multiplayer.multiplayer_peer != null:
		player.set_multiplayer_authority(id)

func _on_player_arrived_at_finish(player_id: int) -> void:
	if not players_at_finish.has(player_id):
		players_at_finish.append(player_id)
		
	# Check if single player or both players reached
	var is_solo = (multiplayer.multiplayer_peer == null)
	if is_solo or players_at_finish.size() >= 2:
		if multiplayer.multiplayer_peer != null:
			rpc("rpc_trigger_victory")
		else:
			trigger_victory_ui()

@rpc("authority", "call_local", "reliable")
func rpc_trigger_victory() -> void:
	trigger_victory_ui()

func trigger_victory_ui() -> void:
	sound_fx.play_victory()
	if ui and ui.has_method("show_victory"):
		ui.show_victory("CONGRATULATIONS GLADIATORS!\nYou deciphered Caesar's inscription and crossed the abyss.\nThe 4-player gate to the Grand Arena is unlocked!")

func setup_milestone_labels() -> void:
	var numerals: Array[String] = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII"]
	var milestones_node = get_node_or_null("Milestones")
	if milestones_node:
		var children = milestones_node.get_children()
		for i in range(min(numerals.size(), children.size())):
			var label = children[i].get_node_or_null("NumeralLabel")
			if label:
				label.text = numerals[i]
