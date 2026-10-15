extends Node3D 

@export var clue_ui: TextureRect
@export var interact_prompt: Label

var player_near = false

func _ready():
	if clue_ui:
		clue_ui.hide()
	if interact_prompt:
		interact_prompt.hide()

func _on_paper_interact_zone_body_entered(body):
	# Checks for "PlayerGroup" and ensures it only triggers for the local player
	if (body.is_in_group("PlayerGroup") or body.is_in_group("player")) and body.is_multiplayer_authority():
		player_near = true
		if interact_prompt and not clue_ui.visible:
			interact_prompt.show()

func _on_paper_interact_zone_body_exited(body):
	if (body.is_in_group("PlayerGroup") or body.is_in_group("player")) and body.is_multiplayer_authority():
		player_near = false
		if interact_prompt:
			interact_prompt.hide()
		if clue_ui:
			clue_ui.hide()

func _input(event):
	if event.is_action_pressed("interact") and player_near:
		if clue_ui:
			clue_ui.visible = !clue_ui.visible
			if clue_ui.visible:
				# Paper is now open -> hide prompt and play paper sound
				if interact_prompt: 
					interact_prompt.hide()
				if has_node("PaperSound"): 
					$PaperSound.play()
			else:
				# Paper is closed -> show prompt again
				if interact_prompt: 
					interact_prompt.show()
