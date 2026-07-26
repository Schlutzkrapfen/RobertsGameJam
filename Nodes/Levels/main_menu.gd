extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$NormalMode.button_down.connect(_on_normal_mode_button_down)
	$HardMode.button_down.connect(_on_hard_mode_button_down)
	$Quit.button_down.connect(_on_quit_button_down)
	pass # Replace with function body.


func _on_normal_mode_button_down() -> void:
	print("Yay")
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")
	GameManager.isHardMode = false


func _on_hard_mode_button_down() -> void:
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")
	GameManager.isHardMode = true


func _on_quit_button_down() -> void:
	get_tree().quit()
