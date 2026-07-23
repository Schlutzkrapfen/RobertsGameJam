extends CharacterBody3D


const SPEED:float = 5.0
const JUMP_VELOCITY:float = 4.5
const SHOOT_SHAKE_AMOUNT:float = 100.0
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
# player components
@onready var camera: Camera3D= get_node("Camera3D")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

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
	if event.is_action_released("shoot"):
		shoot()

func controll_camera(delta:float):
	# rotate camera along X axis
	camera.rotation_degrees -= Vector3(rad_to_deg(mouseDelta.y), 0, 0) * lookSensitivity * delta
	# clamp the vertical camera rotation
	camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, minLookAngle, maxLookAngle)

	# rotate player along Y axis
	rotation_degrees -= Vector3(0, rad_to_deg(mouseDelta.x), 0) * lookSensitivity * delta

	# reset the mouse delta vector
	mouseDelta = Vector2()

func _process(delta):
	controll_camera(delta)

func shoot():
	camera_shake.emit(SHOOT_SHAKE_AMOUNT)
	await Slowmo.slow_motion(1)
	
