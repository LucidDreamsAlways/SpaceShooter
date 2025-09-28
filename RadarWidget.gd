# RadarWidget.gd
extends Control
class_name RadarWidget

@export var heading_up: bool = true        # rotate with ship
@export var clamp_to_edge: bool = true     # stick to rim
@export var blip_size := Vector2(8, 8)
@export var friendly_tex: Texture2D
@export var enemy_tex: Texture2D
@export var neutral_tex: Texture2D
@export var scanner_path: NodePath         # optional; can leave empty

# Add these at the top with your other exports
@export var invert_h: bool = false   # flip left/right
@export var invert_v: bool = false   # flip up/down

@export var bg_texture: Texture2D
@export_enum("FIT","FILL","STRETCH","CENTER") var bg_mode: String = "FIT"
@export var bg_tint: Color = Color(1,1,1,1)
@export var bg_rotate_with_heading: bool = false
@export var show_debug_rim: bool = false
@export var show_debug_cross: bool = false

var _scanner: RadarScanner
var _blips := {}        # body: TextureRect
var _center := Vector2.ZERO
var _radius := 0.0
var _host: Node3D

var _show_debug_rim := true

func _ready() -> void:
	_recalc_geometry()
	resized.connect(_recalc_geometry)
	_resolve_scanner()
	_ensure_default_textures()

func _resolve_scanner() -> void:
	if scanner_path != NodePath():
		_scanner = get_node(scanner_path) as RadarScanner
	if _scanner == null:
		_scanner = get_tree().get_first_node_in_group("radar_scanner") as RadarScanner

	if _scanner:
		_scanner.contact_entered.connect(_on_contact_entered)
		_scanner.contact_exited.connect(_on_contact_exited)
		_host = _scanner.get_parent() as Node3D
	else:
		push_warning("RadarWidget: No scanner found. Set scanner_path or ensure scanner is in group 'radar_scanner'.")

func _draw() -> void:
	# --- Draw background texture if provided ---
	if bg_texture != null:
		var rot: float = 0.0
		if bg_rotate_with_heading and _host != null:
			var f: Vector3 = -_host.global_basis.z
			rot = atan2(f.x, f.z)  # yaw
			
			draw_set_transform(_center, rot, Vector2.ONE)
			# get_size() may return Vector2i in some cases; wrap to Vector2 safely
			var tex_size: Vector2 = Vector2(bg_texture.get_size())
			var dest_size: Vector2 = Vector2(_radius * 2.0, _radius * 2.0)
			
			var scale: Vector2 = Vector2.ONE
			var pos: Vector2 = Vector2.ZERO
			
			match bg_mode:
				"STRETCH":
					scale = dest_size / tex_size
					pos = -(tex_size * scale) * 0.5
				"FIT":
					var k: float = min(dest_size.x / tex_size.x, dest_size.y / tex_size.y)
					scale = Vector2(k, k)
					pos = -(tex_size * scale) * 0.5
				"FILL":
					var k2: float = max(dest_size.x / tex_size.x, dest_size.y / tex_size.y)
					scale = Vector2(k2, k2)
					pos = -(tex_size * scale) * 0.5
				"CENTER":
					scale = Vector2.ONE
					pos = -tex_size * 0.5
				
			draw_texture_rect(bg_texture, Rect2(pos, tex_size * scale), false, bg_tint)
			# reset for any further drawing
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# --- Optional debug overlays ---
		if show_debug_rim and bg_texture == null:
			draw_arc(_center, _radius, 0.0, TAU, 64, Color(0.2, 0.9, 0.2), 2.0)
		
		if show_debug_cross:
			draw_line(_center + Vector2(-6, 0), _center + Vector2(6, 0), Color(0.2, 0.9, 0.2), 1.0)
			draw_line(_center + Vector2(0, -6), _center + Vector2(0, 6), Color(0.2, 0.9, 0.2), 1.0)



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
	# print("[RadarUI] + ", body.name) # debug if needed

func _on_contact_exited(body: Node) -> void:
	if body in _blips:
		_blips[body].queue_free()
		_blips.erase(body)
		# print("[RadarUI] - ", body.name)

func _process(_dt: float) -> void:
	if not _scanner or not is_instance_valid(_scanner) or not _host:
		return

	var scan_range := _scanner.radar_range  # avoid shadowing built-in 'range'

	for body in _blips.keys().duplicate():  # safe iteration
		if not is_instance_valid(body):
			_blips[body].queue_free()
			_blips.erase(body)
			continue

		var p2 := _world_to_radar2d(_host, (body as Node3D).global_position, heading_up)
		var scaled := p2 * (_radius / scan_range)

		if clamp_to_edge and scaled.length() > _radius:
			scaled = scaled.normalized() * _radius
			_blips[body].self_modulate = Color(1,1,1,0.6)
		else:
			_blips[body].self_modulate = Color(1,1,1,1)

		_blips[body].position = _center + scaled - _blips[body].pivot_offset

	queue_redraw()

func _world_to_radar2d(host: Node3D, world_pos: Vector3, heading: bool) -> Vector2:
	var delta := world_pos - host.global_position

	# GDScript style: value_if_true if condition else value_if_false
	var sx := -1.0 if invert_h else 1.0
	var sy := -1.0 if invert_v else 1.0

	if heading:
		var right := host.global_basis.x
		var forward := -host.global_basis.z  # Godot forward = -Z
		return Vector2(delta.dot(right) * sx, delta.dot(forward) * sy)
	else:
		# North-up: world X is right, world -Z is up
		return Vector2(delta.x * sx, -delta.z * sy)

func _tex_for(faction: StringName) -> Texture2D:
	match String(faction):
		"friendly":
			return friendly_tex if friendly_tex else neutral_tex
		"enemy":
			return enemy_tex if enemy_tex else neutral_tex
		_:
			return neutral_tex

# --- fallbacks so blips are visible even if you only set enemy_tex ---
func _ensure_default_textures() -> void:
	if neutral_tex == null:  neutral_tex  = _make_dot_texture(4, Color(0.75,0.75,0.75))
	if friendly_tex == null: friendly_tex = _make_dot_texture(4, Color(0.3,1.0,0.3))

func _make_dot_texture(radius: int, color: Color) -> Texture2D:
	var s := radius * 2 + 1
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # transparent background

	var r2 := float(radius * radius)
	for y in range(s):
		for x in range(s):
			var dx := float(x - radius)
			var dy := float(y - radius)
			if dx * dx + dy * dy <= r2:
				img.set_pixel(x, y, color)

	return ImageTexture.create_from_image(img)
