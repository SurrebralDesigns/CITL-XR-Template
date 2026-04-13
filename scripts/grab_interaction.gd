extends Node

class_name GrabInteraction

@export_category("Required Variables")
@export var xr_origin: XROrigin3D
@export var xr_controller_left: XRController3D
@export var xr_controller_right: XRController3D

@export_category("Grab Interaction Settings")
@export var grab_distance: float = 3
@export var grab_strength: float = 5
@export var controller_offset: float = 90
@export_flags_3d_physics var grab_layers = 4
@export_flags_3d_physics var occlusion_layers = 15

@export_category("Optional Settings")
@export var hand_physics_left: HandPhysics
@export var hand_physics_right: HandPhysics

var hand_grab_interactor_left: Area3D
var hand_grab_interactor_right: Area3D
var distance_grab_interactor_left: Area3D
var distance_grab_interactor_right: Area3D
var occlusion_check_left: RayCast3D
var occlusion_check_right: RayCast3D
var grab_offset_left: Node3D
var grab_offset_right: Node3D

var grabbable_left: RigidBody3D
var grabbable_right: RigidBody3D

var grab_active_left: bool
var grab_active_right: bool

var joint_left: Generic6DOFJoint3D
var joint_right: Generic6DOFJoint3D

func _ready() -> void:
	_construct_grab_interactors(xr_controller_left)
	_construct_grab_interactors(xr_controller_right)

func _construct_grab_interactors(controller: XRController3D):
	var distance_grab_interactor: Area3D = Area3D.new()
	var distance_grab_collision: CollisionShape3D = CollisionShape3D.new()
	distance_grab_collision.shape = CapsuleShape3D.new()
	distance_grab_collision.shape.radius = .1
	distance_grab_collision.shape.height = grab_distance
	distance_grab_interactor.add_child(distance_grab_collision)
	distance_grab_interactor.collision_mask = grab_layers
	distance_grab_interactor.monitoring = true
	
	var hand_grab_interactor: Area3D = Area3D.new()
	var hand_grab_collision: CollisionShape3D = CollisionShape3D.new()
	hand_grab_collision.shape = SphereShape3D.new()
	hand_grab_collision.shape.radius = .15
	hand_grab_interactor.add_child(hand_grab_collision)
	hand_grab_interactor.collision_mask = grab_layers
	hand_grab_interactor.monitoring = true
	
	var occlusion_check: RayCast3D = RayCast3D.new()
	occlusion_check.collision_mask = occlusion_layers
	occlusion_check.enabled = true
	
	var grab_offset: Node3D = Node3D.new()
	grab_offset.name = "Grab Offset"
	controller.add_child(grab_offset)
	
	if hand_physics_left != null and controller == xr_controller_left:
		hand_physics_left.add_child(distance_grab_interactor)
		hand_physics_left.add_child(hand_grab_interactor)
		hand_physics_left.add_child(occlusion_check)
	elif hand_physics_right != null and controller == xr_controller_right:
		hand_physics_right.add_child(distance_grab_interactor)
		hand_physics_right.add_child(hand_grab_interactor)
		hand_physics_right.add_child(occlusion_check)
	else:
		controller.add_child(distance_grab_interactor)
		controller.add_child(hand_grab_interactor)
		controller.add_child(occlusion_check)
	
	distance_grab_interactor.rotate_x(deg_to_rad(controller_offset))
	distance_grab_interactor.position.z = -(grab_distance / 2) + .1
	occlusion_check.target_position = Vector3.FORWARD * grab_distance
	
	if controller == xr_controller_left:
		distance_grab_interactor_left = distance_grab_interactor
		hand_grab_interactor_left = hand_grab_interactor
		occlusion_check_left = occlusion_check
		grab_offset_left = grab_offset
	elif controller == xr_controller_right:
		distance_grab_interactor_right = distance_grab_interactor
		hand_grab_interactor_right = hand_grab_interactor
		occlusion_check_right = occlusion_check
		grab_offset_right = grab_offset
	
func _physics_process(_delta: float) -> void:
	_grab(xr_controller_left)
	_grab(xr_controller_right)
	
func _grab(controller: XRController3D):
	match controller:
		xr_controller_left:
			if controller.get_float("grip") > .1:
				grab_active_left = true
				if grabbable_left != null:
					var contact_distance: float = controller.global_position.distance_to(grabbable_left.global_position)
					grab_offset_left.position.z = -contact_distance
					var grab_force: Vector3 = (grab_offset_left.global_position - grabbable_left.global_position) * (grab_strength * grabbable_left.mass)
					print(grabbable_left)
			else:
				grab_active_left = false
				if grabbable_left != null:
					grabbable_left = null
		xr_controller_right:
			if controller.get_float("grip") > .1:
				grab_active_right = true
				if grabbable_right != null:
					var contact_distance: float = controller.global_position.distance_to(grabbable_right.global_position)
					grab_offset_right.position.z = -contact_distance
					var grab_force: Vector3 = (grab_offset_right.global_position - grabbable_right.global_position) * (grab_strength * grabbable_right.mass)
					print(grabbable_right)
			else:
				grab_active_right = false
				if grabbable_right != null:
					grabbable_right = null

func _create_physics_joint(physics_hand: HandPhysics, object: RigidBody3D):
	match physics_hand:
		hand_physics_left:
			joint_left = Generic6DOFJoint3D.new()
			physics_hand.add_child(joint_left)
			joint_left.global_basis = physics_hand.global_basis
			joint_left.node_a = physics_hand.get_path()
			joint_left.node_b = object.get_path()
		hand_physics_right:
			joint_right = Generic6DOFJoint3D.new()
			physics_hand.add_child(joint_right)
			joint_right.global_basis = physics_hand.global_basis
			joint_right.node_a = physics_hand.get_path()
			joint_right.node_b = object.get_path()

func _distance_check(distance_interactor: Area3D, occlusion_check: RayCast3D):
	pass
		
#@export var debug_force_vector: bool
#
#var grabbed_object_left: RigidBody3D
#var grabbed_object_right: RigidBody3D
#var joint_left: Generic6DOFJoint3D
#var joint_right: Generic6DOFJoint3D
#var player_scale: float
#var debug_mesh_left: MeshInstance3D
#var debug_mesh_right: MeshInstance3D
#
#func _physics_process(delta: float) -> void:
	#player_scale = xr_origin.world_scale
	#_grab_object(hand_physics_left, xr_controller_left, delta)
	#_grab_object(hand_physics_right, xr_controller_right, delta)
#
#func _grab_object(hand_physics: RigidBody3D, xr_controller: XRController3D, delta: float):
	#match hand_physics:
		#hand_physics_left:
			#var contacts = hand_physics.get_colliding_bodies()
			#if xr_controller.get_float("grip") > .1 and hand_physics.global_position.distance_to(xr_controller.global_position) < .5 * player_scale:
				#if contacts.size() > 0:
					#var object = contacts.get(0)
					#if object is RigidBody3D:
						#if object.get_collision_layer_value(3) == true and grabbed_object_left == null:
							#grabbed_object_left = object
							#grabbed_object_left.grabbed = true
							#joint_left = Generic6DOFJoint3D.new()
							#hand_physics.add_child(joint_left)
							#if grabbed_object_left.snap_position != null:
								#var snap_position: Node3D = grabbed_object_left.snap_position
								#hand_physics_left.global_position = hand_physics_left.global_position.move_toward(snap_position.global_position, delta)
								#hand_physics_left.global_rotation = hand_physics_left.global_rotation.move_toward(snap_position.global_rotation, delta)
								#if hand_physics_left.global_position == snap_position.global_position:
									#joint_left.global_basis = snap_position.global_basis
									#joint_left.node_a = hand_physics.get_path()
									#joint_left.node_b = grabbed_object_left.get_path()
							#else:
								#joint_left.global_basis = hand_physics.global_basis
								#joint_left.node_a = hand_physics.get_path()
								#joint_left.node_b = grabbed_object_left.get_path()
							#
							#joint_left.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
							#joint_left.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
							#joint_left.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		#
							#joint_left.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
							#joint_left.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
							#joint_left.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			#else:
				#if is_instance_valid(joint_left):
					#joint_left.queue_free()
					#grabbed_object_left.grabbed = false
					#if grabbed_object_left != null:
						#grabbed_object_left = null
				#
		#hand_physics_right:
			#var contacts = hand_physics.get_colliding_bodies()
			#if xr_controller.get_float("grip") > .1 and hand_physics.global_position.distance_to(xr_controller.global_position) < .5 * player_scale:
				#if contacts.size() > 0:
					#var object = contacts.get(0)
					#if object is RigidBody3D:
						#if object.get_collision_layer_value(3) == true and grabbed_object_right == null:
							#grabbed_object_right = object
							#grabbed_object_right.grabbed = true
							#joint_right = Generic6DOFJoint3D.new()
							#hand_physics.add_child(joint_right)
							#if grabbed_object_right.snap_position != null:
								#var snap_position: Node3D = grabbed_object_right.snap_position
								#grabbed_object_right.global_position = hand_physics_right.global_position.move_toward(snap_position.global_position, delta)
								#hand_physics_right.global_rotation = hand_physics_right.global_rotation.move_toward(snap_position.global_rotation, delta)
								#if hand_physics_right.global_position == snap_position.global_position:
									#joint_right.global_basis = snap_position.global_basis
									#joint_right.node_a = hand_physics.get_path()
									#joint_right.node_b = grabbed_object_left.get_path()
							#else:
								#joint_right.global_basis = hand_physics.global_basis
								#joint_right.node_a = hand_physics.get_path()
								#joint_right.node_b = grabbed_object_right.get_path()
								#
							#joint_right.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
							#joint_right.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
							#joint_right.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		#
							#joint_right.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
							#joint_right.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
							#joint_right.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
			#else:
				#if is_instance_valid(joint_right):
					#joint_right.queue_free()
					#grabbed_object_right.grabbed = false
					#if grabbed_object_right != null:
						#grabbed_object_right = null
