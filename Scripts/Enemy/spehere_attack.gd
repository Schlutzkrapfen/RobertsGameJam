extends Node3D

@export var attack_size: float = 4.0      # target scale for x/z (cone base size)
@export var attack_height: float = 200.0  # target scale for y (spike height)
@export var sphere_attack: PackedScene

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $MeshInstance3D/Area3D/CollisionShape3D
@onready var area_3d: Area3D = $MeshInstance3D/Area3D
@onready var ghost: MeshInstance3D = $Ghost

var time_tile_attack: float = 4.0
var time_for_attack: float = 0.2
var time_for_reset: float = 0.2

var base_scale_xz: float
var base_scale_y: float

var is_attacking: bool = false
var hit_targets: Array[Node] = []

func _ready() -> void:
	base_scale_xz = mesh.scale.x
	base_scale_y = mesh.scale.y
	
	# Collapse the footprint to (near) zero
	mesh.scale.x = 0.01
	mesh.scale.z = 0.01
	
	collision.scale.x = attack_size
	collision.scale.y = attack_height
	collision.scale.z = attack_size
	
	collision.set_deferred("disabled", true)
	
	ghost.scale.x = attack_size
	ghost.scale.y = attack_height
	ghost.scale.z = attack_size

	area_3d.body_entered.connect(_on_body_entered)

	var tween := get_tree().create_tween()
	tween.tween_property(mesh, "scale:x", attack_size, time_tile_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(mesh, "scale:z", attack_size, time_tile_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	if not get_tree():
		return

	$AudioStreamPlayer3D.play()
	
	is_attacking = true
	collision.set_deferred("disabled", false)
	
	var tween2 := get_tree().create_tween()
	tween2.tween_property(mesh, "scale:y", attack_height, time_for_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween2.tween_property(mesh, "scale:y", base_scale_y, time_for_reset).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween2.finished
	
	queue_free()

func _on_body_entered(body: Node3D) -> void:
	if not is_attacking or body in hit_targets:
		return
		
	if body.is_in_group("Player"):
		if body.has_method("player_hit"):
			body.player_hit(1, true)
			hit_targets.append(body)
			
	elif body.is_in_group("Enemie"):
		if body.has_method("take_damage"):
			body.take_damage(100)
			hit_targets.append(body)
