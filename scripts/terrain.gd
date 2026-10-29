extends Node2D
class_name Terrain

# The flyer. We need it to know when to build more mountain.
@export var player: Node2D

# Distance between the points along the top of the slope (pixels).
const STEP := 16.0

# Build this far ahead of the flyer, and throw away pieces this far behind.
const BUILD_AHEAD := 2500.0
const KEEP_BEHIND := 1500.0

# Colours for now. Later your Inkscape textures replace these.
const ROCK_COLOR := Color(0.16, 0.24, 0.21)
const EDGE_COLOR := Color(0.5, 0.66, 0.44)

# Where the track currently ends. The next piece starts exactly here.
var end_x := 0.0
var end_y := 620.0

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
	add_chunk(1500.0, 0.6, 10.0)
	if player == null:
		push_error("Terrain: drag the Player into the Player box in the Inspector!")


func _physics_process(_delta: float) -> void:
	if player == null:
		return

	# Getting close to the end of the track? Lay more pieces.
	while end_x < player.position.x + BUILD_AHEAD:
		var length := randf_range(800.0, 1400.0)     # how long this piece is
		var grade := randf_range(0.5, 0.75)          # how steep it goes down
		var hills := randf_range(15.0, 35.0)         # how tall the big bumps are
		add_chunk(length, grade, hills)

	# Throw away pieces that are far behind the flyer.
	while chunks.size() > 2 and chunks[0].end_x < player.position.x - KEEP_BEHIND:
		chunks[0].poly.queue_free()    # remove it from the game
		chunks.pop_front()             # and from our list


func add_chunk(length: float, grade: float, hills: float) -> void:
	var count := int(length / STEP)

	# Random shape for this piece's two waves.
	var big_wave := randf_range(420.0, 720.0)    # width of a hill
	var big_shift := randf() * TAU               # where along the wave we start
	var small_wave := randf_range(160.0, 260.0)  # width of a lump
	var small_shift := randf() * TAU
	var lumps := randf_range(3.0, 8.0)           # height of the lumps

	# Work out the height of the slope at every point.
	var heights := PackedFloat32Array()
	for i in count + 1:
		var dx := i * STEP

		# Bumps fade in over the first 260 px, so the joint between
		# two pieces is smooth instead of a sharp corner.
		var fade := minf(1.0, dx / 260.0)

		var y := end_y + grade * dx    # the straight downhill line
		# "- sin(shift)" makes each wave start at zero,
		# so this piece begins exactly where the last one ended.
		y += fade * hills * (sin(dx / big_wave * TAU + big_shift) - sin(big_shift))
		y += fade * lumps * (sin(dx / small_wave * TAU + small_shift) - sin(small_shift))
		heights.append(y)

	# Turn the heights into corner points along the top of the slope.
	var top := PackedVector2Array()
	for i in count + 1:
		top.append(Vector2(end_x + i * STEP, heights[i]))
	var last_x := end_x + count * STEP

	# The filled rock: the top line, then down deep underground and back.
	var shape := top.duplicate()
	shape.append(Vector2(last_x, heights[count] + 3000.0))
	shape.append(Vector2(end_x, heights[0] + 3000.0))

	var poly := Polygon2D.new()
	poly.polygon = shape
	poly.color = ROCK_COLOR
	add_child(poly)

	# A lighter line along the top edge, like grass or snow.
	var edge := Line2D.new()
	edge.points = top
	edge.width = 4.0
	edge.default_color = EDGE_COLOR
	poly.add_child(edge)    # child of the rock, so they are deleted together

	# Remember this piece, then move the end of the track.
	chunks.append({"start_x": end_x, "end_x": last_x, "heights": heights, "poly": poly})
	end_x = last_x
	end_y = heights[count]

# How high is the ground at this x? (Bigger y = lower down, like everywhere in Godot.)
func floor_at(x: float) -> float:
	for chunk in chunks:
		if x >= chunk.start_x and x <= chunk.end_x:
			var heights: PackedFloat32Array = chunk.heights
			# Which two points along the slope is x between?
			var f: float = (x - chunk.start_x) / STEP
			var i := int(f)
			if i >= heights.size() - 1:
				return heights[heights.size() - 1]
			# Blend between those two points. Halfway between them = halfway height.
			return lerpf(heights[i], heights[i + 1], f - i)
	# No ground built here (for example, behind the start). Return "very far down".
	return 1.0e9
