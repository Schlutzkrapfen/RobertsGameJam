extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if GameManager.Difficulty == GameManager.DifficultyOptions.HARD:
		$MainMenu.text = "Make it Easier?"
	elif  GameManager.Difficulty == GameManager.DifficultyOptions.Tutorial:
		$MainMenu.text = "Are you Ready for the Game"
		$Restart.text = "Play again if something is unclear"
	else:
		$MainMenu.text = "Make it Harder"

func _on_quit_button_up() -> void:
	get_tree().quit()


func _on_restart_button_up() -> void:
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")


func _on_main_menu_button_up() -> void:
	get_tree().change_scene_to_file("res://Nodes/Levels/MainMenu.tscn")
