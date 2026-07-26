extends CharacterBody3D
@export var player: CharacterBody3D
@export var wait_idle_time: float = 1
@export var wait_idle_time_ez: float = 2
@export var wait_time_between_attacks = 0
@export var wait_time_between_attacks_ez = 0.5

@export var wait_for_spawning:float = 1
@export var enemies_ammount: int = 20
@export var enemies_ammount_ez: int = 10

@export var sphere_attack: PackedScene
@export var sphere_attack_size:float = 20
@export var sphere_attack_size_ez:float = 10
@export var anim:AnimationPlayer
@export var spawn_radius_sphere_attacl:int = 100
@export var spawn_spher_amount:int = 15

@export var hand_scene:PackedScene
@export var hand_damage:int = 4
@export var time_tile_attack_hands: float = 2
@export var time_attack_hands: float = 0.2
@export var time_reset_attack_hands: float = 1
@export var hand_raise_size:float = 20

@export var hp: int = 10000

@warning_ignore("integer_division")
@onready var half_hp:int =hp /2
var healthBar1: TextureProgressBar
var healthBar2: TextureProgressBar
var random:int = 0
signal spawn_enemies()
var hands:Array[Area3D] = []
var used_hands:Array[bool] = []
var k:int = 0
var attack_start:bool = true

enum state{
	idle = 0,
	attack_1 = 1,
	attack_2 = 2,
	spawn_enemies = 3,
	 }
var currents_state: state = state.idle
func _ready() -> void:
	if GameManager.Difficulty == GameManager.DifficultyOptions.EASY:
		hp = half_hp
		@warning_ignore("integer_division")
		half_hp = half_hp /2
		wait_idle_time = wait_idle_time_ez
		sphere_attack_size = sphere_attack_size_ez
		enemies_ammount = enemies_ammount_ez
		wait_time_between_attacks = wait_time_between_attacks_ez
	choose_state()
	healthBar1 = get_node("UI/Health_L")
	healthBar2 = get_node("UI/Health_R")
	healthBar1.max_value = hp
	healthBar1.value = hp
	healthBar2.max_value = hp
	healthBar2.value = hp
func _physics_process(_delta: float) -> void:
	self.look_at(player.global_position)
	
func choose_state():
	match random:
		0:
			print("Idle")
			if half_hp < hp:
				await get_tree().create_timer(wait_idle_time).timeout 
		1:
			anim.play("Attack 1")
			for i in spawn_spher_amount:
				spawn_simple_attacks()
			$Sphere.play()
			await anim.animation_finished
		2:
			anim.play("Attack 2")
			hand_attack()
			await anim.animation_finished
		3:
			print("enemies")
			$Spawn.play()
			for i in enemies_ammount:
				spawn_enemies.emit()
			await get_tree().create_timer(wait_for_spawning).timeout 
	random = randi_range(0,3)
	
	await get_tree().create_timer(wait_time_between_attacks).timeout 
	choose_state()
			
func hand_attack():
	var cur_hand: Area3D
	var cur_id:int 
	if used_hands.has(false):
		var i: int = 0
		for hand_bool in used_hands: 
			if hand_bool == false:
				cur_hand = hands[i]
				used_hands[i] = true
				cur_id = i
			i += 1
	else:
		var hand = hand_scene.instantiate()
		add_child(hand)
		hands.append(hand)
		used_hands.append(true)
		cur_hand = hand
		hand.body_entered.connect(_on_body_entered)
		cur_id = len(hands)-1
	
	cur_hand.look_at(player.global_position)
	var tween:Tween = get_tree().create_tween()
	var cur_player_pos:Vector3 = player.global_position
	
	tween.tween_property(cur_hand, "global_position",Vector3(cur_player_pos.x,cur_player_pos.y+hand_raise_size,cur_player_pos.z), time_tile_attack_hands).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	var tween1:Tween = get_tree().create_tween() #!THIS LINE THREW AN ERROR ONCE ->createTween on empty tree?
	attack_start = true
	tween1.tween_property(cur_hand, "global_position",Vector3(cur_player_pos.x,cur_player_pos.y-hand_raise_size,cur_player_pos.z), time_attack_hands).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween1.tween_property(cur_hand, "global_position",self.global_position, time_reset_attack_hands).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	await tween1.finished
	used_hands[cur_id] = false

func make_damage(thing:Node3D):

		if thing.is_in_group("Player"):
			player.player_hit(1)
		if thing.is_in_group("Enemie"):
			thing.queue_free()

func take_damage(damage: int):
	hp -= damage
	healthBar1.value = hp
	healthBar2.value = hp
	if(hp <= 0):
		get_tree().change_scene_to_file("res://Nodes/Levels/Winscreen.tscn")
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		make_damage(body)
	if body is StaticBody3D && attack_start:
		attack_start = false
		player.emit_signal("camera_shake",0.1,1)
			
func spawn_simple_attacks():
	var attack = sphere_attack.instantiate()
	# Choose a random location on the SpawnPath.
	# We store the reference to the SpawnLocation node
	# And give it a random offset.
	
	attack.position = Vector3(randi_range(-spawn_radius_sphere_attacl,spawn_radius_sphere_attacl),1,randi_range(-spawn_radius_sphere_attacl,spawn_radius_sphere_attacl))
	attack.attack_size = sphere_attack_size
	# Spawn the mob by adding it to the Main scene.
	get_parent().add_child.call_deferred(attack)
