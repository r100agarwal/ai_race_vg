# Altmane

An Undertale-style 2D pixel-art parody of the AI race, told in three acts.

## Story setup

- The player is **"[Name] Altmane"**.
- The game starts in a garage in **2014**, where the player is building an AI called **GBT**.

## Hidden scores

The player never sees these directly.

| Score         | Range   |
|---------------|---------|
| Momentum      | 0–100   |
| Understanding | 0–10    |

## Other tracked flags

- Promises
- Commitments
- Hire choices
- The player's starting command
- GBT's name

## Tech setup

- Engine: **Godot 4.7**, scripts in **GDScript**.
- Base resolution **320x180**, shown in a 1280x720 window.
  - Stretch mode `canvas_items`, aspect `keep`, scale mode `integer`. (It was `viewport`; changed so the 3D lighting, glow and blur render at full window resolution.)
  - Default texture filter is `Nearest` and 2D transforms snap to whole pixels.
  - `rendering/viewport/hdr_2d` is on, so 2D colors can go brighter than white and glow.
- **HD-2D style (like Octopath Traveler):** rooms are 3D dioramas built from the 2D pixel art.
  - 1 art pixel = **0.05 m** (`pixel_size = 0.05` on every `Sprite3D`).
  - The camera looks down at **30°** with a narrow FOV (25°), 22 m from a point just above and behind the player. `follow_camera.gd` makes it glide after the player, clamped to limits, so rooms can be bigger than the screen.
  - Wall art and standing sprites (props, player) are stretched **1.155x tall** (= 1/cos 30°) so their pixels look square from the camera. Floor art is stretched **1.41x in depth**, so the floor looks foreshortened.
  - Background pixel (x, y) maps to 3D as X = (x − 160) × 0.05; wall rows (y < 80): Y = (80 − y) × 0.0577; floor rows (y ≥ 80): Z = (y − 80) × 0.0707.
  - Furniture and props are real 3D objects:
    - Boxy things (desk, monitor, chair parts, shelves, boxes, crate, workbench, stool, books) are `PixelBox` nodes (`scripts/pixel_box.gd`). A `PixelBox` is a box whose front and top faces are cut from `art/garage_3d/props_atlas.png`, by pixel rectangles you set in the Inspector.
    - Thin, irregular things (lamp, plant leaves, globe, the small plant on the shelf) are upright cutout sprites. The plant uses three crossed cutouts.
    - The ottoman is a cylinder.
    - The wall and floor art have these objects painted out, so they don't show twice.
  - Props are spread over the whole walkable floor. Some are reused copies, such as a second crate, box stack and book pile, often mirrored, each with its own collision box.
  - Filler art (brick side walls, brick above the back wall, floor toward the camera) surrounds the room so there's no black void at the screen edges.
  - The garage floor is walkable from the back wall (Z = 0) to Z ≈ 14.7 m: the painted floor (to Z 7.07) plus the first part of `floor_front.png`. A `FrontFill` light with no visible bulb lights that front area.
  - The front wall sits just inside the bottom edge of the screen when the camera is at its front limit (`limit_front` on `Camera3D`), so any floor you can see, you can walk on. If you change the camera's angle, distance or `limit_front`, move the front wall to match.
  - **Import pixel art used in 3D as Lossless with no mipmaps** (`compress/mode=0`, `mipmaps/generate=false`, `detect_3d/compress_to=0` in the `.import` file). Godot otherwise auto-switches 3D textures to lossy GPU compression, which smears fine pixel detail into flat blocks.
- Input actions: `move_up`, `move_down`, `move_left`, `move_right` (W, S, A, D).
- The `addons/godot_ai` plugin and its `_mcp_game_helper` autoload let Claude control the editor. Don't remove them.

## Project layout

- `scenes/`: scene files (`.tscn`).
  - `garage_3d.tscn` (**main scene**): the 2014 garage as a 3D diorama, with real lights, shadows, window light shaft, haze, dust particles, glow and depth-of-field blur.
  - `garage.tscn`: the older flat 2D garage (background image, 2D collision boxes, glow).
  - `test_room.tscn`: the original 2D test room.
- `scripts/`: GDScript files (`.gd`).
  - `player.gd`: top-down movement for the 2D player (`CharacterBody2D` in Floating motion mode), plus picking the 4-direction walk animation.
  - `player_3d.gd`: the same movement and animation for the 3D player (`CharacterBody3D`), walking on the floor plane.
  - `follow_camera.gd`: smoothly follows a target node (the player), keeping its starting offset, inside left/right/back/front limits.
  - `pixel_box.gd` (`PixelBox`, a `@tool` script): builds a 3D box whose faces are cut from pixel art. Its origin is the bottom center of its front face.
- `garage_bg_lit.png`: the full garage background (320x180). `garage_lights.png` is a copy with only the light pixels kept, used as a glowing overlay.
- `art/garage_3d/`: art for the 3D scene, made from the garage background: `floor.png` (floor with the free-standing objects patched out), one transparent PNG per free-standing object, and generated filler art in the same colors (`side_wall.png`, `wall_top.png`, `floor_front.png`). `wall.png` is the back wall with the furniture painted out, `wall_lights.png` is its glow overlay, `props_atlas.png` is the picture `PixelBox` faces are cut from, and `lamp.png`, `plant_leaves.png`, `globe.png`, `shelf_plant.png` are cutouts. The old flat prop cutouts (`workbench.png` and others) are no longer used.
- `sprites/`: `SpriteFrames` resources. `altmane_walk_frames.tres` cuts `altmane_walk_4dir_sheet.png` (4x4 grid of 24x33 frames) into `walk_down`, `walk_left`, `walk_right`, `walk_up` at 6 FPS.

## Code style

- **Keep code simple and well commented.** Choose the clear, beginner-readable way to write something over a clever or advanced one.
- Comments should explain *why* the code does something, not only *what* it does.
- Put tunable numbers (speeds, score limits, and so on) in `@export` variables or named constants, not unexplained numbers in the middle of the code.
