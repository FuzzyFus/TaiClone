extends Node

onready var countText = get_node("Label")
onready var spinCircRot = get_node("RotationObj")
onready var tween = get_node("Tween")
onready var hitManager = get_node("../../../../../HitManager")

export var timing: float = 0
export var length: float = 5

export var neededHits: int = 0
var curHitCount: int = 0
var nextHitIsKat: bool = false

var currentSpeed: float = 0
var finished: bool = false
var loaded:bool = false

onready var approach = get_node("Approach")

func changeProperties(newTiming, newHits, newLength):
	timing = newTiming
	neededHits = newHits
	length = newLength
	
	#set counter text to say how many hits are needed
	countText.text = str(neededHits)
	
	#make approach circle shrink
	tween.interpolate_property(approach, "rect_scale",
		Vector2(1,1), Vector2(0.1,0.1), length,
		Tween.TRANS_LINEAR, Tween.EASE_OUT)
	tween.start()
	
	#make spinner fade in
	tween.interpolate_property(self, "modulate",
		Color(1,1,1,0), Color(1,1,1,1), 0.25,
		Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.start()
	loaded = true

func _process(_delta) -> void:
	if(loaded):
		if (curHitCount == neededHits && !finished): 
			finished = true
			spinnerFinished()
		if (get_node("../../../../../Music").get_playback_position() > (length + timing) && !finished):
			finished = true
			spinnerFinished()
		spinCircRot.rotation_degrees += currentSpeed

#this feels dumb.
func _input(_ev) -> void:
	if (neededHits > curHitCount):
		var thisHit = null;
		if Input.is_action_just_pressed("LeftDon") || Input.is_action_just_pressed("RightDon"): thisHit = false
		if Input.is_action_just_pressed("LeftKat") || Input.is_action_just_pressed("RightKat"): thisHit = true
		
		match thisHit:
			false:
				if (!nextHitIsKat): hitSuccess();
			true:
				if (nextHitIsKat): hitSuccess();
			_: return;

func hitSuccess():
	curHitCount += 1;
	nextHitIsKat = !nextHitIsKat;
	countText.text = str(neededHits - curHitCount)
	hitManager.addScore("spinner")
	
	tween.interpolate_property(self, "currentSpeed",
	3, 0, 1,
	Tween.TRANS_CIRC, Tween.EASE_OUT)
	tween.start()

func spinnerFinished():
	if (neededHits <= curHitCount):
		hitManager.addScore("accurate")
		
		#ik its silly but gets rid of errors
	elif (int(float(neededHits) / 2 ) <= curHitCount):
		hitManager.addScore("inaccurate")
	else:
		hitManager.addScore("miss")
	
	#make spinner fade out
	tween.interpolate_property(self, "modulate",
		Color(1,1,1,1), Color(1,1,1,0), 0.25,
		Tween.TRANS_EXPO, Tween.EASE_OUT)
	tween.connect("tween_completed", self, "deleteSelf")
	tween.start()

func deactivate():
	deleteSelf(1, 1)
func activate():
	deleteSelf(1, 1)

func deleteSelf(_a, _b):
	queue_free()
