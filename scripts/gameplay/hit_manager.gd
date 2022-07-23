extends Node

onready var music = get_node("../Music")
onready var chart = get_node("../ChartLoader")
onready var drumInteraction = get_node("../DrumInteraction")
onready var objContainer = get_node("../BarRight/HitPointOffset/ObjectContainers")
onready var hitError = get_node("../UI/HitError")

onready var comboLabel = get_node("../BarLeft/DrumVisual/Combo")
onready var scoreLabel = get_node("../UI/Score")
onready var accuracyLabel = get_node("../UI/Accuracy")

onready var fDonAud = get_node("../DrumInteraction/FinisherDonAudio")
onready var fKatAud = get_node("../DrumInteraction/FinisherKatAudio")

var auto = false;

var accurateCount: int = 0;
var inaccurateCount: int = 0;
var missCount: int = 0;
var combo: int = 0;
var bestCombo: int = 0;
var score: int = 0;
var scoreMultiplier: float = 1;

var missTiming: float = -0.2
var inaccTiming: float = 0.145
var accTiming: float = 0.06

var nextHittableNote: int = 0;

var lastSideUsedIsRight: bool;
var lastNoteWasFinisher: bool = false;

var curTime: float = 0

func _input(_ev) -> void:
	if !auto:
		if Input.is_action_just_pressed("LeftDon"): checkInput(false, false)
		if Input.is_action_just_pressed("RightDon"): checkInput(false, true)
		if Input.is_action_just_pressed("LeftKat"): checkInput(true, false)
		if Input.is_action_just_pressed("RightKat"): checkInput(true, true)
	
func _process(_delta) -> void:
	if (nextNoteExists() && chart.curPlaying):
		curTime = chart.curTime;
		
		#temp auto
		#doesnt support special note types currently
		if (auto && ((chart.curTime + settings.globalOffset) - objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote - 1).timing) > 0):
			var nextNoteIsKat = objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote - 1).isKat
			
			if lastSideUsedIsRight == null: lastSideUsedIsRight = true
			checkInput(nextNoteIsKat, lastSideUsedIsRight)
			
			if !nextNoteIsKat:
				if lastSideUsedIsRight: #kDdk
					drumInteraction.keypressAnimation(1)
				else: #kdDk
					drumInteraction.keypressAnimation(2)
			else:
				if lastSideUsedIsRight: #Kddk
					drumInteraction.keypressAnimation(3)
				else: #kddK
					drumInteraction.keypressAnimation(4)
			lastSideUsedIsRight = !lastSideUsedIsRight
		
		#miss check
		var nextNote = objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote - 1)
		if (!auto && ((chart.curTime + settings.globalOffset) - nextNote.timing) > inaccTiming):
			hitError.newMarker("miss", curTime - nextNote.timing)
			addScore("miss")
			nextHittableNote += 1;

func checkInput(isKat, isRight) -> void:
	#finisher check
	if chart.curPlaying:
		if (lastNoteWasFinisher):
			var lastNote = objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote);
			if (abs((curTime - lastNote.timing) + settings.globalOffset)  <= accTiming && lastNote.isKat == isKat) && (lastSideUsedIsRight != isRight):
				#swallow input, give more points
				addScore("finisher")
				if isKat: fKatAud.play()
				else: fDonAud.play()
				lastNoteWasFinisher = false

		# make sure theres a note in the chart first so no errors are thrown
		if (nextNoteExists()):
			#get next hittable note and current playback position
			var nextNote = objContainer.get_node("NoteContainer").get_child(objContainer.get_node("NoteContainer").get_child_count() - nextHittableNote - 1);
			var hitType: String
			
			if (abs((curTime - nextNote.timing) + settings.globalOffset) <= inaccTiming):
				#check if accurate and right key pressed
				if (abs((curTime - nextNote.timing) + settings.globalOffset) <= accTiming && nextNote.isKat == isKat):
					hitType = "accurate"
				#check if inaccurate and right key pressed
				elif (nextNote.isKat == isKat): 
					hitType = "inaccurate"
				
				#broken for some reason, not really sure whats wrong. ill look at it later
	#			#check if inaccurate and wrong key pressed
	#			else:
	#				print("bruh")
	#				addScore("miss")
	#				nextHittableNote += 1;
				else: return
				
				addScore(hitType)
				nextHittableNote += 1;
				if hitType != "miss": nextNote.deactivate()
				
				if nextNote.finisher == true: 
					lastNoteWasFinisher = true
				
				hitError.newMarker(hitType, curTime - nextNote.timing)
			lastSideUsedIsRight = isRight

func addScore(type) -> void:
	match type:
		"accurate":
			score += int(300.0 * scoreMultiplier)
			accurateCount += 1
			combo += 1
			drumInteraction.hitNotifyAnimation("accurate");
		"inaccurate":
			score += int(150.0 * scoreMultiplier)
			inaccurateCount += 1
			combo += 1
			drumInteraction.hitNotifyAnimation("inaccurate");
		"miss":
			missCount += 1
			combo = 0
			drumInteraction.hitNotifyAnimation("miss");
		"finisher":
			score += int(300.0 * scoreMultiplier)
		"spinner":
			score += int(600.0 * scoreMultiplier)
		"roll":
			score += int(300.0 * scoreMultiplier)
		_:
			pass;
	
	var accuracy: float = 0;
	if accurateCount + (float(inaccurateCount) / 2) != 0:
		var hitCount = accurateCount + (float(inaccurateCount) / 2)
		var totalCount = accurateCount + inaccurateCount + missCount
		accuracy = float(hitCount / totalCount) * 100
		
	comboLabel.text = str(combo)
	scoreLabel.text = "%010d" % score
	accuracyLabel.text = "%2.2f" % accuracy

func nextNoteExists() -> bool:
		for subContainer in objContainer.get_children():
			if (subContainer.get_child_count() > 1):
				#throws a bunch of errors, not mandatory to change but should look into
				if (subContainer.get_child_count() - 1 >= nextHittableNote) && (objContainer.get_node("NoteContainer").get_child(nextHittableNote) != null):
					return true;
		return false;

func reset() -> void:
	accurateCount = 0
	inaccurateCount = 0
	missCount = 0
	nextHittableNote = 0
	combo = 0;
	bestCombo = 0;
	score = 0;
	scoreMultiplier = 1;
	addScore("")
