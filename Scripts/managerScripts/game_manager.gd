extends Node

signal pointsReady

enum SpawnPointNames {
	Church,
	one,
	two,
	three,
}

var spawn_points: Array[Area3D] = []
#@onready var gm = $"."

func refreshSpawnPoints() -> void:	
	# Automatically find and collect all spawn points in the scene
	var nodes = get_tree().get_nodes_in_group("spawn_points")
	for node in nodes:
		if node is Area3D:
			spawn_points.append(node)
	
	print("Registered spawn points count: ", spawn_points.size())
	#print(len(GameManager.spawn_points))

func getSpawnPointPosition(point_type: SpawnPointNames) -> Vector3:
	var index: int = point_type as int
	if index >= 0 and index < spawn_points.size():
		return spawn_points[index].global_position
	
	print("Spawn point index %d out of bounds! Array size is %d" % [index, spawn_points.size()])
	return Vector3.ZERO
