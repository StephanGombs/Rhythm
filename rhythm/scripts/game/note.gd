extends Area2D

enum Direction { UP, DOWN, LEFT, RIGHT }

var direction: Direction = Direction.UP
var speed: float = 300.0
var spawn_time_ms: int = 0

@onready var sprite: ColorRect = $ColorRect


func _ready() -> void:
	add_to_group("notes")
	spawn_time_ms = Time.get_ticks_msec()
	_set_color()


func _process(delta: float) -> void:
	var target = get_viewport_rect().size / 2
	var move_dir = (target - global_position).normalized()
	global_position += move_dir * speed * delta


func _set_color() -> void:
	if not sprite:
		return
	match direction:
		Direction.UP:    sprite.color = Color.RED
		Direction.DOWN:  sprite.color = Color.BLUE
		Direction.LEFT:  sprite.color = Color.GREEN
		Direction.RIGHT: sprite.color = Color.YELLOW


func get_timing_offset_ms() -> float:
	return Time.get_ticks_msec() - spawn_time_ms
