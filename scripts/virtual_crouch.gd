extends Node

class_name VirtualCrouch

@export_category("Required Variables")
@export var xr_origin: XROrigin3D
@export var xr_controller: XRController3D
@export var hover_suspension: HoverSuspension

@export_category("Crouch Settings")
@export var crouch_height: float = .25

var crouch_enabled: bool

func _ready() -> void:
	crouch_enabled = true

func _physics_process(_delta: float) -> void:
	if crouch_enabled:
		var player_scale = xr_origin.world_scale
		if Input.is_action_pressed("crouch") or xr_controller.get_vector2("primary").y < -.75:
			hover_suspension.hover_height = crouch_height * player_scale
