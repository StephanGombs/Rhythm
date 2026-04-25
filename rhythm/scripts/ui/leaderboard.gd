extends Control

@onready var entries_container: VBoxContainer = $ScrollContainer/EntriesContainer
@onready var status_label: Label = $StatusLabel


func _ready() -> void:
	ApiClient.request_completed.connect(_on_api_response)
	ApiClient.get_leaderboard(10)
	status_label.text = "Loading..."


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_api_response(response_code: int, body: Variant) -> void:
	status_label.hide()
	if response_code != 200:
		status_label.show()
		status_label.text = "Failed to load leaderboard."
		return

	for child in entries_container.get_children():
		child.queue_free()

	if body is Array:
		for i in body.size():
			var entry = body[i]
			var label = Label.new()
			label.text = "%d. %s — %d" % [i + 1, entry.get("username", "?"), entry.get("score", 0)]
			entries_container.add_child(label)
