extends CharacterBody3D

#Body Variables
@onready var xr_origin_3d: XROrigin3D = $XROrigin3D
@onready var xr_camera_3d: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var xr_controller_left: XRController3D = $XROrigin3D/XRControllerLeft
@onready var xr_controller_right: XRController3D = $XROrigin3D/XRControllerRight
@onready var body: CollisionShape3D = $Body
@onready var body_mesh: MeshInstance3D = $Body/BodyMesh
@onready var head_mesh: MeshInstance3D = $XROrigin3D/XRCamera3D/HeadMesh
@onready var shape_cast: ShapeCast3D = $ShapeCast3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D

#Presence Variables
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var distance_fade: MeshInstance3D = $XROrigin3D/XRCamera3D/DistanceFade
@onready var head_collision_detection: Area3D = $XROrigin3D/XRCamera3D/HeadCollisionDetection
@onready var head_collision_shape: CollisionShape3D = $XROrigin3D/XRCamera3D/HeadCollisionDetection/HeadCollisionShape

#Export Variables
@export var spawn_point: Node3D
@export var hand_physics_left: RigidBody3D
@export var hand_physics_right: RigidBody3D
@export var hover_strength: float = 50
@export var jump_strength: float = 5
@export var movement_speed: float = 4
@export var acceleration: float = 20
@export var damping: float = 5
@export var reset_pos_viz: MeshInstance3D

#Internal Variables
var is_scaled: bool
var is_teleporting: bool
var player_scale: float
var total_mass: float = 50
var is_grounded: bool
var location_offset: float
var head_is_colliding: bool
var reset_vector: Vector3
var fade_offset: float
var distance: float
var offset: float
var hover_height: float = 1
var hover_force: float
var real_hight: float
var real_crouch: float
var feet_position: Vector3
var grabbed_object_left: RigidBody3D
var grabbed_object_right: RigidBody3D
var joint_left: Generic6DOFJoint3D
var joint_right: Generic6DOFJoint3D
var left_mass: float
var right_mass: float

func _physics_process(delta: float) -> void:
	if !is_teleporting:
		velocity.y = velocity.y - gravity * delta
	else:
		velocity = Vector3.ZERO
	total_mass = 50 + left_mass + right_mass
	distance_fade.mesh.radius = .25 * player_scale
	distance_fade.mesh.height = .5 * player_scale
	_hand_physics(hand_physics_left, xr_controller_left)
	_grab_object(hand_physics_left, xr_controller_left)
	_hand_physics(hand_physics_right, xr_controller_right)
	_grab_object(hand_physics_right, xr_controller_right)
	_hover_suspension()
	_feet_position()
	_rotate_player()
	_roomscale_movement(delta)
	_move(delta)
	_roomscale_crouch()
	_crouch()
	_reset_roomscale_position()
	_scale_player()
	_teleport()
	if is_grounded:
		_jump()
	move_and_slide()
	#Debug

func _feet_position():
	if ray_cast_3d.is_colliding():
		feet_position = ray_cast_3d.get_collision_point()
		$Feet.global_position = feet_position

func _hover_suspension():
	if shape_cast.is_colliding():
		var collider = shape_cast.get_collider(0)
		var contact := shape_cast.get_collision_point(0)
		distance = shape_cast.global_position.distance_to(contact)
		offset = hover_height - distance
		hover_force = hover_strength * offset
		is_grounded = true
		if distance != hover_height:
			velocity.y = ((velocity.y + hover_force) / gravity)
			if collider is RigidBody3D:
				var downward_force = Vector3(0, -total_mass * gravity, 0)
				var downward_offset = Vector3(feet_position - collider.global_position)
				collider.apply_force(downward_force, downward_offset)
					
	else:
		distance = 0
		offset = 0
		hover_force = 0
		is_grounded = false
	#debug

func _hand_physics(hand_physics: RigidBody3D, xr_controller: Node3D):
	var move_delta: Vector3 = xr_controller.global_position - hand_physics.global_position
	var move_force = 500 * player_scale
	hand_physics.apply_central_force(move_delta * move_force)
	#print((move_delta * move_force).clamp(Vector3(-300, -300, -300) * player_scale, Vector3(300, 300, 300) * player_scale))
	
	var quaternion_hand: Quaternion = hand_physics.global_transform.basis.get_rotation_quaternion()
	var quaternion_xr_controller: Quaternion = xr_controller.global_transform.basis.get_rotation_quaternion()
	var quaternion_delta: Quaternion = quaternion_xr_controller * (quaternion_hand.inverse())
	var rotation_delta: Vector3 = Vector3(quaternion_delta.x, quaternion_delta.y, quaternion_delta.z) * quaternion_delta.w
	
	var coef_torque = 10 * player_scale
	hand_physics.apply_torque((rotation_delta * player_scale) * (coef_torque * player_scale))

func _grab_object(hand_physics: RigidBody3D, xr_controller: XRController3D):
	match hand_physics:
		hand_physics_left:
			var contacts = hand_physics.get_colliding_bodies()
			if xr_controller.get_float("grip") > .1 and hand_physics.global_position.distance_to(xr_controller.global_position) < .5:
				if contacts.size() > 0:
					var object = contacts.get(0)
					if object is RigidBody3D:
						if object.get_collision_layer_value(3) == true and grabbed_object_left == null:
							grabbed_object_left = object
							left_mass = grabbed_object_left.mass
							print("Left Mass: ", left_mass)
							grabbed_object_left.grabbed = true
							joint_left = Generic6DOFJoint3D.new()
							hand_physics.add_child(joint_left)
							joint_left.node_a = hand_physics.get_path()
							joint_left.node_b = grabbed_object_left.get_path()
							joint_left.global_basis = hand_physics.global_basis
							
							joint_left.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
							joint_left.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
							joint_left.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		
							joint_left.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
							joint_left.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
							joint_left.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			else:
				if is_instance_valid(joint_left):
					joint_left.queue_free()
					grabbed_object_left.grabbed = false
					if grabbed_object_left != null:
						grabbed_object_left = null
						left_mass = 0
						print("Left Mass: ", left_mass)
				
		hand_physics_right:
			var contacts = hand_physics.get_colliding_bodies()
			if xr_controller.get_float("grip") > .1 and hand_physics.global_position.distance_to(xr_controller.global_position) < .5 * player_scale:
				if contacts.size() > 0:
					var object = contacts.get(0)
					if object is RigidBody3D:
						if object.get_collision_layer_value(3) == true and grabbed_object_right == null:
							grabbed_object_right = object
							right_mass = grabbed_object_right.mass
							print("Right Mass: ", right_mass)
							grabbed_object_right.grabbed = true
							joint_right = Generic6DOFJoint3D.new()
							hand_physics.add_child(joint_right)
							joint_right.node_a = hand_physics.get_path()
							joint_right.node_b = grabbed_object_right.get_path()
							joint_right.global_basis = hand_physics.global_basis
							
							joint_right.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
							joint_right.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
							joint_right.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		
							joint_right.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
							joint_right.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
							joint_right.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			else:
				if is_instance_valid(joint_right):
					joint_right.queue_free()
					grabbed_object_right.grabbed = false
					if grabbed_object_right != null:
						grabbed_object_right = null
						right_mass = 0
						print("Right Mass: ", right_mass)
func _move(delta):
	var input_dir: Vector2
	if xr_controller_left.get_vector2("primary") != Vector2.ZERO:
		input_dir.x = -xr_controller_left.get_vector2("primary").y
		input_dir.y = xr_controller_left.get_vector2("primary").x
	else:
		input_dir = Input.get_vector("move_forward", "move_backward", "move_left", "move_right")
	var movement_dir := (transform.basis * Vector3(input_dir.y, 0, input_dir.x)).normalized()
	
	if input_dir:
		velocity.x = move_toward(velocity.x, movement_dir.x * movement_speed , acceleration * delta)
		velocity.z = move_toward(velocity.z, movement_dir.z * movement_speed , acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0, acceleration * delta)

func _rotate_player():
	if abs(xr_controller_right.get_vector2("primary").x) > .5:
		global_rotate(Vector3(0,1,0), -xr_controller_right.get_vector2("primary").x * .05)

func _jump():
	if Input.is_action_pressed("jump") or xr_controller_right.get_float("ax_button"):
		velocity.y = jump_strength
		is_grounded = false

func _crouch():
	if Input.is_action_pressed("crouch") or xr_controller_right.get_vector2("primary").y < -.5:
		hover_height = .3 * player_scale

func _roomscale_movement(delta):
	# Remember our current velocity, we'll apply that later
	var current_velocity = velocity

	# Start by rotating the player to face the same way our real player is
	var camera_basis: Basis = xr_origin_3d.transform.basis * xr_camera_3d.transform.basis
	var forward: Vector2 = Vector2(camera_basis.z.x, camera_basis.z.z)
	var angle: float = forward.angle_to(Vector2(0.0, 1.0))
	
	# Rotate our character body
	transform.basis = transform.basis.rotated(Vector3.UP, angle)
	# Reverse this rotation our origin node
	xr_origin_3d.transform = Transform3D().rotated(Vector3.UP, -angle) * xr_origin_3d.transform

	# Now apply movement, first move our player body to the right location
	var org_player_body: Vector3 = global_transform.origin
	var player_body_location: Vector3 = xr_origin_3d.transform * xr_camera_3d.transform.origin
	player_body_location.y = 0.0
	player_body_location = global_transform * player_body_location

	velocity = (player_body_location - org_player_body) / delta
	move_and_slide()
	# Now move our XROrigin back
	var delta_movement = global_transform.origin - org_player_body
	xr_origin_3d.global_transform.origin -= delta_movement

	# Negate any height change in local space due to player hitting ramps etc.
	#xr_origin_3d.transform.origin.y = -1.0

	# Return our value
	velocity = current_velocity
	# Check if we managed to move where we wanted to
	location_offset = (player_body_location - global_transform.origin).length()
	
func _roomscale_crouch():
	real_hight = xr_camera_3d.global_transform.origin.y - xr_origin_3d.global_transform.origin.y
	hover_height = clampf((real_hight * .5) * player_scale, .3 * player_scale, 1 * player_scale)
	xr_origin_3d.transform.origin.y = clampf(-hover_height * player_scale, -1 * player_scale, .3 * player_scale)
	body.position.z = clamp((1.8 - real_hight) * player_scale, 0, .3 * player_scale)
	body.shape.height = clamp((real_hight - 1) * player_scale, .3 * player_scale, 1 * player_scale)
	body_mesh.mesh.height = body.shape.height
	real_crouch = clampf(-hover_height * player_scale, -1 * player_scale, .3 * player_scale)

func _reset_roomscale_position():
	var reset_distance = 1
	var reset_position = global_position + ((global_position - xr_camera_3d.global_position).normalized()) * reset_distance
	var has_reset: bool
	var fade_vision: bool
	
	if location_offset > .05 * player_scale - real_crouch:
		if head_is_colliding:
			fade_vision = true
			has_reset = false
			if fade_offset == 0:
				fade_offset = location_offset
		elif location_offset > .25 * player_scale - real_crouch:
			if fade_vision != true:
				fade_vision = true
				has_reset = false
				if fade_offset == 0:
					fade_offset = location_offset
			else:
				has_reset = false
				if fade_offset == 0:
					fade_offset = location_offset
	else:
		fade_offset = 0
	
	if fade_vision:
		distance_fade.material_override.albedo_color = Color(0,0,0,(location_offset - fade_offset) * 10)
		if location_offset > 0.4 * player_scale - real_crouch:
			distance_fade.material_override.albedo_color = Color(0,0,0,1)
			reset_pos_viz.global_position = reset_position
			self.global_transform.origin.x = reset_position.x
			self.global_transform.origin.z = reset_position.z
			has_reset = true

	if has_reset == true and fade_vision == true:
		fade_vision = false
		var fade_tween = create_tween()
		fade_tween.tween_property(distance_fade.material_override, "albedo_color", Color(0,0,0,0), 1)
		has_reset = false

func _teleport():
	if xr_controller_right.get_float("by_button"):
		global_transform.origin = spawn_point.global_transform.origin

func _scale_player():
	var hand_physics_left_shape: CollisionShape3D = hand_physics_left.get_child(0)
	var hand_physics_left_mesh: MeshInstance3D = hand_physics_left.get_child(1)
	var hand_physics_right_shape: CollisionShape3D = hand_physics_right.get_child(0)
	var hand_physics_right_mesh: MeshInstance3D = hand_physics_right.get_child(1)
	
	player_scale = xr_origin_3d.world_scale
	shape_cast.target_position.y = -player_scale
	ray_cast_3d.target_position.y = -player_scale
	body.shape.radius = .125 * player_scale
	body_mesh.mesh.radius = body.shape.radius
	head_mesh.mesh.radius = .125 * player_scale
	head_mesh.mesh.height = .125 * player_scale * 2
	head_collision_shape.shape.radius = .25 * player_scale
	
	hand_physics_left_shape.shape.radius = .05 * player_scale
	hand_physics_left_shape.shape.height = .2 * player_scale
	hand_physics_left_mesh.mesh.radius = .05 * player_scale
	hand_physics_left_mesh.mesh.height = .2 * player_scale
	hand_physics_left.mass = player_scale

	hand_physics_right_shape.shape.radius = .05 * player_scale
	hand_physics_right_shape.shape.height = .2 * player_scale
	hand_physics_right_mesh.mesh.radius = .05 * player_scale
	hand_physics_right_mesh.mesh.height = .2 * player_scale
	hand_physics_right.mass = player_scale
	
	if Input.is_action_pressed("scale") or xr_controller_left.get_float("by_button"):
		if $ButtonTimer.is_stopped():
			var current_position: Vector3
			var fade_out = create_tween()
			match is_scaled:
				true:
					is_teleporting = true
					is_grounded = false
					fade_out.tween_property(distance_fade.material_override, "albedo_color", Color(0,0,0,1), 1)
					await fade_out.step_finished
					xr_origin_3d.world_scale = 1
					current_position = Vector3($Feet.global_position.x, $Feet.global_position.y + xr_origin_3d.world_scale, $Feet.global_position.z)
					is_scaled = false
					$ButtonTimer.start()
				false:
					is_teleporting = true
					is_grounded = false
					fade_out.tween_property(distance_fade.material_override, "albedo_color", Color(0,0,0,1), 1)
					await fade_out.step_finished
					xr_origin_3d.world_scale = 30
					current_position = Vector3($Feet.global_position.x, $Feet.global_position.y + xr_origin_3d.world_scale, $Feet.global_position.z)
					is_scaled = true
					$ButtonTimer.start()
			await $ButtonTimer.timeout
			global_transform.origin = current_position
			is_teleporting = false
			if global_transform.origin == current_position:
				var fade_in = create_tween()
				fade_in.tween_property(distance_fade.material_override, "albedo_color", Color(0,0,0,0), 1)

func _on_head_collision_detection_body_entered(_body: Node3D) -> void:
	head_is_colliding = true

func _on_head_collision_detection_body_exited(_body: Node3D) -> void:
	head_is_colliding = false
