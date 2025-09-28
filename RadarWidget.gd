# RadarWidget.gd
extends Control
class_name RadarWidget

@export var scanner_path: NodePath
@export var heading_up: bool = true        # true = radar rotates with ship ("heading up")
@export var clamp_to_edge: bool = true     # blips at range stick to the rim
@export var blip_size := Vector2(8, 8)
@export var friendly_tex: Texture2D
@export var enemy_tex: Texture2D
@export var neutral_tex: Texture2D

var _scanner: RadarScanner
var _blips := {}        # body: TextureRect
var _center := Vector2.ZERO
var _radius := 0.0
var _host: Node3D       # the ship that owns the scanner

var _show_debug_rim := true

func _ready() -> void:
	_recalc_geometry()
	resized.connect(_recalc_geometry)

	if scanner_path != NodePath():
		_scanner = get_node(scanner_path) as RadarScanner
		if _scanner:
			_scanner.contact_entered.connect(_on_contact_entered)
			_scanner.contact_exited.connect(_on_contact_exited)
			_host = _scanner.get_parent() as Node3D



func _draw() -> void:
	if _show_debug_rim:
		draw_arc(_center, _radius, 0.0, TAU, 64, Color(0.2, 0.9, 0.2), 2.0)
		draw_line(_center + Vector2(-6,0), _center + Vector2(6,0), Color(0.2,0.9,0.2), 1.0)
		draw_line(_center + Vector2(0,-6), _center + Vector2(0,6), Color(0.2,0.9,0.2), 1.0)

func _recalc_geometry() -> void:
	_center = size * 0.5
	_radius = min(size.x, size.y) * 0.5 - 2.0

func _on_contact_entered(body: Node) -> void:
	var tex := _tex_for(_scanner.get_faction_of(body))
	var r := TextureRect.new()
	r.texture = tex
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.size = blip_size
	r.pivot_offset = blip_size * 0.5
	add_child(r)
	_blips[body] = r

func _on_contact_exited(body: Node) -> void:
	if body in _blips:
		_blips[body].queue_free()
		_blips.erase(body)

func _process(_dt: float) -> void:
	if not _scanner or not is_instance_valid(_scanner) or not _host:
		return
	var range := _scanner.radar_range
	for body in _blips.keys():
		if not is_instance_valid(body):
			_blips[body].queue_free()
			_blips.erase(body)
			continue
		var p2 := _world_to_radar2d(_host, body.global_position, heading_up)
		var scaled := p2 * (_radius / range)

		if clamp_to_edge and scaled.length() > _radius:
			scaled = scaled.normalized() * _radius
			_blips[body].self_modulate = Color(1,1,1,0.6) # at rim
		else:
			_blips[body].self_modulate = Color(1,1,1,1)

		_blips[body].position = _center + scaled - _blips[body].pivot_offset
		
		queue_redraw()

func _world_to_radar2d(host: Node3D, world_pos: Vector3, heading: bool) -> Vector2:
	var delta := world_pos - host.global_position
	if heading:
		# Heading-up: convert into host’s local X/Z plane
		var right := host.global_basis.x
		var forward := -host.global_basis.z   # Godot forward is -Z
		return Vector2(delta.dot(right), delta.dot(forward))
	else:
		# North-up: world X is right, world -Z is up
		return Vector2(delta.x, -delta.z)

func _tex_for(faction: StringName) -> Texture2D:
	match String(faction):
		"friendly":
			return friendly_tex if friendly_tex else neutral_tex
		"enemy":
			return enemy_tex if enemy_tex else neutral_tex
		_:
			return neutral_tex
