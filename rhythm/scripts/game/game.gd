extends Node2D

@onready var score_label:   Label   = $HUD/ScoreLabel
@onready var funds_label:   Label   = $HUD/FundsLabel
@onready var shields_label: Label   = $HUD/ShieldsLabel
@onready var timing_label:  Label   = $HUD/TimingLabel
@onready var pause_menu:    Control = $PauseMenu

const TIMING_DISPLAY_DURATION := 0.6

var _timing_timer: float   = 0.0
var _game_over_shown: bool = false


func _ready() -> void:
	GameManager.score_updated.connect(_on_score_updated)
	GameManager.funds_updated.connect(_on_funds_updated)
	GameManager.shields_updated.connect(_on_shields_updated)
	GameManager.game_over.connect(_on_game_over)
	GameManager.note_hit.connect(_on_note_hit)
	GameManager.start_game()
	_refresh_hud()


func _process(delta: float) -> void:
	if _timing_timer > 0.0:
		_timing_timer -= delta
		if _timing_timer <= 0.0:
			timing_label.text = ""


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not get_tree().paused and not _game_over_shown:
		pause_menu.show_menu()


func _refresh_hud() -> void:
	score_label.text   = "Score: 0"
	funds_label.text   = "Funds: 0.0"
	shields_label.text = "Shields: %d" % GameManager.shields


func _on_score_updated(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score


func _on_funds_updated(new_funds: float) -> void:
	funds_label.text = "Funds: %.1f" % new_funds


func _on_shields_updated(count: int) -> void:
	shields_label.text = "Shields: %d" % count


func _on_note_hit(timing: String) -> void:
	timing_label.text = timing
	_timing_timer = TIMING_DISPLAY_DURATION
	match timing:
		"Perfect": timing_label.modulate = Color.GOLD
		"Good":    timing_label.modulate = Color.GREEN
		"Bad":     timing_label.modulate = Color.ORANGE_RED
		"Miss":    timing_label.modulate = Color.RED


func _on_game_over(final_score: int, total_funds: float) -> void:
	_game_over_shown = true

	for note in get_tree().get_nodes_in_group("notes"):
		note.queue_free()

	if UserSession.is_logged_in:
		ApiClient.submit_score(UserSession.user_id, final_score, total_funds)

	_show_game_over_overlay(final_score, total_funds)


func _show_game_over_overlay(score: int, funds: float) -> void:
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
	title.text                 = "GAME OVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	title.modulate = Color.RED
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

	var btn := Button.new()
	btn.text = "Continue"
	btn.custom_minimum_size = Vector2(160, 44)
	btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(btn)
