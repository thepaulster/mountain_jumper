extends Node2D
class_name Cowrie

# A cowrie shell to collect. It draws itself, so it needs no picture yet.

const PICKUP_RADIUS := 34.0                  # how close the flyer must come (pixels)
const SHELL_COLOR := Color(0.95, 0.9, 0.78)
const SLIT_COLOR := Color(0.54, 0.42, 0.23)

var player: Player                           # set by the terrain when it places us
var taken := false
var time := randf() * TAU                    # each shell bobs at its own moment


func _process(delta: float) -> void:
	time += delta
	queue_redraw()    # ask Godot to run _draw again, so the bob animates


func _physics_process(_delta: float) -> void:
	if taken or player == null or player.crashed:
		return
	if global_position.distance_to(player.global_position) < PICKUP_RADIUS:
		collect()


# _draw is where a node paints itself with simple shapes.
func _draw() -> void:
	var bob := sin(time * 4.0) * 2.5
	# Squash a circle into an oval and tilt it a little: that's our shell.
	draw_set_transform(Vector2(0, bob), -0.35, Vector2(1.0, 0.75))
	draw_circle(Vector2.ZERO, 8.0, SHELL_COLOR)
	# Back to normal drawing, then the slit across the middle.
	draw_set_transform(Vector2(0, bob), 0.0, Vector2.ONE)
	draw_line(Vector2(-5, 2), Vector2(5, -2), SLIT_COLOR, 1.6)


func collect() -> void:
	taken = true
	player.collect_cowrie()
	# A tiny "pop": grow and fade at the same time, then remove ourselves.
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)