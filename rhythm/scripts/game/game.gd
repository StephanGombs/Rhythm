extends Node2D

@onready var score_label:   Label   = $HUD/ScoreLabel
@onready var funds_label:   Label   = $HUD/FundsLabel
@onready var shields_label: Label   = $HUD/ShieldsLabel
@onready var heart_container: CanvasLayer = $HUD/HeartContainer
@onready var shield_indicator: TextureRect = $HUD/ShieldIndicator
@onready var hurt_sound_player: AudioStreamPlayer = $Sfx/HurtSoundPlayer
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var countdown_label: Label = $HUD/CountdownLabel
@onready var timing_label:  Label   = $HUD/TimingLabel
@onready var pause_menu:    Control = $PauseMenu
@onready var heart_1: Control = $HUD/HeartContainer/Heart
@onready var heart_2: Control = $HUD/HeartContainer/Heart2
@onready var heart_3: Control = $HUD/HeartContainer/Heart3

const TIMING_DISPLAY_DURATION := 0.6
const SHIELD_FILLED_TEXTURE := preload("res://assets/shield_filled.png")
const SHIELD_EMPTY_TEXTURE := preload("res://assets/shield_empty.png")
const SHIELD_BROKEN_TEXTURE := preload("res://assets/shield_broken.png")
const WIN_SOUND := preload("res://assets/effects/win_sound.mp3")
const COUNTDOWN_STEPS := [
	{"text": "3", "time": 1.0},
	{"text": "2", "time": 1.0},
	{"text": "1", "time": 1.0},
	{"text": "GO!", "time": 0.5},
]

var _timing_timer: float   = 0.0
var _game_over_shown: bool = false
var _last_hearts: int = 3
var _shield_visual_state: String = "empty"
var _shield_visual_version: int = 0


func _ready() -> void:
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.funds_updated.connect(_on_funds_updated)
	GameManager.shields_updated.connect(_on_shields_updated)
	GameManager.hearts_updated.connect(_on_hearts_updated)
	GameManager.shield_state_updated.connect(_on_shield_state_updated)
	GameManager.game_finished.connect(_on_game_finished)
	GameManager.note_hit.connect(_on_note_hit)
	music_player.finished.connect(_on_music_finished)
	GameManager.start_game()
	_refresh_hud()
	_load_selected_music()
	_start_countdown()


func _process(delta: float) -> void:
	if _timing_timer > 0.0:
		_timing_timer -= delta
		if _timing_timer <= 0.0:
			timing_label.text = ""


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not get_tree().paused and not _game_over_shown:
		pause_menu.show_menu()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		GameManager.activate_shield()


func _refresh_hud() -> void:
	score_label.text   = "Score: 0"
	funds_label.text   = "Funds: 0.0"
	shields_label.text = "Shields: %d" % GameManager.shields
	_update_hearts(GameManager.hearts, false)
	_set_shield_visual("empty")
	countdown_label.hide()


func _on_score_updated(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score


func _on_funds_updated(new_funds: float) -> void:
	funds_label.text = "Funds: %.1f" % new_funds


func _on_shields_updated(count: int) -> void:
	shields_label.text = "Shields: %d" % count


func _on_hearts_updated(count: int) -> void:
	_update_hearts(count, true)


func _on_shield_state_updated(state: String) -> void:
	_set_shield_visual(state)


func _update_hearts(count: int, play_sound: bool) -> void:
	if play_sound and count < _last_hearts:
		hurt_sound_player.stop()
		hurt_sound_player.play()
	heart_1.visible = count >= 1
	heart_2.visible = count >= 2
	heart_3.visible = count >= 3
	_last_hearts = count


func _set_shield_visual(state: String) -> void:
	_shield_visual_version += 1
	_shield_visual_state = state

	match state:
		"filled":
			shield_indicator.texture = SHIELD_FILLED_TEXTURE
			shield_indicator.modulate = Color.WHITE
		"broken":
			shield_indicator.texture = SHIELD_BROKEN_TEXTURE
			shield_indicator.modulate = Color.WHITE
		_:
			shield_indicator.texture = SHIELD_EMPTY_TEXTURE
			shield_indicator.modulate = Color.WHITE

	if state == "broken":
		return


func _load_selected_music() -> void:
	var music_path := UserSession.selected_music_path
	if music_path.is_empty():
		music_path = UserSession.DEFAULT_MUSIC_PATH
		UserSession.select_music(UserSession.DEFAULT_MUSIC_TITLE, music_path)
	var stream := load(music_path)
	if stream is AudioStream:
		music_player.stream = stream
	else:
		push_warning("Unable to load selected music: %s" % music_path)


func _start_countdown() -> void:
	countdown_label.show()
	for step in COUNTDOWN_STEPS:
		countdown_label.text = step["text"]
		countdown_label.modulate = Color.WHITE if step["text"] != "GO!" else Color(0.8, 1.0, 0.4)
		await get_tree().create_timer(step["time"]).timeout
	countdown_label.hide()
	GameManager.begin_play()
	music_player.play()


func _on_music_finished() -> void:
	if _game_over_shown:
		return
	GameManager.finish_game(true)


func _on_note_hit(timing: String) -> void:
	timing_label.text = timing
	_timing_timer = TIMING_DISPLAY_DURATION
	match timing:
		"Perfect": timing_label.modulate = Color.GOLD
		"Good":    timing_label.modulate = Color.GREEN
		"Bad":     timing_label.modulate = Color.ORANGE_RED
		"Miss":    timing_label.modulate = Color.RED


func _on_game_finished(won: bool, final_score: int, total_funds: float) -> void:
	_game_over_shown = true
	music_player.stop()

	for note in get_tree().get_nodes_in_group("notes"):
		note.queue_free()

	if UserSession.is_logged_in:
		ApiClient.submit_score(UserSession.user_id, final_score, total_funds)

	# Play win sound when player finishes the song successfully
	if won:
		var win_player := AudioStreamPlayer.new()
		win_player.stream = WIN_SOUND
		add_child(win_player)
		win_player.play()
		# cleanup after a short delay to avoid lingering nodes
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(win_player):
			win_player.queue_free()

	_show_end_overlay(final_score, total_funds, won)


func _show_end_overlay(score: int, funds: float, won: bool) -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.75)
	bg.anchor_right  = 1.0
	bg.anchor_bottom = 1.0
	layer.add_child(bg)

	var panel := PanelContainer.new()
	panel.anchor_left   = 0.5
	panel.anchor_top    = 0.5
	panel.anchor_right  = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left   = -220.0
	panel.offset_top    = -170.0
	panel.offset_right  = 220.0
	panel.offset_bottom = 170.0
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text                 = "SONG COMPLETE" if won else "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.modulate = Color.GREEN if won else Color.RED
	vbox.add_child(title)

	var score_lbl := Label.new()
	score_lbl.text                 = "Score: %d" % score
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_font_size_override("font_size", 28)
	vbox.add_child(score_lbl)

	var funds_lbl := Label.new()
	funds_lbl.text                 = "Funds Earned: %d" % int(funds)
	funds_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	funds_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(funds_lbl)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var buttons_row := HBoxContainer.new()
	buttons_row.add_theme_constant_override("separation", 10)
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(buttons_row)

	var retry_button := Button.new()
	retry_button.text = "Retry"
	retry_button.custom_minimum_size = Vector2(120, 44)
	retry_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	)
	buttons_row.add_child(retry_button)

	var continue_button := Button.new()
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(120, 44)
	continue_button.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/music_select.tscn")
	)
	buttons_row.add_child(continue_button)
