extends Sprite2D

var zoom_factor = 8

func update_positon(pos):
	global_position = pos / zoom_factor

func delete_marker():
	call_deferred("queue_free")

 
