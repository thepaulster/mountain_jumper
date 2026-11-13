extends CanvasLayer

const PIXELS_PER_METRE := 14.0
const SAVE_PATH := "user://save.cfg"
const COWRIE_VALUE := 10                 # NEW: each cowrie is worth 10 points

@export var player: Player

@onready var dim: ColorRect = $Dim                      # NEW
@onready var box: PanelContainer = $Box                 # NEW
@onready var title_label: Label = $Box/List/Title
@onready var distance_label: Label = $Box/List/Distance
@onready var tricks_label: Label = $Box/List/Tricks
@onready var cowries_label: Label = $Box/List/Cowries
@onready var total_label: Label = $Box/List/Total       # NEW
@onready var best_label: Label = $Box/List/Best
@onready var fly_again: Button = $Box/List/FlyAgain
@onready var tick: AudioStreamPlayer = $Tick


func _ready() -> void:
	if player == null:
		push_error("Results: drag the Player node into the Player box in main.tscn")
		return
	hide()
	player.died.connect(show_results)
	fly_again.pressed.connect(restart)


func show_results() -> void:
	# 1. Work out the numbers (but don't show them yet)
	var metres := int(player.position.x / PIXELS_PER_METRE)
	var tricks := int(player.trick_points)
	var cowrie_points := player.cowries * COWRIE_VALUE
	var total := metres + tricks + cowrie_points

	var best := load_best()
	var new_best := metres > best
	if new_best:
		best = metres
		save_best(best)
		title_label.text = "NEW BEST!"
	best_label.text = "Best  %d m" % best

	# Every line starts at zero
	distance_label.text = "Distance  0 m"
	tricks_label.text = "Tricks  0"
	cowries_label.text = "Cowries  0  × %d" % COWRIE_VALUE
	total_label.text = "SCORE  0"
	fly_again.disabled = true            # wait until the tally finishes

	# 2. Slide the card in
	dim.modulate.a = 0.0
	box.modulate.a = 0.0
	show()
	await get_tree().process_frame
	var final_y := box.position.y
	box.position.y += 300

	var tween := create_tween().set_parallel(true)
	tween.tween_property(dim, "modulate:a", 1.0, 0.3)
	tween.tween_property(box, "modulate:a", 1.0, 0.25)
	tween.tween_property(box, "position:y", final_y, 0.5) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished                 # wait for the card to land

	# 3. Count each line up, one after another (NEW)
	await count_up(distance_label, "Distance  %d m", metres, 0.6)
	await count_up(tricks_label, "Tricks  %d", tricks, 0.5)
	await count_up(cowries_label, "Cowries  %d  × " + str(COWRIE_VALUE), player.cowries, 0.4)
	await count_up(total_label, "SCORE  %d", total, 0.8)

	# 4. Now the button works
	fly_again.disabled = false
	fly_again.grab_focus()


func restart() -> void:
	get_tree().reload_current_scene()


func load_best() -> int:
	var file := ConfigFile.new()
	if file.load(SAVE_PATH) != OK:
		return 0
	var best: int = file.get_value("records", "best_distance", 0)
	return best


func save_best(metres: int) -> void:
	var file := ConfigFile.new()
	file.load(SAVE_PATH)
	file.set_value("records", "best_distance", metres)
	file.save(SAVE_PATH)

func count_up(label: Label, format: String, target: int, duration: float) -> void:
	if target <= 0:                      # nothing to count
		label.text = format % 0
		return
	var time := 0.0
	var next_tick := 0.0
	while time < duration:
		time += get_process_delta_time()
		var shown := int(target * minf(time / duration, 1.0))
		label.text = format % shown
		if time >= next_tick:            # a tick every 0.07 seconds
			tick.pitch_scale = 1.0 + 0.6 * (time / duration)   # gets higher as it counts
			tick.play()
			next_tick += 0.07
		await get_tree().process_frame   # wait for the next frame, then keep going
	label.text = format % target         # end exactly on the real number
