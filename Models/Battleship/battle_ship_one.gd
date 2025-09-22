extends Node3D

#func _ready() -> void:
	## Create a StaticBody3D for the colliders
	#var static_body := StaticBody3D.new()
	#static_body.name = "CollisionBody"
	#add_child(static_body)
#
	## Loop through all MeshInstances in this battleship
	#var meshes := find_children("*", "MeshInstance3D", true, false)
	#for mesh_instance in meshes:
		#var mesh: Mesh = mesh_instance.mesh
		#if mesh == null:
			#continue
#
		## Build a concave shape (accurate for static geometry)
		#var shape := mesh.create_trimesh_shape()
		#var collider := CollisionShape3D.new()
		#collider.shape = shape
		#collider.transform = mesh_instance.transform
#
		#static_body.add_child(collider)
#
	#print("Battleship colliders generated:", static_body.get_child_count())
