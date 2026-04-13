extends Node3D

@export var xr_controller_left: XRController3D
@export var xr_controller_right: XRController3D

func _ready() -> void:
	xr_controller_left.input_float_changed.connect(_on_xr_controller_left_input_float_changed)
	xr_controller_right.input_float_changed.connect(_on_xr_controller_right_input_float_changed)
	
	xr_controller_left.button_pressed.connect(_on_xr_controller_left_button_pressed)
	xr_controller_right.button_pressed.connect(_on_xr_controller_right_button_pressed)
	
	xr_controller_left.input_vector2_changed.connect(_on_xr_controller_left_input_vector2_changed)
	xr_controller_right.input_vector2_changed.connect(_on_xr_controller_right_input_vector2_changed)
func _on_xr_controller_left_input_float_changed(action_input_left: String, _value: float):
	$Floats/Label3DLeft.text = action_input_left

func _on_xr_controller_right_input_float_changed(action_input_right: String, _value: float):
	$Floats/Label3DRight.text = action_input_right

func _on_xr_controller_left_button_pressed(action_button_left: String):
	$Buttons/Label3DLeft.text = action_button_left

func _on_xr_controller_right_button_pressed(action_button_right: String):
	$Buttons/Label3DRight.text = action_button_right
	
func _on_xr_controller_left_input_vector2_changed(action_name: String, _value: Vector2):
	$Vectors/Label3DLeft.text = action_name

func _on_xr_controller_right_input_vector2_changed(action_name: String, _value: Vector2):
	$Vectors/Label3DRight.text = action_name
