extends CharacterBody3D
@export var wait_idle_time: float = 1
@export var wait_for_spawning:float = 1
@export var sphere_attack: PackedScene
@export var sphere_attack_size:float = 20
@export var anim:AnimationPlayer
@export var spawn_radius_sphere_attacl:int = 100
@export var spawn_spher_amount:int = 15
@export var hand_scene:PackedScene
@export var player: CharacterBody3D
@export var enemies_ammount: int = 20
@export var time_tile_attack_hands: float = 2
@export var time_attack_hands: float = 0.2
@export var time_reset_attack_hands: float = 1
signal spawn_enemies()
var hands:Array[Area3D] = []
var used_hands:Array[bool] = []


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
			for i in spawn_spher_amount:
				spawn_simple_attacks()
			await anim.animation_finished
			
		2:
			anim.play("Attack 2")
			
			hand_attack()
			
			
			await anim.animation_finished
			
		3:
			print("enemies")
			for i in enemies_ammount:
				spawn_enemies.emit()
			await get_tree().create_timer(wait_for_spawning).timeout 
	choose_state()
			
func hand_attack():
	var cur_hand: Area3D
	var cur_id:int 
	if used_hands.has(false):
		var i: int = 0
		for hand_bool in used_hands: 
			if hand_bool == false:
				cur_hand = hands[i]
			i += 1
	else:
		var hand = hand_scene.instantiate()
		add_child(hand)
		hands.append(hand)
		used_hands.append(true)
		cur_hand = hand
		hand.body_entered.connect(_on_body_entered)
		cur_id = len(hands)-1
		
	var tween = get_tree().create_tween()
	tween.tween_property(cur_hand, "global_position",Vector3( player.global_position.x,20,player.global_position.z), time_tile_attack_hands).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(cur_hand, "global_position",Vector3( player.global_position.x,-20,player.global_position.z), time_attack_hands).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(cur_hand, "global_position",self.global_position, time_reset_attack_hands).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	used_hands[cur_id] = false

func make_damage(thing:Node3D):

		if thing.is_in_group("Player"):
			print("Player HIT HAhAHA DER BÖSE MAN WAR HIER")

		if thing.is_in_group("Enemie"):
			print("Deleted Enemie")
			thing.queue_free()


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		make_damage(body)
func spawn_simple_attacks():
	var attack = sphere_attack.instantiate()
	# Choose a random location on the SpawnPath.
	# We store the reference to the SpawnLocation node
	# And give it a random offset.
	
	attack.position = Vector3(randi_range(-spawn_radius_sphere_attacl,spawn_radius_sphere_attacl),2,randi_range(-spawn_radius_sphere_attacl,spawn_radius_sphere_attacl))
	attack.attack_size = 8
	# Spawn the mob by adding it to the Main scene.
	get_parent().add_child.call_deferred(attack)
