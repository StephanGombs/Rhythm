extends Control

const TRACKS := [
	{
		"title": "ILYBB",
		"path": "res://assets/music/Ailow, Dionysus - ILYBB [NCS Release].mp3",
	},
	{
		"title": "Your Burn",
		"path": "res://assets/music/vxcelm, ANIZYZ - Your Burn [NCS Release].mp3",
	},
	{
		"title": "Harinezumi",
		"path": "res://assets/music/waera - harinezumi [NCS Release].mp3",
	},
	{
		"title": "Mortals Funk Remix",
		"path": "res://assets/music/Warriyo, LXNGVX - Mortals Funk Remix [NCS Release].mp3",
	},
	{
		"title": "Montagem Toma",
		"path": "res://assets/music/X972, sk3tch01, MXZI - Montagem Toma [NCS Release].mp3",
	},
]

@onready var status_label: Label = $VBox/StatusLabel
@onready var selected_label: Label = $VBox/SelectedLabel
@onready var track_list: VBoxContainer = $VBox/TrackList
@onready var start_button: Button = $VBox/StartButton
@onready var back_button: Button = $VBox/BackButton

var _track_buttons: Array[Button] = []


func _ready() -> void:
	_build_track_buttons()
	if UserSession.selected_music_path.is_empty():
		UserSession.select_music(TRACKS[0]["title"], TRACKS[0]["path"])
	_refresh_selection()
	status_label.text = "Choose a song, then start the run."
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _build_track_buttons() -> void:
	for track in TRACKS:
		var button := Button.new()
		button.toggle_mode = true
		button.text = track["title"]
		button.custom_minimum_size = Vector2(0, 42)
		button.pressed.connect(_on_track_pressed.bind(track["title"], track["path"]))
		track_list.add_child(button)
		_track_buttons.append(button)


func _on_track_pressed(title: String, path: String) -> void:
	UserSession.select_music(title, path)
	_refresh_selection()


func _refresh_selection() -> void:
	selected_label.text = "Selected: %s" % UserSession.selected_music_title
	for button in _track_buttons:
		button.button_pressed = button.text == UserSession.selected_music_title


func _on_start_pressed() -> void:
	if not UserSession.is_logged_in:
		status_label.text = "Please log in first."
		return
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
