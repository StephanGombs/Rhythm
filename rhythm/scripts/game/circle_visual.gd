extends Node2D

const RADIUS := 80.0
const SECTOR_COLORS = [
	Color(1, 0.2, 0.2, 0.5),   # UP    — red
	Color(0.2, 0.4, 1, 0.5),   # DOWN  — blue
	Color(0.2, 0.9, 0.2, 0.5), # LEFT  — green
	Color(1, 0.9, 0.1, 0.5),   # RIGHT — yellow
]


func _ready() -> void:
	position = get_viewport_rect().size / 2


func _draw() -> void:
	var segments := 32
	# Draw 4 quarter-circle sectors
	for sector in 4:
		var start_angle := sector * PI / 2.0 - PI / 4.0
		var points := PackedVector2Array()
		points.append(Vector2.ZERO)
		for i in (segments / 4) + 1:
			var angle := start_angle + i * (PI / 2.0) / (segments / 4)
			points.append(Vector2(cos(angle), sin(angle)) * RADIUS)
		draw_colored_polygon(points, SECTOR_COLORS[sector])

	# White ring border
	draw_arc(Vector2.ZERO, RADIUS, 0, TAU, 64, Color.WHITE, 2.0)
	# Cross dividers
	draw_line(Vector2(0, -RADIUS), Vector2(0, RADIUS), Color.WHITE, 1.5)
	draw_line(Vector2(-RADIUS, 0), Vector2(RADIUS, 0), Color.WHITE, 1.5)
