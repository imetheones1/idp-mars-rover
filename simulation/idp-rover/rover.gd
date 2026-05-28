extends RigidBody3D

@export var target_one:Vector2 : 
	set(val):
		target_one = val
		target_one_change.emit(val)
@export var target_two:Vector2 :
	set(val):
		target_two = val
		target_two_change.emit(val)

func add_target_point(target:int,point:Vector3):
	if target != 1 and target != 2:
		return
	
	terrain_points.append(point)
	
	if target == 1:
		target_one = Vector2(point.x,point.z)
		cur_target = target_two
	elif target == 2:
		target_two = Vector2(point.x,point.z)
		cur_target = target_one
		
var cur_target:Vector2

@export var teleport : bool
@export var teleport_target: Vector3

@onready var target_indicator: Sprite3D = $target_indicator

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if teleport:
		sleeping = false
		var new_transform := state.transform
		new_transform.origin = teleport_target
		new_transform.basis = Basis.IDENTITY
		state.transform = new_transform
		teleport = false

func update_target():
	var cur_xz := Vector2(global_position.x,global_position.z)
	
	if (cur_xz-target_one).length_squared() > (cur_xz-target_two).length_squared():
		cur_target = target_one
	else:
		cur_target = target_two

signal target_one_change(newval:Vector2)
signal target_two_change(newval:Vector2)

enum STATE {
	DRIVING,
	FOLLOWING
}

var cur_state:STATE = STATE.DRIVING

@onready var wheels: Node3D = $wheels

func damp(a,b,lambda:float,dt:float):
	return lerp(a,b, 1-exp(-lambda * dt))

func _physics_process(delta: float) -> void:
	var flip := Input.is_action_just_pressed("ui_accept") and DisplayServer.window_is_focused()
	for wheel: Wheel in wheels.get_children():
		var force = wheel.calculate_force()
		if force != Vector3.ZERO:
			apply_force(force, wheel.global_position - global_position)
		if flip:
			apply_force(wheel.global_basis.y * 10 * sign(wheel.position.x), wheel.global_position - global_position)
	if flip:
		apply_force(Vector3.UP * 100,Vector3.ZERO)
		
@onready var display_multi_mesh: MultiMeshInstance3D = $display/display_multi_mesh
const display_lidar_length := 10

func _ready() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.instance_count = distance_sensors.get_child_count() + front_sensors.get_child_count()
	
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = display_lidar_length
	cylinder.radial_segments = 4
	cylinder.rings = 1
	
	mm.mesh = cylinder
	display_multi_mesh.multimesh = mm
	
	var i := 0
	for ray:RayCast3D in distance_sensors.get_children() + front_sensors.get_children():
		var start_pos = ray.position
		var direction = ray.transform.basis * ray.target_position.normalized()
		var xform := Transform3D()
		xform = xform.looking_at(direction, Vector3.UP)
		xform.basis = xform.basis.rotated(xform.basis.x, deg_to_rad(90))
		xform.origin = start_pos
		xform.origin += direction * (display_lidar_length / 2.0)
		mm.set_instance_transform(i, xform)
		i+=1
		
const satellite_size := 30
const satellite_scale := 3.0

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("update_terrain"):
			write_terrain_to_file()
		elif event.is_action_pressed("follow_path"):
			if cur_state == STATE.DRIVING:
				cur_state = STATE.FOLLOWING
				cur_point = 0
				#update_target()
			elif cur_state == STATE.FOLLOWING:
				cur_state = STATE.DRIVING
		elif event.is_action_pressed("set_target_1"):
			target_one = Vector2(global_position.x,global_position.z)
		elif event.is_action_pressed("set_target_2"):
			target_two = Vector2(global_position.x,global_position.z)
		elif event.is_action_pressed("reset"):
			teleport_target = Vector3(0,6,0)
			teleport = true
			sleeping = false
			reset_rover()
		elif event.is_action_pressed("sattelite"):
			print("simulating sattelite")
			$satellite.global_position = global_position
			var satellite_ray: RayCast3D = $satellite/RayCast3D
			for x in range(-satellite_size,satellite_size+1):
				satellite_ray.position.x = x*satellite_scale
				for z in range(-satellite_size,satellite_size+1):
					if Vector2(x*satellite_scale,z*satellite_scale).length_squared() > satellite_size*satellite_size*satellite_scale*satellite_scale:
						continue
					satellite_ray.position.z = z*satellite_scale
					satellite_ray.force_update_transform()
					satellite_ray.force_raycast_update()
					if satellite_ray.is_colliding():
						terrain_points.append(satellite_ray.get_collision_point())
			print("sattelite simulation finished")
			var mm: MultiMesh = points_mesh.multimesh
			var total_count := terrain_points.size()
			
			mm.instance_count = total_count
			
			for i in range(total_count):
				var xform := Transform3D.IDENTITY

				var display_point := terrain_points[i]
				display_point.y += 0.05
				
				xform.origin = display_point
				mm.set_instance_transform(i, xform)

func reset_rover():
	terrain_points = []
	points_mesh.multimesh.instance_count = 0
	target_one = Vector2.ZERO
	target_two = Vector2.ZERO
	cur_state = STATE.DRIVING
	

@onready var fl: Wheel = $wheels/fl
@onready var fr: Wheel = $wheels/fr
@onready var bl: Wheel = $wheels/bl
@onready var br: Wheel = $wheels/br

@onready var point_indicator: Sprite3D = $pointIndicator

const max_wheel_speed := 5
var points: Array[Vector3] = []
var cur_point := 0

var distance_to_target:float = 0

func _process(delta: float) -> void:
	target_indicator.global_position = global_position + Vector3(0,4,0)
	if cur_state == STATE.DRIVING:
		if DisplayServer.window_is_focused():
			var in_dir = Input.get_vector("left","right","backward","forward")
			var left_power  = in_dir.y + in_dir.x
			var right_power = in_dir.y - in_dir.x
			left_power  = clamp(left_power *max_wheel_speed,-max_wheel_speed,max_wheel_speed)
			right_power = clamp(right_power*max_wheel_speed,-max_wheel_speed,max_wheel_speed)
			fl.cur_speed = left_power
			bl.cur_speed = left_power
			fr.cur_speed = right_power
			br.cur_speed = right_power
		else:
			fl.cur_speed = 0
			bl.cur_speed = 0
			fr.cur_speed = 0
			br.cur_speed = 0
		point_indicator.visible = false
	elif cur_state == STATE.FOLLOWING:
		if cur_point >= points.size():
			print("reached end of path")
			update_target()
			write_terrain_to_file()
			#cur_state = STATE.DRIVING
			return
		point_indicator.visible = true
		point_indicator.global_position = points[cur_point]
		
		#var rover_up = global_transform.basis.y
		#var up_dot = rover_up.dot(Vector3.UP)
		#
		#if up_dot < 0.8:
			## agressively attempt to stabilize self
			#fl.cur_speed = -10
			#bl.cur_speed = -10
			#fr.cur_speed = -10
			#br.cur_speed = -10
			#return 

		var target_pos = points[cur_point]
		var current_pos = global_position 
		
		distance_to_target = current_pos.distance_to(target_pos)
		if distance_to_target <= 3:
			cur_point += 1
			return
		elif distance_to_target > 20:
			write_terrain_to_file()
			return
			
		var horizontal_distance = (Vector2(current_pos.x,current_pos.z)-Vector2(target_pos.x,target_pos.z)).length_squared()
		var vertical_distance = abs(current_pos.y-target_pos.y)
		if horizontal_distance < 1 and vertical_distance > 2:
			write_terrain_to_file()
			return
		
		var left_power : float = 0.0
		var right_power : float = 0.0

		var dir_to_target = (target_pos - current_pos).normalized()

		var forward_dir = -global_transform.basis.z 
		var right_dir = global_transform.basis.x

		var forward_dot = forward_dir.dot(dir_to_target)
		var right_dot = right_dir.dot(dir_to_target)

		var forward_power = clamp(forward_dot, 0.0, 1.0) 
		
		var steer_power = right_dot

		if forward_dot < 0:
			forward_power = 0.0
			steer_power = sign(right_dot)

		left_power  = forward_power + steer_power
		right_power = forward_power - steer_power

		left_power  = clamp(left_power  * Globals.rover_pathing_speed, -Globals.rover_pathing_speed, Globals.rover_pathing_speed)
		right_power = clamp(right_power * Globals.rover_pathing_speed, -Globals.rover_pathing_speed, Globals.rover_pathing_speed)

		fl.cur_speed = left_power
		bl.cur_speed = left_power
		fr.cur_speed = right_power
		br.cur_speed = right_power
	else:
		print("state was set to an invalid value")
		cur_state = STATE.DRIVING

@onready var distance_timer: Timer = $distanceTimer
@onready var distance_sensors: Node3D = $distanceSensors
@onready var front_sensors: Node3D = $frontSensors

var generated_heightmap:HeightmapHolder

var terrain_points: Array[Vector3] = []
var new_point_count := 0
var invalid_point_count := 0

@onready var points_mesh: MultiMeshInstance3D = $pointsMesh

var first := true
func _on_timer_timeout() -> void:
	new_point_count = 0

	for sensor: RayCast3D in distance_sensors.get_children():
		process_sensor(sensor, false)
		
	for sensor: RayCast3D in front_sensors.get_children():
		process_sensor(sensor, true)

	if new_point_count > 0:
		var mm: MultiMesh = points_mesh.multimesh
		var total_count := terrain_points.size()
		
		mm.instance_count = total_count
		
		for i in range(total_count):
			var xform := Transform3D.IDENTITY

			var display_point := terrain_points[i]
			display_point.y += 0.05
			
			xform.origin = display_point
			mm.set_instance_transform(i, xform)

	if first or (invalid_point_count >= 100 and cur_state == STATE.FOLLOWING) or invalid_point_count > 500:
		write_terrain_to_file()
	first = false

func process_sensor(sensor: RayCast3D, is_front_sensor: bool) -> void:
	sensor.enabled = true
	sensor.force_update_transform()
	sensor.force_raycast_update()
	
	if not sensor.is_colliding():
		return
		
	var collision_point := sensor.get_collision_point()
	var collision_normal := sensor.get_collision_normal()
	sensor.enabled = false
	
	var is_obstacle := false
	
	if is_front_sensor:
		is_obstacle = true
	else:
		if collision_normal.dot(Vector3.UP) < 0.7:
			is_obstacle = true

	if is_obstacle:
		collision_point.y += 30.0

	var valid := true
	var point: Vector3
	for point_i: int in terrain_points.size():
		point = terrain_points[-point_i - 1]
		if (point - collision_point).length_squared() < 1:
			valid = false
			break
			
	if valid:
		terrain_points.append(collision_point)
		new_point_count += 1
		if is_obstacle:
			terrain_points.append(collision_point+collision_normal)
			new_point_count += 1
		
		if not is_obstacle and generated_heightmap != null and generated_heightmap.valid:
			var generated_height = generated_heightmap.get_height_at_world(collision_point.x, collision_point.z)
			if absf(generated_height - collision_point.y) > 0.5:
				invalid_point_count += 1
		
		if is_obstacle and cur_state == STATE.FOLLOWING:
			invalid_point_count += 50

@export var debug_marker:PackedScene
@onready var delay_timer: Timer = $delay_timer

var has_path := false

func write_terrain_to_file():
	if delay_timer.time_left > 0:
		return
	delay_timer.start()
	print_debug("\nbeginning pathfinding")
	var app_dir = "user://vertices.txt"
	var file := FileAccess.open(app_dir,FileAccess.WRITE)
	var cur_string := ""
	var line_length = 0
	for vertex: Vector3 in terrain_points:
		var x_str = ("-%015.10f" % abs(vertex.x)) if vertex.x < 0 else ("0%015.10f" % vertex.x)
		var y_str = ("-%015.10f" % abs(vertex.y)) if vertex.y < 0 else ("0%015.10f" % vertex.y)
		var z_str = ("-%015.10f" % abs(vertex.z)) if vertex.z < 0 else ("0%015.10f" % vertex.z)
		var line = "%s,%s,%s\n" % [x_str, y_str, z_str]
		cur_string += line
		if line_length == 0:
			line_length = line.length()
		elif line.length() != line_length:
			print_debug("lines are different sizes!")
	file.store_string(cur_string)
	var vertex_file_path = file.get_path_absolute()
	file.close()
	print("path: "+vertex_file_path)
	print("line length: "+str(line_length))
	var temp_file := FileAccess.open("user://heightmap.roverheightmap",FileAccess.WRITE)
	var heightmap_path := temp_file.get_path_absolute()
	temp_file.close()
	print("output path: "+heightmap_path)
	
	# execute programs
	var output = []
	var exit_code = OS.execute(
		Paths.heightmap_exe_path,
		["\"%s\"" % vertex_file_path, "\"%s\"" %  heightmap_path],
		output,
		true
	)
	print("exit code: ",exit_code)
	for out:String in output:
		for line in out.split("\n"):
			if line.contains("Point"):
				continue
			print(line)
	if exit_code != 0:
		push_error("heightmap generation failed")
		cur_state = STATE.DRIVING
		return
		
	invalid_point_count = 0
	
	generated_heightmap = HeightmapHolder.new()
	if not generated_heightmap.load_from_file("user://heightmap.roverheightmap"):
		push_error("failed to load heightmap")
	
	var temp_file_2 := FileAccess.open("user://path.roverpath",FileAccess.WRITE)
	var path_path := temp_file_2.get_path_absolute()
	temp_file_2.close()
	print("path path: "+path_path)
	
	output = []
	exit_code = OS.execute(
		Paths.pathfind_exe_path,
		[
			"\"%s\"" % heightmap_path,
			"\"%s\"" % path_path,
			global_position.x,
			global_position.z,
			cur_target.x,
			cur_target.y,
			Globals.pathfinding_flatness_weight,
			Globals.pathfinding_lateral_weight
		],
		output,
		true
	)
	for out:String in output:
		for line in out.split("\n"):
			print(line)
	if exit_code != 0:
		push_error("path generation failed")
		has_path = false
		cur_state = STATE.DRIVING
		return
	has_path = true
	
	points = []
	var path_file := FileAccess.open("user://path.roverpath",FileAccess.READ)
	
	while path_file.get_position() < path_file.get_length():
		var line := path_file.get_line().strip_edges()
		
		if line.is_empty():
			continue
			
		var parts := line.split(",")
		
		if parts.size() == 3:
			var x := parts[0].to_float()
			var y := parts[1].to_float()
			var z := parts[2].to_float()
			
			points.append(Vector3(x, y, z))
		else:
			push_warning("Skipping malformed line: " + line)
			
	path_file.close()
	
	cur_point = 0
	print()
	
	if points.size() < 2:
		$PathVisualizer.mesh = null
		return

	var st := SurfaceTool.new()

	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var path_width := 0.35

	var left_points := []
	var right_points := []

	for i in range(points.size()):

		var forward : Vector3

		if i == 0:
			forward = (points[1] - points[0]).normalized()

		elif i == points.size() - 1:
			forward = (points[i] - points[i - 1]).normalized()

		else:
			var dir_prev = (points[i] - points[i - 1]).normalized()
			var dir_next = (points[i + 1] - points[i]).normalized()

			forward = (dir_prev + dir_next).normalized()

			if forward.length_squared() < 0.001:
				forward = dir_next

		var right = forward.cross(Vector3.UP).normalized()

		var left_pos = points[i] - right * path_width
		var right_pos = points[i] + right * path_width

		left_pos.y += 0.05
		right_pos.y += 0.05

		left_points.append(left_pos)
		right_points.append(right_pos)

	for i in range(points.size() - 1):

		var a = left_points[i]
		var b = right_points[i]

		var c = left_points[i + 1]
		var d = right_points[i + 1]

		st.add_vertex(b)
		st.add_vertex(a)
		st.add_vertex(c)

		st.add_vertex(b)
		st.add_vertex(c)
		st.add_vertex(d)

	var mesh := st.commit()

	$PathVisualizer.mesh = mesh
