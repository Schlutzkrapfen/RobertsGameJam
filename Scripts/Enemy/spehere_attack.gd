extends Node3D
@export var attack_size: float = 4.0      # target scale for x/z (cone base size)
@export var attack_height: float = 200.0  # target scale for y (spike height)
@export var sphere_attack: PackedScene
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $MeshInstance3D/Area3D/CollisionShape3D
@onready var area_3d: Area3D = $MeshInstance3D/Area3D
@onready var ghost: MeshInstance3D = $Ghost
@export var time_chargeUp_attack: float = 4.0
@export var time_damage_attack: float = 0.2
@export var time_reset_attack: float = 0.2

# --- Ghost color warning ---
@export var color_warning_time: float = 1.0     # how long before the attack lands the ghost turns red
@export var warning_color: Color = Color(1.0, 0.0, 0.0, 1.0)

# --- Ghost alpha "pop" ---
@export var min_alpha_idle: float = 0.1    # low & easy to miss for most of the charge-up
@export var min_alpha_peak: float = 0.95   # snaps up to near-solid right before the spike erupts
@export var alpha_pop_time: float = 0.4    # how long before the attack lands the pop happens

var base_scale_xz: float
var base_scale_y: float
var is_attacking: bool = false
var hit_targets: Array[Node] = []

var ghost_material: ShaderMaterial
var original_ghost_color: Color = Color.WHITE

func _ready() -> void:
	base_scale_xz = mesh.scale.x
	base_scale_y = mesh.scale.y
	
	# Collapse the footprint to (near) zero
	mesh.scale.x = 0.01
	mesh.scale.z = 0.01
	collision.set_deferred("disabled", true)
	
	ghost.scale.x = attack_size
	ghost.scale.y = attack_height
	ghost.scale.z = attack_size
	area_3d.body_entered.connect(_on_body_entered)

	ghost_material = _get_ghost_material()
	if ghost_material:
		original_ghost_color = ghost_material.get_shader_parameter("ghost_color")
		ghost_material.set_shader_parameter("min_alpha", min_alpha_idle)

	var tween := get_tree().create_tween()
	tween.tween_property(mesh, "scale:x", attack_size, time_chargeUp_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(mesh, "scale:z", attack_size, time_chargeUp_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Kick off the red warning fade so it finishes right as the charge-up ends.
	_start_ghost_warning()

	await tween.finished
	if not get_tree():
		return
	$AudioStreamPlayer3D.play()
	
	is_attacking = true
	collision.set_deferred("disabled", false)
	ghost.visible = false
	
	var tween2 := get_tree().create_tween()
	tween2.tween_property(mesh, "scale:y", attack_height, time_damage_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween2.tween_property(mesh, "scale:y", base_scale_y, time_reset_attack).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
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


func _get_ghost_material() -> ShaderMaterial:
	var mat: ShaderMaterial = null
	var source: String = ""

	if ghost.material_override is ShaderMaterial:
		mat = ghost.material_override
		source = "material_override"
	else:
		var override := ghost.get_surface_override_material(0)
		if override is ShaderMaterial:
			mat = override
			source = "surface_override"
		elif ghost.mesh and ghost.mesh.surface_get_material(0) is ShaderMaterial:
			mat = ghost.mesh.surface_get_material(0)
			source = "mesh_surface"

	if mat == null:
		return null

	# IMPORTANT: duplicate so this pillar gets its own material instance.
	# Without this, every spawned attack shares (and permanently mutates)
	# the same ShaderMaterial resource, so one pillar turning red turns
	# them all red, and it never "resets" because it's the same object.
	var unique_mat := mat.duplicate() as ShaderMaterial

	match source:
		"material_override":
			ghost.material_override = unique_mat
		"surface_override", "mesh_surface":
			ghost.set_surface_override_material(0, unique_mat)

	return unique_mat


func _start_ghost_warning() -> void:
	if ghost_material == null:
		return

	var delay: float = max(time_chargeUp_attack - color_warning_time, 0.0)
	var fade_time: float = min(color_warning_time, time_chargeUp_attack)

	var color_tween := get_tree().create_tween()
	color_tween.bind_node(self) # stop safely if this node is freed early
	color_tween.tween_interval(delay)
	color_tween.tween_method(_set_ghost_shader_color, original_ghost_color, warning_color, fade_time) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)

	# Alpha pop: stays low/subtle right up until the final moments, then
	# snaps up hard so the red becomes suddenly very visible.
	var alpha_delay: float = max(time_chargeUp_attack - alpha_pop_time, 0.0)
	var alpha_duration: float = min(alpha_pop_time, time_chargeUp_attack)

	var alpha_tween := get_tree().create_tween()
	alpha_tween.bind_node(self)
	alpha_tween.tween_interval(alpha_delay)
	alpha_tween.tween_method(_set_ghost_min_alpha, min_alpha_idle, min_alpha_peak, alpha_duration) \
		.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_EXPO)


func _set_ghost_shader_color(c: Color) -> void:
	if ghost_material:
		ghost_material.set_shader_parameter("ghost_color", c)


func _set_ghost_min_alpha(value: float) -> void:
	if ghost_material:
		ghost_material.set_shader_parameter("min_alpha", value)
