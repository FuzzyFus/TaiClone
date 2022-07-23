extends Node

onready var lDonObj = get_node("../BarLeft/DrumVisual/LeftDon")
onready var rDonObj = get_node("../BarLeft/DrumVisual/RightDon")
onready var lKatObj = get_node("../BarLeft/DrumVisual/LeftKat")
onready var rKatObj = get_node("../BarLeft/DrumVisual/RightKat")

onready var lDonAud = get_node("LeftDonAudio")
onready var rDonAud = get_node("RightDonAudio")
onready var rKatAud = get_node("RightKatAudio")
onready var lKatAud = get_node("LeftKatAudio")

onready var accurateObj = get_node("../BarRight/HitPointOffset/Judgements/JudgeAccurate")
onready var inaccurateObj = get_node("../BarRight/HitPointOffset/Judgements/JudgeInaccurate")
onready var missObj = get_node("../BarRight/HitPointOffset/Judgements/JudgeMiss")

onready var tween = get_node("DrumAnimationTween")

func _input(_ev) -> void:
	if Input.is_action_just_pressed("LeftDon"): 
		keypressAnimation(1)
	if Input.is_action_just_pressed("RightDon"): 
		keypressAnimation(2)
	if Input.is_action_just_pressed("LeftKat"): 
		keypressAnimation(3)
	if Input.is_action_just_pressed("RightKat"): 
		keypressAnimation(4)

func keypressAnimation(key) -> void:
	var obj
	match key:
		1: 
			obj = lDonObj
			lDonAud.play()
		2: 
			obj = rDonObj 
			rDonAud.play()
		3: 
			obj = lKatObj
			lKatAud.play()
		4:
			obj = rKatObj
			rKatAud.play()
	
	tween.interpolate_property(obj, "self_modulate",
		Color(1,1,1,1), Color(1,1,1,0), 0.2,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()

func hitNotifyAnimation(type) -> void:
	var obj
	match type:
		"accurate":   obj = accurateObj
		"inaccurate": obj = inaccurateObj
		"miss":       obj = missObj

	tween.interpolate_property(obj, "self_modulate",
		Color(1,1,1,1), Color(1,1,1,0), 0.4,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
