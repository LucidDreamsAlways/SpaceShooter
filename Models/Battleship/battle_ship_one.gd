extends Node3D

@export var max_health: int = 100
var current_health: int

@onready var health_label: Label3D = $HealthLabel

func _ready():
	current_health = max_health
	update_health_label()
	add_to_group("enemies")  # ✅ Now this node belongs to "enemies" group

func take_damage(amount: int):
	current_health -= amount
	current_health = max(current_health, 0)
	update_health_label()
	
	if current_health <= 0:
		die()

func update_health_label():
	if health_label:
		health_label.text = str(current_health, " / ", max_health)
		print("Health label updated:", health_label.text)

func die():
	print("Battleship destroyed!")
	queue_free()  # Later replace with explosion
