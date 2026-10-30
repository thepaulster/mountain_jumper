extends Camera2D

# Who the camera follows. We pick it in the Inspector.
# (Typed as Player now, so we can read its speed.)
@export var target: Player

# Look a bit ahead of the flyer (right) and a bit below it (down),
# so you can see what is coming.
const LOOK_AHEAD := Vector2(300, 80)

# --- Speed zoom ---
const ZOOM_START_SPEED := 700.0   # below this speed: normal view
const ZOOM_FULL_SPEED := 1250.0   # at this speed: zoomed out the most
const ZOOM_OUT := 0.8             # 0.8 = see 25% more in every direction
const ZOOM_SMOOTH := 1.5          # how quickly the zoom changes (bigger = quicker)


func _physics_process(delta: float) -> void:
	if target == null:
		return    # nothing to follow yet

	# How zoomed should we be? Normal (1.0) unless we're flying fast.
	var goal := 1.0
	if target.mode == Player.Mode.FLY and not target.crashed:
		# 0 at ZOOM_START_SPEED, 1 at ZOOM_FULL_SPEED, kept between 0 and 1.
		var t := clampf(inverse_lerp(ZOOM_START_SPEED, ZOOM_FULL_SPEED, target.speed), 0.0, 1.0)
		goal = lerpf(1.0, ZOOM_OUT, t)

	# Move a little toward the goal each beat, so the zoom glides instead of jumping.
	var z := lerpf(zoom.x, goal, ZOOM_SMOOTH * delta)
	zoom = Vector2(z, z)

	# Dividing by the zoom pushes the look-ahead further when zoomed out,
	# so at high speed you see further ahead.
	position = target.position + LOOK_AHEAD / z