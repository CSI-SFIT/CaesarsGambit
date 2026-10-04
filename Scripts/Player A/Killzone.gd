extends Area3D

@onready var death_ui = $DeathUI

func _ready():
	death_ui.hide()

func _on_body_entered(body):
	if body.is_in_group("player"):
		death_ui.show()
		# Wait 2 seconds, then restart the level
		await get_tree().create_timer(2.0).timeout
		get_tree().reload_current_scene()
