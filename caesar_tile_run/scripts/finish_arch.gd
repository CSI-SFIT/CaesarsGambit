extends Node3D

signal player_arrived(player_id: int)

@onready var finish_area: Area3D = $FinishArea
@onready var portal_particles: OmniLight3D = $PortalGlow
@onready var victory_label: Label3D = $VictoryLabel

var players_reached: Array[int] = []

func _ready() -> void:
	if finish_area:
		finish_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and "player_id" in body:
		var pid = body.player_id
		if not players_reached.has(pid):
			players_reached.append(pid)
			player_arrived.emit(pid)
			celebrate_player(pid)

func celebrate_player(pid: int) -> void:
	if portal_particles:
		portal_particles.light_energy = 5.0
	if victory_label:
		victory_label.text = "GLADIATOR %d ARRIVED!" % pid
		victory_label.visible = true
