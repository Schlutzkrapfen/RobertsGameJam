extends Camera3D


@export var decay:float = 0.8  # How quickly the shaking stops [0, 1].
@export var max_offset:Vector2 = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll:float = 0.1  # Maximum rotation in radians (use sparingly).
@export var target:NodePath  # Assign the node this camera will follow.
const NOISE_SEEDS = [0,1000,2000]
var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].
@onready var noise = FastNoiseLite.new()
var noise_y = 0

func _ready():
	randomize()
	noise.seed = randi()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX  # or PERLIN, CELLULAR, VALUE, etc.
	noise.frequency = 1.0 / 4.0                    # replaces "period" — lower = smoother/larger features
	noise.fractal_octaves = 2
	noise.fractal_lacunarity = 2.0                   # frequency multiplier per octave
	noise.fractal_gain = 0.5  
 
func add_trauma(amount):
	trauma = min(trauma + amount, 1.0)
func _process(delta):
	if target:
		global_position = get_node(target).global_position
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()
	
func shake():
	noise_y += 1
	var amount:float = pow(trauma, trauma_power)
	self.rotation.z = max_roll * amount * noise.get_noise_2d(0, noise_y)
	self.position.x = max_offset.x * amount * noise.get_noise_2d(1000*2, noise_y)
	self.position.y = max_offset.y * amount * noise.get_noise_2d(2000*3, noise_y)

	


func _on_player_camerashake(amount: float) -> void:
	add_trauma(amount)
