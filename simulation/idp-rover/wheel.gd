class_name Wheel
extends RayCast3D

@export var radius := 0.5
		
@export var car_body: RigidBody3D

@export var cur_speed := 0.0

var spring_stiffness: float = 150.0
var damping_coefficient: float = 5.0

var is_grounded = false

func calculate_force() -> Vector3:
	is_grounded = false
	if not is_colliding():
		return Vector3.ZERO
	
	# compression force

	var hit_point = get_collision_point()
	var normal = get_collision_normal()

	var dist = global_position.distance_to(hit_point)

	var compression = radius - dist

	if compression <= 0.0:
		return Vector3.ZERO
		
	is_grounded = true
		
	var wheel_point_velocity = get_point_velocity(global_position)
	
	var compression_velocity = wheel_point_velocity.dot(normal)

	var spring_force = compression * spring_stiffness
	var damping_force = compression_velocity * damping_coefficient
		
	var force_magnitude = spring_force - damping_force

	force_magnitude = clamp(force_magnitude, 0.0, (car_body.get_gravity()*car_body.mass).length_squared()) 
	
	var compression_force: Vector3 = normal * force_magnitude
	
	# horizontal friction
	
	var horizontal_speed = wheel_point_velocity.dot(global_basis.x)
	
	var horizontal_friction_force = -global_basis.x * horizontal_speed
	
	# forward force
	var forward_speed = wheel_point_velocity.dot(-global_basis.z)
	var forward_friction_force = global_basis.z * (forward_speed-cur_speed)
	
	# gravity compensation
	var gravity_force = car_body.get_gravity() * car_body.mass

	var gravity_parallel = gravity_force - normal * gravity_force.dot(normal)

	var anti_slide_force := Vector3.ZERO

	if gravity_parallel.length() > 0.0:
		anti_slide_force = -gravity_parallel*0.25

	return compression_force + forward_friction_force + horizontal_friction_force + anti_slide_force

# Helper function to find 3D velocity of any global point on a RigidBody3D
func get_point_velocity(world_point: Vector3) -> Vector3:
	var lin_vel = car_body.linear_velocity
	var ang_vel = car_body.angular_velocity
	
	var center_of_mass_world = car_body.to_global(car_body.center_of_mass)
	
	var lever_arm = world_point - center_of_mass_world
	
	var rotational_vel = ang_vel.cross(lever_arm)
	
	return lin_vel + rotational_vel

func _process(delta: float) -> void:
	$mesh.mesh.top_radius = radius
	$mesh.mesh.bottom_radius = radius
	
	var local_down = global_basis.transposed() * Vector3.DOWN
	
	local_down.x = 0.0
	if local_down.length_squared() > 0.001:
		target_position = local_down.normalized() * radius*1.1
	else:
		target_position = Vector3(0, -radius*1.1, 0)

	var angular_velocity = 0.0
	if radius > 0.0:
		angular_velocity = cur_speed / radius
	
	$mesh.rotation_degrees.x -= angular_velocity
