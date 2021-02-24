tool
extends Node

export var root_node := NodePath("../")
export var behavior_tree : Resource

onready var subject := get_node(root_node)

var Nodes = preload("res://addons/behavior_tree/nodes.gd").new()

func _ready() -> void:
	if Engine.editor_hint:
		return
	yield(subject, "ready")
	while true:
		var states := []
		for node in behavior_tree.graphs.values().front():
			states.append(Nodes.tick(node, subject, behavior_tree))
		for state in states:
			if state is GDScriptFunctionState:
				yield(state, "completed")
		yield(get_tree(), "idle_frame")
