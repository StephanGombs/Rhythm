extends Node2D

const HIT_RADIUS := 300.0


func _process(_delta: float) -> void:
	if not GameManager.is_playing:
		return
	# Auto-miss notes that sat at center past the bad timing window.
	for node in get_tree().get_nodes_in_group("notes"):
		var note := node as Note
		if note == null or note._expired:
			continue
		if note.get_timing_offset_ms() > GameManager.BAD_WINDOW_MS:
			note._expired = true
			GameManager.register_miss()
			note.queue_free()


func _input(event: InputEvent) -> void:
	if not GameManager.is_playing:
		return
	if event.is_action_pressed("move_up"):
		_try_hit(0)
	elif event.is_action_pressed("move_down"):
		_try_hit(1)
	elif event.is_action_pressed("move_left"):
		_try_hit(2)
	elif event.is_action_pressed("move_right"):
		_try_hit(3)


func _try_hit(direction: int) -> void:
	var center := get_viewport_rect().size / 2
	var best: Note = null
	var best_dist := HIT_RADIUS + 1.0

	for node in get_tree().get_nodes_in_group("notes"):
		var note := node as Note
		if note == null or note._expired or note.direction != direction:
			continue
		var dist := note.global_position.distance_to(center)
		if dist < best_dist:
			best_dist = dist
			best = note

	if best == null:
		return  # No note of this direction nearby — no penalty.

	var offset := best.get_timing_offset_ms()
	if abs(offset) > GameManager.BAD_WINDOW_MS:
		return  # Note approaching but outside timing window — ignore press.

	best._expired = true
	GameManager.register_hit(float(offset))
	best.queue_free()
