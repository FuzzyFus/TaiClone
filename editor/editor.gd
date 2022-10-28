extends Control

onready var root_viewport := $"/root" as Root
onready var load_file = $LoadFile as LoadFile
onready var ex_timeline := $Timeline/Ex as Node
onready var timeline := $Timeline/Container/Timeline as Slider
onready var timestamp := $Timeline/Container/Timestamp as Label
onready var debugText := $Debug as Label
onready var metadata := $Metadata as Metadata

onready var obj_container := $Main/Display/HitPoint/ObjectContainer
onready var hit_point := $Main/Display/HitPoint as Control
onready var bar_right := $Main/Display as Control
onready var placer_obj := $Main/Display/HitPoint/Placer as Placer

onready var select_shader : ShaderMaterial

onready var tglkat_tex : Texture
onready var tgldon_tex : Texture
onready var tglfin_on_tex : Texture
onready var tglfin_off_tex : Texture

onready var tglkat_but := $Tools/GridContainer/ToggleKat as Button
onready var tglfin_but := $Tools/GridContainer/ToggleFinisher as Button

onready var tools := $Tools as WindowDialog

onready var save_file := $SaveFile as SaveFile
onready var file_dialog := $FileDialog as FileDialog

var holding_ctrl := false
var holding_shift := false
var current_finisher := false
var current_kat := false

var currently_selected = []

var current_snapping := 4

var currentTool := 0
var cur_time := 0.0
var cur_music_speed := 1.0
var start_time := 0.0

var last_fd_id := -1

var using_constant_sv := true

var interactingWithTimeline := false
var ex_timeline_flip := false

const DEFAULT_VELOCITY := 1750.0
var current_velocity := 1.0

func _init() -> void:
	select_shader = load("res://editor/select_matt.tres") as ShaderMaterial
	tglkat_tex = load("res://temporary/editor/togglekat.png")
	tgldon_tex = load("res://temporary/editor/toggledon.png")
	tglfin_on_tex = load("res://temporary/editor/togglefinisher_on.png")
	tglfin_off_tex = load("res://temporary/editor/togglefinisher_off.png")

func _ready() -> void:
	load_file.loadChart("E:/Games/osu!/Songs/1383022 Toze - Incendiary/Toze - Incendiary (TaiCloneConverter) [Burning].fus")
	print('a')

func _process(_delta: float) -> void:
	# change debug text
	
	debugText.text = "currentTool: " + String(currentTool)
	debugText.text += "\n" + "FPS: %s" % Engine.get_frames_per_second()
	debugText.text += "\n" + "current_snapping: %s" % current_snapping
	if currently_selected.size() != 0:
		debugText.text += "\ncurrent note time: " + String(currently_selected[0].timing) + ", " + String(currently_selected[0].rect_position.x)
	
	# change placer
	var mouse_pos := get_viewport().get_mouse_position().x
	var raw_pos := mouse_pos - hit_point.rect_position.x - (hit_point.rect_size.x / 2)
	
	var new_timing := 0.0
	if using_constant_sv:
		new_timing = cur_time + (raw_pos / current_velocity / DEFAULT_VELOCITY)
	else:
		var tracking_speed := 0.0
		for i in range(obj_container.get_child_count() - 1, -1, -1):
			var hit_object := obj_container.get_child(i) as HitObject
			if hit_object.rect_position.x > raw_pos:
				break
			tracking_speed = hit_object.speed
		new_timing = cur_time + (raw_pos / tracking_speed)

	var timing_info = get_timing_info(new_timing)
	var snapped_timing := 0.0
	if current_snapping > 0:
		var snapped_beat = round((new_timing - timing_info[1]) * timing_info[0] * current_snapping / 60) / current_snapping

		snapped_timing = snapped_beat * 60 / timing_info[0] if timing_info[0] else 0.0
		placer_obj.rect_position.x = (snapped_timing - cur_time + timing_info[1]) * timing_info[2] - 1
	else:
		snapped_timing = new_timing
		placer_obj.rect_position.x = raw_pos
	
	# if using_constant_sv:
	# 	placer_position = (snapped_timing - cur_time + timing_info[1]) * DEFAULT_VELOCITY * current_velocity - 1
	# else:

	# move notes

	if not root_viewport.music.playing:
		return
	
	cur_time = ((Time.get_ticks_usec() / 1000.0 - root_viewport.global_offset) / 1000 - start_time) * cur_music_speed
	
	if not interactingWithTimeline:
		if root_viewport.music.stream.get_length():
			timeline.value = root_viewport.music.get_playback_position() * 100.0 / root_viewport.music.stream.get_length()
		
		#timestamp schenanigans
		var mils = fmod(cur_time,1)*1000
		var secs = fmod(cur_time,60)
		var mins = fmod(cur_time, 60*60) / 60
		timestamp.text = "%02d:%02d:%03d" % [mins,secs,mils]
	
	updateNotes()

func timelineDrag(_dummy, isDragging) -> void:
	if isDragging == false:
		changeCurrentTime()
	interactingWithTimeline = isDragging

func changeTool(newTool) -> void:
	if newTool >= 0:
		if newTool != 0:
			placer_obj.self_modulate.a = 0.5
		else:
			placer_obj.self_modulate.a = 0
		currentTool = newTool;
	else:
		match newTool:
			-1:
				current_kat = !current_kat
				if current_kat:
					tglkat_but.icon = tglkat_tex 
				else:
					tglkat_but.icon = tgldon_tex 
			-2:
				current_finisher = !current_finisher
				if current_finisher:
					tglfin_but.icon = tglfin_on_tex 
				else:
					tglfin_but.icon = tglfin_off_tex
		placer_obj.change_display(current_kat, current_finisher)

func changeExtimelineFlip() -> void:
	ex_timeline_flip = not ex_timeline_flip
	
	(ex_timeline.get_child(int(ex_timeline_flip))as CanvasItem).visible = true
	(ex_timeline.get_child(int(!ex_timeline_flip))as CanvasItem).visible = false

func changeCurrentTime() -> void:
	if timeline.value == 100.0:
		root_viewport.music.stop()
	else:
		cur_time = root_viewport.music.stream.get_length() * timeline.value / 100.0
		root_viewport.music.seek(cur_time)
	start_time = (Time.get_ticks_usec() / 1000000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()) - cur_time
	updateNotes()

func updateNotes(velocity: float = -1.0) -> void:
	for i in range(obj_container.get_child_count() - 1, -1, -1):
		var hit_object := obj_container.get_child(i) as HitObject
		if velocity >= 0:
			hit_object.speed = DEFAULT_VELOCITY * velocity
		hit_object.move(bar_right.rect_size.x, cur_time)

func playPause() -> void:
	if root_viewport.music.playing:
		root_viewport.music.stop()
		return
	start_time = (Time.get_ticks_usec() / 1000000.0 + AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()) - cur_time
	root_viewport.music.play(cur_time)

func stopMusic() -> void:
	root_viewport.music.stop()
	cur_time = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		## Comment
		var k_event := event as InputEventKey
		
		# pause/play
		if k_event.pressed and k_event.scancode == KEY_SPACE:
			playPause()
		# change tool: select
		if k_event.pressed and k_event.scancode == KEY_1:
			changeTool(0)
		# change tool: note
		if k_event.pressed and k_event.scancode == KEY_2:
			changeTool(1)
		# change tool: roll
		if k_event.pressed and k_event.scancode == KEY_3:
			changeTool(2)
		# change tool: spinner
		if k_event.pressed and k_event.scancode == KEY_4:
			changeTool(3)
			
		# change type: kat
		if k_event.pressed and k_event.scancode == KEY_W or k_event.scancode == KEY_R:
			# if editing objects...
			if currently_selected.size() != 0:
				var changingto := true

				# check if first note selected is/isnt kat
				if currently_selected[0].is_in_group("Note"):
					var first_select_obj: Note = currently_selected[0]
					changingto = !first_select_obj._is_kat

				for selection in currently_selected:
					if selection.is_in_group("Note"):
						selection.change_display(changingto, selection.finisher)
			else:
				changeTool(-1)

			
		# change type: finisher
		if k_event.pressed and k_event.scancode == KEY_E:
			if currently_selected.size() != 0:
				var changingto := true

				# check if first note selected is/isnt kat
				if currently_selected[0].is_in_group("Note"):
					var first_select_obj: Note = currently_selected[0]
					print("changing to from true to ", !first_select_obj.finisher)
					changingto = !first_select_obj.finisher

				for selection in currently_selected:
					if selection.is_in_group("Note"):
						selection.change_display(selection._is_kat, changingto)
						selection.move(bar_right.rect_size.x, cur_time)
			else:
				changeTool(-2)

		# delete notes
		if k_event.pressed and k_event.scancode == KEY_DELETE:
			if currently_selected.size() != 0:
				while currently_selected.size() > 0:
					for obj in currently_selected:
						#has to be separate bc of godot sillyness
						currently_selected.erase(obj)
						obj.queue_free()

		# ctrl toggle
		if k_event.pressed and k_event.scancode == KEY_CONTROL:
			holding_ctrl = true
		if not k_event.pressed and k_event.scancode == KEY_CONTROL:
			holding_ctrl = false
		# shift toggle
		if k_event.pressed and k_event.scancode == KEY_SHIFT:
			holding_shift = true
		if not k_event.pressed and k_event.scancode == KEY_SHIFT:
			holding_shift = false

func _input(event) -> void:
	if event is InputEventMouseButton and currentTool != 0:
		if event.pressed and event.button_index == 1:
			var mouse_pos := get_viewport().get_mouse_position().x
			var raw_pos := mouse_pos - hit_point.rect_position.x

			# the timing of the new theoretical note
			var new_timing := cur_time + (raw_pos / current_velocity / DEFAULT_VELOCITY)

			var timing_info = get_timing_info(new_timing)
			var snapped_timing := 0.0
			if current_snapping > 0:
				var snapped_beat = round((new_timing - timing_info[1]) * timing_info[0] * current_snapping / 60) / current_snapping
				
				snapped_timing = snapped_beat * 60 / timing_info[0] if timing_info[0] else 0.0
			else:
				snapped_timing = new_timing

			# spawn note
			var hit_object := root_viewport.note_object.instance() as Note
			hit_object.change_properties(snapped_timing, DEFAULT_VELOCITY, current_kat, current_finisher)
			load_file.add_object(hit_object, false)
			hit_object.move(bar_right.rect_size.x, cur_time)

	
	if holding_ctrl:
		if event.is_action_pressed("SnappingUp") and current_snapping < 46:
			current_snapping += 1
		elif event.is_action_pressed("SnappingDown") and current_snapping > 0:
			current_snapping -= 1

func topOptionSelected(id, type):
	match type:
		"file":
			match id:
				0:
					file_dialog.mode = file_dialog.MODE_SAVE_FILE
					file_dialog.popup()
				1:
					file_dialog.mode = file_dialog.MODE_OPEN_FILE
					file_dialog.popup()
				3:
					save_file.save_map()
		"view":
			match id:
				0:
					tools.visible = true
				2:
					metadata.visible = true
	
	last_fd_id = id	

func change_editor_speed(factor: float) -> void:
	if not using_constant_sv:
		return
	if factor == 0:
		current_velocity = 1
	else:
		current_velocity += factor
	updateNotes(current_velocity)
	
func change_playfield_view(is_constant: bool) -> void:
	using_constant_sv = is_constant
	for i in range(obj_container.get_child_count() - 1, -1, -1):
		## Comment
		var hit_object := obj_container.get_child(i) as HitObject


		if is_constant:
			hit_object.speed = DEFAULT_VELOCITY * current_velocity
		else:
			hit_object.speed = hit_object.actual_speed

		hit_object.move(bar_right.rect_size.x, cur_time)
	
	var width := hit_point.rect_size.x
	if is_constant:
		hit_point.anchor_left = 0.5
		hit_point.anchor_right = 0.5
		hit_point.margin_left = -width / 2
	else:
		hit_point.anchor_left = 0
		hit_point.anchor_right = 0
		hit_point.margin_left = 300
	hit_point.margin_right = hit_point.margin_left + width

func moused_over_object(event: InputEvent, obj: TextureRect) ->  void:
	## deals with selecting objects
	
	# make sure its a mouse input
	if event is InputEventMouseButton and currentTool == 0:
		if event.is_pressed():
			print("MOUSE ", obj.name, " ", event)
			
			if not holding_ctrl:
				var was_selected: bool = currently_selected.has(obj) and currently_selected.size() == 1
				while currently_selected.size() != 0:
					remove_object(currently_selected[0])
				if was_selected:
					return

			elif currently_selected.has(obj):
				remove_object(obj)
				return

			obj.material = select_shader
			currently_selected.append(obj)

func change_object(initial_obj: Node, change: Array) -> void:
	var group = initial_obj.get_groups()[0]
	var obj
	#make sure its one of the valid groups and reassign it accordingly
	match group:
		"Note":
			obj = initial_obj as Note
			if change[0] == "kat":
				obj.change_display(change[1], obj.finisher)
			if change[0] == "finisher":
				obj.change_display(obj._is_kat, change[1])
			pass
		"Roll":
			obj = initial_obj as Roll
			pass
		"SpinnerWarn":
			pass
		_:
			return

func change_speed(new_speed: float) -> void:
	root_viewport.music.pitch_scale = new_speed
	cur_music_speed = new_speed

func remove_object(obj: Control) -> void:
	obj.material = null
	currently_selected.erase(obj)

func get_timing_info(time: float) -> Array:
	var cur_bpm := -1.0
	var cur_bpm_timing := -1.0
	var cur_speed := -1.0
	for i in range(obj_container.get_child_count() - 1, -1, -1):
		var hit_obj: HitObject = obj_container.get_child(i)
		if hit_obj.timing <= time or cur_bpm == -1.0:
			cur_speed = hit_obj.speed
			if hit_obj.is_in_group("TimingPoint"):
				cur_bpm = hit_obj.bpm
				cur_bpm_timing = hit_obj.timing
		else:
			break
	return [cur_bpm, cur_bpm_timing, cur_speed]

func file_dialog_used(file_path):
	match last_fd_id:
		0: # new file
			return
		1: # load file
			load_file.loadChart(file_path)


func edit_metadata(new_text, extra_arg_0):
	pass # Replace with function body.
