class_name Enemy 
extends CharacterBody3D

const SPEED = 15.0
const JUMP_VELOCITY = 4.5

# NEW: Replaced fixed radius with a minimum and maximum range
@export var min_explosion_radius: float = 3.0
@export var max_explosion_radius: float = 6.0

@export var explosion: PackedScene
@export var time_tile_attack: float = 2.0  

@export var explosion_appear_time: float = 0.2
@export var explosion_stay_time: float = 0.5
@export var explosion_collapse_time: float = 0.3

@export var attack_damage: int = 1
@export var attack_jump_up: bool = false

@export var target: Node3D  
@export var stop_distance: float = 0.5 
@export var hp: int = 1
@export var fly_to_player: bool = false 

var stop_movment: bool = false 

func _physics_process(delta: float) -> void:
	if not fly_to_player and not is_on_floor():
		velocity += get_gravity() * delta
		
	if target:
		move_to_point(target.global_position, delta)
		
	move_and_slide()

func move_to_point(point: Vector3, _delta: float) -> void:
	var direction := (point - global_position)
	
	if not fly_to_player:
		direction.y = 0  
		
	var distance := direction.length()

	if distance > stop_distance and not stop_movment:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		if fly_to_player:
			velocity.y = direction.y * SPEED
			
		if direction.length_squared() > 0.001:
			var look_target = global_position + direction
			var up_vector = Vector3.UP if abs(direction.y) < 0.99 else Vector3.FORWARD
			look_at(look_target, up_vector)
	else:
		if stop_movment == false:
			spawn_attack()
		stop_movment = true
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if fly_to_player:
			velocity.y = move_toward(velocity.y, 0, SPEED)
		
func spawn_attack():
	var mesh_instance = $CollisionShape3D/MeshInstance3D
	var mesh_node = $Skeleton3D/Loon_Ghost
	
	var material: Material = null
	if mesh_node and mesh_node.get_active_material(0):
		material = mesh_node.get_active_material(0).duplicate()
		mesh_node.set_surface_override_material(0, material)
		
	var height = 0.0
	if mesh_instance and mesh_instance.mesh:
		height = mesh_instance.mesh.height / 2.0
		
	if not is_inside_tree() or is_queued_for_deletion():
		return
		
	if not explosion:
		push_error("Explosion PackedScene is missing!")
		return
	
	# Instantiate the attack and add it to the parent
	var attack = explosion.instantiate()
	attack.global_position = Vector3(global_position.x, global_position.y - height, global_position.z)
	get_parent().add_child(attack)
	
	if not attack.is_inside_tree():
		return 
		
	# Get explosion nodes
	var ghost = attack.get_node_or_null("Explosion_Ghost")
	var lava_ball = attack.get_node_or_null("LavaBall")
	var area = attack.get_node_or_null("LavaBall/Area3D")
	var collision = attack.get_node_or_null("LavaBall/Area3D/CollisionShape3D")
	var audio = attack.get_node_or_null("AudioStreamPlayer3D")
	
	# Connect the Area3D signal dynamically to handle player collision.
	if area:
		var dmg = attack_damage
		var jump = attack_jump_up
		area.body_entered.connect(func(body: Node):
			if body.has_method("player_hit"):
				body.player_hit(dmg, jump)
		)
	
	# 1. Setup the initial state
	if ghost:
		ghost.scale = Vector3.ZERO
		ghost.visible = true
	if lava_ball:
		lava_ball.scale = Vector3.ZERO
		lava_ball.visible = false
	if collision:
		collision.set_deferred("disabled", true) 
		
	if has_node("charge"):
		$charge.play()
		
	# 2. Tween the enemy color red
	var enemy_tween: Tween = create_tween()
	if material:
		var target_color = Color(1.0, 0.0, 0.0, 1.0)
		enemy_tween.tween_property(material, "albedo_color", target_color, time_tile_attack)
		
	# 3. Tween the attack sequence attached to the attack node
	var attack_tween: Tween = attack.create_tween()
	
	# NEW: Calculate the random radius for this specific attack
	var actual_radius = randf_range(min_explosion_radius, max_explosion_radius)
	var target_scale = Vector3(actual_radius, actual_radius, actual_radius)
	
	# Phase A: Ghost expanding
	if ghost:
		attack_tween.tween_property(ghost, "scale", target_scale, time_tile_attack).set_trans(Tween.TRANS_SINE)
	else:
		attack_tween.tween_interval(time_tile_attack)
		
	# Phase B: Swap to LavaBall and trigger Damage
	attack_tween.tween_callback(func():
		if ghost: ghost.visible = false
		if lava_ball: lava_ball.visible = true
		if collision: collision.set_deferred("disabled", false) 
		if audio: audio.play()
	)
	
	# Phase C: LavaBall Appears (grows rapidly)
	if lava_ball:
		attack_tween.tween_property(lava_ball, "scale", target_scale, explosion_appear_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	else:
		attack_tween.tween_interval(explosion_appear_time)
		
	# Phase D: THE PEAK (Destroy the enemy here)
	attack_tween.tween_callback(func():
		if is_instance_valid(self):
			queue_free()
	)
	
	# Phase E: LavaBall Stays at full size
	attack_tween.tween_interval(explosion_stay_time)
	
	# Phase F: LavaBall Collapses
	attack_tween.tween_callback(func():
		if is_instance_valid(collision): 
			collision.set_deferred("disabled", true) # Stop damaging as it shrinks
	)
	
	if lava_ball:
		attack_tween.tween_property(lava_ball, "scale", Vector3.ZERO, explosion_collapse_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	else:
		attack_tween.tween_interval(explosion_collapse_time)
		
	# Phase G: Cleanup the attack node
	attack_tween.tween_callback(func():
		if is_instance_valid(attack):
			attack.queue_free()
	)

func take_damage(damage: int):
	hp -= damage
	if hp <= 0:
		if has_node("Death small Sound") and $"Death small Sound".playing:
			return
		if has_node("Death small Sound"):
			$"Death small Sound".play()
			await $"Death small Sound".finished
		queue_free()
