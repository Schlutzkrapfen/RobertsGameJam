extends Node3D
@export var attack_size:float = 4
@export var sphere_attack: PackedScene
@onready var area_3d: Area3D = $MeshInstance3D/Area3D
var time_tile_attack:float = 4.0
var time_for_attack:float = 0.2
var time_for_reset:float = 0.2

var nodes:Array[Node] 

var attack_height:float = 200


func _ready() -> void:
	$MeshInstance3D/Area3D/CollisionShape3D.shape.radius = attack_size
	var unique_mesh = $MeshInstance3D.mesh.duplicate()
	$MeshInstance3D.mesh = unique_mesh
#	var collision_shape = $MeshInstance3D/Area3D/CollisionShape3D.shape.duplicate()
	var start_height = $MeshInstance3D.mesh.height
	
	var tween = get_tree().create_tween()
	area_3d.body_entered.connect(_on_body_entered)
	area_3d.body_exited.connect(_on_body_exited)
	
	#tween2.tween_property(collision_shape, "radius", attack_size, time_tile_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(unique_mesh, "radius", attack_size, time_tile_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	make_damage()
	if not get_tree():
		return
	var tween2 = get_tree().create_tween()
	tween2.tween_property(unique_mesh, "height", attack_height, time_for_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween2.tween_property(unique_mesh, "height", start_height, time_for_reset).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween2.finished
	queue_free()


func make_damage():
	for thing in nodes:
		if thing.is_in_group("Player"):
			thing.player_hit(1,true)
			continue
		if thing.is_in_group("Enemie"):
			thing.queue_free()
			continue

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		nodes.append(body)
func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		nodes.erase(body)
