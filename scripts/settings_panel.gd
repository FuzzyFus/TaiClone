extends Panel

onready var settingsButt = get_node("../SettingsButton")
onready var saveButt = get_node("SaveButton")

onready var lateearlyDrop = get_node("ScrollContainer/VBoxContainer/ExtraDisplays/LateEarly/OptionButton")
onready var hiterrToggle = get_node("ScrollContainer/VBoxContainer/ExtraDisplays/HitError/Toggle")

func _ready():
	settingsButt.connect("pressed", self, "toggleSettings")
	saveButt.connect("pressed", self, "saveSettings")
	
	lateearlyDrop.connect("item_selected", self, "enableDisplay", ["lateearly"])
	lateearlyDrop.add_item("Off")
	lateearlyDrop.add_item("Simple")
	lateearlyDrop.add_item("Advanced")
	
	hiterrToggle.connect("toggled", self, "enableDisplay", ["hiterr"])
	
	hiterrToggle.pressed = true
	pass # Replace with function body.

func toggleSettings():
	self.visible = !self.visible

func saveSettings():
	settings.saveConfig()
	
			
func enableDisplay(input, display):
	match display:
		"lateearly":
			match input:
				1:
					get_node("../../BarLeft/TimingIndicator").visible = true
					get_node("../../UI/HitError").lateearlySimpleDisplay = true
				2:
					get_node("../../BarLeft/TimingIndicator").visible = true
					get_node("../../UI/HitError").lateearlySimpleDisplay = false
				_:
					get_node("../../BarLeft/TimingIndicator").visible = false
			
		"hiterr":
			get_node("../../UI/HitError").visible = input
