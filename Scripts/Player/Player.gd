extends CharacterBody3D

var curJumps = 2

const SPEED:float = 5.0
const JUMP_VELOCITY:float = 4.5
const SHOOT_SHAKE_AMOUNT:float = 0.01
signal camera_shake(amount:float)


# stats
var curHp : int = 10
var maxHp : int = 10

var score : int = 0

# physics
var moveSpeed : float = 5.0
var jumpForce : float = 5.0
var gravity : float = 12.0

# cam look
var minLookAngle : float = -90.0
var maxLookAngle : float = 90.0
var lookSensitivity : float = 0.5

# vectors
var vel : Vector3 = Vector3()
var mouseDelta : Vector2 = Vector2()

#Normal Weapon
@export_category("Weapon")
@export var bullet: PackedScene
@export var muzzle : Node3D 
@export var bulletsPerBurst : int = 3
@export var burstSpeed : float = 0.05
@export var burstCooldown : float = 0.5
@export var tracerSpeed : float = 0.1
var curShootTimer : float = 0
var curBurstCountdown : int = bulletsPerBurst - 1

#inputs
@export_category("Inputs")
var isShooting : bool = false
@export var jumpBuffer : float = 0.05
var curJumpBuffered : float = jumpBuffer

# player components
@onready var camera: Camera3D = get_node("Camera3D")

func _process(delta):
	controll_camera(delta)
	if(isShooting):
		shoot(delta)
	
	curJumpBuffered -= delta
	if(Input.is_action_just_pressed("jump")):
		curJumpBuffered = jumpBuffer
	
	if(is_on_floor()):
		curJumps = 2

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Handle jump.
	if curJumpBuffered >= 0 and curJumps > 0:
		curJumpBuffered = -1
		velocity.y = JUMP_VELOCITY
		curJumps -= 1

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()
	
func _input(event):
	if event is InputEventMouseMotion:
		mouseDelta = event.relative
	if event.is_action_pressed("shoot"):
		isShooting = true
	if event.is_action_released("shoot"):
		isShooting = false
		curShootTimer = 0
		curBurstCountdown = bulletsPerBurst - 1

func controll_camera(delta:float):
	# rotate camera along X axis
	camera.rotation_degrees -= Vector3(rad_to_deg(mouseDelta.y), 0, 0) * lookSensitivity * delta
	# clamp the vertical camera rotation
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, minLookAngle, maxLookAngle)
	
	# rotate player along Y axis
	rotation_degrees -= Vector3(0, rad_to_deg(mouseDelta.x), 0) * lookSensitivity * delta
	
	# reset the mouse delta vector
	mouseDelta = Vector2()

func shoot(delta):
	curShootTimer -= delta
	
	if(curShootTimer <= 0):
		
		shootProjectile()
		
		if(curBurstCountdown > 0):
			curBurstCountdown = curBurstCountdown - 1
			curShootTimer = burstSpeed
		else:
			curBurstCountdown = bulletsPerBurst - 1
			curShootTimer = burstCooldown
	
	camera_shake.emit(SHOOT_SHAKE_AMOUNT)
	# await Slowmo.slow_motion(1)
	

func shootProjectile():
	var space_state = get_world_3d().direct_space_state
	
	var from = muzzle.global_position
	var to = from + -camera.global_transform.basis.z * 1000.0

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		# Damage the target
		# if result.collider.has_method("take_damage"):
		# 	result.collider.take_damage(20)
		
		spawn_tracer(from, result.position)
	else:
		spawn_tracer(from, to)

func spawn_tracer(from: Vector3, to: Vector3):
	if bullet == null:
		return
	print("Bullet")
	var tracer = bullet.instantiate()
	get_tree().current_scene.add_child(tracer)
	tracer.initialize(from, to, tracerSpeed)
