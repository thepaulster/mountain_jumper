extends Node2D
class_name Terrain

# The flyer. We need it to know when to build more mountain.
@export var player: Node2D

# Distance between the points along the slope (pixels).
const STEP := 16.0

# Build this far ahead of the flyer, and throw away pieces this far behind.
const BUILD_AHEAD := 2500.0
const KEEP_BEHIND := 1500.0

# Colours for now. Later your Inkscape textures replace these.
const ROCK_COLOR := Color(0.16, 0.24, 0.21)
const EDGE_COLOR := Color(0.5, 0.66, 0.44)
const ROOF_COLOR := Color(0.12, 0.18, 0.16)        # underside of overhangs, a bit darker
const ROOF_EDGE_COLOR := Color(0.3, 0.4, 0.34)
const CAVE_BACK_COLOR := Color(0.06, 0.09, 0.08)   # the dark back wall inside caves
const ISLAND_COLOR := Color(0.3, 0.33, 0.42)        # bluish floating rock
const ISLAND_TOP_COLOR := Color(0.45, 0.75, 0.5)    # mossy green top
const VINE_COLOR := Color(0.3, 0.55, 0.35)          # hanging vines (just decoration)

# What ceil_at returns where there is no roof: "very far up".
const NO_CEILING := -1.0e9

# Where the track currently ends. The next piece starts exactly here.
var end_x := 0.0      # the slope starts right at the foot of the cliff...
var end_y := 620.0    # ...620 pixels below the ledge

# What kind the last piece was, so we never get two caves in a row.
var last_kind := "open"

# Every piece we have built, oldest first.
var chunks: Array = []


func _ready() -> void:
	# The summit ledge: flat on top at height 0, ending in a cliff at x = 0.
	var ledge := Polygon2D.new()
	ledge.polygon = PackedVector2Array([
		Vector2(-900, 0), Vector2(0, 0),       # the flat top
		Vector2(0, 3000), Vector2(-900, 3000), # straight down the cliff, deep underground
	])
	ledge.color = ROCK_COLOR
	add_child(ledge)

	var ledge_edge := Line2D.new()
	ledge_edge.points = PackedVector2Array([Vector2(-900, 0), Vector2(0, 0)])
	ledge_edge.width = 4.0
	ledge_edge.default_color = EDGE_COLOR
	ledge.add_child(ledge_edge)

	# A gentle first piece, so the start is calm.
	add_chunk("open", 1500.0, 0.6, 10.0)

	if player == null:
		push_error("Terrain: drag the Player into the Player box in the Inspector!")


func _physics_process(_delta: float) -> void:
	if player == null:
		return

	# Getting close to the end of the track? Lay more pieces.
	while end_x < player.position.x + BUILD_AHEAD:
		add_random_chunk()

	# Throw away pieces that are far behind the flyer.
	while chunks.size() > 2 and chunks[0].end_x < player.position.x - KEEP_BEHIND:
		chunks[0].node.queue_free()    # remove it from the game
		chunks.pop_front()             # and from our list


# Choose what kind of piece comes next, with its own random numbers.
func add_random_chunk() -> void:
	var roll := randf()    # a random number from 0 to 1
	var kind := "open"
	if roll < 0.2:
		kind = "overhang"                                  # 20% chance
	elif roll < 0.38 and last_kind != "cave":
		kind = "cave"                                      # 18%, never twice in a row
	elif roll < 0.58 and last_kind != "islands":
		kind = "islands"                                   # 20%, never twice in a row

	match kind:
		"open":
			add_chunk(kind, randf_range(800, 1400), randf_range(0.5, 0.75), randf_range(15, 35))
		"overhang":
			#                 length                  grade                    hills                 gap                   wobble ramp_in ramp_out
			add_chunk(kind, randf_range(750, 1100), randf_range(0.45, 0.62), randf_range(10, 22), randf_range(210, 265), 20.0, 0.28, 0.25)
		"cave":
			add_chunk(kind, randf_range(1400, 2200), randf_range(0.36, 0.55), randf_range(40, 72), randf_range(215, 275), 30.0, 0.1, 0.1)
		"islands":
			# A calm slope underneath, then a row of floating mountains above it.
			var chunk := add_chunk(kind, randf_range(1200, 1700), randf_range(0.45, 0.6), randf_range(10, 20))
			add_islands(chunk)

	last_kind = kind


# Build one piece of mountain.
# gap = 0 means no roof. ramp_in / ramp_out = how much of the piece (0 to 1)
# the roof takes to close in at the start and open up at the end.
func add_chunk(kind: String, length: float, grade: float, hills: float,
		gap := 0.0, wobble := 0.0, ramp_in := 0.0, ramp_out := 0.0) -> Dictionary:
	var count := int(length / STEP)

	# ---------- floor heights (same as before) ----------
	var big_wave := randf_range(420.0, 720.0)
	var big_shift := randf() * TAU
	var small_wave := randf_range(160.0, 260.0)
	var small_shift := randf() * TAU
	var lumps := randf_range(3.0, 8.0)

	var heights := PackedFloat32Array()
	for i in count + 1:
		var dx := i * STEP
		var fade := minf(1.0, dx / 260.0)
		var y := end_y + grade * dx
		y += fade * hills * (sin(dx / big_wave * TAU + big_shift) - sin(big_shift))
		y += fade * lumps * (sin(dx / small_wave * TAU + small_shift) - sin(small_shift))
		heights.append(y)

	# ---------- ceiling heights (only if this piece has a roof) ----------
	var ceilings := PackedFloat32Array()
	if gap > 0.0:
		var roof_wave := randf_range(260.0, 420.0)
		var roof_shift := randf() * TAU
		for i in count + 1:
			var t := float(i) / count    # how far along the piece: 0 at start, 1 at end
			var g: float
			if t < ramp_in:
				# Closing in: from a huge gap down to the narrow gap.
				g = lerpf(1700.0, gap, smoothstep(0.0, 1.0, t / ramp_in))
			elif t > 1.0 - ramp_out:
				# Opening up again at the end.
				g = lerpf(1700.0, gap, smoothstep(0.0, 1.0, (1.0 - t) / ramp_out))
			else:
				# The narrow part, wobbling a little so it isn't too regular.
				g = gap + wobble * (0.5 + 0.5 * sin(i * STEP / roof_wave * TAU + roof_shift))
			ceilings.append(heights[i] - g)    # the roof is "gap" pixels above the floor

	# ---------- drawing ----------
	# One container node per piece, so everything in it can be deleted together.
	var node := Node2D.new()
	add_child(node)

	var last_x := end_x + count * STEP
	var floor_line := PackedVector2Array()
	var roof_line := PackedVector2Array()
	for i in count + 1:
		floor_line.append(Vector2(end_x + i * STEP, heights[i]))
		if gap > 0.0:
			roof_line.append(Vector2(end_x + i * STEP, ceilings[i]))

	# Caves get a dark back wall between roof and floor. Drawn first, so it sits behind.
	if kind == "cave":
		var back_shape := roof_line.duplicate()
		var floor_backwards := floor_line.duplicate()
		floor_backwards.reverse()
		back_shape.append_array(floor_backwards)
		add_shape(node, back_shape, CAVE_BACK_COLOR)

	# The floor: top line, then down deep underground and back.
	var floor_shape := floor_line.duplicate()
	floor_shape.append(Vector2(last_x, heights[count] + 3000.0))
	floor_shape.append(Vector2(end_x, heights[0] + 3000.0))
	var floor_poly := add_shape(node, floor_shape, ROCK_COLOR)
	add_edge(floor_poly, floor_line, EDGE_COLOR)

	# The roof: roof line, then up high and back.
	if gap > 0.0:
		var highest := ceilings[0]
		for c in ceilings:
			highest = minf(highest, c)    # smallest y = highest point
		var roof_shape := roof_line.duplicate()
		roof_shape.append(Vector2(last_x, highest - 3000.0))
		roof_shape.append(Vector2(end_x, highest - 3000.0))
		var roof_poly := add_shape(node, roof_shape, ROOF_COLOR)
		add_edge(roof_poly, roof_line, ROOF_EDGE_COLOR)

	# Remember this piece, then move the end of the track.
	var chunk := {
		"kind": kind, "start_x": end_x, "end_x": last_x,
		"heights": heights, "ceilings": ceilings, "node": node,
		"islands": [],    # floating mountains over this piece (filled in by add_islands)
	}
	chunks.append(chunk)
	end_x = last_x
	end_y = heights[count]
	return chunk    # hand the piece back, so add_islands can use it


# Small helpers so we don't repeat the same 4 lines everywhere.
func add_shape(parent: Node, points: PackedVector2Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.polygon = points
	poly.color = color
	parent.add_child(poly)
	return poly


func add_edge(parent: Node, points: PackedVector2Array, color: Color) -> void:
	var edge := Line2D.new()
	edge.points = points
	edge.width = 4.0
	edge.default_color = color
	parent.add_child(edge)


# ---------- questions the flyer asks ----------

# How high is the ground at this x? (Bigger y = lower down.)
func floor_at(x: float) -> float:
	var chunk = chunk_at(x)
	if chunk == null:
		return 1.0e9    # no ground built here: "very far down"
	return sample(chunk.heights, chunk.start_x, x)


# How high is the roof at this x? NO_CEILING if there is none.
func ceil_at(x: float) -> float:
	var chunk = chunk_at(x)
	if chunk == null:
		return NO_CEILING
	var ceilings: PackedFloat32Array = chunk.ceilings
	if ceilings.is_empty():
		return NO_CEILING
	return sample(ceilings, chunk.start_x, x)


# Which piece is at this x? (null if none.)
func chunk_at(x: float) -> Variant:
	for chunk in chunks:
		if x >= chunk.start_x and x <= chunk.end_x:
			return chunk
	return null


# Read a height between two stored points by blending them.
func sample(values: PackedFloat32Array, start_x: float, x: float) -> float:
	var f := (x - start_x) / STEP
	var i := int(f)
	if i >= values.size() - 1:
		return values[values.size() - 1]
	return lerpf(values[i], values[i + 1], f - i)

# Place a row of floating mountains over this piece.
func add_islands(chunk: Dictionary) -> void:
	var x: float = chunk.start_x + 350.0      # leave room at the start
	var high := randf() < 0.5                 # first island high or low?

	while x < chunk.end_x - 450.0:            # leave room at the end
		var width := randf_range(170.0, 280.0)
		var center := x + width / 2.0

		# How far above the ground the island floats, and how deep its spike hangs.
		var lift: float
		var depth: float
		if high:
			lift = randf_range(320.0, 380.0)
			depth = randf_range(90.0, 130.0)
		else:
			lift = randf_range(240.0, 280.0)
			depth = randf_range(60.0, 90.0)

		var base := Vector2(center, floor_at(center) - lift)
		var shape := make_island(base, width, depth)

		# Draw it: the rock, a mossy line along the top, and a few vines.
		var rock := add_shape(chunk.node, shape, ISLAND_COLOR)
		add_edge(rock, shape.slice(0, 11), ISLAND_TOP_COLOR)    # the first 11 points are the top
		for k in 3:
			var p := shape[12 + k * 2]                          # a point on the jagged bottom
			var vine := Line2D.new()
			vine.points = PackedVector2Array([p, p + Vector2(randf_range(-4, 4), randf_range(25, 55))])
			vine.width = 2.0
			vine.default_color = VINE_COLOR
			rock.add_child(vine)

		chunk.islands.append(shape)    # remember it, so the flyer can hit it

		high = not high                          # next one at the other height
		x += width + randf_range(220.0, 340.0)   # gap before the next island


# The outline of one floating mountain, around its "base" point.
func make_island(base: Vector2, width: float, depth: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var half := width / 2.0
	var dome := randf_range(35.0, 60.0)    # how tall the rounded top is

	# The top: a gentle hump from the left edge to the right edge (11 points).
	for k in 11:
		var t := k / 10.0                  # 0 at the left, 1 at the right
		var x := lerpf(-half, half, t)
		var y := -dome * sin(t * PI)       # highest in the middle
		points.append(base + Vector2(x, y))

	# The bottom: jagged rock, from right back to left, coming to a point in the middle.
	for k in range(1, 10):
		var t := k / 10.0                  # 0 at the right, 1 at the left
		var x := lerpf(half, -half, t)
		var taper := 1.0 - absf(t * 2.0 - 1.0)    # 0 at the edges, 1 in the middle
		var jag := randf_range(-12.0, 12.0)       # rough rock
		points.append(base + Vector2(x, (depth + jag) * taper))

	return points

# Is this point inside a floating mountain?
func hits_island(point: Vector2) -> bool:
	var chunk = chunk_at(point.x)
	if chunk == null:
		return false
	for shape in chunk.islands:
		var outline: PackedVector2Array = shape
		if Geometry2D.is_point_in_polygon(point, outline):
			return true
	return false


# How far is this point from the nearest floating mountain's edge? (Huge if none.)
func island_gap(point: Vector2) -> float:
	var best := 1.0e9
	var chunk = chunk_at(point.x)
	if chunk == null:
		return best
	for shape in chunk.islands:
		var outline: PackedVector2Array = shape
		# Check every edge of the outline, keep the closest one.
		for i in outline.size():
			var a := outline[i]
			var b := outline[(i + 1) % outline.size()]    # % wraps the last edge back to the first point
			var closest := Geometry2D.get_closest_point_to_segment(point, a, b)
			best = minf(best, point.distance_to(closest))
	return best

