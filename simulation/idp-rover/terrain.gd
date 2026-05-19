@tool
extends StaticBody3D

@export var update_terrain_button : bool :
	set(val):
		update_terrain()

@onready var collision_shape_3d: CollisionShape3D = $CollisionShape3D
@onready var mesh_instance_3d: MeshInstance3D = $MeshInstance3D

func update_terrain():
	var terrain_noise:NoiseTexture2D = load("uid://bk21j4x80m4g2")
	var heightmap_image := terrain_noise.get_image()
	heightmap_image.convert(Image.FORMAT_RF)
	
	var height_min = 0.0
	var height_max = 10.0
	
	var shape := HeightMapShape3D.new()
	
	shape.update_map_data_from_image(
		heightmap_image,
		height_min,
		height_max
	)

	collision_shape_3d.shape = shape
	
	var width := heightmap_image.get_width()
	var depth := heightmap_image.get_height()
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for z in range(depth - 1):
		for x in range(width - 1):
			var h00 := lerpf(height_min, height_max, heightmap_image.get_pixel(x, z).r)
			var h10 := lerpf(height_min, height_max, heightmap_image.get_pixel(x + 1, z).r)
			var h01 := lerpf(height_min, height_max, heightmap_image.get_pixel(x, z + 1).r)
			var h11 := lerpf(height_min, height_max, heightmap_image.get_pixel(x + 1, z + 1).r)

			var half_w := (width - 1) * 0.5
			var half_d := (depth - 1) * 0.5

			var v00 := Vector3(x - half_w, h00, z - half_d)
			var v10 := Vector3(x + 1 - half_w, h10, z - half_d)
			var v01 := Vector3(x - half_w, h01, z + 1 - half_d)
			var v11 := Vector3(x + 1 - half_w, h11, z + 1 - half_d)

			st.add_vertex(v00)
			st.add_vertex(v10)
			st.add_vertex(v01)

			st.add_vertex(v10)
			st.add_vertex(v11)
			st.add_vertex(v01)

	st.generate_normals()

	mesh_instance_3d.mesh = st.commit()
	
	#mesh_instance_3d.position.x = -width/2
	#mesh_instance_3d.position.z = -depth/2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
