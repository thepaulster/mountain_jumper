extends Camera2D

# Who the camera follows. We pick it in the Inspector.
@export var target: Node2D

# Look a bit ahead of the flyer (right) and a bit below it (down),
# so you can see what is coming.
const LOOK_AHEAD := Vector2(300, 80)


func _physics_process(_delta: float) -> void:
	if target == null:
		return    # nothing to follow yet
	position = target.position + LOOK_AHEAD