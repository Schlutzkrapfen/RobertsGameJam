@tool
extends Node3D

@export_category("Spawning Configuration")
@export var platform_scene: PackedScene
@export var max_platforms: int = 50
@export var initial_spawn_count: int = 20
@export var spawn_interval: float = 2.0 # How often to spawn a new platform (in seconds)

@export_category("Cylinder Dimensions")
@export var outer_radius: float = 30.0
@export var inner_radius: float = 10.0
@export var cylinder_height: float = 40.0

@export_category("Platform Scale")
@export var min_scale: Vector3 = Vector3(1.0, 0.5, 1.0)
@export var max_scale: Vector3 = Vector3(8.0, 1.5, 8.0)

@export_category("Debug")
## Toggle this to see the spawn volume in the editor
@export var show_spawn_volume: bool = true

var _spawned_platforms: Array[Node3D] = []
var _debug_combiner: CSGCombiner3D
var _debug_outer: CSGCylinder3D
var _debug_inner: CSGCylinder3D
var _spawn_timer: float = 0.0 # Internal timer to track spawn delays

func _ready() -> void:
	if(GameManager.Difficulty == GameManager.DifficultyOptions.HARD):
		$Ground.visible = false
		$StaticBody3D.collision_layer = 4
	
	if Engine.is_editor_hint():
		_setup_debug_visuals()
		return
		
	# Game start logic (Hides the debug volume when playing)
	if is_instance_valid(_debug_combiner):
		_debug_combiner.hide()
		
	if not platform_scene:
		push_error("Platform Spawner: No platform_scene assigned!")
		return
		
	for i in range(initial_spawn_count):
		spawn_platform()

func _process(delta: float) -> void:
	# This runs continuously in the editor to update the visual cylinder
	if Engine.is_editor_hint():
		if is_instance_valid(_debug_combiner):
			_debug_combiner.visible = show_spawn_volume
			_debug_outer.radius = outer_radius
			_debug_outer.height = cylinder_height
			_debug_inner.radius = inner_radius
			# Make the inner cylinder slightly taller to ensure a clean cutout
			_debug_inner.height = cylinder_height + 2.0 
		return
		
	# Runtime Spawning Logic
	# Clean up any null references (in case platforms are destroyed elsewhere)
	_spawned_platforms = _spawned_platforms.filter(func(p): return is_instance_valid(p))
	
	# Only spawn if we haven't reached the max platforms limit
	if _spawned_platforms.size() < max_platforms:
		_spawn_timer += delta
		if _spawn_timer >= spawn_interval:
			spawn_platform()
			_spawn_timer = 0.0 # Reset timer after spawning

func spawn_platform() -> void:
	var platform = platform_scene.instantiate()
	add_child(platform)
	
	_set_random_position(platform)
	_set_random_rotation(platform)
	_set_random_scale(platform)
	_manage_platform_queue(platform)

func _set_random_position(platform: Node3D) -> void:
	var r_inner_sq = inner_radius * inner_radius
	var r_outer_sq = outer_radius * outer_radius
	var radius = sqrt(randf_range(r_inner_sq, r_outer_sq))
	
	var theta = randf_range(0.0, TAU)
	var y_pos = randf_range(-cylinder_height / 2.0, cylinder_height / 2.0)
	
	var x_pos = radius * cos(theta)
	var z_pos = radius * sin(theta)
	
	platform.position = Vector3(x_pos, y_pos, z_pos)

func _set_random_rotation(platform: Node3D) -> void:
	# Random rotation exclusively on the Y axis
	var random_y_rot = randf_range(0.0, TAU)
	platform.rotation = Vector3(0.0, random_y_rot, 0.0)

func _set_random_scale(platform: Node3D) -> void:
	# Picks a random size between the min and max limits for each axis independently
	var random_x = randf_range(min_scale.x, max_scale.x)
	var random_y = randf_range(min_scale.y, max_scale.y)
	var random_z = randf_range(min_scale.z, max_scale.z)
	
	platform.scale = Vector3(random_x, random_y, random_z)

func _manage_platform_queue(new_platform: Node3D) -> void:
	_spawned_platforms.append(new_platform)
	
	if _spawned_platforms.size() > max_platforms:
		var oldest = _spawned_platforms.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

## Automatically generates the visual nodes in the editor
func _setup_debug_visuals() -> void:
	if has_node("DebugVolume"):
		_debug_combiner = get_node("DebugVolume")
		_debug_outer = _debug_combiner.get_node("Outer")
		_debug_inner = _debug_outer.get_node("Inner")
		return
		
	_debug_combiner = CSGCombiner3D.new()
	_debug_combiner.name = "DebugVolume"
	
	_debug_outer = CSGCylinder3D.new()
	_debug_outer.name = "Outer"
	_debug_outer.sides = 32
	
	_debug_inner = CSGCylinder3D.new()
	_debug_inner.name = "Inner"
	_debug_inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	_debug_inner.sides = 32
	
	add_child(_debug_combiner)
	_debug_combiner.set_owner(get_tree().edited_scene_root) 
	
	_debug_combiner.add_child(_debug_outer)
	_debug_outer.set_owner(get_tree().edited_scene_root)
	
	_debug_outer.add_child(_debug_inner)
	_debug_inner.set_owner(get_tree().edited_scene_root)

	#Difficulty
	#if(GameManager.Difficulty == GameManager.DifficultyOptions.HARD):
	#	$Ground.visible = false
	#	$StaticBody3D.collision_layer = 4
