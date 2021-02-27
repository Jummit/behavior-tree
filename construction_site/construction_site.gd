extends Area2D

var progress := 0.0 setget set_progress
var completed := false

func set_progress(to):
	progress = to
	$ProgressBar.value = progress
	if progress == 10:
		completed = true
