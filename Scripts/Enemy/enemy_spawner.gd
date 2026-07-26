extends Node

# This creates an expandable list in the Inspector
@export var mob_scenes: Array[PackedScene] = []
@export var player: CharacterBody3D

func _on_boss_spawn_enemies() -> void:
	# Safety check: make sure the array isn't empty before trying to pick one
	if mob_scenes.is_empty():
		push_warning("No mobs assigned in the Inspector!")
		return

	# Pick a random scene directly from the exported array
	var chosen_scene = mob_scenes.pick_random()
	var mob = chosen_scene.instantiate()
	
	# Choose a random location on the SpawnPath
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	mob_spawn_location.progress_ratio = randf()
	
	# Assign the target and position
	mob.target = player
	mob.position = mob_spawn_location.position
	
	# Spawn the mob by adding it to the Main scene
	add_child(mob)
