extends CharacterBody3D

const SHOOT_SHAKE_AMOUNT:float = 0.05
signal camera_shake(amount:float)

# stats
@export_subgroup("Health")
@export var curHp : int = 3
@export var shild_time:float = 0.5
@export var healt_control:Control
var shild:bool 

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
@export var jump_power_when_hit:float = 24
# wall kick
@export_subgroup("Wall Kick")
@export var wallCheckDistance: float = 1.0
@export var wallKickForce: float = 8.0
@export var wallKickUpForce: float = 10.0
@export var wallRayCount: int = 16
@export_flags_3d_physics var wallCollisionMask: int = 1 << 1
@export var wallKickControlTime: float = 0.35
var curWallKickTimer: float = 0.0
var wallKickVelocity: Vector3 = Vector3.ZERO

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

#Ultimate Weapon
@export_category("Ultimate Weapon")
var overchargeUI : TextureProgressBar
var ultChargeUI : TextureProgressBar
# @export var chargeSpeed : float = 20
# @export var dischargeSpeed : float = 40
# @export var overChargeThreshhold : float = 10
@export var ultChargeSpeed : float = 3
@export var ultDischargeSpeed : float = 2
@export var ultFireDischargeSpeed : float = 10
@export var ultDamageTickDuration : float = 0.3
@export var ultDamagePerTick : float = 10
@export var ultKnockbackForce : float = 6.0
@export var ultMaxKnockbackSpeed : float = 20.0
@export var beamShakeStrength : float = 0.1
@export var beamSlowmoDuration : float = 0.1

var isChargingUlt : bool = false
var ultimateReady : bool = false
var isUlting : bool = false
var curUltimateCharge : float = 0
var deathBeam : Node3D
var deathRay : ShapeCast3D
var curUltTick : float = 0
var curKnockbackVelocity : Vector3 = Vector3.ZERO
var curKnockbackStrength : float = 0

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
	overchargeUI = get_node("UI/OverheatCharge")
	ultChargeUI = get_node("UI/UltimateCharge")
	deathBeam = get_node("Camera3D/DeathBeam")
	deathRay = get_node("Camera3D/DeathRay")

func _process(delta):
	controll_camera(delta)
	
	#Shooting
	if(isShooting and !isChargingUlt):
		shoot(delta)
	
	# Ultimate
	if (isUlting):
		curUltimateCharge -= ultFireDischargeSpeed * delta;
		curUltTick -= delta
		if(curUltTick <= 0):
			# DAMAGE ENEMY
			curUltTick = ultDamageTickDuration
			deathRay.force_shapecast_update()
			if(deathRay.is_colliding()):
				for i in range(deathRay.get_collision_count()):
					var hit = deathRay.get_collider(i)
					if (hit.has_method("take_damage")):
						hit.take_damage(ultDamagePerTick)
						camera_shake.emit(beamShakeStrength)
						await SlowMotion.slow_motion(beamSlowmoDuration)
	else:
		if(isChargingUlt):
			curUltimateCharge += ultChargeSpeed * delta
		else:
			curUltimateCharge -= ultDischargeSpeed * delta
	
	if(curUltimateCharge < 0):
		isUlting = false
		curUltimateCharge = 0
	if(curUltimateCharge > 100):
		ultimateReady = true
	
	ultChargeUI.value = curUltimateCharge
	
	#Jump Buffer
	curJumpBuffered -= delta
	if(Input.is_action_just_pressed("jump")):
		curJumpBuffered = jumpBuffer
		
	# Dash Buffer
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
	
	# Ult Knockback
	if(isUlting):
		var knockbackDir := camera.global_transform.basis.z.normalized() # points away from where you're looking
		curKnockbackStrength += ultKnockbackForce * delta
		curKnockbackVelocity.x = knockbackDir.x * curKnockbackStrength
		curKnockbackVelocity.y = knockbackDir.y * curKnockbackStrength / 500
		curKnockbackVelocity.z = knockbackDir.z * curKnockbackStrength
		
		if(curKnockbackVelocity.length() > ultMaxKnockbackSpeed):
			curKnockbackVelocity = curKnockbackVelocity.normalized() * ultMaxKnockbackSpeed
	else:
		curKnockbackVelocity = Vector3.ZERO
	
	# Handle Movement
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var targetVelocity := Vector3.ZERO
	if direction:
		targetVelocity = direction * curSpeed
	else:
		targetVelocity = Vector3(move_toward(velocity.x, 0, curSpeed), 0, move_toward(velocity.z, 0, curSpeed))
	
	if curWallKickTimer > 0:
		curWallKickTimer -= delta
		var t = 1.0 - (curWallKickTimer / wallKickControlTime) # 0 right after kick -> 1 when done
		velocity.x = lerp(wallKickVelocity.x, targetVelocity.x, t)
		velocity.z = lerp(wallKickVelocity.z, targetVelocity.z, t)
	else:
		velocity.x = targetVelocity.x
		velocity.z = targetVelocity.z
	
	# Wall kick
	var wallNormal = find_nearby_wall_normal()
	if (curJumpBuffered >= 0 and !is_on_floor() and wallNormal != Vector3.ZERO):
		curJumpBuffered = -1
		velocity.y = wallKickUpForce
	
		var incomingVelocity := Vector3(velocity.x, 0, velocity.z)
		var reflected := incomingVelocity.bounce(wallNormal)
		var awayFromWallSpeed := reflected.dot(wallNormal)
		if awayFromWallSpeed < wallKickForce:
			reflected += wallNormal * (wallKickForce - awayFromWallSpeed)
		
		wallKickVelocity = reflected
		curWallKickTimer = wallKickControlTime
		velocity.x = wallKickVelocity.x
		velocity.z = wallKickVelocity.z
	
	# Jump
	if (curJumpBuffered >= 0 and curJumps > 0):
		curJumpBuffered = -1 #consume jump input
		velocity.y = jumpForce
		
		# Hyper jump
		if (isDashing and curJumps == NumberOfJumps):
			velocity.y = hyperJumpForce
		
		curJumps -= 1
	
	velocity += curKnockbackVelocity
	move_and_slide()

func player_hit(amount:int,jump_up:bool = false):
	
	if shild:
		return
	var healt_texture = healt_control.get_children()
	shild = true
	curHp -= amount
	emit_signal("camera_shake",0.4)
	var i:int = 0
	for texture in healt_texture:
		if i < curHp:
			texture.visible = true
		else:
			texture.visible = false
		i +=1
	if jump_up:
		velocity.y = jump_power_when_hit
		curJumps -=1
	
	if curHp <= 0:
		get_tree().change_scene_to_file("res://Nodes/Levels/LoseScreen.tscn")
		return
	await get_tree().create_timer(shild_time).timeout 
	shild = false

func _input(event):
	if event is InputEventMouseMotion:
		mouseDelta = event.relative
	if event.is_action_pressed("shoot"):
		isShooting = true
	if event.is_action_released("shoot"):
		isShooting = false
		curShootTimer = 0
		curBurstCountdown = bulletsPerBurst - 1
	if event.is_action_pressed("ChargeUltimate"):
		isChargingUlt = true
	if event.is_action_released("ChargeUltimate"):
		isChargingUlt = false
		if(ultimateReady):
			isUlting = true
			for child in deathBeam.get_children():
				if child is GPUParticles3D:
					child.lifetime = curUltimateCharge / ultFireDischargeSpeed
					child.restart()
					child.emitting = true
					

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
