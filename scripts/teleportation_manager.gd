extends Node

var xr_controller_left: XRController3D
var xr_controller_right: XRController3D

var teleport_visualizer_left: MeshInstance3D = MeshInstance3D.new()

func _ready() -> void:
	xr_controller_left = get_tree().get_first_node_in_group("LeftController")
	teleport_visualizer_left.mesh = BoxMesh.new()
	xr_controller_left.add_child(teleport_visualizer_left)
