extends Camera3D


@export var decay:float = 0.8
@export var max_offset:Vector2 = Vector2(100, 75)
@export var max_roll:float = 0.1 
@export var target:NodePath
const NOISE_SEEDS = [0,1000,2000]
var trauma = 0.0 
var trauma_power = 2 
@onready var noise = FastNoiseLite.new()
var noise_y = 0

var base_position:Vector3 = Vector3.ZERO

func _ready():
	randomize()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 1.0 / 4.0 
	noise.fractal_octaves = 2
	noise.fractal_lacunarity = 2.0
	noise.fractal_gain = 0.5
	base_position = position

func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)

func _process(delta):
	if target:
		global_position = get_node(target).global_position
		base_position.x = position.x
		base_position.z = position.z

	trauma = max(trauma - decay * delta, 0)
	shake()

func shake():
	noise_y += 1
	var amount:float = pow(trauma, trauma_power)
	rotation.z = max_roll * amount * noise.get_noise_2d(0, noise_y)
	position.x = base_position.x + max_offset.x * amount * noise.get_noise_2d(2000, noise_y)
	position.y = base_position.y + max_offset.y * amount * noise.get_noise_2d(6000, noise_y)
	position.z = base_position.z

func set_base_y(y:float) -> void:
	base_position.y = y

func get_base_y() -> float:
	return base_position.y

func _on_player_camera_shake(amount: float) -> void:
	add_trauma(amount)
