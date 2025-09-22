extends Camera3D

# ── References ──────────────────────────────────────────────────────────────
@export var ship_path: NodePath        # leave empty if Camera3D's parent is the ship
@export var ship_max_speed: float = 200.0   # for FOV kick curve

# ── Position lag controls ───────────────────────────────────────────────────
@export var pos_lag_per_100: float = 0.05   # m backward per 100 speed
@export var lateral_lag_scale: float = 0.03 # m sideways per 100 speed
@export var smooth: float = 6.0             # higher = snappier return
@export var max_backward: float = 1.5
@export var max_side: float = 0.8
@export var max_up: float = 0.5

# ── Tilt controls ───────────────────────────────────────────────────────────
@export var rot_tilt_scale: float = 0.003   # radians tilt per rad/s angular rate

# ── FOV controls ────────────────────────────────────────────────────────────
@export var base_fov: float = 45.0
@export var max_fov: float = 55.0
@export var fov_smooth: float = 5.0
@export var fov_curve: float = 1.0   # >1 = kick late, <1 = kick early

# ── Internals ───────────────────────────────────────────────────────────────
var ship: Node
var cam_offset: Vector3 = Vector3.ZERO
var cam_rot: Quaternion = Quaternion.IDENTITY
var base_local_transform: Transform3D

func _ready() -> void:
	# Find the ship
	if ship_path == NodePath(""):
		ship = get_parent()
	else:
		ship = get_node(ship_path)

	if ship == null:
		push_error("ShipCamGFeel: ship not found. Set ship_path or make Camera3D a child of the ship.")
		set_process(false)
		return

	# Remember how the camera is placed in the editor
	base_local_transform = transform
	fov = base_fov

func _process(delta: float) -> void:
	if ship == null:
		return

	# --- Velocity-based positional lag ---------------------------------------
	var v_world: Vector3 = ship.velocity if "velocity" in ship else Vector3.ZERO
	var ship_b: Basis = ship.global_transform.basis
	var v_local: Vector3 = ship_b.inverse() * v_world

	var back: float = clamp(-v_local.z * (pos_lag_per_100 * 0.01), -max_backward, 0.0)
	var side: float = clamp(-v_local.x * (lateral_lag_scale * 0.01), -max_side, max_side)
	var up: float   = clamp( v_local.y * (lateral_lag_scale * 0.005), -max_up, max_up)

	var target_offset: Vector3 = Vector3(side, up, back)
	var a_pos: float = 1.0 - exp(-smooth * delta)
	cam_offset = cam_offset.lerp(target_offset, a_pos)

	# --- Angular tilt using ship’s own smoothed rates ------------------------
	var rates: Vector3 = Vector3.ZERO
	if ship.has_method("get_angular_rates"):
		rates = ship.get_angular_rates()  # expected: (pitch, yaw, roll) in rad/s

	var tilt_x: float =  rates.x * rot_tilt_scale
	var tilt_y: float = -rates.y * rot_tilt_scale
	var tilt_z: float = -rates.z * rot_tilt_scale

	var target_rot: Quaternion = Quaternion(Vector3.RIGHT, tilt_x) \
		* Quaternion(Vector3.UP, tilt_y) \
		* Quaternion(Vector3.FORWARD, tilt_z)

	cam_rot = cam_rot.slerp(target_rot, a_pos)

	# --- Apply relative to the original camera transform ---------------------
	var t: Transform3D = base_local_transform
	t.origin += cam_offset
	t.basis = Basis(cam_rot) * t.basis
	transform = t

	# --- FOV kick ------------------------------------------------------------
	var speed: float = v_world.length()
	var t_speed: float = pow(clamp(speed / ship_max_speed, 0.0, 1.0), fov_curve)
	var target_fov: float = lerp(base_fov, max_fov, t_speed)
	var a_fov: float = 1.0 - exp(-fov_smooth * delta)
	fov = lerp(fov, target_fov, a_fov)
