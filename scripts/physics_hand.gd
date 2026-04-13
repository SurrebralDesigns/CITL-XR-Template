extends Node3D

func _ready() -> void:
	$Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation(
		["mixamorig_RightHandThumb1",
		"mixamorig_RightHandThumb2",
		"mixamorig_RightHandThumb3",
		"mixamorig_RightHandThumb4",
		"mixamorig_RightHandIndex1",
		"mixamorig_RightHandIndex2",
		"mixamorig_RightHandIndex3",
		"mixamorig_RightHandIndex4",
		"mixamorig_RightHandMiddle1",
		"mixamorig_RightHandMiddle2",
		"mixamorig_RightHandMiddle3",
		"mixamorig_RightHandMiddle4",
		"mixamorig_RightHandRing1",
		"mixamorig_RightHandRing2",
		"mixamorig_RightHandRing3",
		"mixamorig_RightHandRing4",
		"mixamorig_RightHandPinky1",
		"mixamorig_RightHandPinky2",
		"mixamorig_RightHandPinky3",
		"mixamorig_RightHandPinky4"])
