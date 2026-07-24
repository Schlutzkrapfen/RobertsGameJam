extends Node

@export var mob_scene: PackedScene
@export var player:CharacterBody3D
# Called when the node enters the scene tree for the first time.


func _on_boss_spawn_enemies() -> void:
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on the SpawnPath.
	# We store the reference to the SpawnLocation node.
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	# And give it a random offset.
	mob_spawn_location.progress_ratio = randf()

	#var player_position =player.position
	#mob.initialize(mob_spawn_location.position, player_position)
	mob.target = player
	mob.position = mob_spawn_location.position
	# Spawn the mob by adding it to the Main scene.
	add_child(mob)
