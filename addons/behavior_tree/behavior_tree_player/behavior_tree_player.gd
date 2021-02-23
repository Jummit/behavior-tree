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
		for node in behavior_tree.nodes:
			states.append(Nodes.tick(node, subject))
		for state in states:
			yield(state, "completed")
