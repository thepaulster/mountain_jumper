extends Node2D
class_name Helmet

# The flyer's helmet: pops off in a crash, bounces, then rolls downhill on its own.

const RADIUS := 9.0
const GRAVITY := 1900.0
const BOUNCE := 0.45        # bouncier than the body
const ROLL_FRICTION := 0.25 # low: it keeps rolling a long way
const LIFETIME := 6.0       # seconds before it fades away

var terrain: Terrain
var velocity := Vector2.ZERO
var age := 0.0


func _physics_process(delta: float) -> void:
	age += delta
	if age > LIFETIME:
		queue_free()
		return

	velocity.y += GRAVITY * delta
	position += velocity * delta

	var ground := terrain.floor_at(position.x) - RADIUS
	if position.y > ground:
		position.y = ground
		if velocity.y > 150.0:
			velocity.y = -velocity.y * BOUNCE        # a real hit: bounce
		else:
			# Rolling: how steep is the ground here? (Downhill to the right = positive.)
			var slope := (terrain.floor_at(position.x + 8.0) - terrain.floor_at(position.x - 8.0)) / 16.0
			velocity.y = 0.0
			velocity.x += GRAVITY * slope * 0.6 * delta    # the slope pushes it downhill
			velocity.x *= exp(-ROLL_FRICTION * delta)

	var roof := terrain.ceil_at(position.x) + RADIUS
	if position.y < roof:                            # inside a cave: knocked back down
		position.y = roof
		velocity.y = absf(velocity.y)

	rotation += velocity.x / RADIUS * delta          # spin like a wheel as it rolls
	modulate.a = clampf(LIFETIME - age, 0.0, 1.0)    # fade out during the last second


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(0.95, 0.45, 0.2))                  # orange shell
	draw_arc(Vector2.ZERO, RADIUS - 2.5, -0.6, 0.9, 8, Color(0.1, 0.12, 0.15), 4.0)   # dark visor
	draw_circle(Vector2(-3, -4), 2.0, Color(1, 1, 1, 0.6))                     # shine