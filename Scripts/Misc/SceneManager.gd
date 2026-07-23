extends Node

@export var pauseMenu: CanvasLayer

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	var paused = !get_tree().paused
	get_tree().paused = paused

	pauseMenu.visible = paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
