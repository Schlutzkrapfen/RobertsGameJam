extends Control
@onready var different_restart_text:Array[String]= ["Again",
"I will be ready for you.",
"Are you sure you want to go another round.",
"Even if you try again, the outcome will never change.", 
"Again, really? I thought you learned something.",
"Sorry, kid, but I don't think you're made for this.",
"I think you should just quit.",
"If you try again, I'll just have another victory to celebrate.",
"Hmm, are you sure?",
"Again?",
"Please stop. I'm slowly pitying you.",
"Mhh, maybe try something else. How does garbage collecter sound?",
"...",
"That round wasn't even close.",
"Are you even trying?",
"You're so far detached from reality if you think you can win.",
"Dude, this is just sad.",
"You know I'm holding back, right?",
"Sorry, kid, not even I like to punch people who are that far down.",
"You don't look so good. Maybe just give up.",
"Hmm? How about not?",
"Why are you here, just to hurt yourself?",
"Do you really think next time will be better?",
"Why, just why?",
"I think it's less shameful to just give up on how pitiful you've done.",
]


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if different_restart_text.size() > GameManager.deaths:
		$Restart.text = different_restart_text[GameManager.deaths]
	else:
		$Restart.text = different_restart_text[randi_range(0,different_restart_text.size()-1)]
	GameManager.deaths += 1
	if GameManager.Difficulty == GameManager.DifficultyOptions.EASY:
		$MainMenu.text = "Maybe the Tutorial?"
	elif GameManager.Difficulty == GameManager.DifficultyOptions.Tutorial:
		$MainMenu.visible = false
		$Restart.text = "Really in the tutorial"
	else:
		$MainMenu.text = "Make it Easier?"
		
	

func _on_quit_button_up() -> void:
	get_tree().quit()


func _on_restart_button_up() -> void:
	
	if GameManager.Difficulty == GameManager.DifficultyOptions.Tutorial:
		get_tree().change_scene_to_file("res://Nodes/Levels/tutorial.tscn")
		return
	get_tree().change_scene_to_file("res://Nodes/Levels/Level0.tscn")


func _on_main_menu_button_up() -> void:
	get_tree().change_scene_to_file("res://Nodes/Levels/MainMenu.tscn")
