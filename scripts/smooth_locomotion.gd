# This script extends Node and creates a reusable class called "SmoothLocomotion"
extends Node
class_name SmoothLocomotion

##OVERVIEW
# This script handles smooth, continuous movement for a VR player character.
# It supports both VR controller input (thumbstick) and keyboard input.
#
# VISUAL DIAGRAM:
# ┌─────────────────────────────────────────────────────────────────────────┐
# │                    SMOOTH LOCOMOTION FLOW CHART                         │
# ├─────────────────────────────────────────────────────────────────────────┤
# │                                                                         │
# │  [1] EVERY PHYSICS FRAME                                                │
# │       │                                                                 │
# │       ▼                                                                 │
# │  [2] CHECK INPUT SOURCE:                                                │
# │       │                                                                 │
# │       ├─► VR Controller Thumbstick? ──Yes──► Use XR input               │
# │       │                                        │                        │
# │       └─► No? ──────────────────────► Use Keyboard input                │
# │                                                │                        │
# │                                                ▼                        │
# │  [3] CONVERT INPUT TO 2D DIRECTION:                                     │
# │       • Thumbstick: Forward/Back = Y, Left/Right = X                    │
# │       • Keyboard: WASD keys mapped to X/Y                               │
# │                                                │                        │
# │                                                ▼                        │
# │  [4] TRANSFORM TO 3D WORLD SPACE:                                       │
# │       • Rotate input direction by player's current facing               │
# │       • Convert 2D (x,y) → 3D (x,0,z) for horizontal movement           │
# │                                                │                        │
# │                                                ▼                        │
# │  [5] APPLY SMOOTH ACCELERATION:                                         │
# │       │                                                                 │
# │       ├─► Moving? ──Yes──► Accelerate toward target speed               │
# │       │                     (uses move_toward for smoothness)           │
# │       │                                                                 │
# │       └─► Stopped? ──────► Decelerate to zero                           │
# │                             (prevents instant stops)                    │
# │                                                │                        │
# │                                                ▼                        │
# │  [6] CHARACTER MOVES AUTOMATICALLY                                      │
# │       (CharacterBody3D.move_and_slide() called by Godot)                │
# │                                                                         │
# └─────────────────────────────────────────────────────────────────────────┘
#
# INPUT MAPPING VISUALIZATION:
#
#   VR THUMBSTICK              TRANSFORMS TO           3D MOVEMENT
#   ═════════════              ═════════════           ═══════════
#
#       Forward                                         Player moves
#         (↑)                      ┌───┐                forward in
#          │                       │ P │                the direction
#    Left ─┼─ Right    ──────►     └─┬─┘    ──────►     they're facing
#         (←) (→)                    │
#          │                         ▼
#      Backward                (Movement
#         (↓)                   Direction)

# EXPORTED VARIABLES (Visible in Godot Inspector)
@export_category("Required Variables")

# Reference to the VR player's CharacterBody3D node
# This is the actual character that moves through the world
@export var xr_player: CharacterBody3D

# Reference to the VR controller (left or right hand controller)
# This reads the thumbstick input for movement
@export var xr_controller: XRController3D

@export_category("Movement Settings")

# Maximum speed the player can move (in meters per second)
# Default: 1 m/s (approximately walking speed)
@export var movement_speed: float = 2

# How quickly the player accelerates/decelerates (in m/s²)
# Higher values = snappier movement, Lower values = more momentum
# Default: 10 ensures smooth but responsive movement
@export var acceleration: float = 10

var enabled: bool

func _ready() -> void:
	enabled = true

# PHYSICS PROCESS FUNCTION
# This function runs every physics frame (typically 90 times per second for VR)
# The 'delta' parameter is the time elapsed since last frame (usually ~0.016s)
func _physics_process(delta: float) -> void:
	if enabled:
		# Step 1: Get input direction as a 2D vector
		# Vector2(x, y) where x = left/right, y = forward/backward
		var input_dir: Vector2
		
		# Step 2: Check if VR controller thumbstick is being used
		# "primary" typically refers to the main thumbstick on the controller
		if xr_controller.get_vector2("primary") != Vector2.ZERO:
			# VR Controller input detected!
			# Note: We swap and negate axes to match expected movement:
			# - Thumbstick Y (forward/back) becomes input X (negated for correct direction)
			# - Thumbstick X (left/right) becomes input Y
			input_dir.x = -xr_controller.get_vector2("primary").y
			input_dir.y = xr_controller.get_vector2("primary").x
		else:
			# No VR input, fall back to keyboard/gamepad input
			# Uses Godot's Input Map for action-based controls
			# Returns a normalized vector based on configured input actions
			input_dir = Input.get_vector("move_forward", "move_backward", "move_left", "move_right")
		
		# Step 3: Transform 2D input into 3D world-space direction
		# - xr_player.transform.basis contains the player's rotation
		# - Multiply by Vector3(input_dir.y, 0, input_dir.x) to convert to 3D
		#   (y component is 0 because we only move horizontally, not vertically)
		# - .normalized() ensures the direction vector has length of 1
		#   (prevents diagonal movement from being faster)
		var movement_dir := (xr_player.transform.basis * Vector3(input_dir.y, 0, input_dir.x)).normalized()
		
		# Step 4: Apply smooth acceleration or deceleration
		if input_dir:
			# Player is pressing movement input - ACCELERATE toward target velocity
			
			# Smoothly adjust X velocity (left/right movement)
			# move_toward(current, target, max_delta) prevents jarring instant changes
			xr_player.velocity.x = move_toward(
				xr_player.velocity.x,                      # Current X velocity
				movement_dir.x * movement_speed,           # Target X velocity
				acceleration * delta                       # Maximum change this frame
			)
			
			# Smoothly adjust Z velocity (forward/backward movement)
			xr_player.velocity.z = move_toward(
				xr_player.velocity.z,                      # Current Z velocity
				movement_dir.z * movement_speed,           # Target Z velocity
				acceleration * delta                       # Maximum change this frame
			)
		else:
			# No input detected - DECELERATE to a stop
			
			# Smoothly reduce X velocity to zero
			xr_player.velocity.x = move_toward(
				xr_player.velocity.x,                      # Current X velocity
				0,                                         # Target: complete stop
				acceleration * delta                       # Deceleration rate
			)
			
			# Smoothly reduce Z velocity to zero
			xr_player.velocity.z = move_toward(
				xr_player.velocity.z,                      # Current Z velocity
				0,                                         # Target: complete stop
				acceleration * delta                       # Deceleration rate
			)
		
	# Note: The actual movement is handled automatically by CharacterBody3D
	# Make sure that the CharacterBody3D has a script that calls move_and_slide() in _physics_process
