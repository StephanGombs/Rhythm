extends Control

@onready var username_input: LineEdit = $VBox/UsernameInput
@onready var password_input: LineEdit = $VBox/PasswordInput
@onready var status_label: Label = $VBox/StatusLabel


func _ready() -> void:
	ApiClient.request_completed.connect(_on_api_response)


func _on_start_pressed() -> void:
	if not UserSession.is_logged_in:
		status_label.text = "Please log in first."
		return
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_login_pressed() -> void:
	ApiClient.login(username_input.text.strip_edges(), password_input.text)


func _on_register_pressed() -> void:
	ApiClient.register(username_input.text.strip_edges(), password_input.text)


func _on_leaderboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/leaderboard.tscn")


func _on_shop_pressed() -> void:
	if not UserSession.is_logged_in:
		status_label.text = "Please log in first."
		return
	get_tree().change_scene_to_file("res://scenes/shop.tscn")


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/quit_dialog.tscn")


func _on_api_response(response_code: int, body: Dictionary) -> void:
	if response_code == 200 or response_code == 201:
		UserSession.login(body)
		status_label.text = "Logged in as " + UserSession.username
	else:
		status_label.text = body.get("detail", "Error " + str(response_code))
