extends RigidBody3D

func _on_body_entered(body: Node) -> void:
	# Failsafe: Checks if it's in the group OR if the node is exactly named "Boulder"
	if body.is_in_group("boulder") or body.name == "Boulder":
		
		# 1. Unfreeze the door so gravity and physics take over
		freeze = false
		
		# 2. Calculate a dramatic push based on how fast the boulder is rolling
		if body is RigidBody3D:
			# Take the boulder's speed/direction and multiply it for a stronger impact
			var smash_force = body.linear_velocity * 1.5
			
			# Apply the force directly to the center of the door
			apply_central_impulse(smash_force)
		print("Door smashed by the boulder!")
	
	await get_tree().create_timer(3).timeout
	queue_free()
