extends Node3D
@export var attack_size:float = 4
@export var sphere_attack: PackedScene
var time_tile_attack:float = 4.0
var time_for_attack:float = 0.2
var time_for_reset:float = 0.2

var attack_height:float = 200

func _ready() -> void:
	
	var unique_mesh = $MeshInstance3D.mesh.duplicate()
	$MeshInstance3D.mesh = unique_mesh
	var cur_height = $MeshInstance3D.mesh.height
	var tween = get_tree().create_tween()
	tween.tween_property(unique_mesh, "radius", attack_size, time_tile_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(unique_mesh, "height", attack_height, time_for_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(unique_mesh, "height", cur_height, time_for_reset).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	delete()

func delete():
	visible = false
	queue_free()
	
