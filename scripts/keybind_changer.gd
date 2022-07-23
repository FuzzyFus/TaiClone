extends Node

onready var LeftKatButt = get_node("LeftKat/Button")
onready var RightKatButt = get_node("RightKat/Button")
onready var LeftDonButt = get_node("LeftDon/Button")
onready var RightDonButt = get_node("RightDon/Button")

var currentlyChanging = null

# Called when the node enters the scene tree for the first time.
func _ready():
	LeftKatButt.connect("pressed", self, "buttonPressed", ["LeftKat"])
	RightKatButt.connect("pressed", self, "buttonPressed", ["RightKat"])
	LeftDonButt.connect("pressed", self, "buttonPressed", ["LeftDon"])
	RightDonButt.connect("pressed", self, "buttonPressed", ["RightDon"])
	
	changeText("LeftKat", OS.get_scancode_string(InputMap.get_action_list("LeftKat")[0].scancode))
	changeText("RightKat", OS.get_scancode_string(InputMap.get_action_list("RightKat")[0].scancode))
	changeText("LeftDon", OS.get_scancode_string(InputMap.get_action_list("LeftDon")[0].scancode))
	changeText("RightDon", OS.get_scancode_string(InputMap.get_action_list("RightDon")[0].scancode))
	pass # Replace with function body.

func _input(ev):
	if currentlyChanging != null:
		if (ev is InputEventKey) || (ev is InputEventJoypadButton):
			changeKey(currentlyChanging, ev.scancode)
			buttonPressed(currentlyChanging)

func buttonPressed(type):
	if currentlyChanging == null:
		currentlyChanging = type
		changeText(currentlyChanging, "...")
	else:
		LeftKatButt.pressed = false
		RightKatButt.pressed = false
		LeftDonButt.pressed = false
		RightDonButt.pressed = false
		
		changeText(currentlyChanging, 
					OS.get_scancode_string(InputMap.get_action_list(currentlyChanging)[0].scancode))
		currentlyChanging = null

func changeText(button, text):
	match button:
			"LeftKat":
				LeftKatButt.text = text
			"RightKat":
				RightKatButt.text = text
			"LeftDon":
				LeftDonButt.text = text
			"RightDon":
				RightDonButt.text = text

func changeKey(button, key):
	var actionList = InputMap.get_action_list(button)
	if !actionList.empty():
		InputMap.action_erase_event(button, actionList[0])
	var newKey = InputEventKey.new()
	newKey.set_scancode(key)
	InputMap.action_add_event(button, newKey)
	settings.keybinds[button] = key
