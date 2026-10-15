extends Area3D

@onready var death_ui = $DeathUI

func _ready():
	death_ui.hide()

func _on_body_entered(body):
	#if body.is_in_group("PlayerGroup"):
		#death_ui.show()
		## Wait 2 seconds, then restart the level
		#await get_tree().create_timer(2.0).timeout
		#get_tree().reload_current_scene()
	if(body.is_in_group("PlayerGroup")):
		print("PLAYER COLLIDED WITH BALL")
		if is_instance_valid(body):
			var spawn_pos: Vector3 = GameManager.getSpawnPointPosition(GameManager.SpawnPointNames.PlayerSpawnPoint_Decipher)
			
			# Reset player position and cancel momentum
			if body.has_method("teleport_to"):
				body.teleport_to(spawn_pos)
