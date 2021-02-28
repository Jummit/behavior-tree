tool
extends Node

"""
Node that is used to play a behavior tree resource in game
"""

export var root_node := NodePath("../")
export var behavior_tree : Resource

onready var subject := get_node(root_node)

var Nodes = preload("res://addons/behavior_tree/nodes.gd").new()

func _ready() -> void:
	if Engine.editor_hint:
		return
	yield(subject, "ready")
	behavior_tree.strip_comments()
	while true:
		var result = Nodes.tick(behavior_tree.get_first_node(), subject,
				behavior_tree)
		if result is GDScriptFunctionState:
			yield(result, "completed")
		else:
			yield(get_tree(), "idle_frame")
