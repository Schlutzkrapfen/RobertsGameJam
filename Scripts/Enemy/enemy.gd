class_name Enemy 
extends CharacterBody3D

const SPEED = 15.0
const JUMP_VELOCITY = 4.5


@export var explosion_radius:float = 4
@export var sphere_attack:PackedScene
@export var time_tile_attack:float = 2

@export var target: Node3D  # assign the player (or any node) in the Inspector
@export var stop_distance: float = 0.5  # how close before it stops
@export var hp: int = 10

var stop_movment:bool = false 
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_to_point(target.global_position, delta)
	move_and_slide()

func move_to_point(point: Vector3, _delta: float) -> void:
	var direction := (point - global_position)
	direction.y = 0  # ignore height difference so it doesn't try to fly/dig
	var distance := direction.length()

	if distance > stop_distance && not stop_movment:
		
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		look_at(global_position + direction, Vector3.UP)
	else:
		if stop_movment == false:
			spawn_attack()
		stop_movment = true
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
	
func spawn_attack():
	var mesh_instance = $CollisionShape3D/MeshInstance3D
	if mesh_instance == null:
		return
	var height = mesh_instance.mesh.height /2
	if not is_inside_tree():
		return
	if self.is_queued_for_deletion():
		return
	var attack = sphere_attack.instantiate()
	get_parent().add_child(attack)
	if not attack.is_inside_tree():
		return 
	attack.global_position = Vector3(self.global_position.x,self.global_position.y-height,self.global_position.z)
	attack.attack_size = explosion_radius
	attack.time_tile_attack = time_tile_attack
	$charge.play()
	

func take_damage(damage: int):
	hp -= damage
	if(hp <= 0):
		$"Death small Sound".play()
		await $"Death small Sound".finished
		queue_free()
