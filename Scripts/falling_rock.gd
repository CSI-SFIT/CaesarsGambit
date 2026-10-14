extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:

	await get_tree().create_timer(6.00).timeout
	queue_free()


#func _on_area_3d_body_entered(body: Node3D) -> void:
	##print("PLAYER COLLIDED WITH BALL___")
	#if(body.is_in_group("PlayerGroup")):
		#print("PLAYER COLLIDED WITH BALL")
		#body.global_position = GameManager.getSpawnPointPosition(GameManager.SpawnPointNames.four)


func _on_rigid_body_3d_body_entered(body: Node) -> void:
	#print("PLAYER COLLIDED WITH BALL___")
	if(body.is_in_group("PlayerGroup")):
		print("PLAYER COLLIDED WITH BALL")
		if is_instance_valid(body):
			var spawn_pos: Vector3 = GameManager.getSpawnPointPosition(GameManager.SpawnPointNames.PlayerSpawnPoint_Final)
			
			# Reset player position and cancel momentum
			if body.has_method("teleport_to"):
				body.teleport_to(spawn_pos)
