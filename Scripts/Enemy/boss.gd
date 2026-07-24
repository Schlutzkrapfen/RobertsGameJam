extends CharacterBody3D
@export var wait_idle_time: float = 1
@export var wait_for_spawning:float = 1
@export var sphere_attack: PackedScene
@export var anim:AnimationPlayer
@export var spawn_radius_sphere_attacl:int = 100
signal spawn_enemies()

enum state{
	idle = 0,
	attack_1 = 1,
	attack_2 = 2,
	spawn_enemies = 3,
	 }
var currents_state: state = state.idle
func _ready() -> void:
	choose_state()
	


func choose_state():
	var random = randi_range(0,3)
	match random:
		0:
			print("Idle")
			await get_tree().create_timer(wait_idle_time).timeout 
		1:
			anim.play("Attack 1")
			print("Attack 1")
			for i in 10:
				spawn_simple_attacks()
			await anim.animation_finished
			
		2:
			anim.play("Attack 2")
			print("Attack 2")
			await anim.animation_finished
			
		3:
			print("enemies")
			spawn_enemies.emit()
			await get_tree().create_timer(wait_for_spawning).timeout 
	choose_state()
			
func spawn_simple_attacks():
	var attack = sphere_attack.instantiate()
	# Choose a random location on the SpawnPath.
	# We store the reference to the SpawnLocation node
	# And give it a random offset.
	
	attack.position = Vector3(randi_range(-spawn_radius_sphere_attacl,spawn_radius_sphere_attacl),2,randi_range(-spawn_radius_sphere_attacl,spawn_radius_sphere_attacl))
	attack.attack_size = 4
	# Spawn the mob by adding it to the Main scene.
	get_parent().add_child(attack)
