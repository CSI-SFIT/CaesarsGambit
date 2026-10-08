extends RigidBody3D

func _on_body_entered(body: Node) -> void:
	# Check if the object hitting the door is in the "boulder" group
	if body.is_in_group("boulder"):
		# Unfreeze the door so physics takes over and it gets smashed away
		freeze = false
		print("Door smashed by the boulder!")
