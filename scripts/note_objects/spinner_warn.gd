extends KinematicBody2D

onready var spinnerObj = preload("res://game/objects/spinner_object.tscn")

export var timing = 0
export var speed = 1
export var length = 1

export var active = false

var vel: Vector2

func _process(_delta) -> void:
	# move note if not hit yet
	if(active == true): 
		vel = move_and_slide(Vector2((speed * -1.9), 0))
		if (get_node("../../../../../Music").get_playback_position() >= timing):
			deactivate()

func changeProperties(newTiming, newSpeed, newLength):
	timing = newTiming
	speed = newSpeed
	length = newLength

func activate() -> void:
	modulate = Color(1,1,1,1)
	position = Vector2(timing * speed, 0)
	active = true

func deactivate() -> void:
	#make spinner obj first
	var spinner = spinnerObj.instance()
	#note to self; couldnt i just give the cur sv timing from the chart loader? seems redundant to do this and
	#possibly more laggy honestly
	var chartSV = get_node("../../../../../ChartLoader").findTiming(timing)
	var hitsRequired = floor(length / ((chartSV[0] / 60)) * 16)
	get_parent().add_child(spinner)
	get_parent().move_child(spinner, 0)
	spinner.changeProperties(timing, hitsRequired, length)
	
	#make self deactive (duh!)
	modulate = Color(0,0,0,0)
	active = false
