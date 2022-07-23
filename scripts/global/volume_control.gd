extends Panel

onready var volViews = [
	get_node("Bars/Master/TextureProgress"),
	get_node("Bars/Spesifics/Music/TextureProgress"),
	get_node("Bars/Spesifics/SFX/TextureProgress")
]

onready var changeSound = get_node("ChangeSound")

onready var tween = get_node("VolumeIncreaseTween")
onready var timer = get_node("Timer")
onready var music = get_node("../../Music")

var vols = [
	1,
	1,
	1
]

var curChanging: int = 0

var precise = false

onready var allSFX = [
	get_node("../../DrumInteraction/LeftDonAudio"),
	get_node("../../DrumInteraction/LeftKatAudio"),
	get_node("../../DrumInteraction/RightDonAudio"),
	get_node("../../DrumInteraction/RightKatAudio"),
	get_node("../../DrumInteraction/FinisherDonAudio"),
	get_node("../../DrumInteraction/FinisherKatAudio"),
	get_node("ChangeSound")
]

func _ready() -> void:
	volViews[0].get_parent().connect("mouse_entered", self, "changeChannelViaMouseover", [0])
	volViews[1].get_parent().connect("mouse_entered", self, "changeChannelViaMouseover", [1])
	volViews[2].get_parent().connect("mouse_entered", self, "changeChannelViaMouseover", [2])

func _process(_delta) -> void:
	if self.modulate.a == 0 and curChanging != 0: 
		curChanging = 0
		changeChannel()

func _input(ev) -> void:
	var changed = false

	if ev is InputEventKey:
		if ev.pressed and ev.scancode == 16777238:
			precise = true
		elif !ev.pressed and ev.scancode == 16777238:
			precise = false

	var volDifference = 0.05
	if precise: volDifference = 0.01
	
	if Input.is_action_just_pressed("VolumeUp"):
		changed = changeVolume(volDifference)

	elif Input.is_action_just_pressed("VolumeDown"):
		changed = changeVolume(volDifference * -1)
		
	elif Input.is_action_just_pressed("VolumeNext"):
		if curChanging != 2: curChanging += 1
		else: curChanging = 0
		changeChannel()
		
	elif Input.is_action_just_pressed("VolumePrevious"):
		if curChanging != 0: curChanging -= 1
		else: curChanging = 2
		changeChannel()
		appearanceTimeout()
	
	if changed:
		volViews[curChanging].get_node("../Percentage").text = str(vols[curChanging] * 100)
		
		tween.interpolate_property(volViews[curChanging], "value",
			volViews[curChanging].value, vols[curChanging], 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		tween.start()

func changeVolume(amount) -> bool:
	var changed = false
	var channelVol = 0;
	
	match curChanging:
		1: channelVol = vols[1]
		2: channelVol = vols[2]
		_: channelVol = vols[0]
	
	if amount > 0:
		channelVol = min(1, channelVol + amount)
		changed = true
	else:
		channelVol = max(0, channelVol + amount)
		changed = true
	
	match curChanging:
		1: vols[1] = channelVol
		2: vols[2] = channelVol
		_: vols[0] = channelVol
		
	if changed == false: return false
	
	else:
		changeSound.pitch_scale = vols[curChanging] / 2 + 1
		changeSound.play()
		var masterdb = linear2db(vols[0])
		var musicdb = linear2db((vols[1] * vols[0]) / 2)
		var sfxdb = linear2db((vols[2] * vols[0]) / 2)
		
		appearanceTimeout()
		
		match(curChanging):
			_: #master
				music.volume_db = musicdb
				
				for sfx in allSFX:
					sfx.volume_db = sfxdb
			
			1: #music
				music.volume_db = musicdb
			
			2: #sfx
				for sfx in allSFX:
					sfx.volume_db = sfxdb
		return true

func changeChannel() -> void:
	appearanceTimeout()
	var i = 0;
	for meter in volViews:
		var colour: Color = Color(1,1,1,0.5)
		if i == curChanging: 
			colour = Color(1,1,1,1)
		
		tween.interpolate_property(meter.get_parent(), "modulate",
			volViews[i].get_parent().modulate, colour, 0.2,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		tween.start()
		i += 1

func changeChannelViaMouseover(channel) -> void:
	if self.modulate.a > 0:
		curChanging = channel
		changeChannel()

func appearanceTimeout() -> void:
	if self.modulate == Color(1,1,1,0):
		tween.interpolate_property(self, "modulate",
			Color(1,1,1,0), Color(1,1,1,1), 0.25,
			Tween.TRANS_QUART, Tween.EASE_OUT)
		tween.start()
	
	timer.start()
	yield(timer, "timeout")
	curChanging = 0

	tween.interpolate_property(self, "modulate",
			Color(1,1,1,1), Color(1,1,1,0), 1,
			Tween.TRANS_QUART, Tween.EASE_OUT)
	tween.start()
