extends HBoxContainer

onready var music = get_node("../../Music")

onready var input = get_node("LineEdit")
onready var loadButt = get_node("LoadButton")
onready var playButt = get_node("PlayButton")
onready var rateButt = get_node("PlayButton")
onready var autoToggle = get_node("AutoToggle")

onready var hitManager = get_node("../../HitManager")
onready var chartLoader = get_node("../../ChartLoader")
onready var debugTextThing = get_node("../debugtext")
onready var fpsText = get_node("../fpstext")
onready var versionText = get_node("../VersionText")

func _process(_delta):
	fpsText.text = "FPS: " + str(Engine.get_frames_per_second())
	
func _ready():
	loadButt.connect("pressed", self, "loadFunc")
	playButt.connect("pressed", get_node("../../ChartLoader"), "playChart")
	autoToggle.connect("pressed", self, "autoThing")
	
	versionText.text = settings.version

func loadFunc():
	debugTextThing.text = "Loading... [Checking File]"
	var rawFile = tools.loadText(tools.fwdToBackSlash(input.text))
	if rawFile != "" && rawFile != null:
		#var audioFileName = rawFile.substr(rawFile.find("AudioFilename: ") + 15)
		#audioFileName = audioFileName.substr(0, audioFileName.find("\n"))
		#debugTextThing.text = chartLoader.loadMetadata(rawFile);
		debugTextThing.text = "Loading... [Reading File]"
		chartLoader.loadAndProcessAll(tools.fwdToBackSlash(input.text))
		debugTextThing.text = "Done!"
	else: debugTextThing.text = "Invalid file!"

func autoThing():
	hitManager.auto = autoToggle.pressed

# todo: make all volume things use linear2db
# see https://godotengine.org/qa/40911/best-way-to-create-a-volume-slider	
