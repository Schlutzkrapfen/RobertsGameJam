extends Node3D
@export var attack_size:float = 4
@export var sphere_attack: PackedScene

func _ready() -> void:
	
	var unique_mesh = $MeshInstance3D.mesh.duplicate()
	$MeshInstance3D.mesh = unique_mesh

	var tween = get_tree().create_tween()
	tween.tween_property(unique_mesh, "radius", attack_size, 4.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(unique_mesh, "height", 200, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(unique_mesh, "height", 0.01, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	delete()

func delete():
	visible = false
	queue_free()
	
