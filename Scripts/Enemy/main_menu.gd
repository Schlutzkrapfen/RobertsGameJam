extends Control

@onready var SFX_BUS_ID:int = AudioServer.get_bus_index("SFX")
@onready var MUSIC_BUS_ID:int = AudioServer.get_bus_index("Music")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Settings/VBoxContainer/Music/Music.value =  db_to_linear(0)
	$Settings/VBoxContainer/Sound/Sound.value =  db_to_linear(0)


func _on_easy_mode_button_down() -> void:
	GameManager.Difficulty = GameManager.DifficultyOptions.EASY
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")
	

func _on_normal_mode_button_down() -> void:
	GameManager.Difficulty = GameManager.DifficultyOptions.NORMAL
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")
	


func _on_hard_mode_button_down() -> void:
	GameManager.Difficulty = GameManager.DifficultyOptions.HARD
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")
	


func _on_quit_button_down() -> void:
	get_tree().quit()


func _on_settings_button_up() -> void:
	$Settings.visible = true
	

func _on_check_box_button_up() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_check_box_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else: 
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_h_slider_value_changed(value: float) -> void:
	GameManager.mouse_sensitivity = value

func _on_sound_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(SFX_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(SFX_BUS_ID, value < .05)

	


func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(MUSIC_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(MUSIC_BUS_ID, value < .05)
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and $Settings.visible:
		$Settings.visible = false

func _on_close_button_up() -> void:
	$Settings.visible = false


func _on_tutorial_button_button_down() -> void:
	GameManager.Difficulty = GameManager.DifficultyOptions.Tutorial
	get_tree().change_scene_to_file("res://Nodes/Levels/tutorial.tscn")
	
