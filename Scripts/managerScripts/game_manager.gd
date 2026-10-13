extends Node

signal pointsReady

var players = {}

enum SpawnPointNames {
	Church,
	one,
	two,
	three,
	four,
}

var spawn_points: Array[Area3D] = []
#@onready var gm = $"."

func refreshSpawnPoints() -> void:
	spawn_points.clear()  # avoid duplicates on repeat calls
	for node in get_tree().get_nodes_in_group("spawn_points"):
		if node is Area3D:
			spawn_points.append(node)
	print("Registered spawn points count: ", spawn_points.size())
	
	print("Registered spawn points count: ", spawn_points.size())
	#print(len(GameManager.spawn_points))

func getSpawnPointPosition(point_type: SpawnPointNames) -> Vector3:
	var index: int = point_type as int
	if index >= 0 and index < spawn_points.size():
		return spawn_points[index].global_position
	
	print("Spawn point index %d out of bounds! Array size is %d" % [index, spawn_points.size()])
	return Vector3.ZERO
	
func addPlayer(player_name: String, obj: Node) -> void:
	if player_name in players:
		print("PLAYER ALREADY EXISTS")
		return
	players[player_name] = obj
	EventBus.player_count += 1

func removePlayer(player_name: String) -> void:
	if players.erase(player_name):
		EventBus.player_count -= 1
		
