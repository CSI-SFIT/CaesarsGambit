extends Node

signal player_registered(pid: int, player: Node)
signal player_unregistered(pid: int)

enum SpawnPointNames {
	PlayerSpawnPoint_Church,
	PlayerSpawnPoint_Decipher,
	PlayerSpawnPoint_Logic,
	PlayerSpawnPoint_Maze,
	PlayerSpawnPoint_Final,
}

var players: Dictionary = {}        # pid (int) -> player node, filled on EVERY peer
var spawn_points: Dictionary = {}   # SpawnPointNames value -> Area3D (server only)
var spawn_owners: Dictionary = {}   # SpawnPointNames value -> pid (server only)

const FIANL_CUT_SCENE = preload("uid://cnqu0iukwskim")


# ---------- Players (all peers) ----------
func registerPlayer(pid: int, player: Node) -> void:
	if players.has(pid):
		print("PLAYER ALREADY EXISTS: ", pid)
		return
	players[pid] = player
	EventBus.player_count = players.size()
	player_registered.emit(pid, player)

func unregisterPlayer(pid: int) -> void:
	if players.erase(pid):
		EventBus.player_count = players.size()
		player_unregistered.emit(pid)

# ---------- Spawn points (server only) ----------
func refreshSpawnPoints() -> void:
	spawn_points.clear()
	spawn_owners.clear()
	for node in get_tree().get_nodes_in_group("spawn_points"):
		var key := str(node.name)
		if node is Area3D and SpawnPointNames.has(key):
			spawn_points[SpawnPointNames[key]] = node
		else:
			push_warning("Spawn point '%s' doesn't match any SpawnPointNames entry" % key)
	print("Registered spawn points count: ", spawn_points.size())

# Gives the next free spawn point (in enum order) to this peer
func claimSpawnPoint(pid: int) -> Vector3:
	for point in SpawnPointNames.values():
		if spawn_points.has(point) and not spawn_owners.has(point):
			spawn_owners[point] = pid
			print("peer %d -> spawn point %s at %s" % [pid, SpawnPointNames.keys()[point], spawn_points[point].global_position])
			return spawn_points[point].global_position
	push_warning("No free spawn point for peer %d" % pid)
	return Vector3.ZERO

func releaseSpawnPoint(pid: int) -> void:
	for point in spawn_owners.keys():
		if spawn_owners[point] == pid:
			spawn_owners.erase(point)
			
func getSpawnPointPosition(point: SpawnPointNames) -> Vector3:
	if spawn_points.has(point):
		return spawn_points[point].global_position
	push_warning("Spawn point %s not found" % SpawnPointNames.keys()[point])
	return Vector3.ZERO
	
func respawn_all_team(spawn_point_name: SpawnPointNames) -> void:
	if not multiplayer.is_server():
		return

	# 1. Resolve the spawn coordinates once on the server
	var target_pos: Vector3 = getSpawnPointPosition(spawn_point_name)
	print("Server resolved spawn position to: ", target_pos)

	# 2. Broadcast the exact Vector3 to all peers
	_teleport_all_rpc.rpc(target_pos)

@rpc("call_local", "reliable")
func _teleport_all_rpc(target_pos: Vector3) -> void:
	for pid in players:
		var p = players[pid]
		if is_instance_valid(p) and p.has_method("teleport_to"):
			p.teleport_to(target_pos)

# ---------- Players (all peers) ----------

## Call this to drop a player across all connected peers
@rpc("any_peer", "call_local", "reliable")
func dropPlayer(pid: int) -> void:
	if players.erase(pid):
		EventBus.player_count = players.size()
		player_unregistered.emit(pid)
		print("Peer %d successfully dropped from GameManager. Remaining: %d" % [pid, players.size()])
		
		# ONLY the server decides when all players have finished
		if multiplayer.is_server() and players.is_empty():
			print("All players cleared the level! Starting cutscene for everyone...")
			playCutscene.rpc()
	else:
		push_warning("Attempted to drop non-existent peer ID: %d" % pid)

## Broadcasts the cutscene trigger to every connected machine (host + clients)
@rpc("call_local", "reliable")
func playCutscene() -> void:
	print("Playing cutscene on peer: ", multiplayer.get_unique_id())
	# Ensure the filename matches your actual file name in the FileSystem dock
	get_tree().change_scene_to_file("res://Scenes/fianl_cut_scene.tscn")
	
	# 1. Disable player inputs/HUD if needed
	# UI.hide_game_hud()
	
	# 2. Trigger your AnimationPlayer, Camera switch, or cutscene scene
	# $CutsceneAnimationPlayer.play("end_level_cutscene")
	# Or load/change to a cutscene scene:
	# get_tree().change_scene_to_file("res://Scenes/Cutsc
