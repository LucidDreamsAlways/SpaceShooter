extends Label

func _on_speed_changed(s: float) -> void:
	text = "Speed: %.1f" % s
