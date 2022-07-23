extends VBoxContainer

onready var dropdown = get_node("OptionButton")
onready var fullscreenToggle = get_node("Fullscreen/Toggle")

var fullscreen = false
var resolutions = [
	["16:9 | 1920x1080", Vector2(1920,1080)],
	["16:9 | 1280x720", Vector2(1280,720)],
	["16:9 | 1024x576", Vector2(1024,576)],
	["separator"],
	["4:3 | 1280x1024", Vector2(1280,1024)],
	["4:3 | 1024x768", Vector2(1024,768)],
	["separator"],
	["5:4 | 1025x820", Vector2(1025,820)]
	]

# hey incase youre looking at the source code to see if you can help
# the way taiclone currently gets 4:3 and lower resolutions working is honestly insane
# the games resolution starts at 0x720 so it forcefully can take in any resolution
# but obviously this is horrible because it means in the editor its squished super badly
# if anyone can come up with a better fix, id REALLY appreciate it much love bbgurl kissing emoji

func _ready():
	addDropdownOptions();
	dropdown.connect("item_selected", self, "changeRes")
	fullscreenToggle.connect("toggled", self, "toggleFullscreen")

func addDropdownOptions():
	for item in resolutions:
		if item[0] == "separator":
			dropdown.add_separator()
		else:
			dropdown.add_item(item[0])

func changeRes(index):
	print("Resolution changed to ", resolutions[index][0])
	OS.set_window_size(resolutions[index][1])

func toggleFullscreen(toggle) -> void:
	print("fullscreen ", toggle)
	OS.window_fullscreen = toggle
	
	var i = 0
	for res in resolutions:
		dropdown.set_item_disabled(i, toggle)
		i += 1
