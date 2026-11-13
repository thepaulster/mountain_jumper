extends CanvasLayer

const PIXELS_PER_METRE := 14.0
const SAVE_PATH := "user://save.cfg"

@export var player: Player

@onready var distance_label: Label = $Box/List/Distance
@onready var title_label: Label = $Box/List/Title
@onready var tricks_label: Label = $Box/List/Tricks
@onready var cowries_label: Label = $Box/List/Cowries
@onready var best_label: Label = $Box/List/Best
@onready var fly_again: Button = $Box/List/FlyAgain


func _ready() -> void:
	hide()                                  # invisible until you crash
	player.died.connect(show_results)       # when the player shouts "died", run show_results
	fly_again.pressed.connect(restart)      # when the button is clicked, run restart


func show_results() -> void:
	var metres := int(player.position.x / PIXELS_PER_METRE)
	distance_label.text = "Distance  %d m" % metres
	tricks_label.text = "Tricks  %d" % player.trick_points
	cowries_label.text = "Cowries  %d" % player.cowries
	var best := load_best()
	if metres > best:                  # beat the record?
		best = metres
		save_best(best)
		title_label.text = "NEW BEST!"
	best_label.text = "Best  %d m" % best
	show()
	fly_again.grab_focus()                  # so pressing Space/Enter also presses the button


func restart() -> void:
	get_tree().reload_current_scene()


func load_best() -> int:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:     # no save yet (first game ever)
		return 0
	var best: int = file.get_value("records", "best_distance", 0)
	return best


func save_best(metres: int) -> void:
	var file := ConfigFile.new()
	file.load(SAVE_PATH)               # keep anything else we save later
	file.set_value("records", "best_distance", metres)
	file.save(SAVE_PATH)