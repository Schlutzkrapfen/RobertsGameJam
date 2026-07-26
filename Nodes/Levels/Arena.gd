@tool
extends Node3D

@export_category("Spawning Configuration")
@export var platform_scene: PackedScene
@export var player_node: Node3D
@export var startingBlock: Node3D
@export var max_platforms: int = 50
@export var initial_spawn_count: int = 20
@export var spawn_interval: float = 2.0 # How often to spawn a new platform (in seconds)
@export var max_spawn_attempts: int = 5 ## Times it will try to find a safe spot before skipping

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
var _spawn_timer: float = 0.0

func _ready() -> void:
	if(GameManager.Difficulty == GameManager.DifficultyOptions.EASY):
		startingBlock.queue_free()
		player_node.position.y -= 15
	if(GameManager.Difficulty == GameManager.DifficultyOptions.HARD):
		$Ground.visible = false
		$StaticBody3D.collision_layer = 4
		
	
	if Engine.is_editor_hint():
		_setup_debug_visuals()
		return
		
	if is_instance_valid(_debug_combiner):
		_debug_combiner.hide()
		
	if not platform_scene:
		push_error("Platform Spawner: No platform_scene assigned!")
		return
		
	for i in range(initial_spawn_count):
		spawn_platform()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if is_instance_valid(_debug_combiner):
			_debug_combiner.visible = show_spawn_volume
			_debug_outer.radius = outer_radius
			_debug_outer.height = cylinder_height
			_debug_inner.radius = inner_radius
			_debug_inner.height = cylinder_height + 2.0 
		return
		
	_spawned_platforms = _spawned_platforms.filter(func(p): return is_instance_valid(p))
	
	if _spawned_platforms.size() < max_platforms:
		_spawn_timer += delta
		if _spawn_timer >= spawn_interval:
			spawn_platform()
			_spawn_timer = 0.0 

func spawn_platform() -> void:
	var valid_spot_found = false
	var p_pos: Vector3
	var p_rot: Vector3
	var p_scale: Vector3
	
	# Attempt to find a safe location that doesn't overlap with the player
	for attempt in range(max_spawn_attempts):
		p_pos = _get_random_position()
		p_rot = _get_random_rotation()
		p_scale = _get_random_scale()
		
		if _is_position_safe(p_pos, p_scale):
			valid_spot_found = true
			break
			
	# If we couldn't find a spot that wasn't on the player, abort the spawn this time
	if not valid_spot_found:
		return 

	var platform = platform_scene.instantiate()
	add_child(platform)
	
	platform.position = p_pos
	platform.rotation = p_rot
	platform.scale = p_scale
	
	_manage_platform_queue(platform)

func _get_random_position() -> Vector3:
	var r_inner_sq = inner_radius * inner_radius
	var r_outer_sq = outer_radius * outer_radius
	var radius = sqrt(randf_range(r_inner_sq, r_outer_sq))
	
	var theta = randf_range(0.0, TAU)
	var y_pos = randf_range(-cylinder_height / 2.0, cylinder_height / 2.0)
	
	var x_pos = radius * cos(theta)
	var z_pos = radius * sin(theta)
	
	return Vector3(x_pos, y_pos, z_pos)

func _get_random_rotation() -> Vector3:
	var random_y_rot = randf_range(0.0, TAU)
	return Vector3(0.0, random_y_rot, 0.0)

func _get_random_scale() -> Vector3:
	var random_x = randf_range(min_scale.x, max_scale.x)
	var random_y = randf_range(min_scale.y, max_scale.y)
	var random_z = randf_range(min_scale.z, max_scale.z)
	
	return Vector3(random_x, random_y, random_z)

func _is_position_safe(check_pos: Vector3, check_scale: Vector3) -> bool:
	if not is_instance_valid(player_node):
		return true # Automatically safe if there's no player assigned or alive
		
	# Calculate an approximate bounding radius based on the largest scale dimension
	var max_dimension = maxf(check_scale.x, maxf(check_scale.y, check_scale.z))
	
	# Add a 2.0 unit buffer to account for the player's own size (tweak if necessary)
	var safe_distance = (max_dimension / 2.0) + 2.0 
	
	# Convert local spawn position to global so it correctly checks against player's global position
	var global_check_pos = to_global(check_pos)
	var distance_to_player = global_check_pos.distance_to(player_node.global_position)
	
	return distance_to_player >= safe_distance

func _manage_platform_queue(new_platform: Node3D) -> void:
	_spawned_platforms.append(new_platform)
	
	if _spawned_platforms.size() > max_platforms:
		var oldest = _spawned_platforms.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

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
