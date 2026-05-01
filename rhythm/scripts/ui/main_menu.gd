extends Control

func _on_start_pressed() -> void:
	if not UserSession.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/login.tscn")
		return
	get_tree().change_scene_to_file("res://scenes/music_select.tscn")


func _on_leaderboard_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/leaderboard.tscn")


func _on_shop_pressed() -> void:
	if not UserSession.is_logged_in:
		get_tree().change_scene_to_file("res://scenes/login.tscn")
		return
	get_tree().change_scene_to_file("res://scenes/shop.tscn")


func _on_logout_pressed() -> void:
	UserSession.logout()
	get_tree().change_scene_to_file("res://scenes/login.tscn")


func _on_quit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/quit_dialog.tscn")
