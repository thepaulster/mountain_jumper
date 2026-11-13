extends Node

const SAVE_PATH := "user://save.cfg"

var best_distance := 0          # later: total cowries, unlocked suits, settings…


func _ready() -> void:
	load_game()                 # read the notebook as soon as the game opens


func load_game() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:      # no notebook yet = first time playing
		return
	best_distance = file.get_value("records", "best_distance", 0)


func save_game() -> void:
	var file := ConfigFile.new()
	file.set_value("records", "best_distance", best_distance)
	file.save(SAVE_PATH)