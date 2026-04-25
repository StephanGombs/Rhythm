extends Node

var user_id: String = ""
var username: String = ""
var account_funds: float = 0.0
var shields_owned: int = 0
var is_logged_in: bool = false


func login(data: Dictionary) -> void:
	user_id = data.get("id", "")
	username = data.get("username", "")
	account_funds = data.get("account_funds", 0.0)
	shields_owned = data.get("shields_owned", 0)
	is_logged_in = true


func logout() -> void:
	user_id = ""
	username = ""
	account_funds = 0.0
	shields_owned = 0
	is_logged_in = false


func update_from_response(data: Dictionary) -> void:
	account_funds = data.get("account_funds", account_funds)
	shields_owned = data.get("shields_owned", shields_owned)
