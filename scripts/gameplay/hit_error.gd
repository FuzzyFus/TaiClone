extends Control

onready var avgHit = get_node("AverageHit")
onready var middleMarker = get_node("MiddleMarker")
onready var hitPoints = get_node("HitPoints")
onready var timingIndicator = get_node("../../BarLeft/TimingIndicator")
onready var tween = get_node("../../BarLeft/TimingIndicator/Tween")

var hitPositions = []

var lateearlySimpleDisplay: bool = true

func newMarker(type, timing):
	var newMarker = middleMarker.duplicate()
	hitPoints.add_child(newMarker)
	
	var markerColour: Color;
	match type:
		"accurate": markerColour = skin.AccurateColour
		"inaccurate": markerColour = skin.InaccurateColour
		"miss": markerColour = skin.MissColour
	newMarker.modulate = markerColour;
	
	newMarker.rect_position = Vector2(timing * self.rect_size.x * 3.2 + (self.rect_size.x / 2), 0)
	
	hitPositions.push_back(newMarker.rect_position.x)
	if(hitPositions.size() > 25): hitPositions.remove(0)
	
	fadeOutMarkers()
	changeAvgHitPos()
	
	if type == "inaccurate": changeIndicator(type, timing)

func fadeOutMarkers():
	#print(hitPoints.get_child_count(), " markers")
	var i: int = 0
	for marker in hitPoints.get_children():
		if i >= 25: 
			hitPoints.get_child(0).queue_free()
		else:
			var markerAlpha: float = float(i) / 25
			hitPoints.get_child(i).self_modulate = Color(1,1,1,markerAlpha)
		i += 1

func changeAvgHitPos():
	var avg: float = 0
	for hp in hitPositions:
		avg += hp - (self.rect_size.x / 2) + 187
	avg = avg / hitPositions.size()
	
	avgHit.rect_position = Vector2(avg, 18)

func changeIndicator(type, timing):
	var val: String
	var colour: Color
	var num: int
	
	num = round(timing * 1000)
	if timing > 0:
		if lateearlySimpleDisplay: val = "LATE"
		else: val = "+" + str(num)
		colour = Color("5A5AFF")
	else:
		if lateearlySimpleDisplay: val = "EARLY"
		else: val = str(num)
		colour = Color("FF5A5A")
	
	timingIndicator.text = val
	timingIndicator.modulate = colour
	
	tween.interpolate_property(timingIndicator, "self_modulate",
		Color(1,1,1,1), Color(1,1,1,0), 0.5,
		Tween.TRANS_QUART, Tween.EASE_IN)
	tween.start()
