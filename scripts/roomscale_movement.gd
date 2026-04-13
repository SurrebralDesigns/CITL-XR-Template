# This script extends Node and creates a reusable class called "RoomscaleMovement"
# Credit for the original implementation goes to Bastiaan Olij
extends Node
class_name RoomscaleMovement

## ROOMSCALE MOVEMENT SYSTEM FOR VR
# This script handles physical room-scale movement in VR, where the player
# can physically walk around in their real-world play space and have that
# movement translated into the game world.
#
# KEY CONCEPT:
# In VR, there are TWO types of movement:
# 1. PHYSICAL: Player walks around in real room (tracked by VR headset)
# 2. VIRTUAL: Character moves in game world (handled by physics)
#
# This script synchronizes these two movement systems!

## VISUAL DIAGRAM - VR HIERARCHY STRUCTURE:
#
#   CharacterBody3D (xr_player) ← Physics body that moves in game world
#   └── XROrigin3D (xr_origin)  ← Anchor point for VR tracking space
#       └── XRCamera3D (xr_camera) ← Player's actual head position in room
#
# IMPORTANT RELATIONSHIPS:
# • xr_player = Where the game thinks you are (handles collisions/physics)
# • xr_camera = Where your head actually is in real space
# • xr_origin = The "bridge" that connects these two coordinate systems
#
# VISUAL DIAGRAM - HOW ROOMSCALE MOVEMENT WORKS:
#
# PROBLEM: When the player walks in the real room, the camera moves but the character doesn't!
#
#   BEFORE:                           AFTER THIS SCRIPT:
#   ═══════                           ══════════════════
#
#   ┌─────────────┐                  ┌─────────────┐
#   │ Real Room   │                  │ Real Room   │
#   │             │                  │             │
#   │    @        │  Player walks    │        @    │
#   │   Camera    │  to the right    │      Camera │
#   └─────────────┘  ────────────►   └─────────────┘
#                                             
#   ┌─────────────┐                  ┌─────────────┐
#   │ Game World  │                  │ Game World  │
#   │             │                  │             │
#   │     $       │  Character       │       $     │
#   │  Character  │  moves too!      │   Character │
#   └─────────────┘                  └─────────────┘

## THE ALGORITHM (5 MAJOR STEPS):
#
#   [1] ROTATION SYNC
#       ├─► Calculate which way the player's head is facing
#       ├─► Rotate the character body to match
#       └─► Counter-rotate XROrigin to keep camera in same spot
#
#   [2] CALCULATE TARGET POSITION
#       ├─► Find where the camera is relative to character
#       └─► This is where the character should move to
#
#   [3] MOVE CHARACTER BODY
#       ├─► Set velocity to reach target position
#       ├─► Call move_and_slide() to handle physics/collisions
#       └─► Character may hit walls and not reach target!
#
#   [4] COMPENSATE ORIGIN
#       ├─► Move XROrigin backward by same amount character moved
#       └─► This keeps camera-to-character relationship consistent
#
#   [5] EMIT SIGNAL
#       └─► Tell other systems if there was a collision
#           (difference between where we wanted to go vs. where we ended up)
#
# COORDINATE TRANSFORM VISUALIZATION:
#
#   STEP-BY-STEP EXAMPLE (Player walks 1 meter forward in real room):
#
#   Initial State:
#   ┌────────────────────────────────────────────────────────────┐
#   │ Character Body        XROrigin           Camera            │
#   │ Position: (0,0,0) ──► (0,0,0) ────────► (0,0,1) [moved!]   │
#   └────────────────────────────────────────────────────────────┘
#
#   After Processing:
#   ┌────────────────────────────────────────────────────────────┐
#   │ Character Body        XROrigin           Camera            │
#   │ Position: (0,0,1) ◄── (0,0,-1) ◄─────── (0,0,1)            │
#   │   [MOVED!]            [COMPENSATED]      [tracking space]  │
#   └────────────────────────────────────────────────────────────┘
#
#   Result: Character moved forward in world, Origin moved back,
#           Camera stayed in same relative position = Seamless!

# EXPORTED VARIABLES (Visible in Godot Inspector)
@export_category("Required Variables")

# The physics body that represents the player in the game world
# This handles collisions, gravity, and movement through the game space
@export var xr_player: CharacterBody3D

# The origin point of the VR tracking space
# This acts as the "anchor" between real-world movement and game-world position
@export var xr_origin: XROrigin3D

# The VR camera representing the player's head/viewpoint
# This tracks where the player's head is in their real-world play space
@export var xr_camera: XRCamera3D

# SIGNALS
# Emitted each frame with the distance between where the player wanted to move
# and where they actually ended up (useful for detecting collisions/obstacles)
# Value will be 0.0 if movement was unobstructed, >0.0 if blocked by something
signal location_offset

# PHYSICS PROCESS FUNCTION
# This runs every physics frame
# It synchronizes the player's physical room-scale movement with the game world
func _physics_process(delta: float) -> void:
	# STEP 0: PRESERVE CURRENT VELOCITY
	# Store the current velocity (from gravity, jumping, other movement scripts)
	# We'll restore this at the end so we don't interfere with other movement
	var current_velocity = xr_player.velocity
	
	# STEP 1: ROTATION SYNCHRONIZATION
	# We need to rotate the character body to face the same direction as the
	# player's head, so they don't walk sideways or backwards unintentionally
	# Get the combined rotation of both XROrigin and XRCamera
	# This represents the actual direction the player is facing
	var camera_basis: Basis = xr_origin.transform.basis * xr_camera.transform.basis
	
	# Extract the forward direction (-Z axis) and project it onto the XZ plane
	# We only care about horizontal rotation, not if player is looking up/down
	var forward: Vector2 = Vector2(camera_basis.z.x, camera_basis.z.z)
	
	# Calculate the angle between the camera's forward direction and world forward
	# Vector2(0.0, 1.0) represents "forward" in Godot's 2D coordinate system
	var angle: float = forward.angle_to(Vector2(0.0, 1.0))
	
	# Rotate the character body around the Y axis (up) by the calculated angle
	# This makes the character face the same direction as the player's head
	xr_player.transform.basis = xr_player.transform.basis.rotated(Vector3.UP, angle)
	
	# CRITICAL: Counter-rotate the XROrigin by the negative angle
	# This keeps the camera in the same position relative to the world
	# Without this, the camera would spin around when the character rotates!
	xr_origin.transform = Transform3D().rotated(Vector3.UP, -angle) * xr_origin.transform
	
	# STEP 2: CALCULATE TARGET POSITION
	# Now we figure out where the character body should move to based on
	# where the player's head (camera) is positioned in the tracking space
	# Store the character's current position (we'll need this later)
	var org_player_body: Vector3 = xr_player.global_transform.origin
	
	# Calculate where the camera is in world space
	# First: Get camera position relative to XROrigin
	# Then: Transform it by XROrigin to get local position
	var player_body_location: Vector3 = xr_origin.transform * xr_camera.transform.origin
	
	# Flatten the Y component to 0 (we don't want the character to fly up
	# just because the player is tall or crouched down in real life)
	player_body_location.y = 0.0
	
	# Transform this local position into global world coordinates
	player_body_location = xr_player.global_transform * player_body_location
	
	# STEP 3: MOVE THE CHARACTER BODY
	# Set the velocity needed to move from current position to target position
	# in exactly one frame (that's why we divide by delta)
	xr_player.velocity = (player_body_location - org_player_body) / delta
	
	# Execute the movement with physics and collision detection
	# This may result in the character NOT reaching the target if blocked by walls
	xr_player.move_and_slide()
	
	# STEP 4: COMPENSATE THE XRORIGIN
	# The character body just moved, but the XROrigin (and camera) didn't
	# We need to move the XROrigin backward to maintain proper relationship
	# Calculate how far the character actually moved
	# (might be different from target if they hit a wall!)
	var delta_movement = xr_player.global_transform.origin - org_player_body
	
	# Move the XROrigin backward by the same amount the character moved forward
	# This creates the illusion that the tracking space moves with the player
	xr_origin.global_transform.origin -= delta_movement
	
	# OPTIONAL: Negate height changes (commented out by default)
	# This line would lock the origin height, preventing the player from
	# experiencing vertical movement when walking up ramps or stairs
	# Uncomment if you want a completely flat experience:
	##xr_origin.transform.origin.y = -1.0
	
	# STEP 5: RESTORE VELOCITY AND EMIT SIGNAL
	# Restore the original velocity (gravity, jumping, smooth locomotion, etc.)
	# We only temporarily changed it to handle room-scale movement
	xr_player.velocity = current_velocity
	
	# Calculate the difference between where we wanted to go and where we ended up
	# If this value is > 0, the player bumped into something
	# Other scripts can listen to this signal to play bump sounds, haptics, etc.
	location_offset.emit((player_body_location - xr_player.global_transform.origin).length())

## USAGE NOTES FOR BEGINNERS:
#
# 1. ATTACH THIS SCRIPT to a Node in your VR scene (not the CharacterBody3D)
#
# 2. SET THE EXPORTS in the Inspector:
#    • xr_player → Your CharacterBody3D node
#    • xr_origin → Your XROrigin3D node (child of CharacterBody3D)
#    • xr_camera → Your XRCamera3D node (child of XROrigin3D)
#
# 3. HIERARCHY should look like:
#    CharacterBody3D (xr_player)
#    ├── CollisionShape3D
#    ├── XROrigin3D (xr_origin)
#    │   └── XRCamera3D (xr_camera)
#    └── Node (this script attached here)
#
# 4. CONNECT THE SIGNAL (optional):
#    You can connect location_offset to other scripts to detect when
#    the player bumps into walls or gets blocked
