extends RichTextLabel

var array_input:Array[bool] = [false,false,false,false]
signal first_tutorial_part_done
var already_played:bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if GameManager.Difficulty == GameManager.DifficultyOptions.Tutorial:
		self.visible = true

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

func check_if_tutorial_finished():
	if not array_input.has(false) and not already_played :
		already_played = true
		self.text = "Use [b][i]Space [/i][/b]to Jump"
		
		emit_signal("first_tutorial_part_done")
