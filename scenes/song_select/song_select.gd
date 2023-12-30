extends Control

var listings := []
var song_listing_scene := preload("res://entites/songselect/chart_listing.tscn")

@onready var listing_container := $ListingContainer
var list_movement_tween: Tween

@export var selected_list_idx := 0

var unselected_tuck_amount := 100.0

# Called when the node enters the scene tree for the first time.
func _ready():
	refresh_listings_from_song_folders()
	update_visual()

func _unhandled_key_input(event):
	if event.is_action_pressed("LeftKat"):
		selected_list_idx = listings.size() - 1 if selected_list_idx - 1 < 0 else selected_list_idx - 1
		update_visual()
	elif event.is_action_pressed("RightKat"):
		selected_list_idx = (selected_list_idx + 1) % listings.size()
		update_visual()

func refresh_listings_from_song_folders() -> void:
	# roku note 2023-12-29
	# no matter what listings cant be fully cleared, listings.clear() doesnt work nor does below
	# it just leaves null values for some reason, which breaks menu navigation
	# see line 66 mayb
	listings = []
	for listing in listing_container.get_children():
		listing.queue_free()
	
	for chart_folder in Global.get_chart_folders():
		if !DirAccess.dir_exists_absolute(chart_folder) or chart_folder.is_empty():
			print("SongSelect: cant access chart folder at ", chart_folder)
			continue
		
		# get chart files
		var diraccess = DirAccess.open(chart_folder)
		for file_name in diraccess.get_files():
			print("file_name extention: ", file_name.get_extension())
			if Global.SUPPORTED_CHART_FILETYPES.has(file_name.get_extension()):
				var chart = ChartLoader.get_chart(ChartLoader.get_chart_path(chart_folder + "/" + file_name))
				if not listing_already_exists(chart):
					create_new_listing(chart)
	selected_list_idx = 0
	update_visual()

func create_new_listing(chart: Chart) -> void:
	var new_song_listing = song_listing_scene.instantiate()
	new_song_listing.init(chart)
	listing_container.add_child(new_song_listing)

func select_listing(listing: ChartListing) -> void:
	listings[selected_list_idx].selected = false
	selected_list_idx = listings.find(listing)
	update_visual()

func update_visual() -> void:
	var listing_size: Vector2
	var list_idx := 0
	
	for listing in listing_container.get_children():
		if not listings.has(listing) and listing != null:
			listings.append(listing)
		
		# get default position
		if !listing_size:
			listing_size = listing.size
		var default_position := Vector2(listing_size.x, listing_size.y / 2) * -1
		
		# stop any current tweens
		if listing.movement_tween:
			listing.movement_tween.kill()
		
		var new_pos := Vector2.ZERO
		new_pos.x = -listing.size.x if listings[selected_list_idx] == listing else -listing.size.x + unselected_tuck_amount
		new_pos.y = list_idx * listing.size.y
		
		listing.movement_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		listing.movement_tween.tween_property(listing, "position", new_pos, 0.2)
		
		list_idx += 1
	
	if list_movement_tween:
		list_movement_tween.kill()
	
	list_movement_tween = create_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	list_movement_tween.tween_property(
		listing_container, 
		"position", 
		Vector2(listing_container.position.x, (get_viewport_rect().size.y / 2) - (selected_list_idx * listing_size.y)), 
		0.5 )

func transition_to_gameplay() -> void:
	get_tree().get_first_node_in_group("Root").change_to_gameplay(listings[selected_list_idx].chart)

func listing_already_exists(chart: Chart) -> bool:
	for listing in listing_container.get_children():
		if listing.chart == chart:
			print("found identical chart! - ", chart)
			return true
	return false