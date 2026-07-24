class_name Enemy
extends CharacterBody3D

const SPEED = 15.0
const JUMP_VELOCITY = 4.5

@export var target: Node3D  # assign the player (or any node) in the Inspector
@export var stop_distance: float = 0.5  # how close before it stops

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

	if distance > stop_distance:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		# Optional: make the enemy face the direction it's moving
		look_at(global_position + direction, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
