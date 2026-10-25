extends CharacterBody3D

# 3D version of player.gd, for the HD-2D style garage (scenes/garage_3d.tscn).
# The player moves on the floor (the X/Z plane), and the walk sprite is a flat
# card standing upright in the 3D room.

# Walking speed in meters per second. One background pixel is 5 cm in the 3D
# room, so 3.6 m/s matches the 72 pixels per second the 2D player walks.
@export var speed: float = 3.6

# The floor art is stretched 1.41 times in depth so it looks right through the
# tilted camera (see garage_3d.tscn). Walking toward or away from the camera is
# sped up by the same amount, so up/down looks as fast on screen as left/right.
const DEPTH_STRETCH: float = 1.41421

# The direction the player last walked: "down", "left", "right" or "up".
# We remember it so that when the player stops, they keep facing that way.
var facing: String = "down"

# The sprite that plays the walk animations (walk_down, walk_left, walk_right, walk_up).
@onready var sprite: AnimatedSprite3D = $AnimatedSprite3D


func _physics_process(_delta: float) -> void:
	# get_vector returns a 2D direction from the four actions, e.g. (1, 0) for right.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# Turn the 2D input into 3D floor movement. Screen "up" (y = -1) means walking
	# away from the camera, toward the back wall, which is the -Z direction.
	velocity = Vector3(direction.x, 0.0, direction.y * DEPTH_STRETCH) * speed
	move_and_slide()

	update_animation(direction)


# Picks which walk animation to show based on the movement direction.
# This is the same logic as the 2D player.
func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		# Idle: show the first frame of the last direction we faced.
		sprite.animation = "walk_" + facing
		sprite.stop()
		sprite.frame = 0
		return

	# We only have 4 directions of art, so for diagonals we pick the axis
	# the player is moving along more.
	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			facing = "right"
		else:
			facing = "left"
	else:
		if direction.y > 0:
			facing = "down"
		else:
			facing = "up"

	sprite.play("walk_" + facing)
