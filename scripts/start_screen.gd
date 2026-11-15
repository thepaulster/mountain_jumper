extends CanvasLayer

@export var player: Player

@onready var panel: PanelContainer = $Panel
@onready var best_label: Label = $Panel/List/Best
@onready var hint: Label = $Panel/List/Hint

var pulse_tween: Tween


func _ready() -> void:
	if player == null:
		push_error("StartScreen: drag the Player node into the Player box in main.tscn")
		return

	if SaveData.best_distance > 0:
		best_label.text = "Best flight  %d m" % SaveData.best_distance
	else:
		best_label.text = "First flight. Good luck!"

	player.jumped.connect(leave)

	# the hint gently breathes so your eye finds it
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(hint, "modulate:a", 0.35, 0.7)
	pulse_tween.tween_property(hint, "modulate:a", 1.0, 0.7)


func leave() -> void:
	pulse_tween.kill()
	var tween := create_tween().set_parallel(true)
	# slide off to the right, speeding up
	tween.tween_property(panel, "position:x", panel.position.x + 520, 0.6) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(hide)