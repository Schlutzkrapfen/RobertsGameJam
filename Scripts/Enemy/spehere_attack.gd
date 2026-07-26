extends Node3D

@export var attack_size: float = 4.0      # target scale for x/z (cone base size)
@export var attack_height: float = 200.0  # target scale for y (spike height)
@export var sphere_attack: PackedScene

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var area_3d: Area3D = $MeshInstance3D/Area3D

var time_tile_attack: float = 4.0
var time_for_attack: float = 0.2
var time_for_reset: float = 0.2

var nodes: Array[Node]

var base_scale_xz: float
var base_scale_y: float



func _ready() -> void:
	base_scale_xz = mesh_instance.scale.x
	base_scale_y = mesh_instance.scale.y

	# Collapse the footprint to (near) zero so the cone grows in from nothing.
	# (Using a tiny epsilon instead of exactly 0 avoids a zero-size collision
	# shape warning from the physics server.)
	mesh_instance.scale.x = 0.01
	mesh_instance.scale.z = 0.01

	area_3d.body_entered.connect(_on_body_entered)
	area_3d.body_exited.connect(_on_body_exited)

	# Grow the cone's base (x/z). Because CollisionShape3D is nested under
	# MeshInstance3D, it inherits this scale too - mesh and collider grow
	# together automatically.
	var tween := get_tree().create_tween()
	tween.tween_property(mesh_instance, "scale:x", attack_size, time_tile_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(mesh_instance, "scale:z", attack_size, time_tile_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished

	$AudioStreamPlayer3D.play()
	make_damage()
	if not get_tree():
		return

	# Spike the cone upward (y), then settle back to its authored height.
	# The collider spikes with it, since it inherits scale.y as well.
	var tween2 := get_tree().create_tween()
	tween2.tween_property(mesh_instance, "scale:y", attack_height, time_for_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween2.tween_property(mesh_instance, "scale:y", base_scale_y, time_for_reset).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween2.finished
	queue_free()


func make_damage() -> void:
	for thing in nodes:
		if thing.is_in_group("Player"):
			thing.player_hit(1, true)
			continue
		if thing.is_in_group("Enemie"):
			thing.take_damage(100)
			continue


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		nodes.append(body)


func _on_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		nodes.erase(body)
