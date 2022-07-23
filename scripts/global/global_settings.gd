extends Node

var configPath = "res://config.ini"
var configFile

var version = "v0.2 - volume slider go brrr"
var globalOffset: float = 0

var keybinds = {}

func _ready():
	#load config, and all the variables
	configFile = ConfigFile.new()
	if configFile.load(configPath) == OK:
		for key in configFile.get_section_keys("Keybinds"):
			var key_value = configFile.get_value("Keybinds", key)
			
			keybinds[key] = key_value
		loadKeybinds()
		
		if(configFile.get_value("Display", "ResolutionX") != null):
			OS.set_window_size(Vector2(configFile.get_value("Display", "ResolutionX"),
									configFile.get_value("Display", "ResolutionY")))
		
		if(configFile.get_value("Gameplay", "GlobalOffset") != null):
			globalOffset = configFile.get_value("Gameplay", "GlobalOffset")
	else:
		print("config not found!")

func loadKeybinds():
	for key in keybinds.keys():
		var actionList = InputMap.get_action_list(key)
		if !actionList.empty():
			InputMap.action_erase_event(key, actionList[0])
		var newKey = InputEventKey.new()
		newKey.set_scancode(keybinds[key])
		InputMap.action_add_event(key, newKey)

func saveConfig():
	print("saving config... - keybinds")
	for key in keybinds.keys():
		var key_value = keybinds[key]
		configFile.set_value("Keybinds", key, key_value)
	
	print("saving config... - resolution")
	var res = OS.window_size
	configFile.set_value("Display", "ResolutionX", int(res[0]))
	configFile.set_value("Display", "ResolutionY", int(res[1]))
	
	configFile.set_value("Gameplay", "GlobalOffset", globalOffset)
	
	configFile.save(configPath)
	print("saved!")
