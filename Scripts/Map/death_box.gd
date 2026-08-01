extends Area3D
@export var respawn:Node 

func _on_body_entered(body: Node3D) -> void:
	if GameManager.Difficulty == GameManager.DifficultyOptions.Tutorial:
		var second:bool = false
		var respawn_points  = respawn.get_children()
		if body.is_in_group("Player"):
			respawn_points.reverse()
			for point:Node3D in respawn_points:
				if point.visible:
					body.global_position = Vector3 (point.global_position.x+3,point.global_position.y+3,point.global_position.z+3)
					if point == respawn_points[respawn_points.size()-1] or second:
						return
					second = true
	if body.is_in_group("Player"):
		get_tree().change_scene_to_file("res://Nodes/Levels/LoseScreen.tscn")
	body.queue_free()
