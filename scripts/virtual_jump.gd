extends Node

class_name VirtualJump

@export_category("Required Variables")
@export var xr_player: CharacterBody3D
@export var xr_controller: XRController3D
@export var hover_suspension: HoverSuspension

@export_category("Jump Settings")
@export var jump_strength: float = 4
@onready var timer = Timer.new()

var jump_enabled: bool

func _ready() -> void:
	jump_enabled = true
	timer.wait_time = .5
	timer.one_shot = true
	add_child(timer)

func _physics_process(_delta: float) -> void:
	if jump_enabled:
		if Input.is_action_pressed("jump") or xr_controller.get_float("ax_button"):
			if hover_suspension.is_grounded:
				hover_suspension.enabled = false
				timer.start()
				xr_player.velocity.y = jump_strength
				await timer.timeout
				hover_suspension.enabled = true
