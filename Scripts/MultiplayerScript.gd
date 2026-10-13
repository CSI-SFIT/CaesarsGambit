extends Node3D

const PORT = 7777  # ports below 1024 are privileged
var peer = ENetMultiplayerPeer.new()
var player_scene = preload("res://Scenes/player.tscn")

func _ready() -> void:
	match EventBus.selected_role:
		EventBus.Role.HOST:
			start_host()
		EventBus.Role.CLIENT:
			start_client()
		_:
			print("No multiplayer role selected")

func start_host():
	var error = peer.create_server(PORT)
	if error != OK:
		print("Failed to host: ", error)
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(peer_added)
	multiplayer.peer_disconnected.connect(peer_removed)

	GameManager.refreshSpawnPoints()
	peer_added(multiplayer.get_unique_id())  # host's own player

func start_client():
	var error = peer.create_client("localhost", PORT)
	if error != OK:
		print("Failed to connect: ", error)
		return
	multiplayer.multiplayer_peer = peer
	# the client does not spawn or register anything, the server does

func peer_added(pid: int):
	if has_node(str(pid)):
		return
	print("player ", pid, " joined")
	var spawn_pos: Vector3 = GameManager.claimSpawnPoint(pid)
	var p = player_scene.instantiate()
	p.name = str(pid)
	p.position = spawn_pos
	add_child(p, true)
	if pid != multiplayer.get_unique_id():  # host's own player is already placed
		p.set_spawn_position.rpc_id(pid, spawn_pos)
	
	add_child(p, true)
	# no addPlayer here, the player registers itself (see player.gd)

func peer_removed(pid: int):
	var p = get_node_or_null(str(pid))
	if p:
		p.queue_free()  # its _exit_tree removes it from GameManager.players
	GameManager.releaseSpawnPoint(pid)
