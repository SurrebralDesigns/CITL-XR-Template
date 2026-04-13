extends Camera3D

@export var subject: Node3D
@export var offset_height: float = 4.0
@export var offset_depth: float = 3.0
@export var xr_origin_3d: XROrigin3D

func _process(_delta: float) -> void:
	global_transform.origin.y = subject.global_position.y + ((offset_height * xr_origin_3d.world_scale) * .5)
	self.look_at(subject.global_position)
	self.global_position = lerp(global_position, subject.global_position + Vector3(0, 0, (offset_depth * xr_origin_3d.world_scale) * .5), .01)
