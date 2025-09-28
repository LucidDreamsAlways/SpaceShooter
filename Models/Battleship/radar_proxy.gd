# RadarProxy.gd
extends Area3D
@export var faction: StringName = &"enemy"

func _ready() -> void:
	# Let the scanner find us via groups
	add_to_group("ship")
	if faction == &"enemy":
		add_to_group("enemy")
	elif faction == &"friendly":
		add_to_group("friendly")
	# Defaults are fine: monitoring=true, monitorable=true
	# We don't need to detect anything; we just need to be detected.

func get_faction() -> StringName:
	return faction
