extends CharacterBody3D

@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var xr_origin_3d: XROrigin3D = $XROrigin3D
@onready var xr_camera_3d: XRCamera3D = $XROrigin3D/XRCamera3D
@onready var xr_controller_left: XRController3D = $XROrigin3D/XRControllerLeft
@onready var xr_controller_right: XRController3D = $XROrigin3D/XRControllerRight

func _ready():
	_setup_physics_layers()

func _setup_physics_layers():
	set_collision_layer_value(1, false)
	set_collision_layer_value(7, true)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, true)
	set_collision_mask_value(4, true)
		
func _physics_process(_delta: float) -> void:
	move_and_slide()
