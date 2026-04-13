extends Node3D

func _ready() -> void:
	$Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation([
		"mixamorig_RightHandThumb1",
		"mixamorig_RightHandIndex1",
		"mixamorig_RightHandMiddle1",
		"mixamorig_RightHandRing1",
		"mixamorig_RightHandPinky1"
		])
