extends Node

@export var player_controller: CharacterBody3D
@export var xr_controller_left: XRController3D
@export var xr_controller_right: XRController3D
var left_reference: AnimatableBody3D
var right_reference: AnimatableBody3D
@export var hand_physics_left: RigidBody3D
@export var hand_physics_right: RigidBody3D

func _ready() -> void:
	var parent = get_tree().get_first_node_in_group("PlayerController")
	if parent is CharacterBody3D:
		player_controller = parent
		xr_controller_left = get_tree().get_first_node_in_group("LeftController")
		xr_controller_right = get_tree().get_first_node_in_group("RightController")
		_setup_hand_physics()

func _setup_hand_physics():
	if xr_controller_left:
		var child = xr_controller_left.get_child(0)
		if child is AnimatableBody3D:
			left_reference = child
		hand_physics_left.freeze = true
		hand_physics_left.global_transform = xr_controller_left.global_transform
		hand_physics_left.freeze = false
	
	if xr_controller_right:
		var child = xr_controller_right.get_child(0)
		if child is AnimatableBody3D:
			right_reference = child
		hand_physics_right.freeze = true
		hand_physics_right.global_transform = xr_controller_right.global_transform
		hand_physics_right.freeze = false
