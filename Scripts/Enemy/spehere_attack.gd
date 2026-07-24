extends Node3D
@export var attack_size:float = 4

func _ready() -> void:
	var tween = get_tree().create_tween()
	tween.tween_property($MeshInstance3D.mesh, "radius", attack_size, 4.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property($MeshInstance3D.mesh, "height", 400, 0.2).set_trans(Tween.TRANS_BOUNCE)
	await tween.finished
	visible = false
