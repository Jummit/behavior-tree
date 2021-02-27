extends Area2D

export var speed := 250.0

var resources := 0
var target_object : Area2D
var target : Vector2

const ConstructionSite = preload("res://construction_site/construction_site.gd")
const GatherResource = preload("res://resource/resource.gd")

onready var tween : Tween = $Tween

func near_resource() -> int:
	return OK if get_overlapping_areas().size() > 0 else FAILED


func gather_resource():
	if not get_overlapping_areas().size() or\
			not get_overlapping_areas().front() is GatherResource:
		return FAILED
	else:
		yield(get_tree().create_timer(1.0), "timeout")
		if get_overlapping_areas().size():
			get_overlapping_areas().front().free()
			target_object = null
			resources += 1
			return OK
		else:
			return FAILED


func find_nearest_resource(max_range := "") -> int:
	target_object = get_nearest(get_tree().get_nodes_in_group("Resources"))
	if not target_object:
		return FAILED
	if max_range and\
			target_object.position.distance_to(position) > float(max_range):
		return FAILED
	target = target_object.position
	return OK


func target_random_point() -> int:
	target = Vector2(randf(), randf()) * 100
	return OK


func walk() -> int:
	if not target:
		return FAILED
	tween.interpolate_property(self, "position", position, target,
			position.distance_to(target) / speed, Tween.TRANS_LINEAR,
			Tween.EASE_IN)
	tween.start()
	yield(tween, "tween_completed")
	target = Vector2()
	return OK


func find_nearest_construction_site() -> int:
	target_object = get_nearest(get_tree().get_nodes_in_group("ConstructionSites"))
	if not target_object:
		return FAILED
	target = target_object.position
	return OK


func build() -> int:
	if not get_overlapping_areas().size()\
			or not get_overlapping_areas().front() is ConstructionSite\
			or resources <= 0 or get_overlapping_areas().front().completed:
		return FAILED
	else:
		yield(get_tree().create_timer(0.5), "timeout")
		if not get_overlapping_areas().size():
			return FAILED
		else:
			resources -= 1
			get_overlapping_areas().front().progress += 1
			return OK


func get_nearest(nodes : Array) -> Area2D:
	var nearest : Area2D
	var nearest_distance := INF
	for resource in nodes:
		var distance := position.distance_squared_to(resource.position)
		if distance < nearest_distance:
			nearest = resource
			nearest_distance = distance
	return nearest
