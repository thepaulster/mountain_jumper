
extends Node2D

enum TreeType {
    EMERGENT,
    UMBRELLA,
    LAYERED,
    STRANGLER_FIG,
    PALM
}

@export var tree_type: TreeType = TreeType.EMERGENT
@export var tree_height: float = 280.0
@export var tree_width: float = 220.0
@export var seed_value: int = 1

var rng = RandomNumberGenerator.new()

const BARK = Color("#554333")
const BARK_LIGHT = Color("#806247")

const DARK = Color("#183E30")
const DEEP = Color("#24543A")
const GREEN = Color("#326B43")
const LIGHT = Color("#4B8050")
const SUNLIT = Color("#79A35A")


func _ready():
    rng.seed = seed_value
    queue_redraw()


func _draw():
    match tree_type:
        TreeType.EMERGENT:
            draw_emergent()
        TreeType.UMBRELLA:
            draw_umbrella()
        TreeType.LAYERED:
            draw_layered()
        TreeType.STRANGLER_FIG:
            draw_strangler()
        TreeType.PALM:
            draw_palm()


# --------------------------------
# MATHEMATICAL CANOPY GENERATOR
# --------------------------------

func draw_blob(center, rx, ry, color, seed_offset, lobes = 5):
    var points = PackedVector2Array()

    for i in range(64):
        var angle = TAU * float(i) / 64.0

        # Superimposed waves create organic edges
        var wave = sin(angle * lobes + seed_offset) * 0.09
        wave += sin(angle * (lobes + 3) + seed_offset * 2.0) * 0.045
        wave += sin(angle * 11.0 + seed_offset * 3.0) * 0.025

        var radius = 1.0 + wave

        points.append(center + Vector2(
            cos(angle) * rx * radius,
            sin(angle) * ry * radius
        ))

    draw_colored_polygon(points, color)


# --------------------------------
# LEAF GENERATOR
# --------------------------------

func draw_leaf(base: Vector2, tip: Vector2, width: float, color: Color):
    var direction = (tip - base).normalized()
    var perpendicular = Vector2(-direction.y, direction.x)

    var points = PackedVector2Array()

    # One side of the leaf
    for i in range(13):
        var t = float(i) / 12.0
        var center = base.lerp(tip, t)
        var spread = sin(t * PI) * width

        points.append(center + perpendicular * spread)

    # Other side
    for i in range(12, -1, -1):
        var t = float(i) / 12.0
        var center = base.lerp(tip, t)
        var spread = sin(t * PI) * width

        points.append(center - perpendicular * spread)

    draw_colored_polygon(points, color)

    # Central leaf vein
    draw_line(base, tip, color.lightened(0.17), 1.2)


# --------------------------------
# TRUNK GENERATOR
# --------------------------------

func draw_trunk(h, lean = 0.0):
    var points = PackedVector2Array([
        Vector2(-13, 0),
        Vector2(-9 + lean * 0.3, -h * 0.35),
        Vector2(-7 + lean * 0.6, -h * 0.7),
        Vector2(lean - 8, -h),
        Vector2(lean + 9, -h),
        Vector2(10 + lean * 0.6, -h * 0.7),
        Vector2(12 + lean * 0.3, -h * 0.35),
        Vector2(15, 0)
    ])

    draw_colored_polygon(points, BARK)

    draw_line(
        Vector2(-5, -5),
        Vector2(lean - 4, -h * 0.85),
        BARK_LIGHT,
        3
    )


func draw_roots():
    for side in [-1, 1]:
        var root = PackedVector2Array([
            Vector2(side * 12, -12),
            Vector2(side * 42, 0),
            Vector2(side * 14, -25)
        ])
        draw_colored_polygon(root, BARK)


# --------------------------------
# 01 EMERGENT GIANT
# --------------------------------

func draw_emergent():
    var h = tree_height
    var w = tree_width

    draw_trunk(h)
    draw_roots()

    # Branches
    draw_line(Vector2(0, -h * 0.68),
        Vector2(-w * 0.38, -h * 0.86), BARK, 9)

    draw_line(Vector2(0, -h * 0.73),
        Vector2(w * 0.40, -h * 0.87), BARK, 9)

    # Large dark canopy
    draw_blob(Vector2(0, -h * 0.99),
        w * 0.48, h * 0.19, DARK, 1)

    # Main foliage masses
    draw_blob(Vector2(-w * 0.27, -h * 0.94),
        w * 0.26, h * 0.17, DEEP, 2)

    draw_blob(Vector2(w * 0.27, -h * 0.94),
        w * 0.27, h * 0.17, GREEN, 3)

    draw_blob(Vector2(0, -h * 1.07),
        w * 0.30, h * 0.15, LIGHT, 4)

    draw_blob(Vector2(-w * 0.10, -h * 1.13),
        w * 0.20, h * 0.10, SUNLIT, 5)


# --------------------------------
# 02 UMBRELLA CANOPY
# --------------------------------

func draw_umbrella():
    var h = tree_height
    var w = tree_width

    draw_trunk(h * 0.85)

    # Spreading branches
    for side in [-1, 1]:
        draw_line(
            Vector2(0, -h * 0.65),
            Vector2(side * w * 0.48, -h * 0.85),
            BARK, 8
        )

    # Flattened canopy
    draw_blob(Vector2(0, -h * 0.90),
        w * 0.53, h * 0.16, DARK, 10, 7)

    draw_blob(Vector2(-w * 0.25, -h * 0.91),
        w * 0.29, h * 0.14, GREEN, 11)

    draw_blob(Vector2(w * 0.25, -h * 0.91),
        w * 0.29, h * 0.14, DEEP, 12)

    draw_blob(Vector2(0, -h * 0.98),
        w * 0.34, h * 0.13, LIGHT, 13)

    draw_blob(Vector2(0, -h * 0.88),
        w * 0.20, h * 0.10, SUNLIT, 14)


# --------------------------------
# 03 LAYERED RAINFOREST
# --------------------------------

func draw_layered():
    var h = tree_height
    var w = tree_width

    draw_trunk(h)

    # Three horizontal foliage levels
    for i in range(3):
        var y = -h * (0.55 + i * 0.18)
        var width = w * (0.35 + i * 0.045)

        draw_line(
            Vector2(0, y + 25),
            Vector2(-width, y - 12),
            BARK, 6
        )

        draw_line(
            Vector2(0, y + 25),
            Vector2(width, y - 12),
            BARK, 6
        )

        draw_blob(
            Vector2(0, y),
            width,
            h * 0.105,
            DARK,
            i + 20,
            6
        )

        draw_blob(
            Vector2(-width * 0.32, y - 12),
            width * 0.60,
            h * 0.09,
            GREEN,
            i + 30
        )

        draw_blob(
            Vector2(width * 0.32, y - 12),
            width * 0.60,
            h * 0.09,
            DEEP,
            i + 40
        )

        draw_blob(
            Vector2(0, y - 25),
            width * 0.55,
            h * 0.075,
            LIGHT,
            i + 50
        )


# --------------------------------
# 04 STRANGLER FIG
# --------------------------------

func draw_strangler():
    var h = tree_height
    var w = tree_width

    draw_trunk(h * 0.9, 8)

    # Aerial roots
    for i in range(7):
        var x = -w * 0.38 + i * w * 0.125
        var start = Vector2(x, -h * 0.90)

        var end = Vector2(
            x + sin(float(i) * 2.1) * 16,
            -h * rng.randf_range(0.20, 0.65)
        )

        var middle = start.lerp(end, 0.5)
        middle.x += rng.randf_range(-12, 12)

        draw_line(start, middle, BARK_LIGHT, 3)
        draw_line(middle, end, BARK, 3)

    # Wide irregular crown
    draw_blob(Vector2(0, -h * 0.91),
        w * 0.51, h * 0.22, DARK, 61, 8)

    draw_blob(Vector2(-w * 0.27, -h * 0.94),
        w * 0.29, h * 0.16, GREEN, 62)

    draw_blob(Vector2(w * 0.28, -h * 0.94),
        w * 0.30, h * 0.17, DEEP, 63)

    draw_blob(Vector2(0, -h * 1.06),
        w * 0.25, h * 0.13, LIGHT, 64)


# --------------------------------
# 05 TROPICAL PALM
# --------------------------------

func draw_palm():
    var h = tree_height
    var w = tree_width

    draw_trunk(h * 0.92, -15)

    var crown = Vector2(-15, -h * 0.92)

    # Eight sweeping palm fronds
    for i in range(8):
        var angle = -PI * 0.85 + float(i) * PI * 0.22

        var length = rng.randf_range(w * 0.40, w * 0.58)

        var tip = crown + Vector2(
            cos(angle) * length,
            sin(angle) * length * 0.65
        )

        # Main frond stem
        draw_line(crown, tip, BARK_LIGHT, 3)

        # Individual leaflets
        for j in range(1, 9):
            var t = float(j) / 10.0
            var point = crown.lerp(tip, t)

            var leaflet_length = length * 0.23 * sin(t * PI * 0.85)

            var side = Vector2(
                -sin(angle),
                cos(angle)
            )

            var leaf_color = GREEN if j % 2 == 0 else LIGHT

            draw_leaf(
                point,
                point + side * leaflet_length,
                5,
                leaf_color
            )

            draw_leaf(
                point,
                point - side * leaflet_length,
                5,
                leaf_color
            )

    # Crown foliage
    draw_blob(crown, 23, 15, DEEP, 70, 6)
