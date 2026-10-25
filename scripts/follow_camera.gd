extends Camera3D

# A camera that smoothly follows the player around the room, so the room can be
# bigger than the screen. It keeps the same angle and distance it starts with in
# the scene; it only slides along with the player.

# The node to follow (the player).
@export var target: Node3D

# How quickly the camera catches up. Higher = snappier, lower = floatier.
@export var follow_speed: float = 4.0

# How far the camera itself may move, so it never shows too far past the room's
# walls. X is left/right, Z is toward/away from the back wall (in meters).
@export var limit_left: float = -2.5
@export var limit_right: float = 2.5
@export var limit_back: float = 0.0
@export var limit_front: float = 10.0

# The gap between the camera and the player at the start, kept the same while following.
var offset: Vector3


func _ready() -> void:
	offset = global_position - target.global_position


func _process(delta: float) -> void:
	# Where the camera wants to be: the same spot relative to the player as at the start.
	var goal := target.global_position + offset
	# Keep that spot inside the limits.
	goal.x = clamp(goal.x, limit_left, limit_right)
	goal.z = clamp(goal.z, limit_back, limit_front)
	# Move only part of the way there each frame. This makes the camera glide and
	# ease in, instead of being stuck rigidly to the player.
	# min(..., 1.0) stops it from overshooting if a frame takes unusually long.
	global_position = global_position.lerp(goal, min(follow_speed * delta, 1.0))
