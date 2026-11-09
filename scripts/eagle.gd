extends Node2D
class_name Eagle

# The crowned eagle: waits, swoops in from behind, hunts you, then gives up.

@export var player: Player
@export var terrain: Terrain

# The three things the eagle can be doing.
enum State { WAIT, HUNT, LEAVE }
var state := State.WAIT

const FIRST_WAIT := 14.0          # seconds of flying before it can ever appear
const HUNT_SPEED := 820.0         # its top speed. Your normal glide is a little faster.
const TURN := 2.4                 # how sharply it can steer (bigger = sharper)
const CATCH_RADIUS := 30.0        # this close and it has you
const GIVE_UP_TIME := 22.0        # it gives up after hunting this long...
const GIVE_UP_DISTANCE := 1600.0  # ...or if you get this far ahead of it
const ESCAPE_POINTS := 150        # points for escaping
const CAVE_ESCAPE_POINTS := 250   # more for losing it in a cave

var velocity := Vector2.ZERO
var wait_timer := 0.0
var hunt_timer := 0.0
var flap := 0.0                   # wing flapping animation

@onready var screech: AudioStreamPlayer2D = $Screech


func _ready() -> void:
	visible = false
	wait_timer = FIRST_WAIT + randf_range(8.0, 16.0)    # the first one comes after 22-30 s


func _physics_process(delta: float) -> void:
	if player == null or terrain == null:
		return

	match state:
		State.WAIT:
			wait(delta)
		State.HUNT:
			hunt(delta)
		State.LEAVE:
			leave(delta)

	if state != State.WAIT:
		move(delta)
		queue_redraw()    # redraw so the wings flap


# --- WAIT: invisible, counting down ---
func wait(delta: float) -> void:
	# Only count down while the flyer is actually flying.
	if player.mode != Player.Mode.FLY or player.crashed:
		return
	wait_timer -= delta
	# Never appear while you're in a cave (it would give up straight away).
	if wait_timer <= 0.0 and not terrain.is_in_cave(player.global_position.x):
		start_hunt()


func start_hunt() -> void:
	state = State.HUNT
	hunt_timer = 0.0
	global_position = player.global_position + Vector2(-900, -260)    # behind and above, off-screen
	velocity = Vector2(player.speed, 0)
	modulate.a = 1.0
	visible = true
	screech.play()


# --- HUNT: chase the flyer ---
func hunt(delta: float) -> void:
	hunt_timer += delta

	if player.crashed:
		give_up(0)    # something else got the flyer first: just leave
		return

	# Aim where the flyer will be in a quarter of a second, not where it is now.
	var player_velocity := Vector2(cos(player.angle), sin(player.angle)) * player.speed
	var aim := player.global_position + player_velocity * 0.25
	var wanted := (aim - global_position).normalized() * HUNT_SPEED
	# Turn toward that a little each beat (so it swoops instead of snapping).
	velocity += (wanted - velocity) * minf(1.0, TURN * delta)

	# Caught you?
	if global_position.distance_to(player.global_position) < CATCH_RADIUS:
		player.crash()
		give_up(0)
		return

	# Ways to escape it.
	if terrain.is_in_cave(global_position.x):
		give_up(CAVE_ESCAPE_POINTS, "LOST IT IN A CAVE")
	elif hunt_timer > GIVE_UP_TIME or player.global_position.x - global_position.x > GIVE_UP_DISTANCE:
		give_up(ESCAPE_POINTS, "EAGLE ESCAPED")


func give_up(points: int, message := "") -> void:
	state = State.LEAVE
	if points > 0:
		player.award(message, points)    # counts as a trick: combo, points, sound


# --- LEAVE: fly away upward and fade out ---
func leave(delta: float) -> void:
	velocity = velocity.lerp(Vector2(200, -500), minf(1.0, 1.5 * delta))
	modulate.a -= 0.5 * delta
	if modulate.a <= 0.0:
		state = State.WAIT
		visible = false
		wait_timer = randf_range(30.0, 50.0)    # next one comes later


# --- Moving (used while hunting and leaving) ---
func move(delta: float) -> void:
	global_position += velocity * delta
	flap += delta * 9.0

	# Don't fly through the mountain.
	var floor_y := terrain.floor_at(global_position.x) - 30.0
	if global_position.y > floor_y:
		global_position.y = floor_y
		velocity.y = minf(velocity.y, 0.0)
	if state == State.HUNT:
		var roof_y := terrain.ceil_at(global_position.x) + 30.0
		if global_position.y < roof_y:
			global_position.y = roof_y
			velocity.y = maxf(velocity.y, 0.0)

	# Face the way it's flying. Flip when flying left, so it's never upside down.
	rotation = velocity.angle()
	scale.y = -1.0 if velocity.x < 0.0 else 1.0


# --- Drawing: a dark eagle with a crest, facing right ---
func _draw() -> void:
	var climbing := velocity.y < -50.0 or state == State.LEAVE
	var f := sin(flap) if climbing else 0.25    # flap when climbing, glide when diving
	var dark := Color(0.17, 0.12, 0.09)
	var wing := Color(0.23, 0.17, 0.13)
	var gold := Color(0.9, 0.76, 0.35)

	# Far wing (behind the body).
	draw_colored_polygon(PackedVector2Array([Vector2(4, -2), Vector2(-6, -20 - f * 12), Vector2(-26, -28 - f * 18), Vector2(-14, -6)]), dark)
	# Tail.
	draw_colored_polygon(PackedVector2Array([Vector2(-18, -2), Vector2(-34, -6), Vector2(-34, 6), Vector2(-18, 3)]), dark)
	# Body: a squashed circle.
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.36))
	draw_circle(Vector2.ZERO, 22.0, dark)
	# Pale chest.
	draw_set_transform(Vector2(4, 3), 0.0, Vector2(1.0, 0.33))
	draw_circle(Vector2.ZERO, 12.0, Color(0.73, 0.54, 0.37))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Head, crest and beak.
	draw_circle(Vector2(22, -3), 6.5, dark)
	draw_colored_polygon(PackedVector2Array([Vector2(18, -8), Vector2(12, -15), Vector2(21, -9)]), dark)
	draw_colored_polygon(PackedVector2Array([Vector2(27, -4), Vector2(33, -1), Vector2(27, 0)]), gold)
	# Talons out when it's close.
	if state == State.HUNT and global_position.distance_to(player.global_position) < 140.0:
		draw_line(Vector2(4, 7), Vector2(10, 14), gold, 2.0)
		draw_line(Vector2(-2, 7), Vector2(3, 15), gold, 2.0)
	# Near wing (in front of the body).
	draw_colored_polygon(PackedVector2Array([Vector2(6, -1), Vector2(-2, -18 - f * 10), Vector2(-22, -30 - f * 16), Vector2(-10, -4)]), wing)