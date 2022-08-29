class_name SpinnerWarn
extends HitObject

## Comment
signal object_added(obj, loaded)

## The BPM of the chart when the [Spinner] starts. Used to determine the number of hits required.
var _bpm := 1.0


## Initialize [SpinnerWarn] variables.
func change_properties(new_timing: float, new_speed: float, new_length: float, new_bpm: float) -> void:
	.ini(new_timing, new_speed, new_length)
	_bpm = new_bpm
	end_time = timing


## See [HitObject].
func miss_check(hit_time: float) -> bool:
	if hit_time <= timing:
		return true

	if state != int(State.FINISHED):
		state = int(State.FINISHED)

		## The [Spinner] object to spawn.
		var spinner := preload("res://scenes/gameplay/spinner.tscn").instance() as Spinner

		spinner.change_properties(timing, length, int(length * 960 / _bpm))
		emit_signal("object_added", spinner, false)
		queue_free()

	return false
