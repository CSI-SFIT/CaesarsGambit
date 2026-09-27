extends Control
class_name GameUI

signal host_pressed()
signal join_pressed(ip: String)
signal solo_pressed()
signal hint_toggled(show: bool)
signal play_again_pressed()

@onready var lobby_panel: PanelContainer = $LobbyPanel
@onready var hud_panel: Control = $HUD
@onready var victory_panel: PanelContainer = $VictoryPanel
@onready var leaderboard_modal: PanelContainer = $LeaderboardModal

@onready var ip_edit: LineEdit = $LobbyPanel/Margin/VBox/JoinBox/IPEdit
@onready var host_btn: Button = $LobbyPanel/Margin/VBox/HostBtn
@onready var join_btn: Button = $LobbyPanel/Margin/VBox/JoinBox/JoinBtn
@onready var solo_btn: Button = $LobbyPanel/Margin/VBox/SoloBtn
@onready var copy_ip_btn: Button = $LobbyPanel/Margin/VBox/IPRow/CopyIPBtn
@onready var copied_notice: Label = $LobbyPanel/Margin/VBox/CopiedNotice
@onready var host_ip_label: Label = $LobbyPanel/Margin/VBox/IPRow/HostIPLabel
@onready var leaderboard_btn_lobby: Button = $LobbyPanel/Margin/VBox/LeaderboardBtnLobby

# HUD Elements
@onready var cipher_text_label: Label = $HUD/TopBar/Margin/HBox/CipherLabel
@onready var shift_text_label: Label = $HUD/TopBar/Margin/HBox/ShiftLabel
@onready var word_tracker_label: Label = $HUD/TopBar/Margin/HBox/WordTracker
@onready var timer_label: Label = $HUD/TopBar/Margin/HBox/TimerLabel
@onready var p1_badge: Label = $HUD/PlayersBox/P1Badge
@onready var p2_badge: Label = $HUD/PlayersBox/P2Badge
@onready var hint_card: PanelContainer = $HUD/HintCard
@onready var hint_solution_label: Label = $HUD/HintCard/Margin/VBox/SolutionLabel
@onready var spectator_banner: PanelContainer = $HUD/SpectatorBanner
@onready var spectator_label: Label = $HUD/SpectatorBanner/Margin/Label

# Victory Elements
@onready var victory_title: Label = $VictoryPanel/Margin/VBox/VictoryTitle
@onready var victory_desc: Label = $VictoryPanel/Margin/VBox/VictoryDesc
@onready var stats_label: Label = $VictoryPanel/Margin/VBox/StatsLabel
@onready var log_notice_label: Label = $VictoryPanel/Margin/VBox/LogNotice
@onready var play_again_btn: Button = $VictoryPanel/Margin/VBox/PlayAgainBtn
@onready var leaderboard_btn_vic: Button = $VictoryPanel/Margin/VBox/LeaderboardBtnVic

# Leaderboard Modal Elements
@onready var runs_list: VBoxContainer = $LeaderboardModal/Margin/VBox/Scroll/RunsList
@onready var close_leaderboard_btn: Button = $LeaderboardModal/Margin/VBox/CloseLeaderboardBtn

var is_hint_open: bool = false

func _ready() -> void:
	lobby_panel.visible = true
	hud_panel.visible = false
	victory_panel.visible = false
	hint_card.visible = false
	leaderboard_modal.visible = false
	if spectator_banner:
		spectator_banner.visible = false
	
	host_btn.pressed.connect(_on_host_pressed)
	join_btn.pressed.connect(_on_join_pressed)
	solo_btn.pressed.connect(_on_solo_pressed)
	if copy_ip_btn:
		copy_ip_btn.pressed.connect(_on_copy_ip_pressed)
	if leaderboard_btn_lobby:
		leaderboard_btn_lobby.pressed.connect(open_leaderboard)
	if leaderboard_btn_vic:
		leaderboard_btn_vic.pressed.connect(open_leaderboard)
	if close_leaderboard_btn:
		close_leaderboard_btn.pressed.connect(close_leaderboard)
	if play_again_btn:
		play_again_btn.pressed.connect(_on_play_again_pressed)
	
	var ip = get_local_ip()
	host_ip_label.text = "LAN IP: %s (Port: 7777)" % ip

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
	victory_panel.visible = false
	leaderboard_modal.visible = false
	if spectator_banner:
		spectator_banner.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func update_cipher_display(cipher_word: String, shift: int, plain_word: String) -> void:
	update_cipher_display_split(cipher_word, shift, plain_word, 1, true)

func update_cipher_display_split(cipher_word: String, shift: int, plain_word: String, player_role: int, is_solo: bool) -> void:
	var prefix = "+" if shift > 0 else ""
	if is_solo:
		if cipher_text_label:
			cipher_text_label.text = "CIPHER: %s" % cipher_word
		if shift_text_label:
			shift_text_label.text = "SHIFT: %s%d" % [prefix, shift]
		if hint_solution_label:
			hint_solution_label.text = "SOLO PRACTICE DECODER:\nDecrypted Word: %s\n(Follow these letters across rows!)" % plain_word
	elif player_role == 1 or player_role <= 1:
		if cipher_text_label:
			cipher_text_label.text = "[CAESAR] CLUE: " + cipher_word
		if shift_text_label:
			shift_text_label.text = "SHIFT: ??? [ASK CENTURION (P2)]"
		if hint_solution_label:
			hint_solution_label.text = "TEAMWORK REQUIRED:\nYou have the Cipher: " + cipher_word + "\nAsk Centurion (P2) for the secret shift number to decode your path!"
	else:
		if cipher_text_label:
			cipher_text_label.text = "CIPHER: ??? [ASK CAESAR (P1)]"
		if shift_text_label:
			shift_text_label.text = "[CENTURION] CLUE: SHIFT " + prefix + str(shift)
		if hint_solution_label:
			hint_solution_label.text = "TEAMWORK REQUIRED:\nYou have the Shift: " + prefix + str(shift) + "\nAsk Caesar (P1) for the encrypted word to calculate the path together!"

func update_word_tracker(revealed_letters: String, target_word_length: int) -> void:
	if not word_tracker_label:
		return
	var text_display = "DECODED: ["
	for i in range(target_word_length):
		if i < revealed_letters.length():
			text_display += " " + revealed_letters[i]
		else:
			text_display += " _"
	text_display += " ]"
	word_tracker_label.text = text_display

func show_spectator_banner(text_msg: String) -> void:
	if spectator_banner:
		spectator_banner.visible = true
	if spectator_label:
		spectator_label.text = text_msg

func hide_spectator_banner() -> void:
	if spectator_banner:
		spectator_banner.visible = false

func update_player_badges(p1_active: bool, p2_active: bool) -> void:
	if p1_badge:
		p1_badge.text = "Caesar (P1): " + ("READY" if p1_active else "WAITING...")
	if p2_badge:
		p2_badge.text = "Centurion (P2): " + ("READY" if p2_active else "WAITING...")

func update_timer(seconds: int) -> void:
	if timer_label:
		timer_label.text = "HOURGLASS: %ds" % seconds
		if seconds <= 20:
			timer_label.modulate = Color(1.0, 0.25, 0.2)
		else:
			timer_label.modulate = Color(1.0, 0.85, 0.2)

func show_tournament_victory(time_sec: float, acc: float, rank: String, word: String) -> void:
	lobby_panel.visible = false
	victory_panel.visible = true
	if spectator_banner:
		spectator_banner.visible = false
	if victory_title:
		victory_title.text = "AVE CAESAR! TRIAL CONQUERED!"
	if victory_desc:
		victory_desc.text = "Both Gladiators deciphered '%s' and crossed the abyss!\nThe 4-player gate to the Grand Arena is unlocked!" % word
	if stats_label:
		stats_label.text = "TIME: %.1fs   |   ACCURACY: %.0f%%   |   RANK: %s" % [time_sec, acc, rank]
	if log_notice_label:
		log_notice_label.text = "Tournament run recorded to tournament_results.json"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_victory(message: String = "") -> void:
	show_tournament_victory(35.0, 100.0, "S - IMPERATOR", "ROMA")

func open_leaderboard() -> void:
	leaderboard_modal.visible = true
	populate_leaderboard()

func close_leaderboard() -> void:
	leaderboard_modal.visible = false
	if hud_panel and hud_panel.visible and not victory_panel.visible and not lobby_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func populate_leaderboard() -> void:
	if not runs_list:
		return
	for c in runs_list.get_children():
		c.queue_free()
		
	var path = "user://tournament_results.json"
	if not FileAccess.file_exists(path):
		var empty_lbl = Label.new()
		empty_lbl.text = "No tournament runs logged yet. Complete a trial to rank!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		runs_list.add_child(empty_lbl)
		return
		
	var f = FileAccess.open(path, FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	
	if not (parsed is Array) or parsed.size() == 0:
		var empty_lbl = Label.new()
		empty_lbl.text = "No runs logged yet."
		runs_list.add_child(empty_lbl)
		return
		
	# Sort runs by clear time ascending
	parsed.sort_custom(func(a, b): return a.get("clear_time_sec", 999.0) < b.get("clear_time_sec", 999.0))
	
	var count = min(6, parsed.size())
	for i in range(count):
		var item = parsed[i]
		var panel = PanelContainer.new()
		var lbl = Label.new()
		var rank_str = item.get("rank", "B")
		var time_str = str(item.get("clear_time_sec", 0.0)) + "s"
		var acc_str = str(item.get("accuracy_pct", 100.0)) + "%"
		var mode_str = item.get("mode", "Co-op")
		var word_str = item.get("word", "")
		
		lbl.text = "#%d | %s | CLEAR: %s | ACC: %s | WORD: %s | %s" % [i + 1, rank_str, time_str, acc_str, word_str, mode_str]
		if rank_str.begins_with("S"):
			lbl.modulate = Color(1.0, 0.88, 0.25)
		elif rank_str.begins_with("A"):
			lbl.modulate = Color(0.4, 0.8, 1.0)
		else:
			lbl.modulate = Color(0.9, 0.9, 0.9)
			
		runs_list.add_child(lbl)

func _on_copy_ip_pressed() -> void:
	DisplayServer.clipboard_set(get_local_ip())
	if copied_notice:
		copied_notice.visible = true
		get_tree().create_timer(2.5).timeout.connect(func(): if copied_notice: copied_notice.visible = false)

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

func _on_play_again_pressed() -> void:
	victory_panel.visible = false
	if leaderboard_modal:
		leaderboard_modal.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	play_again_pressed.emit()
