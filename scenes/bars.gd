extends Scene

onready var bottom := $Bottom
onready var charter_name := $Top/V/Bottom/CharterName as Label
onready var difficulty_name_label := $Top/V/Bottom/DifficultyName as Label
onready var play_date := $Top/V/Bottom/PlayDate as Label
onready var root_viewport := $"/root" as Root
onready var song_name := $Top/V/Top/SongName as Label
onready var top := $Top


func _ready() -> void:
	charter_name.text = root_viewport.charter
	difficulty_name_label.text = root_viewport.difficulty_name
	play_date.text = Time.get_datetime_string_from_system(false, true)
	song_name.text = "%s - %s" % [root_viewport.artist, root_viewport.title]

	## Comment
	var position_tween := root_viewport.new_tween(SceneTreeTween.new()).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT).set_parallel()

	## Comment
	var _top_tween := position_tween.tween_property(top, "rect_position:y", 0.0, 1).from(-100.0)

	## Comment
	var _bottom_tween := position_tween.tween_property(bottom, "rect_position:y", 980.0, 1).from(1080.0)


func back_button_pressed() -> void:
	root_viewport.add_blackout(root_viewport.gameplay)
