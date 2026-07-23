extends CharacterBody3D

const SHOOT_SHAKE_AMOUNT:float = 0.05
signal camera_shake(amount:float)

# stats
var curHp : int = 10
var maxHp : int = 10
var score : int = 0

# physics
var gravity : float = 12.0

# movement
@export_subgroup("Movement")
@export var moveSpeed : float = 5.0
@export var sprintSpeed : float = 12.0
var curSpeed : float = moveSpeed

# jump
@export_subgroup("Jump")
@export var jumpForce : float = 5.0
@export var curJumps = 2
@export var jumpBuffer : float = 0.05
var curJumpBuffered : float = jumpBuffer

# dash
@export_subgroup("Dash")
@export var dashBuffer : float = 0.05
var curDashBuffered : float = dashBuffer
@export var dashDuration : float = 0.2
@export var dashCooldown : float = 0.5
var curDashTimer : float = 0
var isDashing : bool = true

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
var isShooting : bool = false


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
	
	curDashBuffered -= delta
	if(Input.is_action_just_pressed("dash")):
		curDashBuffered = dashBuffer

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	# Handle Jump
	if curJumpBuffered >= 0 and curJumps > 0:
		curJumpBuffered = -1
		velocity.y = jumpForce
		curJumps -= 1
	
	# Handle Dashing
	curDashTimer -= delta
	if(curDashBuffered >= 0 and curDashTimer <= 0 and !isDashing):
		curDashTimer = dashDuration
		#Dash here
	
	# Handle Sprinting
	curSpeed = moveSpeed
	if(Input.is_action_pressed("sprint")):
		curSpeed = sprintSpeed
	
	# Handle Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * curSpeed
		velocity.z = direction.z * curSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, curSpeed)
		velocity.z = move_toward(velocity.z, 0, curSpeed)
	
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

func shootProjectile():
	var space_state = get_world_3d().direct_space_state
	
	var from = muzzle.global_position
	var to = from + -camera.global_transform.basis.z * 1000.0

	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result:
		# Damage the target
		
		spawn_tracer(from, result.position)
	else:
		spawn_tracer(from, to)
	
	camera_shake.emit(SHOOT_SHAKE_AMOUNT)
	await SlowMotion.slow_motion(5)

func spawn_tracer(from: Vector3, to: Vector3):
	if bullet == null:
		return
	
	var tracer = bullet.instantiate()
	get_tree().current_scene.add_child(tracer)
	tracer.initialize(from, to, tracerSpeed)
