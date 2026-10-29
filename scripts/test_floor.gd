extends Polygon2D

# A simple straight slope, just for testing.
# Next step we replace it with a real, bumpy mountain.

const SLOPE := 0.6    # the floor drops 0.6 pixels for every 1 pixel to the right


func _ready() -> void:
	# _ready runs once, when the scene starts.
	# A polygon is a list of corner points, joined up and filled in.
	polygon = PackedVector2Array([
		Vector2(-1000, 400),                       # top-left corner
		Vector2(40000, 400 + 41000 * SLOPE),       # top-right: far away and much lower
		Vector2(40000, 40000),                     # bottom-right, deep underground
		Vector2(-1000, 40000),                     # bottom-left
	])