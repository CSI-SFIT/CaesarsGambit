extends Control
class_name GameUI

signal host_pressed()
signal join_pressed(ip: String)
signal solo_pressed()
signal hint_toggled(show: bool)

@onready var lobby_panel: PanelContainer = $LobbyPanel
@onready var hud_panel: Control = $HUD
@onready var victory_panel: PanelContainer = $VictoryPanel

@onready var ip_edit: LineEdit = $LobbyPanel/Margin/VBox/JoinBox/IPEdit
@onready var host_btn: Button = $LobbyPanel/Margin/VBox/HostBtn
@onready var join_btn: Button = $LobbyPanel/Margin/VBox/JoinBox/JoinBtn
@onready var solo_btn: Button = $LobbyPanel/Margin/VBox/SoloBtn
@onready var host_ip_label: Label = $LobbyPanel/Margin/VBox/HostIPLabel

# HUD Elements
@onready var cipher_text_label: Label = $HUD/TopBar/Margin/HBox/CipherLabel
@onready var shift_text_label: Label = $HUD/TopBar/Margin/HBox/ShiftLabel
@onready var timer_label: Label = $HUD/TopBar/Margin/HBox/TimerLabel
@onready var p1_badge: Label = $HUD/PlayersBox/P1Badge
@onready var p2_badge: Label = $HUD/PlayersBox/P2Badge
@onready var hint_card: PanelContainer = $HUD/HintCard
@onready var hint_solution_label: Label = $HUD/HintCard/Margin/VBox/SolutionLabel

# Victory Elements
@onready var victory_title: Label = $VictoryPanel/Margin/VBox/VictoryTitle
@onready var victory_desc: Label = $VictoryPanel/Margin/VBox/VictoryDesc

var is_hint_open: bool = false

func _ready() -> void:
	lobby_panel.visible = true
	hud_panel.visible = false
	victory_panel.visible = false
	hint_card.visible = false
	
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	solo_btn.pressed.connect(_on_solo_pressed)
	
	# Detect local IP
	var ip = get_local_ip()
	host_ip_label.text = "Your Local LAN IP: %s (Port: 7777)" % ip

func get_local_ip() -> String:
	for address in IP.get_local_addresses():
		if address.begins_with("192.168.") or address.begins_with("10.") or address.begins_with("172."):
			return address
	return "127.0.0.1"

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_hint"):
		toggle_hint_card()

func toggle_hint_card() -> void:
	is_hint_open = not is_hint_open
	hint_card.visible = is_hint_open

func start_game_ui() -> void:
	lobby_panel.visible = false
	hud_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_cipher_display(cipher_word: String, shift: int, plain_word: String) -> void:
	if cipher_text_label:
		cipher_text_label.text = "CIPHER: %s" % cipher_word
	if shift_text_label:
		var prefix = "+" if shift > 0 else ""
		shift_text_label.text = "SHIFT: " + prefix + str(shift)
	if hint_solution_label:
		hint_solution_label.text = "DECODED WORD: %s\n(Follow these letters across rows!)" % plain_word

func update_player_badges(p1_active: bool, p2_active: bool) -> void:
	if p1_badge:
		p1_badge.text = "Player 1 (Caesar): " + ("READY" if p1_active else "WAITING...")
	if p2_badge:
		p2_badge.text = "Player 2 (Centurion): " + ("READY" if p2_active else "WAITING...")

func update_timer(seconds: int) -> void:
	if timer_label:
		timer_label.text = "HOURGLASS: %ds" % seconds
		if seconds <= 20:
			timer_label.modulate = Color(1.0, 0.25, 0.2)
		else:
			timer_label.modulate = Color(1.0, 0.85, 0.2)

func show_victory(message: String = "") -> void:
	victory_panel.visible = true
	if message != "":
		victory_desc.text = message
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_host_pressed() -> void:
	start_game_ui()
	host_pressed.emit()

func _on_join_pressed() -> void:
	var target_ip = ip_edit.text.strip_edges()
	if target_ip == "":
		target_ip = "127.0.0.1"
	start_game_ui()
	join_pressed.emit(target_ip)

func _on_solo_pressed() -> void:
	start_game_ui()
	solo_pressed.emit()
