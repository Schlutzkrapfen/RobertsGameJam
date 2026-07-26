extends Area3D









func _on_area_3d_body_entered(body: Node3D) -> void:
	$CPUParticles3D.emitting = true
	if body.is_in_group("Player") :
		body.attention()


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player") :
		body.no_attention()
