extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("PlayerGroup"):
		return

	# Only the multiplayer authority of the player (or the server) triggers the clear
	if not body.is_multiplayer_authority() and not multiplayer.is_server():
		return

	# Retrieve the integer Peer ID
	var pid: int = body.get_multiplayer_authority()

	print("Player with Peer ID %d has cleared the level." % pid)
	
	# Broadcast removal to all peers via RPC
	GameManager.dropPlayer.rpc(pid)
