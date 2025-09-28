# RadarScanner.gd
extends Area3D
class_name RadarScanner

@export var radar_range: float = 5000.0
@export var detectable_groups: Array[String] = ["ship", "asteroid", "missile"]
@export var default_enemy_faction: StringName = &"enemy"

signal contact_entered(body: Node)
signal contact_exited(body: Node)

var _tracked := {} # body/area -> true

func _ready() -> void:
	monitoring = true
	monitorable = false     # others don't need to detect us
	add_to_group("radar_scanner")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	var cs := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if cs and cs.shape is SphereShape3D:
		(cs.shape as SphereShape3D).radius = radar_range

func _on_area_entered(a: Area3D) -> void: _on_body_entered(a)
func _on_area_exited(a: Area3D)  -> void: _on_body_exited(a)

func _on_body_entered(body: Node) -> void:
	if not _should_track(body):
		return
	_tracked[body] = true
	contact_entered.emit(body)

func _on_body_exited(body: Node) -> void:
	if _tracked.erase(body):
		contact_exited.emit(body)

func _should_track(body: Node) -> bool:
	if not (body is Node3D):
		return false
	if body == get_parent():  # ignore the owning ship
		return false
	for g in detectable_groups:
		if body.is_in_group(g):
			return true
	return body.has_method("get_faction")

func get_faction_of(body: Node) -> StringName:
	if body.has_method("get_faction"):
		return body.get_faction()
	if body.is_in_group("friendly"):
		return &"friendly"
	if body.is_in_group("enemy"):
		return &"enemy"
	return default_enemy_faction if body.is_in_group("ship") else &"neutral"
