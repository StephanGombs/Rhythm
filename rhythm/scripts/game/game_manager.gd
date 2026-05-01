extends Node

signal score_updated(new_score: int)
signal funds_updated(new_funds: float)
signal shields_updated(count: int)
signal hearts_updated(count: int)
signal shield_state_updated(state: String)
signal game_finished(won: bool, final_score: int, total_funds: float)
signal note_hit(timing: String)

const PERFECT_WINDOW_MS := 50
const GOOD_WINDOW_MS    := 100
const BAD_WINDOW_MS     := 150
const MAX_HEARTS        := 3

var current_score: int  = 0
var funds_earned: float = 0.0
var shields: int        = 0
var hearts: int         = MAX_HEARTS
var shield_active: bool = false
var shield_broken: bool = false
var perfect_hits: int   = 0
var good_hits: int      = 0
var bad_hits: int       = 0
var misses: int         = 0
var combo: int          = 0
var is_playing: bool    = false


func start_game() -> void:
	current_score = 0
	funds_earned  = 0.0
	shields       = UserSession.shields_owned
	hearts        = MAX_HEARTS
	shield_active = false
	shield_broken = false
	perfect_hits  = 0
	good_hits     = 0
	bad_hits      = 0
	misses        = 0
	combo         = 0
	is_playing    = false
	emit_signal("shields_updated", shields)
	emit_signal("shield_state_updated", "empty")


func begin_play() -> void:
	is_playing = true


func activate_shield() -> bool:
	if shield_active or shield_broken:
		return false
	if shields <= 0:
		return false

	shields -= 1
	UserSession.shields_owned = shields
	emit_signal("shields_updated", shields)
	shield_active = true
	emit_signal("shield_state_updated", "filled")
	return true


func register_hit(offset_ms: float) -> void:
	var abs_offset := absf(offset_ms)
	var timing: String

	if abs_offset <= PERFECT_WINDOW_MS:
		timing = "Perfect"
		current_score += 100
		funds_earned  += 15.0
		combo         += 1
		perfect_hits  += 1
	elif abs_offset <= GOOD_WINDOW_MS:
		timing = "Good"
		current_score += 50
		funds_earned  += 10.0
		combo         += 1
		good_hits     += 1
	else:
		timing = "Bad"
		current_score += 10
		funds_earned  += 5.0
		combo          = 0
		bad_hits      += 1

	emit_signal("score_updated", current_score)
	emit_signal("funds_updated", funds_earned)
	emit_signal("note_hit", timing)


func register_miss() -> void:
	if not is_playing:
		return
	combo   = 0
	misses += 1
	emit_signal("note_hit", "Miss")

	if shield_active:
		shield_active = false
		shield_broken = true
		emit_signal("shield_state_updated", "broken")
		return

	hearts -= 1
	emit_signal("hearts_updated", hearts)
	if hearts <= 0:
		finish_game(false)


func finish_game(won: bool) -> void:
	is_playing = false
	emit_signal("game_finished", won, current_score, funds_earned)
