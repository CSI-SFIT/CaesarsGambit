#extends Node3D
#@onready var rigid_body_3d: RigidBody3D = $RigidBody3D
#
#
## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#if not multiplayer.is_server():
		#rigid_body_3d.freeze = true
		#rigid_body_3d.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	#else:
		## Only start the despawn timer once upon spawn, strictly on the host
		#get_tree().create_timer(9.0).timeout.connect(queue_free)
	##pass
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#
	##await get_tree().create_timer(9).timeout
	##queue_free()
	#pass
	#
#
#
##func _on_area_3d_body_entered(body: Node3D) -> void:
	###print("PLAYER COLLIDED WITH BALL___")
	##if(body.is_in_group("PlayerGroup")):
		##print("PLAYER COLLIDED WITH BALL")
		##body.global_position = GameManager.getSpawnPointPosition(GameManager.SpawnPointNames.four)
#
#
## fallingrock.gd
#
#func _on_rigid_body_3d_body_entered(body: Node) -> void:
	## Only let the server handle collisions and coordinate respawns
	#if not multiplayer.is_server():
		#return
#
	#if body.is_in_group("PlayerGroup"):
		#print("Rock hit player. Server initiating group respawn.")
		#GameManager.respawn_all_team(GameManager.SpawnPointNames.PlayerSpawnPoint_Final)

extends RigidBody3D

func _ready() -> void:
	can_sleep = false
	
	if not multiplayer.is_server():
		# Clients don't compute physics; they follow the synchronizer
		freeze = true
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	else:
		# Auto-despawn after 9 seconds on server (MultiplayerSpawner removes it from clients)
		get_tree().create_timer(10).timeout.connect(queue_free)

func _on_body_entered(body: Node) -> void:
	if not multiplayer.is_server():
		return

	if body.is_in_group("PlayerGroup"):
		print("Rock hit player. Server initiating group respawn.")
		GameManager.respawn_all_team(GameManager.SpawnPointNames.PlayerSpawnPoint_Final)
