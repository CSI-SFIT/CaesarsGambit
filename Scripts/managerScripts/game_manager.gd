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
