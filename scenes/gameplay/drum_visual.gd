extends TextureRect

## Comment
var _l_don_tween := SceneTreeTween.new()

## Comment
var _l_kat_tween := SceneTreeTween.new()

## Comment
var _r_don_tween := SceneTreeTween.new()

## Comment
var _r_kat_tween := SceneTreeTween.new()

onready var root_viewport := $"/root" as Root
onready var combo_break_aud := $ComboBreakAudio as AudioStreamPlayer
onready var f_don_aud := $FinisherDonAudio as AudioStreamPlayer
onready var f_kat_aud := $FinisherKatAudio as AudioStreamPlayer
onready var l_don_aud := $LeftDonAudio as AudioStreamPlayer
onready var l_kat_aud := $LeftKatAudio as AudioStreamPlayer
onready var r_don_aud := $RightDonAudio as AudioStreamPlayer
onready var r_kat_aud := $RightKatAudio as AudioStreamPlayer
onready var l_don_obj := $LeftDon as TextureRect
onready var l_kat_obj := $LeftKat as TextureRect
onready var r_don_obj := $RightDon as TextureRect
onready var r_kat_obj := $RightKat as TextureRect
onready var combo_label := $Combo as Label


func _ready() -> void:
	add_to_group("Skinnables")
	apply_skin()
	l_don_obj.modulate.a = 0
	l_kat_obj.modulate.a = 0
	r_don_obj.modulate.a = 0
	r_kat_obj.modulate.a = 0


## Applies the [member root_viewport]'s [SkinManager] to this [Node]. This method is seen in all [Node]s in the "Skinnables" group.
func apply_skin() -> void:
	combo_break_aud.stream = root_viewport.skin.combo_break
	f_don_aud.stream = root_viewport.skin.hit_finish
	f_kat_aud.stream = root_viewport.skin.hit_whistle
	l_don_aud.stream = root_viewport.skin.hit_normal
	l_kat_aud.stream = root_viewport.skin.hit_clap
	r_don_aud.stream = root_viewport.skin.hit_normal
	r_kat_aud.stream = root_viewport.skin.hit_clap
	l_don_obj.texture = root_viewport.skin.don_texture
	l_kat_obj.texture = root_viewport.skin.kat_texture
	r_don_obj.texture = root_viewport.skin.don_texture
	r_kat_obj.texture = root_viewport.skin.kat_texture
	texture = root_viewport.skin.bar_left_texture


## Comment
func change_combo(combo: int) -> void:
	combo_label.text = str(combo)


## Comment
func keypress_animation(key: String) -> SceneTreeTween:
	## Comment
	var drum_obj: Node

	## Comment
	var scene_tween: SceneTreeTween

	match key:
		"LeftDon":
			drum_obj = l_don_obj
			scene_tween = _l_don_tween

		"LeftKat":
			drum_obj = l_kat_obj
			scene_tween = _l_kat_tween

		"RightDon":
			drum_obj = r_don_obj
			scene_tween = _r_don_tween

		"RightKat":
			drum_obj = r_kat_obj
			scene_tween = _r_kat_tween

		_:
			push_warning("Unknown keypress animation.")
			return scene_tween

	scene_tween = root_viewport.new_tween(scene_tween).set_ease(Tween.EASE_OUT)

	## Comment
	var _tween := scene_tween.tween_property(drum_obj, "modulate:a", 0.0, 0.2).from(1.0)

	return scene_tween


## Comment
func play_audio(key: String) -> void:
	match key:
		"ComboBreak":
			combo_break_aud.play()

		"FinisherDon":
			f_don_aud.play()

		"FinisherKat":
			f_kat_aud.play()

		"LeftDon":
			l_don_aud.play()

		"LeftKat":
			l_kat_aud.play()

		"RightDon":
			r_don_aud.play()

		"RightKat":
			r_kat_aud.play()
