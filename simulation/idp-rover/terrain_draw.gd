extends Control

const MAP_SIZE = Vector2i(512, 512)
const BASE_HEIGHT = 0.5

@onready var display_rect: TextureRect = $HeightmapDisplay
@onready var finish_button: Button = $FinishButton

var heightmap_image: Image
var display_texture: ImageTexture
var is_drawing: bool = false
var draw_mode: int = 1

var brush_radius: float = 30.0
var brush_strength: float = 2

func _ready() -> void:
	heightmap_image = Image.create(MAP_SIZE.x, MAP_SIZE.y, false, Image.FORMAT_RF)
	heightmap_image.fill(Color(BASE_HEIGHT, 0, 0, 1))
	
	display_texture = ImageTexture.create_from_image(heightmap_image)
	display_rect.texture = display_texture

func _process(delta: float) -> void:
	if is_drawing:
		var img_pos = _get_texture_pixel_pos()
		# If the helper returns a valid position inside the texture bounds
		if img_pos != Vector2(-1, -1):
			_apply_brush(img_pos, delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_drawing = event.pressed
			draw_mode = 1
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			is_drawing = event.pressed
			draw_mode = -1

func _get_texture_pixel_pos() -> Vector2:
	var mouse_pos = display_rect.get_local_mouse_position()
	var rect_size = display_rect.size
	var tex_size = Vector2(MAP_SIZE)
	
	var scale_factor = min(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
	
	var displayed_tex_size = tex_size * scale_factor
	
	var offset = (rect_size - displayed_tex_size) / 2.0

	var relative_mouse_pos = mouse_pos - offset
	
	if relative_mouse_pos.x < 0 or relative_mouse_pos.y < 0 or relative_mouse_pos.x > displayed_tex_size.x or relative_mouse_pos.y > displayed_tex_size.y:
		return Vector2(-1, -1)
		
	return (relative_mouse_pos / displayed_tex_size) * tex_size

func _apply_brush(center: Vector2, delta: float) -> void:
	var cx = int(center.x)
	var cy = int(center.y)
	var r = int(brush_radius)
	
	var start_x = max(0, cx - r)
	var end_x = min(MAP_SIZE.x - 1, cx + r)
	var start_y = max(0, cy - r)
	var end_y = min(MAP_SIZE.y - 1, cy + r)
	
	for y in range(start_y, end_y + 1):
		for x in range(start_x, end_x + 1):
			var dist = center.distance_to(Vector2(x, y))
			if dist < brush_radius:
				var falloff = 1.0 - (dist / brush_radius) 
				
				var current_pixel = heightmap_image.get_pixel(x, y)
				var current_height = current_pixel.r
				
				var height_delta = draw_mode * brush_strength * falloff * delta
				var new_height = clampf(current_height + height_delta, 0.0, 1.0)
				
				heightmap_image.set_pixel(x, y, Color(new_height, 0, 0, 1))
	
	display_texture.update(heightmap_image)

func _reset_texture() -> void:
	heightmap_image.fill(Color(BASE_HEIGHT, 0, 0, 1))
	display_texture.update(heightmap_image)

func _on_finish_pressed() -> void:
	Globals.created_heightmap_image = heightmap_image
	Globals.created_heightmap = true
	
	get_tree().change_scene_to_file("res://main.tscn")
