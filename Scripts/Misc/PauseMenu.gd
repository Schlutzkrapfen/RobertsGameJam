extends CanvasLayer

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume_button_pressed():
	get_tree().paused = false
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_quit_button_pressed():
	get_tree().quit()
