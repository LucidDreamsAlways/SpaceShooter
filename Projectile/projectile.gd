extends RayCast3D

@export var speed : float = 300
@export var damage: int = 10

func _physics_process(delta: float) -> void:
	position += global_basis * Vector3.FORWARD * speed * delta 
	target_position = Vector3.FORWARD * speed * delta
	force_raycast_update()
	
	if is_colliding():
		var collider = get_collider()
		print("Projectile hit:", collider.name, "(", collider.get_class(), ")")

		# Most likely hitting a CollisionShape/Mesh child, so check its parent
		var target = collider.get_parent()
		if target.is_in_group("enemies"):
			target.take_damage(damage)

		# Disappear after impact
		queue_free()



#extends RayCast3D
#
#@export var speed : float = 300
#@export var damage: int = 10  # how much damage this projectile does
#
## @onready var remote_transform := RemoteTransform3D.new()  # old stick-to-target feature
#
#func _physics_process(delta: float) -> void:
	#position += global_basis * Vector3.FORWARD * speed * delta 
	#target_position = Vector3.FORWARD * speed * delta
	#force_raycast_update()
	#
	#if is_colliding():
		#var collider = get_collider()
		#global_position = get_collision_point()
		#set_physics_process(false)
		#
		## Deal damage if collider can take it
		#if collider.has_method("take_damage"):
			#collider.take_damage(damage)
		#
		## === Old stick-to-target code (disabled for now) ===
		## collider.add_child(remote_transform)
		## remote_transform.global_transform = global_transform
		## remote_transform.remote_path = remote_transform.get_path_to(self)
		## remote_transform.tree_exited.connect(cleanup)
#
		## New behavior: just disappear on impact
		#queue_free()
#
## === Old cleanup function (only used if sticking was enabled) ===
## func cleanup() -> void:
## 	queue_free()
