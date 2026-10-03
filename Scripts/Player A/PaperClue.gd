extends CSGCylinder3D 

@export var clue_ui: TextureRect
@onready var interact_prompt = $"../UI/InteractPrompt" # Grabs the new label

var player_near = false

func _ready():
	if clue_ui:
		clue_ui.hide()
	if interact_prompt:
		interact_prompt.hide()

func _on_paper_interact_zone_body_entered(body):
	if body.is_in_group("player"):
		player_near = true
		if interact_prompt:
			interact_prompt.show() # Show "Press E"

func _on_paper_interact_zone_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		if interact_prompt:
			interact_prompt.hide() # Hide "Press E"
		if clue_ui:
			clue_ui.hide()

func _unhandled_input(event):
	if event.is_action_pressed("interact") and player_near:
		if clue_ui:
			clue_ui.visible = !clue_ui.visible
			# Hide the prompt while reading the paper
			if clue_ui.visible:
				interact_prompt.hide()
			else:
				interact_prompt.show()
