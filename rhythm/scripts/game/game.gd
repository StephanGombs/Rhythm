extends Node2D

@onready var score_label: Label = $HUD/ScoreLabel
@onready var funds_label: Label = $HUD/FundsLabel
@onready var shields_label: Label = $HUD/ShieldsLabel
@onready var timing_label: Label = $HUD/TimingLabel
@onready var pause_menu: Control = $PauseMenu

var _timing_timer: float = 0.0
const TIMING_DISPLAY_DURATION := 0.6


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
	if event.is_action_pressed("ui_cancel") and not get_tree().paused:
		pause_menu.show_menu()


func _refresh_hud() -> void:
	score_label.text = "Score: 0"
	funds_label.text = "Funds: 0.0"
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
	if UserSession.is_logged_in:
		ApiClient.request_completed.connect(_on_score_submitted, CONNECT_ONE_SHOT)
		ApiClient.submit_score(UserSession.user_id, final_score, total_funds)
	else:
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_score_submitted(_code: int, _body: Dictionary) -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
