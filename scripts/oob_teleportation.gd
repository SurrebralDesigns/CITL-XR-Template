extends Node3D

@onready var oob_view: Node3D = $OOBView
@onready var oob_render: MeshInstance3D = $OOBView/OOBRender
@onready var out_of_body_teleportation_character: CharacterBody3D = $OOBPlayerView/OutOfBodyTeleportationCharacter
@onready var oob_controller_left: Node3D = $OOBPlayerView/OutOfBodyTeleportationCharacter/XROrigin3D/XRControllerLeft/HandMeshLeft
@onready var oob_controller_right: Node3D = $OOBPlayerView/OutOfBodyTeleportationCharacter/XROrigin3D/XRControllerRight/HandMeshRight
@onready var oob_portal: Node3D = $OOBPortal
@onready var portal_collider: Area3D = $OOBPortal/PortalCollider
@onready var oob_player_view: SubViewport = $OOBPlayerView
@onready var oob_locomotion: SmoothLocomotion = $OOBPlayerView/OutOfBodyTeleportationCharacter/FUNCTIONS/SmoothLocomotion
@onready var timer: Timer = $Timer

@export var xr_controller: XRController3D
@export var hand_physics_left: HandPhysics
@export var hand_physics_right: HandPhysics
@export var xr_player: CharacterBody3D
@export var xr_head: XRCamera3D
@export var smooth_locomotion: SmoothLocomotion
@export var smooth_rotation: SmoothRotation
@export var virtual_jump: VirtualJump
@export var virtual_crouch: VirtualCrouch
@export var controller_offset: Vector3 = Vector3(0, .1, 0)
@export_range(.05, .15, .0001) var portal_offset: float = .125
@export var oob_tracker: Node3D

var oob_enabled: bool = false
var render_mat: ShaderMaterial
var opacity: float = 1.0
var head_overlap: bool = false

func _ready() -> void:
	var xr_interface = XRServer.find_interface("OpenXR")
	if smooth_locomotion != null:
		smooth_locomotion.enabled = false
	if smooth_rotation != null:
		smooth_rotation.enabled = true
	if virtual_crouch != null:
		virtual_crouch.crouch_enabled = false
	if virtual_jump != null:
		virtual_jump.jump_enabled = false
	oob_player_view.size = xr_interface.get_render_target_size()
	oob_view.reparent(xr_head)
	oob_view.position = Vector3.ZERO
	oob_locomotion.enabled = false
	out_of_body_teleportation_character.global_position = xr_player.global_position
	out_of_body_teleportation_character.global_rotation = xr_player.global_rotation
	out_of_body_teleportation_character.hide()
	oob_portal.hide()
	oob_portal.scale = Vector3(.01, .01, .01)
	render_mat = oob_render.material_override
	print(oob_player_view.size)

func _process(_delta: float) -> void:
	oob_portal.global_position = lerp(oob_portal.global_position, oob_tracker.global_position, .05)
	oob_portal.look_at(xr_head.global_position)
	render_mat.set_shader_parameter("alpha", opacity)
	oob_view.position.z = -portal_offset
	if xr_controller.get_vector2("primary") != Vector2.ZERO:
		if timer.is_stopped():
			if oob_enabled == false:
				_activate_out_of_body_teleportation()
				oob_enabled = true
			timer.start()
	if oob_enabled:
		portal_collider.monitoring = true
		if xr_controller.get_float("primary_click") or head_overlap == true:
			_initiate_out_of_body_teleportation()
			oob_enabled = false
			head_overlap = false

func _activate_out_of_body_teleportation():
	var enable_tween: Tween = create_tween()
	oob_portal.global_position = oob_tracker.global_position
	oob_portal.scale = Vector3(.01, .01, .01)
	oob_locomotion.enabled = true
	smooth_rotation.enabled = false
	opacity = 1.0
	out_of_body_teleportation_character.show()
	oob_portal.show()
	enable_tween.tween_property(oob_portal, "scale", Vector3(1,1,1), .25)
	hand_physics_left.hide()
	hand_physics_left.process_mode = Node.PROCESS_MODE_DISABLED
	hand_physics_right.hide()
	hand_physics_right.process_mode = Node.PROCESS_MODE_DISABLED

func _initiate_out_of_body_teleportation():
	var teleport_tween: Tween = create_tween()
	oob_locomotion.enabled = false
	smooth_rotation.enabled = true
	teleport_tween.tween_property(oob_portal, "scale", Vector3(5, 5, 5), .25)
	teleport_tween.tween_property(oob_portal, "scale", Vector3(100, 100, 100), .1)
	teleport_tween.tween_callback(_teleport_player)
	teleport_tween.tween_property(self, "opacity", 0.0, .25)
	teleport_tween.tween_callback(_deactivate_out_of_body_teleportation)
	
func _teleport_player():
	out_of_body_teleportation_character.velocity = Vector3.ZERO
	xr_player.global_position = out_of_body_teleportation_character.global_position
	xr_player.global_rotation = out_of_body_teleportation_character.global_rotation
	hand_physics_left.global_position = oob_controller_left.global_position
	hand_physics_left.global_rotation = oob_controller_left.global_rotation
	hand_physics_right.global_position = oob_controller_right.global_position
	hand_physics_right.global_rotation = oob_controller_right.global_rotation
	hand_physics_left.process_mode = Node.PROCESS_MODE_INHERIT
	hand_physics_left.linear_velocity = Vector3.ZERO
	hand_physics_right.process_mode = Node.PROCESS_MODE_INHERIT
	hand_physics_right.linear_velocity = Vector3.ZERO
	out_of_body_teleportation_character.hide()
	
func _deactivate_out_of_body_teleportation():
	xr_player.velocity = Vector3.ZERO
	oob_portal.hide()
	oob_portal.scale = Vector3(.01, .01, .01)
	opacity = 1.0
	hand_physics_left.show()
	hand_physics_right.show()

func _on_portal_collider_area_entered(_area: Area3D) -> void:
	head_overlap = true

func _on_portal_collider_area_exited(_area: Area3D) -> void:
	head_overlap = false
