extends RigidBody3D

@export_category("Custom Properties")
@export var simulated_mass: float
@export var snap_position: Node3D

var contacts: Array
var walkable_contacts: Array
var grabbed: bool

func _ready() -> void:
	mass = simulated_mass
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 32
	set_collision_layer_value(1, false)
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	set_collision_mask_value(2, true)
	set_collision_mask_value(3, true)
	set_collision_mask_value(4, true)
	set_collision_mask_value(7, true)

func _physics_process(_delta: float) -> void:
	_collision_check()

func _collision_check():
	if get_contact_count() > 0:
		for collisions in get_colliding_bodies():
			if contacts.has(collisions):
				pass
			else:
				contacts.append(collisions)
	if grabbed:
		set_collision_layer_value(2, false)
	else:
		set_collision_layer_value(2, true)
	
	for bodies in contacts:
		if bodies.get_collision_layer_value(2) == true:
			if walkable_contacts.has(bodies):
				pass
			else:
				walkable_contacts.append(bodies)
		if walkable_contacts.size() > 0:
			set_collision_layer_value(2, true)
		else:
			set_collision_layer_value(2, false)
		if bodies not in get_colliding_bodies():
			contacts.erase(bodies)
			walkable_contacts.erase(bodies)
