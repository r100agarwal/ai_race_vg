extends CharacterBody2D

# How fast the player walks, in pixels per second (at the 320x180 base resolution).
@export var speed: float = 72.0

# The direction the player last walked: "down", "left", "right" or "up".
# We remember it so that when the player stops, they keep facing that way.
var facing: String = "down"

# The sprite that plays the walk animations (walk_down, walk_left, walk_right, walk_up).
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(_delta: float) -> void:
	# get_vector returns a direction from the four actions, e.g. (1, 0) for right.
	# Pressing two keys (like W + D) gives a diagonal; it's already normalized,
	# so diagonals aren't faster than straight movement.
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	update_animation(direction)


# Picks which walk animation to show based on the movement direction.
func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		# Idle: show the first frame of the last direction we faced.
		# stop() pauses the animation; setting frame = 0 resets it to the standing pose.
		sprite.animation = "walk_" + facing
		sprite.stop()
		sprite.frame = 0
		return

	# We only have 4 directions of art, so for diagonals we pick the axis
	# the player is moving along more. On a perfect keyboard diagonal
	# (both equal) this picks up/down.
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

	# play() keeps going smoothly if this animation is already playing,
	# so calling it every frame doesn't restart the walk cycle.
	sprite.play("walk_" + facing)
