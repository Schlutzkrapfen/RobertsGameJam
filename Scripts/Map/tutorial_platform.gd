extends Node3D
signal next_phase

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		emit_signal("next_phase")


func start():
	self.visible =true
