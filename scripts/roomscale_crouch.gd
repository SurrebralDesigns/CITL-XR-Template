extends Node

class_name RoomscaleCrouch

@export_category("Required Variables")
@export var xr_player: CharacterBody3D
@export var xr_origin: XROrigin3D
@export var xr_camera: XRCamera3D
@export var body_collider: CollisionShape3D
@export var body_mesh: MeshInstance3D
@export var hover_suspension: HoverSuspension
var initial_hover_height: float
signal real_crouch

func _ready() -> void:
	initial_hover_height = hover_suspension.hover_height

func _physics_process(_delta: float) -> void:
	var player_scale = xr_origin.world_scale
	var real_hight = xr_camera.global_transform.origin.y - xr_origin.global_transform.origin.y
	if initial_hover_height:
		hover_suspension.hover_height = clampf((real_hight * .75) * player_scale, .25 * player_scale, initial_hover_height * player_scale)
		xr_origin.transform.origin.y = clampf(-hover_suspension.hover_height * player_scale, -initial_hover_height * player_scale, .25 * player_scale)
		body_collider.position.z = clamp((1.8 - real_hight) * player_scale, 0, .3 * player_scale)
		real_crouch.emit(clampf(-hover_suspension.hover_height * player_scale, -initial_hover_height * player_scale, .25 * player_scale))
