extends Node3D

const PROJECTILE = preload("res://Projectile/projectile.tscn")

@onready var timer: Timer = $Timer

@export var shoot_delay: float = 0.3

func _physics_process(delta: float) -> void:
	if timer.is_stopped():
		if Input.is_action_pressed("shoot"):
			timer.start(shoot_delay)
			var attack = PROJECTILE.instantiate()
			add_child(attack)
			attack.global_transform = global_transform
			$ShootSound.play()
