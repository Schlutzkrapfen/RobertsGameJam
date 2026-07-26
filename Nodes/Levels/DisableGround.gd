extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(GameManager.Difficulty == GameManager.DifficultyOptions.HARD):
		$Ground.visible = false
		$StaticBody3D.collision_layer = 4
