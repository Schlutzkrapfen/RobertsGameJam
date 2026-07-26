extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$NormalMode.button_down.connect(_on_normal_mode_button_down)
	$HardMode.button_down.connect(_on_hard_mode_button_down)
	$Quit.button_down.connect(_on_quit_button_down)
	pass # Replace with function body.


func _on_easy_mode_button_down() -> void:
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")
	GameManager.Difficulty = GameManager.DifficultyOptions.EASY

func _on_normal_mode_button_down() -> void:
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")
	GameManager.Difficulty = GameManager.DifficultyOptions.NORMAL


func _on_hard_mode_button_down() -> void:
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")
	GameManager.Difficulty = GameManager.DifficultyOptions.HARD


func _on_quit_button_down() -> void:
	get_tree().quit()


func _on_settings_button_up() -> void:
	$Settings/Popup.visible = true
	
