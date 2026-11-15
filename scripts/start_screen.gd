extends CanvasLayer

@export var player: Player

@onready var list: VBoxContainer = $List
@onready var hint: Label = $List/Hint
@onready var best_label: Label = $List/Best

var pulse_tween: Tween


func _ready() -> void:
	if player == null:
		push_error("StartScreen: drag the Player node into the Player box in main.tscn")
		return

	if SaveData.best_distance > 0:
		best_label.text = "Best  %d m" % SaveData.best_distance
	else:
		best_label.hide()               # very first game: no best yet

	player.jumped.connect(leave)        # when the player jumps, run leave

	# Make the hint gently fade in and out, forever
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(hint, "modulate:a", 0.35, 0.7)
	pulse_tween.tween_property(hint, "modulate:a", 1.0, 0.7)


func leave() -> void:
	pulse_tween.kill()
	var tween := create_tween().set_parallel(true)
	# slide left, speeding up, like scenery you're flying past
	tween.tween_property(list, "position:x", list.position.x - 1400, 1.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(list, "modulate:a", 0.0, 1.2).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(hide)   # after both finish, hide the screen