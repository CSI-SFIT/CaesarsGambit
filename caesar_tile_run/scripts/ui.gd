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
@onready var adrenaline_vignette: Panel = $HUD/AdrenalineVignette
@onready var p1_badge: Label = $HUD/PlayersBox/P1Badge
@onready var p2_badge: Label = $HUD/PlayersBox/P2Badge
@onready var hint_card: PanelContainer = $HUD/HintCard
@onready var hint_solution_label: Label = $HUD/HintCard/Margin/VBox/SolutionLabel
@onready var spectator_banner: PanelContainer = $HUD/SpectatorBanner
@onready var spectator_label: Label = $HUD/SpectatorBanner/Margin/Label
@onready var alphabet_strip: PanelContainer = $HUD/AlphabetStrip
@onready var shift_helper_label: Label = $HUD/AlphabetStrip/Margin/VBox/ShiftHelperLabel

# Victory Elements
@onready var victory_title: Label = $VictoryPanel/Margin/VBox/VictoryTitle
@onready var victory_desc: Label = $VictoryPanel/Margin/VBox/VictoryDesc
@onready var stats_label: Label = $VictoryPanel/Margin/VBox/StatsLabel
@onready var log_notice_label: Label = $VictoryPanel/Margin/VBox/LogNotice
@onready var play_again_btn: Button = $VictoryPanel/Margin/VBox/PlayAgainBtn
@onready var leaderboard_btn_vic: Button = $VictoryPanel/Margin/VBox/LeaderboardBtnVic

# Leaderboard Modal Elements
@onready var rules_modal: PanelContainer = $RulesModal
@onready var rules_btn_lobby: Button = $LobbyPanel/Margin/VBox/RulesBtnLobby
@onready var close_rules_btn: Button = $RulesModal/Margin/VBox/CloseRulesBtn
@onready var decrypted_word_banner: Label = $VictoryPanel/Margin/VBox/DecryptedWordBanner
@onready var runs_list: VBoxContainer = $LeaderboardModal/Margin/VBox/Scroll/RunsList
@onready var close_leaderboard_btn: Button = $LeaderboardModal/Margin/VBox/CloseLeaderboardBtn

var is_hint_open: bool = false
var round_elapsed_timer: float = 0.0
var hint_penalty_used: bool = false
const HINT_LOCKOUT_TIME: float = 20.0

var current_shift: int = 3
var current_cipher_word: String = ""
var current_plain_word: String = ""
var current_role: int = 1
var is_solo_session: bool = false

func _ready() -> void:
	lobby_panel.visible = true
	hud_panel.visible = false
	victory_panel.visible = false
	hint_card.visible = false
	leaderboard_modal.visible = false
	if spectator_banner:
		spectator_banner.visible = false
	if alphabet_strip:
		alphabet_strip.visible = false
	if adrenaline_vignette:
		adrenaline_vignette.visible = false
	
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
	if rules_modal:
		rules_modal.visible = false
	if rules_btn_lobby:
		rules_btn_lobby.pressed.connect(open_rules)
	if close_rules_btn:
		close_rules_btn.pressed.connect(close_rules)
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
	if event.is_action_pressed("toggle_hint") or (event is InputEventKey and event.pressed and event.keycode == KEY_H):
		toggle_hint_card()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F2:
		toggle_rules()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		toggle_alphabet_strip()
	elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		handle_escape_key()

func is_any_modal_open() -> bool:
	if rules_modal and rules_modal.visible:
		return true
	if leaderboard_modal and leaderboard_modal.visible:
		return true
	if lobby_panel and lobby_panel.visible:
		return true
	if victory_panel and victory_panel.visible:
		return true
	return false

func handle_escape_key() -> void:
	get_viewport().set_input_as_handled()
	
	if rules_modal and rules_modal.visible:
		close_rules()
		return
	if leaderboard_modal and leaderboard_modal.visible:
		close_leaderboard()
		return
	if is_hint_open:
		is_hint_open = false
		if hint_card:
			hint_card.visible = false
		return
	if alphabet_strip and alphabet_strip.visible:
		alphabet_strip.visible = false
		return
		
	if (lobby_panel and lobby_panel.visible) or (victory_panel and victory_panel.visible):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
		
	open_rules()
func toggle_alphabet_strip() -> void:
	if not alphabet_strip:
		return
	alphabet_strip.visible = not alphabet_strip.visible

func toggle_hint_card() -> void:
	if not hint_card:
		return
		
	# 20-second timer lockout anti-cheat
	if round_elapsed_timer < HINT_LOCKOUT_TIME and not is_solo_session:
		is_hint_open = true
		hint_card.visible = true
		var rem = int(HINT_LOCKOUT_TIME - round_elapsed_timer)
		if hint_solution_label:
			hint_solution_label.text = "🔒 HINT LOCKED: %ds remaining!\nGladiators must talk and communicate first!" % rem
		return
		
	is_hint_open = not is_hint_open
	hint_card.visible = is_hint_open
	if is_hint_open and round_elapsed_timer >= HINT_LOCKOUT_TIME:
		hint_penalty_used = true

func reset_round_ui() -> void:
	round_elapsed_timer = 0.0
	hint_penalty_used = false
	is_hint_open = false
	if hint_card:
		hint_card.visible = false
	if alphabet_strip:
		alphabet_strip.visible = false
	if adrenaline_vignette:
		adrenaline_vignette.visible = false

func start_game_ui() -> void:
	lobby_panel.visible = false
	hud_panel.visible = true
	victory_panel.visible = false
	leaderboard_modal.visible = false
	round_elapsed_timer = 0.0
	hint_penalty_used = false
	if spectator_banner:
		spectator_banner.visible = false
	if alphabet_strip:
		alphabet_strip.visible = false
	if adrenaline_vignette:
		adrenaline_vignette.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	if hud_panel and hud_panel.visible and not victory_panel.visible:
		round_elapsed_timer += delta

func update_cipher_display(cipher_word: String, shift: int, plain_word: String) -> void:
	update_cipher_display_split(cipher_word, shift, plain_word, 1, true)

func update_cipher_display_split(cipher_word: String, shift: int, plain_word: String, player_role: int, is_solo: bool) -> void:
	current_shift = shift
	current_cipher_word = cipher_word
	current_plain_word = plain_word
	current_role = player_role
	is_solo_session = is_solo
	
	if shift_helper_label:
		shift_helper_label.text = "SHIFT +%d: Count %d letters backward from Cipher letter to decode! [TAB to toggle]" % [shift, shift]

	if is_solo:
		if cipher_text_label:
			cipher_text_label.text = "CIPHER: %s" % cipher_word
		if shift_text_label:
			shift_text_label.text = "SHIFT: +%d" % shift
		if hint_solution_label:
			hint_solution_label.text = "SOLO PRACTICE DECODER:\nDecrypted Word: %s\n(Follow these letters across rows!)" % plain_word
	elif player_role == 1 or player_role <= 1:
		if cipher_text_label:
			cipher_text_label.text = "[CAESAR] CLUE: " + cipher_word
		if shift_text_label:
			shift_text_label.text = "SHIFT: ??? [ASK CENTURION]"
		if hint_solution_label:
			hint_solution_label.text = "TEAMWORK REQUIRED:\nYou have the Cipher: " + cipher_word + "\nAsk Centurion (P2) for the secret shift number to decode your path!"
	else:
		if cipher_text_label:
			cipher_text_label.text = "CIPHER: ??? [ASK CAESAR]"
		if shift_text_label:
			shift_text_label.text = "[CENTURION] CLUE: SHIFT +" + str(shift)
		if hint_solution_label:
			hint_solution_label.text = "TEAMWORK REQUIRED:\nYou have the Shift: +" + str(shift) + "\nAsk Caesar (P1) for the encrypted word to calculate the path together!"

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
		if seconds <= 15:
			timer_label.modulate = Color(1.0, 0.2, 0.15)
			# 15s Adrenaline Vignette pulsation
			if adrenaline_vignette:
				adrenaline_vignette.visible = true
				var pulse = (sin(Time.get_ticks_msec() * 0.012) + 1.0) * 0.5
				adrenaline_vignette.modulate.a = 0.25 + pulse * 0.55
		elif seconds <= 25:
			timer_label.modulate = Color(1.0, 0.45, 0.2)
			if adrenaline_vignette:
				adrenaline_vignette.visible = false
		else:
			timer_label.modulate = Color(1.0, 0.85, 0.2)
			if adrenaline_vignette:
				adrenaline_vignette.visible = false

func show_tournament_victory(time_sec: float, acc: float, rank: String, word: String) -> void:
	lobby_panel.visible = false
	victory_panel.visible = true
	if spectator_banner:
		spectator_banner.visible = false
	if alphabet_strip:
		alphabet_strip.visible = false
	if adrenaline_vignette:
		adrenaline_vignette.visible = false
	if victory_title:
		victory_title.text = "AVE CAESAR! TRIAL CONQUERED!"
	if decrypted_word_banner:
		decrypted_word_banner.text = "DECRYPTED WORD: [ %s ]" % word.to_upper()
	if victory_desc:
		victory_desc.text = "Both Gladiators deciphered '%s' and crossed the abyss!\nThe 4-player gate to the Grand Arena is unlocked!" % word
	if stats_label:
		stats_label.text = "TIME: %.1fs   |   ACCURACY: %.0f%%   |   RANK: %s" % [time_sec, acc, rank]
	if log_notice_label:
		log_notice_label.text = "Tournament run recorded to tournament_results.json"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func show_victory(message: String = "") -> void:
	show_tournament_victory(35.0, 100.0, "S - IMPERATOR", "ROMA")

func open_rules() -> void:
	if rules_modal:
		rules_modal.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_rules() -> void:
	if rules_modal:
		rules_modal.visible = false
	if hud_panel and hud_panel.visible and not victory_panel.visible and not lobby_panel.visible:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func toggle_rules() -> void:
	if not rules_modal:
		return
	if rules_modal.visible:
		close_rules()
	else:
		open_rules()

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
		
	parsed.sort_custom(func(a, b): return a.get("clear_time_sec", 999.0) < b.get("clear_time_sec", 999.0))
	
	var count = min(6, parsed.size())
	for i in range(count):
		var item = parsed[i]
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
