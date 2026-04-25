extends Node2D

const HIT_RADIUS := 80.0

var _pending_notes: Array = []


func _input(event: InputEvent) -> void:
	if not GameManager.is_playing:
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_check_hit(0)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_check_hit(1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_check_hit(2)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_check_hit(3)


func _check_hit(direction: int) -> void:
	var center = get_viewport_rect().size / 2
	var notes = get_tree().get_nodes_in_group("notes")
	var closest: Node2D = null
	var closest_dist: float = HIT_RADIUS

	for note in notes:
		if note.direction != direction:
			continue
		var dist = note.global_position.distance_to(center)
		if dist < closest_dist:
			closest_dist = dist
			closest = note

	if closest:
		var offset = closest_dist / closest.speed * 1000.0
		GameManager.register_hit(offset)
		closest.queue_free()
	else:
		GameManager.register_miss()
