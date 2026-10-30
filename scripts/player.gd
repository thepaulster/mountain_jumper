extends Node2D
class_name Player


# Shouted whenever we do a trick. The HUD listens for it.
signal trick_done(trick_name: String, points: int)

# Which way the nose points (in radians).
# 0 = flat to the right. Bigger = nose further down.
# 0.6 is about 35 degrees down, a gentle glide.
@export var angle := 0.6
# The ground. We plug it in from the Inspector in the Main scene.
@export var terrain:Terrain

# How fast holding turns the nose up (radians per second).
const PULL := 3.6
# How fast the nose drops back down when you let go.
const DROP := 2.4
# Where the nose settles when you are not holding (about 35 degrees down).
const DIVE := 0.6
# Speed gained per second when pointing straight down.
const DIVE_PUSH := 950.0
# Speed lost per second when pointing straight up.
const CLIMB_COST := 650.0
# Air pushing back. The faster you go, the harder it pushes.
const AIR_DRAG := 0.00075
# Extra speed lost while holding the pull. Stops endless loops.
const PULL_DRAG := 0.35
# Slowest and fastest you can ever go.
const MIN_SPEED := 60.0
const MAX_SPEED := 1250.0
# A wingsuit always sinks a little, even flying level.
const SINK := 40.0
# Stall: below STALL_SPEED you stall, above RECOVER_SPEED you fly again.
const STALL_SPEED := 230.0
const RECOVER_SPEED := 340.0
# While stalled, the nose drops toward this steep angle (about 70 degrees down)...
const STALL_NOSE := 1.2
# ...this quickly...
const STALL_DROP := 3.0
# ...and you fall this much extra.
const STALL_SINK := 260.0
# --- Proximity scoring ---
# Closer than this to the ground (pixels) counts as proximity flying.
const PROX_RANGE := 75.0
# Points per second at the edge of the range (double when almost touching).
const PROX_POINTS := 90.0

# Are we stalled right now?
var stalled := false

# How fast the flyer moves, in pixels per second.
var speed := 400.0
# Have we crashed? Once true, the flyer stops moving.
var crashed := false

# The three things the flyer can be doing.
enum Mode { LEDGE, FALL, FLY }
var mode := Mode.LEDGE    # every run starts standing on the ledge

# How hard gravity pulls during the free fall.
const GRAVITY := 1900.0
# How long the free fall lasts before the suit opens (seconds).
const FALL_TIME := 0.75

# Free fall movement (we don't use speed and angle until the suit opens).
var fall_velocity := Vector2.ZERO
var fall_timer := 0.0
var trick_points := 0      # points that are safely banked
var prox_time := 0.0       # how long the current close pass has lasted (seconds)
var prox_pending := 0.0    # points from the current close pass, not banked yet
# --- Loops ---
const LOOP_POINTS := 200      # points for each full loop
const LOOP_BOOST := 120.0     # speed added for each full loop
var loop_turn := 0.0          # how far the nose has turned up in a row (negative = up)
var loops := 0                # loops this run

# --- Combo ---
const COMBO_MAX := 8          # highest multiplier
const COMBO_WINDOW := 3.5     # seconds you have to land the next trick
var combo := 0                # current multiplier (0 = no combo)
var combo_timer := 0.0        # seconds since the last trick

func _physics_process(delta: float) -> void:
	if crashed:
		return    # crashed: do nothing until the restart

	if mode == Mode.LEDGE:
		rotation = 0.0                              # stand upright
		if Input.is_action_just_pressed("pull"):    # "just pressed" = the moment you tap
			jump()
		return    # standing still: skip all the flying code

	var old_angle := angle    # so we can see how much we turned this beat

	if mode == Mode.FALL:
		free_fall(delta)
		return    # falling: skip the flying code too

	if stalled:
		# Stalled: you can't steer. The nose falls toward STALL_NOSE by itself.
		var fall := angle_difference(angle, STALL_NOSE)
		angle += clamp(fall, -STALL_DROP * delta, STALL_DROP * delta)
		# Fast enough again? Then the suit flies again.
		if speed > RECOVER_SPEED:
			stalled = false
	elif Input.is_action_pressed("pull"):
		# Holding: tip the nose up. Smaller angle = nose higher.
		angle -= PULL * delta
	else:
		# Not holding: swing the nose back toward the glide angle,
		# but only a little each beat, so it feels smooth.
		var diff := angle_difference(angle, DIVE)
		angle += clamp(diff, -DROP * delta, DROP * delta)
	
	# --- Loop detection ---
	# Add this beat's turn. minf(0, ...) means turning down undoes progress,
	# but can never count as "negative progress" toward the next loop.
	loop_turn = minf(0.0, loop_turn + (angle - old_angle))
	if loop_turn <= -TAU:            # turned a full circle upward!
		loop_turn += TAU             # start counting the next one
		loops += 1
		speed = minf(MAX_SPEED, speed + LOOP_BOOST)
		award("LOOP", LOOP_POINTS)    # multiply, bank and shout

	# --- Combo timer ---
	# Too long without a trick? The combo is lost.
	combo_timer += delta
	if combo_timer > COMBO_WINDOW:
		combo = 0

	# How much the nose points down: +1 straight down, -1 straight up, 0 level.
	var down := sin(angle)

	if down > 0:
		speed += DIVE_PUSH * down * delta    # diving: gain speed
	else:
		speed += CLIMB_COST * down * delta   # climbing: down is negative, so we lose speed

	# Air pushes back. speed * speed means it gets much stronger when fast.
	speed -= AIR_DRAG * speed * speed * delta

	# Holding the pull costs a little extra speed.
	if Input.is_action_pressed("pull") and not stalled:
		speed *= exp(-PULL_DRAG * delta)

	# Keep speed between the slowest and fastest allowed.
	speed = clamp(speed, MIN_SPEED, MAX_SPEED)
	# Too slow? Stall.
	if not stalled and speed < STALL_SPEED:
		stalled = true

	# Turn the angle into a direction arrow, then make it as long as our speed.
	var velocity := Vector2(cos(angle), sin(angle)) * speed
	velocity.y += SINK    # always drift down a little

	if stalled:
		velocity.y += STALL_SINK    # stalled: drop like a stone

	# Move a little bit along that arrow this frame.
	position += velocity * delta
	# Did any part of us touch the ground?
	var forward := Vector2(cos(angle), sin(angle))    # an arrow pointing where the nose points
	var nose := position + forward * 20.0
	var tail := position - forward * 20.0
	if terrain != null:
		for point in [nose, position, tail]:
			if point.y > terrain.floor_at(point.x) or point.y < terrain.ceil_at(point.x):
				crash()
				return

	# Score points for flying close to the ground.
	if terrain != null:
		update_proximity(delta)
	# Point the icon the way we are flying.
	rotation = angle

	# Turn red while stalled so we can see it (just for testing).
	modulate = Color(1, 0.4, 0.4) if stalled else Color.WHITE


func crash() -> void:
	crashed = true
	modulate = Color(0.3, 0.3, 0.3)    # go grey so we can see the crash
	# Wait one second, then restart the whole level.
	await get_tree().create_timer(1.0).timeout
	get_tree().reload_current_scene()


func jump() -> void:
	mode = Mode.FALL
	fall_velocity = Vector2(330, -300)    # leap forward (right) and a little up
	fall_timer = 0.0


func free_fall(delta: float) -> void:
	fall_timer += delta
	fall_velocity.y += GRAVITY * delta    # gravity pulls us down faster and faster
	position += fall_velocity * delta

	# Tumble to face the way we're falling, but only partly.
	rotation = fall_velocity.angle() * 0.6

	# Time's up: the suit opens and we start flying.
	if fall_timer >= FALL_TIME:
		mode = Mode.FLY
		speed = maxf(420.0, fall_velocity.length())                  # keep the speed we built up
		angle = clampf(fall_velocity.angle(), 0.3, 1.2)              # start flying the way we were falling



func update_proximity(delta: float) -> void:
	# How far is the ground below us? (Ground y minus our y.)
	var gap_below := terrain.floor_at(position.x) - position.y    # ground below us
	var gap_above = position.y - terrain.ceil_at(position.x)     # roof above us (huge if none)
	var gap_island := terrain.island_gap(position)                # nearest floating mountain
	var gap := minf(minf(gap_below, gap_above), gap_island)       # whichever is closest

	if gap < PROX_RANGE:
		# Close to the rock: the timer runs and points pile up.
		prox_time += delta
		# closeness goes from 1.0 (edge of the range) to 2.0 (touching).
		var closeness := 1.0 + (PROX_RANGE - gap) / PROX_RANGE
		prox_pending += PROX_POINTS * closeness * delta
		combo_timer = 0.0    # skimming the rock keeps your combo alive
	elif prox_time > 0.0:
		# We just pulled away: bank the points.
		if prox_time >= 1.2:
			# A proper pass counts as a trick: it gets multiplied.
			award("PROXIMITY %.1f s" % prox_time, int(prox_pending))
		else:
			# A tiny touch-and-go: keep the points, but no trick.
			trick_points += int(prox_pending)
		prox_time = 0.0
		prox_pending = 0.0


# Every trick goes through here: grow the combo, multiply, bank, shout.
func award(trick_name: String, points: int) -> void:
	combo = mini(COMBO_MAX, combo + 1)
	combo_timer = 0.0
	var total := points * combo
	trick_points += total
	trick_done.emit(trick_name, total)
	
