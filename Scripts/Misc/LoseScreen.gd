extends Control

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if GameManager.Difficulty == GameManager.DifficultyOptions.EASY:
		$MainMenu.text = "Maybe the Tutorial?"
	elif GameManager.Difficulty == GameManager.DifficultyOptions.Tutorial:
		$MainMenu.visible = false
		$Restart.text = "Really in the tutorial"
	else:
		$MainMenu.text = "Make it Easier?"
		
	

func _on_quit_button_up() -> void:
	get_tree().quit()


func _on_restart_button_up() -> void:
	if GameManager.Difficulty == GameManager.DifficultyOptions.Tutorial:
		get_tree().change_scene_to_file("res://Nodes/Levels/tutorial.tscn")
		return
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")


func _on_main_menu_button_up() -> void:
	get_tree().change_scene_to_file("res://Nodes/Levels/MainMenu.tscn")
