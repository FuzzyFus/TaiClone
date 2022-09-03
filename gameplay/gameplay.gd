class_name Gameplay
extends Scene

## Signals DrumVisual when a sound should be played.
signal audio_played(key)

## Comment
signal combo_changed(combo)

## Comment
signal key_pressed(key)

## Comment
signal marker_added(type, timing, indicate)

## Comment
var _auto := false

## Comment
var _auto_left := true

## Comment
var _cur_time := 0.0

## Comment
var _current_combo := 0

## Comment
var _f := File.new()

## Comment
var _inactive := true

## Comment
var _judgement_tween := SceneTreeTween.new()

## the time for the last note in the chart
var _last_note_time := -1.0

## Comment
var _score_indicator_tween := SceneTreeTween.new()

## Comment
var _time_begin := 0.0

## Comment
var _timing_indicator_tween := SceneTreeTween.new()

onready var bar_right := $BarRight as TextureRect
onready var debug_text := $Debug/DebugText as Label
onready var drum_visual := $BarRight/DrumVisual
onready var fpstext := $Debug/TempLoadChart/Text/FPS as Label
onready var hit_point := $BarRight/HitPointOffset/HitPoint as TextureRect
onready var hit_point_rim := $BarRight/HitPointOffset/HitPoint/Rim as TextureRect
onready var judgement := $BarRight/HitPointOffset/Judgement as TextureRect
onready var last_hit_score := $UI/LastHitScore as Label
onready var line_edit := $Debug/TempLoadChart/LineEdit as LineEdit
onready var obj_container := $BarRight/HitPointOffset/ObjectContainer as Control
onready var play_button := $Debug/TempLoadChart/PlayButton as Button
onready var root_viewport := $"/root" as Root
onready var song_progress := $UI/SongProgress as ProgressBar
onready var timing_indicator := $BarRight/HitPointOffset/TimingIndicator as Label
onready var ui_accuracy := $UI/Accuracy/Label as Label
onready var ui_score := $UI/Score as Label


func _ready() -> void:
	Root.send_signal(self, "late_early_changed", root_viewport, "change_late_early")
	change_late_early()
	bar_right.texture = root_viewport.skin.bar_right_texture
	hit_point.texture = root_viewport.skin.big_circle
	hit_point_rim.texture = root_viewport.skin.approach_circle
	last_hit_score.modulate.a = 0
	root_viewport.music.stop()
	_reset()

	## Comment
	var _bars_removed := root_viewport.remove_scene("Bars")

	# dev autoload map
	if _f.file_exists(ChartLoader.FUS):
		load_func(ChartLoader.FUS)


func _process(_delta: float) -> void:
	fpstext.text = "FPS: %s" % Engine.get_frames_per_second()
	if _inactive:
		return

	_cur_time = (Time.get_ticks_usec() - _time_begin - root_viewport.global_offset * 1000) / 1000000
	song_progress.value = _cur_time * 100 / _last_note_time
	if _cur_time > _last_note_time + 1:
		_end_chart()

	## Comment
	var check_auto := false

	## Comment
	var check_misses := true

	for i in range(obj_container.get_child_count() - 1, -1, -1):
		## Comment
		var hit_object := obj_container.get_child(i) as HitObject

		hit_object.move(_cur_time)
		if check_misses and hit_object.miss_check(_cur_time - (HitError.INACC_TIMING if hit_object is Note else 0.0)):
			check_auto = true
			check_misses = false

		if _auto and check_auto:
			## Comment
			var hit_auto := hit_object.auto_hit(_cur_time, _auto_left)

			if hit_auto == 1:
				check_auto = false

			elif hit_auto:
				_auto_left = not _auto_left


func _unhandled_input(event: InputEvent) -> void:
	## Comment
	var inputs := [2]

	for key in Root.KEYS:
		if event.is_action_pressed(str(key)):
			inputs.append(str(key))
			emit_signal("key_pressed", str(key))

	if Root.inputs_empty(inputs):
		return

	for i in range(obj_container.get_child_count() - 1, -1, -1):
		## Comment
		var hit_object := obj_container.get_child(i) as HitObject

		if hit_object.hit(inputs, _cur_time + (HitError.INACC_TIMING if hit_object is Note else 0.0)) or Root.inputs_empty(inputs):
			break

	for key in inputs:
		emit_signal("audio_played", str(key))


## Comment
func add_marker(timing: float, previous_timing: float) -> void:
	timing -= HitError.INACC_TIMING

	## Comment
	var type := int(HitObject.Score.ACCURATE if abs(timing) < HitError.ACC_TIMING else HitObject.Score.INACCURATE if abs(timing) < HitError.INACC_TIMING else HitObject.Score.MISS)

	if previous_timing < 0:
		emit_signal("marker_added", type, timing, true)
		add_score(type)
		return

	emit_signal("marker_added", type, timing, false)
	previous_timing -= HitError.INACC_TIMING
	if abs(previous_timing) < HitError.ACC_TIMING:
		root_viewport.f_accurate_count += 1

	elif abs(previous_timing) < HitError.INACC_TIMING:
		root_viewport.f_inaccurate_count += 1


## Comment
func add_object(hit_object: HitObject, loaded := true) -> void:
	obj_container.add_child(hit_object)
	for i in range(obj_container.get_child_count()):
		if hit_object.end_time > (obj_container.get_child(i) as HitObject).end_time:
			obj_container.move_child(hit_object, i)
			break

	if loaded:
		return

	hit_object.apply_skin()
	Root.send_signal(drum_visual, "audio_played", hit_object, "play_audio")
	Root.send_signal(self, "score_added", hit_object, "add_score")


## Comment
func add_score(type: int, marker := false) -> void:
	## Comment
	var play_tween := true

	## Comment
	var score_value := 300

	match type:
		-1:
			score_value = 0
			play_tween = false

		HitObject.Score.ACCURATE:
			root_viewport.accurate_count += 1
			root_viewport.max_combo += 1
			_current_combo += 1
			_hit_notify_animation()
			judgement.texture = root_viewport.skin.accurate_judgement

		HitObject.Score.INACCURATE:
			root_viewport.inaccurate_count += 1
			root_viewport.max_combo += 1
			_current_combo += 1
			score_value = 150
			_hit_notify_animation()
			judgement.texture = root_viewport.skin.inaccurate_judgement

		HitObject.Score.MISS:
			if _current_combo >= 25:
				emit_signal("audio_played", "ComboBreak")
			root_viewport.miss_count += 1
			root_viewport.max_combo += 1
			_current_combo = 0
			score_value = 0
			_hit_notify_animation()
			judgement.texture = root_viewport.skin.miss_judgement
			play_tween = false
			if marker:
				emit_signal("marker_added", type, HitError.INACC_TIMING, true)

		HitObject.Score.SPINNER:
			score_value = 600

	root_viewport.combo = int(max(root_viewport.combo, _current_combo))
	score_value = int(score_value * (1 + min(1, _current_combo / 300.0)))
	root_viewport.score += score_value
	last_hit_score.text = str(score_value)
	if play_tween:
		_score_indicator_tween = root_viewport.new_tween(_score_indicator_tween)

		## Comment
		var _tween := _score_indicator_tween.tween_property(last_hit_score, "modulate:a", 0.0, 1).from(1.0)

	## Comment
	var hit_count := root_viewport.accurate_count + root_viewport.inaccurate_count / 2.0

	emit_signal("combo_changed", _current_combo)
	ui_score.text = "%010d" % root_viewport.score
	root_viewport.accuracy = "%2.2f" % (hit_count * 100 / (root_viewport.accurate_count + root_viewport.inaccurate_count + root_viewport.miss_count) if hit_count else 0.0)
	ui_accuracy.text = root_viewport.accuracy


## Comment
func auto_toggled(new_auto: bool) -> void:
	_auto = new_auto


## Comment
func change_indicator(timing: float) -> void:
	if timing > 0:
		timing_indicator.modulate = root_viewport.skin.late_color
		timing_indicator.text = "LATE"
		root_viewport.late_count += 1

	else:
		timing_indicator.modulate = root_viewport.skin.early_color
		timing_indicator.text = "EARLY"
		root_viewport.early_count += 1

	if root_viewport.late_early_simple_display > 1:
		timing_indicator.text = "%+d" % int(timing * 1000)

	_timing_indicator_tween = root_viewport.new_tween(_timing_indicator_tween).set_trans(Tween.TRANS_QUART)

	## Comment
	var _tween := _timing_indicator_tween.tween_property(timing_indicator, "self_modulate:a", 0.0, 0.5).from(1.0)


## Comment
func change_late_early() -> void:
	timing_indicator.visible = root_viewport.late_early_simple_display > 0


## Comment
func load_func(file_path := "") -> void:
	_inactive = true
	debug_text.text = "Loading... [Checking File]"
	if not file_path:
		file_path = line_edit.text.replace("\\", "/")

	if ChartLoader.load_chart(file_path):
		_load_finish("Invalid file!")
		return

	if not file_path.ends_with(".fus"):
		file_path = ChartLoader.FUS

	debug_text.text = "Loading... [Reading File]"

	if not _f.file_exists(file_path):
		_load_finish("Invalid file!")
		return

	if _f.open(file_path, File.READ):
		_load_finish("Unable to read temporary .fus file!")
		return

	if _f.get_line() != ChartLoader.FUS_VERSION:
		_load_finish("Outdated .fus file!")
		return

	root_viewport.bg_changed(ChartLoader.texture_from_image(_f.get_line()), Color("373737"))
	root_viewport.music.stream = ChartLoader.load_audio_file(_f.get_line())
	root_viewport.artist = _f.get_line()
	root_viewport.charter = _f.get_line()
	root_viewport.difficulty_name = _f.get_line()
	root_viewport.title = _f.get_line()
	_reset()

	## Comment
	var cur_bpm := -1.0

	while _f.get_position() < _f.get_len():
		## Comment
		var line_data := _f.get_csv_line()

		## Comment
		var timing := float(line_data[0]) + root_viewport.global_offset / 1000.0

		_last_note_time = timing

		## Comment
		var total_cur_sv := float(line_data[1]) * cur_bpm * 5.7

		match int(line_data[2]):
			ChartLoader.NoteType.BARLINE:
				## Comment
				var hit_object := root_viewport.bar_line_object.instance() as BarLine

				hit_object.change_properties(timing, total_cur_sv)
				add_object(hit_object)

			ChartLoader.NoteType.DON, ChartLoader.NoteType.KAT:
				## Comment
				var hit_object := root_viewport.note_object.instance() as Note

				hit_object.change_properties(timing, total_cur_sv, int(line_data[2]) == int(ChartLoader.NoteType.KAT), bool(int(line_data[3])))
				add_object(hit_object)
				Root.send_signal(self, "new_marker_added", hit_object, "add_marker")

			ChartLoader.NoteType.ROLL:
				## Comment
				var hit_object := root_viewport.roll_object.instance() as Roll

				hit_object.change_properties(timing, total_cur_sv, float(line_data[3]), bool(int(line_data[4])), cur_bpm)
				add_object(hit_object)

			ChartLoader.NoteType.SPINNER:
				## Comment
				var hit_object := root_viewport.spinner_warn_object.instance() as SpinnerWarn

				hit_object.change_properties(timing, total_cur_sv, float(line_data[3]), cur_bpm)
				add_object(hit_object)
				Root.send_signal(self, "object_added", hit_object, "add_object")

			ChartLoader.NoteType.TIMING_POINT:
				cur_bpm = float(line_data[1])

	get_tree().call_group("HitObjects", "apply_skin")
	get_tree().call_group("HitObjects", "connect", "audio_played", drum_visual, "play_audio")
	get_tree().call_group("HitObjects", "connect", "score_added", self, "add_score")
	play_button.disabled = false
	_load_finish("Done!")


## Comment
func play_button_pressed() -> void:
	if root_viewport.music.playing:
		_end_chart()

	else:
		_reset(false)
		root_viewport.music.play()
		_time_begin += Time.get_ticks_usec() - root_viewport.global_offset * 1000 + (AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()) * 1000000
		_inactive = false


## Comment
func toggle_settings() -> void:
	if not root_viewport.remove_scene("SettingsPanel"):
		root_viewport.add_scene(root_viewport.settings_panel.instance(), name)


## Comment
func _end_chart() -> void:
	root_viewport.add_blackout(root_viewport.results)
	_inactive = true


## Comment
func _hit_notify_animation() -> void:
	_judgement_tween = root_viewport.new_tween(_judgement_tween).set_ease(Tween.EASE_OUT)

	## Comment
	var _tween := _judgement_tween.tween_property(judgement, "modulate:a", 0.0, 0.4).from(1.0)


## Comment
func _load_finish(new_text: String) -> void:
	_f.close()
	debug_text.text = new_text


## Comment
func _reset(dispose := true) -> void:
	root_viewport.accurate_count = 0
	root_viewport.early_count = 0
	root_viewport.f_accurate_count = 0
	root_viewport.f_inaccurate_count = 0
	root_viewport.inaccurate_count = 0
	root_viewport.late_count = 0
	root_viewport.max_combo = 0
	root_viewport.miss_count = 0
	root_viewport.score = 0
	_current_combo = 0
	add_score(-1)
	_cur_time = 0
	play_button.disabled = dispose
	play_button.text = "Play" if dispose else "Stop"
	get_tree().call_group("HitObjects", "queue_free" if dispose else "activate")
