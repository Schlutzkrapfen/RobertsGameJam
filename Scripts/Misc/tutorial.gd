extends RichTextLabel

var array_input:Array[bool] = [false,false,false,false]
signal first_tutorial_part_done
var already_played:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.Difficulty == GameManager.DifficultyOptions.Tutorial:
		self.visible = true
		$"../UltimateCharge".visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("move_backward"):
		array_input[0] = true
		print(array_input)
		check_if_tutorial_finished()
	if event.is_action_pressed("move_forward"):
		array_input[1] = true
		check_if_tutorial_finished()
	if event.is_action_pressed("move_left"):
		array_input[2] = true
		check_if_tutorial_finished()
	if event.is_action_pressed("move_right"):
		array_input[3] = true
		check_if_tutorial_finished()
	
func start_double_jump():
	self.text = "Use [b][i]Space [/i][/b] again to double Jump"

func wall_jumps():
	self.text = "Use [b][i]Space [/i][/b] near walls to Wall Jump"
func far_jump():
	self.text = "Use [b][i]shift [/i][/b] to dash"
func wait():
	$"../..".ultChargeSpeed = 10
	$"../UltimateCharge".visible = true
	self.text = "[b][i]Wait [/i][/b] until ray is is charged\n do not get hit ;) "

func far_space_jump():
	self.text = "Use [b][i]shift [/i][/b] than [b][i]space[/i][/b] still on the ground to make a far jump"
func check_if_tutorial_finished():
	if not array_input.has(false) and not already_played :
		already_played = true
		self.text = "Use [b][i]Space [/i][/b]to Jump"
		
		emit_signal("first_tutorial_part_done")


func _on_ultimate_charge_value_changed(value: float) -> void:
	if value == 100:
		self.text = "Use [b][i]left mouse [/i][/b] to shoot \"böse Mann\""
