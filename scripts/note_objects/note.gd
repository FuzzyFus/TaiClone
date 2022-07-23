extends KinematicBody2D

export var timing = 0
export var speed = 1

export var finisher = true
export var isKat = false
export var active = false

var vel: Vector2

func _process(_delta) -> void:
	# move note if not hit yet
	if active: vel = move_and_slide(Vector2((speed * -1.9), 0))

func changeProperties(newTiming, newSpeed, newIsKat, newFinisher):
	timing = newTiming
	speed = newSpeed
	
	#finisher scale
	finisher = newFinisher
	if(finisher): get_child(0).rect_scale = Vector2(0.9,0.9)
	
	#note colour
	if (newIsKat == 1): isKat = true
	else: isKat = false
	if(isKat): get_child(0).self_modulate = skin.KatColour
	else:      get_child(0).self_modulate = skin.DonColour

func activate() -> void:
	modulate = Color(1,1,1,1)
	position = Vector2(timing * speed, 0)
	active = true

func deactivate() -> void:
	modulate = Color(0,0,0,0)
	active = false
