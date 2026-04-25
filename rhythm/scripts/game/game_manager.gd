extends Node

signal score_updated(new_score: int)
signal funds_updated(new_funds: float)
signal shields_updated(count: int)
signal game_over(final_score: int, total_funds: float)
signal note_hit(timing: String)

const PERFECT_WINDOW_MS := 50
const GOOD_WINDOW_MS := 100
const BAD_WINDOW_MS := 150

var current_score: int = 0
var funds_earned: float = 0.0
var shields: int = 0
var perfect_hits: int = 0
var good_hits: int = 0
var bad_hits: int = 0
var misses: int = 0
var combo: int = 0
var is_playing: bool = false


func start_game() -> void:
	current_score = 0
	funds_earned = 0.0
	shields = UserSession.shields_owned
	perfect_hits = 0
	good_hits = 0
	bad_hits = 0
	misses = 0
	combo = 0
	is_playing = true


func register_hit(offset_ms: float) -> String:
	var abs_offset = abs(offset_ms)
	var timing: String

	if abs_offset <= PERFECT_WINDOW_MS:
		timing = "Perfect"
		current_score += 100
		funds_earned += 15
		combo += 1
		perfect_hits += 1
	elif abs_offset <= GOOD_WINDOW_MS:
		timing = "Good"
		current_score += 50
		funds_earned += 10
		combo += 1
		good_hits += 1
	elif abs_offset <= BAD_WINDOW_MS:
		timing = "Bad"
		current_score += 10
		funds_earned += 5
		combo = 0
		bad_hits += 1
	else:
		timing = "Miss"
		combo = 0
		_handle_miss()

	emit_signal("score_updated", current_score)
	emit_signal("funds_updated", funds_earned)
	emit_signal("note_hit", timing)
	return timing


func register_miss() -> void:
	combo = 0
	_handle_miss()
	emit_signal("note_hit", "Miss")


func _handle_miss() -> void:
	misses += 1
	if shields > 0:
		shields -= 1
		emit_signal("shields_updated", shields)
	else:
		_end_game()


func _end_game() -> void:
	is_playing = false
	emit_signal("game_over", current_score, funds_earned)
