@tool
class_name PixelBox
extends MeshInstance3D

# A 3D box whose faces are cut out of a piece of pixel art, so flat drawings of
# desks, boxes and shelves become solid objects that light and shadows work on.
#
# You pick two rectangles in the art (in pixels):
#   front_rect: the front of the object, as it is drawn.
#   top_rect:   the top of the object, as it is drawn. It gets stretched over the
#               box's depth. If you leave it empty, the top row of front_rect is used.
# The sides use the left/right edge column of the front, stretched back.
#
# The box's origin is the bottom center of its FRONT face, and it reaches back
# toward -Z (toward the back wall). That makes it easy to stand it on the floor:
# put the origin where the front of the object touches the ground.
#
# "@tool" makes this script also run in the editor, so you see the box there too.

# Same scale as the rest of the HD-2D room (see CLAUDE.md):
# one art pixel is 5 cm wide, and upright art is stretched 1.155x tall.
const PIXEL_SIZE: float = 0.05
const TALL_STRETCH: float = 1.1547
# How far (in pixels) to stay inside each art rectangle's border.
const INSET: float = 0.02

# The picture the faces are cut from.
@export var texture: Texture2D:
	set(value):
		texture = value
		build()

@export var front_rect: Rect2i:
	set(value):
		front_rect = value
		build()

@export var top_rect: Rect2i:
	set(value):
		top_rect = value
		build()

# How deep the box is, from front to back, in meters.
@export var depth: float = 0.5:
	set(value):
		depth = value
		build()

# Mirror the art left-to-right, so copies of the same object don't look identical.
@export var flip: bool = false:
	set(value):
		flip = value
		build()


# Rebuilds the box mesh from the settings above. Called whenever one of them changes.
func build() -> void:
	if texture == null or front_rect.size.x <= 0 or front_rect.size.y <= 0:
		return

	var w: float = front_rect.size.x * PIXEL_SIZE
	var h: float = front_rect.size.y * PIXEL_SIZE * TALL_STRETCH
	var x0: float = -w / 2.0
	var x1: float = w / 2.0

	var top := top_rect
	if top.size.x <= 0 or top.size.y <= 0:
		top = Rect2i(front_rect.position.x, front_rect.position.y, front_rect.size.x, 1)

	# Thin 1-pixel-wide strips at the left and right edges of the front, for the sides.
	var left_edge := Rect2i(front_rect.position.x, front_rect.position.y, 1, front_rect.size.y)
	var right_edge := Rect2i(front_rect.end.x - 1, front_rect.position.y, 1, front_rect.size.y)
	if flip:
		var swap := left_edge
		left_edge = right_edge
		right_edge = swap

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Each face: 4 corners (bottom-left, bottom-right, top-right, top-left as seen
	# from outside the box), the art rectangle to show, and which way it faces.
	# Front (faces the camera, +Z)
	add_face(st, [Vector3(x0, 0, 0), Vector3(x1, 0, 0), Vector3(x1, h, 0), Vector3(x0, h, 0)],
		front_rect, Vector3.BACK, flip)
	# Top (faces up). Its "bottom" edge is the front edge of the box.
	add_face(st, [Vector3(x0, h, 0), Vector3(x1, h, 0), Vector3(x1, h, -depth), Vector3(x0, h, -depth)],
		top, Vector3.UP, flip)
	# Left side (faces -X)
	add_face(st, [Vector3(x0, 0, -depth), Vector3(x0, 0, 0), Vector3(x0, h, 0), Vector3(x0, h, -depth)],
		left_edge, Vector3.LEFT, false)
	# Right side (faces +X)
	add_face(st, [Vector3(x1, 0, 0), Vector3(x1, 0, -depth), Vector3(x1, h, -depth), Vector3(x1, h, 0)],
		right_edge, Vector3.RIGHT, false)
	# Back (faces the wall, -Z). Rarely seen, so it just reuses the front art.
	add_face(st, [Vector3(x1, 0, -depth), Vector3(x0, 0, -depth), Vector3(x0, h, -depth), Vector3(x1, h, -depth)],
		front_rect, Vector3.FORWARD, not flip)

	mesh = st.commit()

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	# Nearest = keep the pixels crisp instead of blurring them.
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	# Draw both sides of every face, so we never have to worry about which
	# order the corners were listed in.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Matte, like painted wood and cardboard (no shiny highlights).
	mat.roughness = 1.0
	mat.metallic_specular = 0.2
	material_override = mat


# Adds one rectangle face (two triangles) showing the art inside `rect`.
func add_face(st: SurfaceTool, corners: Array, rect: Rect2i, normal: Vector3, mirror: bool) -> void:
	var size := Vector2(texture.get_size())
	# UV coordinates go from 0 to 1 across the whole texture, so divide pixels by its size.
	# The tiny INSET keeps each face from picking up a sliver of the neighboring pixel.
	var u0: float = (rect.position.x + INSET) / size.x
	var u1: float = (rect.end.x - INSET) / size.x
	var v_top: float = (rect.position.y + INSET) / size.y
	var v_bottom: float = (rect.end.y - INSET) / size.y
	if mirror:
		var swap := u0
		u0 = u1
		u1 = swap
	var uvs := [Vector2(u0, v_bottom), Vector2(u1, v_bottom), Vector2(u1, v_top), Vector2(u0, v_top)]

	# Two triangles: corners 0-1-2 and 0-2-3.
	for i in [0, 1, 2, 0, 2, 3]:
		st.set_normal(normal)
		st.set_uv(uvs[i])
		st.add_vertex(corners[i])
