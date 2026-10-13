extends CSGCylinder3D 

@export var clue_ui: TextureRect
@export var interact_prompt: Label

var player_near = false

func _ready():
	if clue_ui:
		clue_ui.hide()
	if interact_prompt:
		interact_prompt.hide()

func _on_paper_interact_zone_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		if interact_prompt and not clue_ui.visible:
			interact_prompt.show()

func _on_paper_interact_zone_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		if interact_prompt:
			interact_prompt.hide()
		if clue_ui:
			clue_ui.hide()

# Changed to _input so it ALWAYS registers the E key
func _input(event):
	if event.is_action_pressed("interact") and player_near:
		if clue_ui:
			clue_ui.visible = !clue_ui.visible
			if clue_ui.visible:
				if interact_prompt: interact_prompt.hide()
			else:
				if interact_prompt: interact_prompt.show()
