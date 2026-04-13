extends Node

class_name SmoothRotation

@export_category("Required Variables")
@export var xr_player: CharacterBody3D
@export var xr_controller: XRController3D

@export_category("Rotation Settings")
@export var rotation_speed: int = 3

var enabled: bool

func _ready() -> void:
	enabled = true

func _physics_process(_delta: float) -> void:
	if enabled:
		if abs(xr_controller.get_vector2("primary").x) > .5:
			xr_player.global_rotate(Vector3(0,1,0), -xr_controller.get_vector2("primary").x * rotation_speed * .01)
