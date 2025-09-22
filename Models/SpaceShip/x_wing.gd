extends CharacterBody3D

# ── Flight tuning ──────────────────────────────────────────────────────────────
@export var max_speed: float = 200.0
@export var acceleration: float = 0.9
@export var input_response: float = 8.0           # throttle smoothing
@export var pitch_speed: float = 1.5              # rad/s
@export var roll_speed: float  = 1.9              # rad/s
@export var yaw_speed: float   = 1.25             # rad/s

# Less "snappy" feel: lower = more inertia/lag
@export var rot_sharpness: float = 0.1            # try 0.07–0.12 for heavier feel

# ── Combat stats ───────────────────────────────────────────────────────────────
@export var max_health: float = 100.0
@export var max_shield: float = 75.0
@export var shield_regen_rate: float = 8.0        # HP/sec
@export var shield_regen_delay: float = 3.0       # sec after damage before regen

var health: float = max_health
var shield: float = max_shield
var _time_since_damage: float = 999.0

# ── Inputs & dynamics ─────────────────────────────────────────────────────────
var forward_speed: float = 0.0
var pitch_input: float = 0.0
var roll_input: float = 0.0
var yaw_input: float = 0.0

# Smoothed angular rates actually applied each frame
var pitch_rate: float = 0.0
var roll_rate: float  = 0.0
var yaw_rate: float   = 0.0

# ── HUD refs (under Camera -> HUD) ────────────────────────────────────────────
@onready var speed_label: Label       = $Camera3D/HUD/SpeedLabel as Label
@onready var health_bar: ProgressBar  = $Camera3D/HUD/HealthBar  as ProgressBar
@onready var shield_bar: ProgressBar  = $Camera3D/HUD/ShieldBar  as ProgressBar

var _last_speed: float = -1.0

func _ready() -> void:
	# Init HUD once
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = health
	if shield_bar:
		shield_bar.max_value = max_shield
		shield_bar.value = shield
	if speed_label:
		speed_label.text = "Speed: %.1f" % forward_speed

func get_input(delta: float) -> void:
	if Input.is_action_pressed("throttle_up"):
		forward_speed = lerp(forward_speed, max_speed, acceleration * delta)
	if Input.is_action_pressed("throttle_down"):
		forward_speed = lerp(forward_speed, 0.0,      acceleration * delta)

	pitch_input = lerp(pitch_input, Input.get_axis("pitch_down", "pitch_up"),  input_response * delta)
	roll_input  = lerp(roll_input,  Input.get_axis("roll_right", "roll_left"), input_response * delta)
	yaw_input   = lerp(yaw_input,   Input.get_axis("yaw_right", "yaw_left"),   input_response * delta)

func _physics_process(delta: float) -> void:
	get_input(delta)

	# ── Rotation with inertia (less snappy) ────────────────────────────────────
	var tgt_pitch: float = pitch_input * pitch_speed
	var tgt_roll:  float = roll_input  * roll_speed
	var tgt_yaw:   float = yaw_input   * yaw_speed

	# Exponential smoothing factor: a = 1 - exp(-k*dt), with k = 1/rot_sharpness
	var k: float = 1.0 / max(rot_sharpness, 0.0001)
	var a: float = 1.0 - exp(-k * delta)

	pitch_rate = lerp(pitch_rate, tgt_pitch, a)
	roll_rate  = lerp(roll_rate,  tgt_roll,  a)
	yaw_rate   = lerp(yaw_rate,   tgt_yaw,   a)

	transform.basis = transform.basis.rotated(transform.basis.z, roll_rate  * delta)
	transform.basis = transform.basis.rotated(transform.basis.x, pitch_rate * delta)
	transform.basis = transform.basis.rotated(transform.basis.y, yaw_rate   * delta)
	transform.basis = transform.basis.orthonormalized()

	# ── Translation ───────────────────────────────────────────────────────────
	velocity = transform.basis.z * forward_speed
	move_and_collide(velocity * delta)

	# ── Shield regen (delayed) ────────────────────────────────────────────────
	_time_since_damage += delta
	if _time_since_damage >= shield_regen_delay and shield < max_shield and health > 0.0:
		shield = min(max_shield, shield + shield_regen_rate * delta)

	# ── HUD updates ──────────────────────────────────────────────────────────
	if speed_label and not is_equal_approx(forward_speed, _last_speed):
		_last_speed = forward_speed
		speed_label.text = "Speed: %.1f" % forward_speed

	if health_bar:
		health_bar.value = health
	if shield_bar:
		shield_bar.value = shield

# ───────────────────────── Combat helpers ─────────────────────────────────────
func apply_damage(amount: float) -> void:
	_time_since_damage = 0.0
	if shield > 0.0:
		var from_shield: float = min(shield, amount)
		shield -= from_shield
		amount -= from_shield
	if amount > 0.0:
		health = clamp(health - amount, 0.0, max_health)

func heal(amount: float) -> void:
	health = min(health + amount, max_health)

func add_shield(amount: float) -> void:
	shield = min(shield + amount, max_shield)

# ───────────────────────── Camera helper ─────────────────────────────────────
func get_angular_rates() -> Vector3:
	return Vector3(pitch_rate, yaw_rate, roll_rate)
