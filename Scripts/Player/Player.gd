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
@export var hyperJumpForce : float = 15.0
@export var NumberOfJumps = 2
var curJumps = 0
@export var jumpBuffer : float = 0.05
var curJumpBuffered : float = jumpBuffer

# wall kick
@export_subgroup("Wall Kick")
@export var wallCheckDistance: float = 1.0
@export var wallKickForce: float = 8.0
@export var wallKickUpForce: float = 10.0
@export var wallRayCount: int = 16
@export_flags_3d_physics var wallCollisionMask: int = 1 << 1

# dash
@export_subgroup("Dash")
@export var dashBuffer : float = 0.05
var curDashBuffered : float = dashBuffer
@export var dashSpeed : float = 15
@export var dashDuration : float = 0.2
@export var dashCooldown : float = 0.5
@export var dashTransitionTimer : float = 0.1
@export var camDipYHeight : float = 0.5
@export var camDipTransitionStrength : float = 1
var curDashTimer : float = 0
var curDashTransitionTimer : float = 0
var curCamDipTransition : float = 0
var normalCamYHeight : float = 0
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
var camera : Camera3D
var standingCollider : CollisionShape3D
var standingMesh : MeshInstance3D
var slidingCollider : CollisionShape3D
var slidingMesh : MeshInstance3D

func _enter_tree() -> void:
	camera = get_node("Camera3D")
	normalCamYHeight = camera.transform.origin.y
	standingCollider = get_node("NormalCollider")
	standingMesh = get_node("NormalCollider/NormalMesh")
	slidingCollider = get_node("SlidingCollider")
	slidingMesh = get_node("SlidingCollider/SlidingMesh")

func _process(delta):
	controll_camera(delta)
	if(isShooting):
		shoot(delta)
	
	curJumpBuffered -= delta
	if(Input.is_action_just_pressed("jump")):
		curJumpBuffered = jumpBuffer
	

	
	curDashBuffered -= delta
	if(Input.is_action_just_pressed("dash")):
		curDashBuffered = dashBuffer

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if(is_on_floor()):
		curJumps = NumberOfJumps
	
	# Handle Speed
	curSpeed = moveSpeed
	
	# Handle Sprinting
	if(Input.is_action_pressed("sprint")):
		curSpeed = sprintSpeed
	
	# Handle Dashing
	curDashTimer -= delta
	if(curDashBuffered >= 0 and curDashTimer <= 0 and !isDashing):
		curDashBuffered = 0
		curDashTimer = dashDuration
		isDashing = true
		
		standingCollider.disabled = true
		standingMesh.visible = false
		slidingCollider.disabled = false
		slidingMesh.visible = true
	
	if(isDashing):
		curSpeed = dashSpeed
		#curCamDipTransition -= delta
	
	if(isDashing && curDashTimer < 0):
		isDashing = false
		curDashTransitionTimer = dashTransitionTimer
		
		standingCollider.disabled = false
		standingMesh.visible = true
		slidingCollider.disabled = true
		slidingMesh.visible = false
	
	curDashTransitionTimer -= delta
	if(curDashTransitionTimer > 0 and !isDashing):
		curSpeed = lerpf(dashSpeed, sprintSpeed, curDashTransitionTimer / dashTransitionTimer)
	
	# Cam Dip
	var target_height
	if isDashing:
		target_height = camDipYHeight
	else:
		target_height = normalCamYHeight
	camera.set_base_y(move_toward(camera.get_base_y(), target_height, camDipTransitionStrength * delta))
	
	# Handle Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * curSpeed
		velocity.z = direction.z * curSpeed
	else:
		velocity.x = move_toward(velocity.x, 0, curSpeed)
		velocity.z = move_toward(velocity.z, 0, curSpeed)
	
	# Wall kick
	var wallNormal = get_wall_normal()
	if (curJumpBuffered >= 0 and !is_on_floor() and wallNormal != Vector3.ZERO):
		curJumpBuffered = -1 #consume jump input
		velocity.y = wallKickUpForce
		velocity.x = wallNormal.x * wallKickForce
		velocity.z = wallNormal.z * wallKickForce
	
	# Jump
	if (curJumpBuffered >= 0 and curJumps > 0):
		curJumpBuffered = -1 #consume jump input
		velocity.y = jumpForce
		
		# Hyper jump
		if (isDashing and curJumps == NumberOfJumps):
			velocity.y = hyperJumpForce
		
		curJumps -= 1
	
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

	if !result.is_empty():
		# Damage the target
		if result.collider is Enemy:
			await SlowMotion.slow_motion(0.5)
		
		spawn_tracer(from, result.position)
	else:
		spawn_tracer(from, to)
	
	camera_shake.emit(SHOOT_SHAKE_AMOUNT)

func spawn_tracer(from: Vector3, to: Vector3):
	if bullet == null:
		return
	
	var tracer = bullet.instantiate()
	get_tree().current_scene.add_child(tracer)
	tracer.initialize(from, to, tracerSpeed)

func find_nearby_wall_normal() -> Vector3:
	var space_state = get_world_3d().direct_space_state
	var origin = global_transform.origin
	origin.y = camera.global_transform.origin.y  # cast at camera's height, not the feet

	var closest_normal := Vector3.ZERO
	var closest_dist := wallCheckDistance + 1.0

	for i in range(wallRayCount):
		var angle = (TAU / wallRayCount) * i
		var dir = Vector3(cos(angle), 0, sin(angle))
		var to = origin + dir * wallCheckDistance

		var query = PhysicsRayQueryParameters3D.create(origin, to)
		query.collision_mask = wallCollisionMask
		query.exclude = [get_rid()]  # don't hit your own body

		var result = space_state.intersect_ray(query)
		if result:
			# optional: ignore shallow ramps/floors that slipped onto this layer
			if abs(result.normal.y) < 0.3:
				var dist = origin.distance_to(result.position)
				if dist < closest_dist:
					closest_dist = dist
					closest_normal = result.normal

	return closest_normal
