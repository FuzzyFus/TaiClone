extends KinematicBody2D

onready var hitManager = get_node("../../../../../HitManager")

export var timing = 0
export var speed = 1
export var length = 1

export var finisher = true
export var active = false

var totalTicks: int = 0
var currentTick: int = 0
var tickDistance: float = 0

var curSongTime: float = 0

var vel: Vector2

#will need to be cleaned, some values arent used other than this func so i should get rid
#of the "new" part of it
func changeProperties(newTiming, newSpeed, newFinisher, newLength, beatlength):
	timing = newTiming
	speed = newSpeed
	length = newLength
	
	#finisher scale
	finisher = newFinisher
	if(finisher): get_child(0).rect_scale = Vector2(0.9,0.9)
	
	#note colour
	get_node("Scale/Head").self_modulate = skin.RollColour
	get_node("Scale/Body").modulate = skin.RollColour
	
	get_node("Scale/Body").rect_size = Vector2(speed * length, 129)
	
	tickDistance = beatlength / 100
	
	totalTicks = floor(length / tickDistance * 48.0)
	#length of the roll divided by the distance between ticks
	#and multiplied by the frequency
	
	#haha funny !!! idx like iidx as in funny beatmania silly game keys
	# but its alos like INDEX!!!!!!!!!!!!!!!
	#GET IT
	for tickIdx in totalTicks:
		#duplicate base tick and put it on the tick container
		var newTick = get_child(1).duplicate() 
		get_node("TickContainer").add_child(newTick)
		get_node("TickContainer").move_child(newTick, get_node("TickContainer").get_child_count())
		
		#newTick.rect_position = Vector2( (tickIdx * (tickDistance * 4)) * (speed / 1000) * 40, -64.5)
		newTick.rect_position = Vector2( tickIdx * (tickDistance / 40) * speed , -64.5)
		#(the number of tick * (tick distance * time signature)) * (note speed / 1000) * (time signature * 10)

func _input(_ev) -> void:
	if (totalTicks > currentTick && active):
		#lol
		if Input.is_action_just_pressed("LeftDon") || Input.is_action_just_pressed("RightDon") || Input.is_action_just_pressed("LeftKat") || Input.is_action_just_pressed("RightKat"):
			
			if curSongTime > timing + length + hitManager.inaccTiming: #if after slider is hittable
				active = false
			elif curSongTime < timing - hitManager.inaccTiming: #if before slider is hittable
				pass
			
			else:
				#get current tick target
				currentTick = floor((curSongTime - timing) * (tickDistance * 4))
				if currentTick < 0: currentTick = 0
				elif currentTick > totalTicks: currentTick = totalTicks
				
				if(get_node("TickContainer").get_child_count() - 1 < currentTick): currentTick = get_node("TickContainer").get_child_count() - 1
				if get_node("TickContainer").get_child(currentTick).visible:
					print(currentTick)
					get_node("TickContainer").get_child(currentTick).set_visible(false)
					hitManager.addScore("roll")

func _process(_delta):
	if active: vel = move_and_slide(Vector2((speed * -1.9), 0))
	#this feels dumb too idk...
	curSongTime = get_node("../../../../../Music").get_playback_position()

func activate():
	position = Vector2(timing * speed, 0)
	for tick in get_node("TickContainer").get_children():
		tick.set_visible(true)
	active = true
	
func deactivate():
	active = false
