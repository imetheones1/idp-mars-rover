class_name HeightmapHolder
extends RefCounted

var min_x: float
var min_z: float
var pixel_size: float
var width: int
var height: int

var heights: PackedFloat64Array

var valid = false

func load_from_file(file_path: String) -> bool:
	valid = false
	if not FileAccess.file_exists(file_path):
		push_error("heightmap file does not exist: ", file_path)
		return false
		
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		push_error("failed to open heightmap file: ", file_path)
		return false
		
	var magic = file.get_buffer(4).get_string_from_ascii()
	if magic != "rvhp":
		push_error("invalid heightmap magic number: ", magic)
		return false
		
	min_x = file.get_double()
	min_z = file.get_double()
	pixel_size = file.get_double()
	width = file.get_32()
	height = file.get_32()
	
	var total_pixels = width * height
	
	var double_array := PackedFloat64Array()
	double_array.resize(total_pixels)
	
	for i in range(total_pixels):
		double_array[i] = file.get_double()
	
	heights = double_array
	
	file.close()
	valid = true
	return true

func get_height_at_world(world_x: float, world_z: float) -> float:
	var grid_x: int = floor((world_x - min_x) / pixel_size)
	var grid_z: int = floor((world_z - min_z) / pixel_size)
	
	if grid_x < 0 or grid_x >= width or grid_z < 0 or grid_z >= height:
		return 0.0
	
	var index = grid_z * width + grid_x
	return heights[index]
