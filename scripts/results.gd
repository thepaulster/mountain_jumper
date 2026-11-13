extends CanvasLayer

const PIXELS_PER_METRE := 14.0

@export var player: Player

@onready var distance_label: Label = $Box/List/Distance
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
	show()
	fly_again.grab_focus()                  # so pressing Space/Enter also presses the button


func restart() -> void:
	get_tree().reload_current_scene()