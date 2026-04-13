extends RigidBody3D

class_name HandPhysics

@export_category("Required Variables")
@export var xr_player: CharacterBody3D
@export var xr_origin: XROrigin3D
@export var xr_controller: XRController3D

@export_category("Hand Physics Settings")
@export_group("Position PID")
@export var pos_p: float = 5000   # Higher = snappier tracking, but risks oscillation
@export var pos_i: float = 0
@export var pos_d: float = 25   # Damping — increase if it oscillates

@export_group("Rotation PID")
@export var rot_p: float = 10
@export var rot_i: float = 0
@export var rot_d: float = .1

@export_category("Additional Settings")
@export var hand_strength: float = 3
@export var position_offset: Vector3 = Vector3(0.0, -0.05, 0.1)
@export var generate_default_shape: bool = true
var offset: Node3D
var player_scale: float
var tracked_target: Node3D

func _ready() -> void:
	if generate_default_shape:
		var collider = CollisionShape3D.new()
		collider.shape = CapsuleShape3D.new()
		collider.shape.radius = .05
		collider.shape.height = .2
		collider.rotation.x = deg_to_rad(-60)
		add_child(collider)
		var hand_mesh = MeshInstance3D.new()
		hand_mesh.mesh = CapsuleMesh.new()
		hand_mesh.mesh.radius = .05
		hand_mesh.mesh.height = .2
		hand_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		collider.add_child(hand_mesh)
	
	if position_offset != Vector3.ZERO:
		offset = Node3D.new()
		xr_controller.add_child(offset)
		offset.position = position_offset
	
	mass = hand_strength
	gravity_scale = 0
	can_sleep = false
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 1
	set_collision_layer_value(1, false)
	set_collision_layer_value(7, true)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(4, true)
	top_level = true

##PHYSICS PID APPROACH
func _physics_process(delta: float) -> void:
	if position_offset != Vector3.ZERO:
		tracked_target = offset
	else:
		tracked_target = xr_controller
	_apply_position_pid(tracked_target, delta)
	_apply_rotation_pid(tracked_target, delta)
	
func _apply_position_pid(target: Node3D, delta: float) -> void:
	var target_pos: Vector3 = target.global_position
	var pos_error: Vector3 = target_pos - global_position
	var pos_integral: Vector3 = pos_error * delta
	var error_derivative: Vector3 = -linear_velocity + xr_player.velocity
	var p: Vector3 = pos_p * pos_error
	var i: Vector3 = pos_i * pos_integral
	var d: Vector3 = pos_d * error_derivative
	var force: Vector3 = p + i + d
	apply_central_force(force * hand_strength)
	
func _apply_rotation_pid(target: Node3D, delta: float) -> void:
	var current_quaternion: Quaternion = Quaternion(global_basis)
	var target_quaternion: Quaternion = target.global_basis.get_rotation_quaternion()
	var q_error: Quaternion = (target_quaternion * current_quaternion.inverse()).normalized()
	if q_error.w < 0.0:
		q_error = -q_error
	var axis: Vector3 = q_error.get_axis()
	var angle: float = q_error.get_angle()
	var rot_error: Vector3 = axis * angle
	var rot_integral: Vector3 = rot_error * delta
	var error_derivative: Vector3 = -angular_velocity
	var p: Vector3 = rot_p * rot_error
	var i: Vector3 = rot_i * rot_integral
	var d: Vector3 = rot_d * error_derivative
	var torque: Vector3 = p + i + d
	apply_torque(torque * hand_strength)
