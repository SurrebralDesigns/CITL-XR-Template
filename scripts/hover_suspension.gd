extends ShapeCast3D
class_name HoverSuspension

##OVERVIEW
# ============================================================
#  HOVER SUSPENSION DIAGRAM (ASCII VISUALIZATION)
# ============================================================
#
#                 XR PLAYER BODY
#                ┌──────────────┐
#                │              │
#                │ body_collider│  <–– CollisionShape3D
#                │              │
#                └───────┬──────┘
#                        │  (hover_height)
#                        ▼
#                 (ShapeCast3D origin -> typically positioned at the bottom of the body_collider)
#                        ●  <–– SphereShape3D (casts downward)
#                        │
#                        │  shapecast distance
#                        │
#                ────────┼────────────────────  <–– contact point
#                    GROUND SURFACE
# How it works:
# 1. The ShapeCast sphere checks how far the player is from the ground.
# 2. If the distance is LESS than hover_height → push player upward.
# 3. If the distance is MORE than hover_height → gravity pulls player down.
# 4. If standing on a RigidBody, the player also applies a downward force
#    so they do not unrealistically lift heavy objects.
# ============================================================

## Required Variables
@export_category("Required Variables")
# Get the gravity value from the project settings so physics matches the engine's gravity.
@onready var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Reference to the XR player character (the body that will move and receive forces).
@export var xr_player: CharacterBody3D

# Reference to the XR Origin, which represents where the VR player stands in the world.
@export var xr_origin: XROrigin3D

# Collision shape of the character's body (used to keep the suspension aligned).
@export var body_collider: CollisionShape3D

## Hover Suspension Settings
@export_category("Hover Suspension Settings")
# Desired distance to maintain above ground
@export var hover_height: float = 1.25

# How strong the suspension pushes upward
@export var hover_strength: float = 50

# Simulate the mass of the character's body
@export var simulated_weight: int = 5

# True when the suspension detects the ground
var is_grounded: bool

## _ready() initializes the system
func _ready() -> void:
	# If the ShapeCast has no shape, create a small sphere for detection
	if shape == null:
		shape = SphereShape3D.new()
		shape.radius = .1
	
	# Make sure that are target_position is the same as our hover height
	target_position.y = -hover_height
	
	# Align VR origin height with target position of the ShapeCast
	xr_origin.position.y = target_position.y
	
	# Position the player’s collider to match hover height
	#body_collider.position.y = hover_height * body_collider.shape.height - .1
	
	collision_mask = 2 # Only detect objects on layer 2

## _physics_process runs every physics step (framerate independent)
func _physics_process(delta: float) -> void:
	# Keep the ShapeCast under the player's body
	position.x = body_collider.position.x
	position.z = body_collider.position.z
	
	# Apply gravity ourselves (since CharacterBody3D doesn't use built-in gravity)
	xr_player.velocity.y -= gravity * delta
	
	# If ShapeCast hits the ground, calculate distance + apply suspension
	if is_colliding():
		var collider = get_collider(0) # The object the ShapeCast hit
		var contact: Vector3 = get_collision_point(0) # The position where the ShapeCast made contact
		
		# Distance from the player to the ground contact point
		var distance: float = global_position.distance_to(contact)
		
		# How far off we are from the intended hover height
		var offset: float = hover_height - distance
		
		# Upward force proportional to how far below hover height we are
		var hover_force: float = hover_strength * offset
		
		# Acknowledge that we are touching the ground
		is_grounded = true
		
		# Adjust vertical velocity to maintain hover effect
		if distance != hover_height:
			# Apply an upward force by modifying vertical velocity
			# Dividing by gravity scales the force to feel natural
			xr_player.velocity.y = (xr_player.velocity.y + hover_force) / gravity
			
			# Apply downward force to RigidBodies below the player (realistic weight transfer)
			if collider is RigidBody3D:
				var downward_force: Vector3 = Vector3(0, -simulated_weight, 0) / delta # How much force to apply
				var downward_offset: Vector3 = Vector3(contact - collider.global_position) # Where to apply the force
				collider.apply_force(downward_force, downward_offset) # Apply the force to the RigidBody

	else: # If the ShapeCast is not colliding
		is_grounded = false  # No ground detected → airborne
