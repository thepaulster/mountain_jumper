extends CanvasLayer

# The flyer whose numbers we show. Plug it in from the Inspector.
@export var player: Player

# 14 pixels in the game = 1 metre in real life.
const PIXELS_PER_METRE := 14.0

# Furthest we've got this run. Only ever goes up,
# so looping backwards doesn't make the number shrink.
var distance := 0.0

# Grab the two labels when the scene starts.
# $Distance means "my child node called Distance".
@onready var distance_label: Label = $Distance
@onready var speed_label: Label = $Speed
@onready var score_label: Label = $Score
@onready var prox_label: Label = $Prox


func _process(_delta: float) -> void:
	if player == null:
		return

	# Distance: how far right of the ledge we are, in metres.
	var metres := player.position.x / PIXELS_PER_METRE
	distance = maxf(distance, metres)
	distance_label.text = "%d m" % int(distance)

	# Speed: only while actually flying. Standing, falling or crashed shows 0.
	var kmh := 0
	if player.mode == Player.Mode.FLY and not player.crashed:
		kmh = int(player.speed / PIXELS_PER_METRE * 3.6)
	speed_label.text = "%d km/h" % kmh


	# Score: one point per metre, plus banked points, plus whatever is pending right now.
	var score := int(distance) + player.trick_points + int(player.prox_pending)
	score_label.text = "%d pts" % score

	# While skimming the rock, show how long and how much.
	if player.prox_time > 0.2:
		prox_label.text = "PROXIMITY %.1f s   +%d" % [player.prox_time, int(player.prox_pending)]
	else:
		prox_label.text = ""