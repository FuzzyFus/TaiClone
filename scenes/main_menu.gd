extends Scene

onready var root_viewport := $"/root" as Root


func _ready() -> void:
	add_to_group("Skinnables")
	apply_skin()
	root_viewport.music.stop()

	## Comment
	var _bars_removed := root_viewport.remove_scene("Bars")


## Comment
func apply_skin() -> void:
	root_viewport.bg_changed(root_viewport.skin.menu_bg)


## Comment
func exit_button_pressed() -> void:
	get_tree().quit()


## Comment
func play_button_pressed() -> void:
	root_viewport.add_blackout(root_viewport.gameplay)


## Comment
func toggle_settings() -> void:
	root_viewport.toggle_settings(name)
