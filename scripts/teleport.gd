extends Node

@export var player_controller: CharacterBody3D
@export var xr_controller_right: XRController3D
@export var spawn_point: Node3D

func _ready() -> void:
	if player_controller == null:
		player_controller = get_tree().get_first_node_in_group("PlayerController")

func _physics_process(_delta: float) -> void:
	_teleport()

func _teleport():
	if xr_controller_right.get_float("by_button"):
		player_controller.global_transform.origin = spawn_point.global_transform.origin
		print("teleported")
