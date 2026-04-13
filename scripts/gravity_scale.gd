extends Node

@export var xr_origin_3d: XROrigin3D
var props: Array[RigidBody3D]

func _ready() -> void:
	for nodes in get_tree().get_nodes_in_group("Prop"):
		if props.has(nodes):
			pass
		else:
			props.append(nodes)

func _physics_process(_delta: float) -> void:
	if !props.is_empty():
		for objects in props:
			objects.gravity_scale = xr_origin_3d.world_scale
