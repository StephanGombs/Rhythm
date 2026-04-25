extends Node2D

const NOTE_SCENE = preload("res://scenes/note.tscn")

@export var spawn_interval: float = 1.5
@export var note_speed: float = 300.0

var _timer: float = 0.0
var _directions = [0, 1, 2, 3]


func _process(delta: float) -> void:
	if not GameManager.is_playing:
		return
	_timer += delta
	if _timer >= spawn_interval:
		_timer = 0.0
		_spawn_note()


func _spawn_note() -> void:
	var note = NOTE_SCENE.instantiate()
	var dir = _directions[randi() % _directions.size()]
	note.direction = dir
	note.speed = note_speed
	note.global_position = _get_spawn_position(dir)
	get_tree().current_scene.add_child(note)


func _get_spawn_position(dir: int) -> Vector2:
	var vp = get_viewport_rect().size
	match dir:
		0: return Vector2(vp.x / 2, -50)        # UP — spawn at top
		1: return Vector2(vp.x / 2, vp.y + 50)  # DOWN — spawn at bottom
		2: return Vector2(-50, vp.y / 2)          # LEFT — spawn at left
		3: return Vector2(vp.x + 50, vp.y / 2)   # RIGHT — spawn at right
	return Vector2.ZERO
