extends Node

const SAVE_PATH := "user://save.cfg"

var best_distance := 0          # later: total cowries, unlocked suits, settings…
var sound_on := true

func _ready() -> void:
	load_game()                 # read the notebook as soon as the game opens
	apply_sound()


func load_game() -> void:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:      # no notebook yet = first time playing
		return
	best_distance = file.get_value("records", "best_distance", 0)
	sound_on = file.get_value("settings", "sound_on", true)
	sound_on = file.get_value("settings", "sound_on", true)


func save_game() -> void:
	var file := ConfigFile.new()
	file.set_value("records", "best_distance", best_distance)
	file.set_value("settings", "sound_on", sound_on)
	file.save(SAVE_PATH)

func apply_sound() -> void:
	AudioServer.set_bus_mute(0, not sound_on)    # bus 0 = "Master", every sound goes through it