class_name SkinManager

## The color of hit error markers with an ACCURATE [member HitObject.Score].
var accurate_color: Color

## The texture of a judgement with an ACCURATE [member HitObject.Score].
var accurate_judgement: Texture

## The color of [BarLine]s.
var barline_color: Color

## The color of don [Note]s.
var don_color: Color

## The color of an early timing indicator or container.
var early_color: Color

## The color of hit error markers with an INACCURATE [member HitObject.Score].
var inaccurate_color: Color

## The texture of a judgement with an INACCURATE [member HitObject.Score].
var inaccurate_judgement: Texture

## The color of kat [Note]s.
var kat_color: Color

## The color of a late timing indicator or container.
var late_color: Color

## The color of hit error markers with a MISS [member HitObject.Score].
var miss_color: Color

## The texture of a judgement with a MISS [member HitObject.Score].
var miss_judgement: Texture

## The color of [Roll]s.
var roll_color: Color


func _init() -> void:
	accurate_color = Color("52a6ff")
	barline_color = Color.white
	don_color = Color("eb452c")
	early_color = Color("ff5a5a")
	inaccurate_color = Color("79da5e")
	kat_color = Color("438eac")
	late_color = Color("5a5aff")
	miss_color = Color("c74b4b")
	roll_color = Color("fcb806")

	accurate_judgement = load("res://skins/test_skin/taiko-hit300.png") as Texture
	inaccurate_judgement = load("res://skins/test_skin/taiko-hit100.png") as Texture
	miss_judgement = load("res://skins/test_skin/taiko-hit0.png") as Texture
