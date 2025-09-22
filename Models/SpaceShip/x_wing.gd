extends CharacterBody3D

@export var max_speed = 200.0
@export var acceleration = 0.9
@export var pitch_speed = 1.5
@export var roll_speed = 1.9
@export var yaw_speed = 1.25  # Set lower for linked roll/yaw
@export var input_response = 8.0

var forward_speed = 0.0
var pitch_input = 0.0
var roll_input = 0.0
var yaw_input = 0.0

@onready var speed_label: Label = $Camera3D/HUD/Speed_data  # <- adjust names if needed
var _last_speed := -1.0

func _ready():
	print("eh")
	#Load and instance the HUD scene
	#hud_instance = preload("res://UI/HUD/HUD.tscn").instance()
	#add_child(hud_instance)

func get_input(delta: float) -> void:
	if Input.is_action_pressed("throttle_up"):
		forward_speed = lerp(forward_speed, max_speed, acceleration * delta)
	if Input.is_action_pressed("throttle_down"):
		forward_speed = lerp(forward_speed, 0.0, acceleration * delta)

	pitch_input = lerp(pitch_input, Input.get_axis("pitch_down", "pitch_up"),
			input_response * delta)
	roll_input = lerp(roll_input, Input.get_axis("roll_right", "roll_left"),
			input_response * delta)
	yaw_input = lerp(yaw_input, Input.get_axis("yaw_right", "yaw_left"),
			input_response * delta)
	#yaw_input = roll_input

func _physics_process(delta: float) -> void:
	get_input(delta)
	
	transform.basis = transform.basis.rotated(transform.basis.z, roll_input * roll_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.x, pitch_input * pitch_speed * delta)
	transform.basis = transform.basis.rotated(transform.basis.y, yaw_input * yaw_speed * delta)
	transform.basis = transform.basis.orthonormalized()
	
	velocity = transform.basis.z * forward_speed
	move_and_collide(velocity * delta)

# Update HUD only when the value changes
	if not is_equal_approx(forward_speed, _last_speed):
		_last_speed = forward_speed
		if speed_label:
			speed_label.text = "Speed: %.1f" % forward_speed
