tool
extends Node

enum ProcessMode {
	IDLE,
	PHYSICS,
	MANUAL,
}

export var root_node := NodePath("../")
export var behavior_tree : Resource
export var active := true setget set_active
export(ProcessMode) var process_mode := ProcessMode.IDLE setget set_process_mode

onready var subject := get_node(root_node)

var Nodes = preload("res://addons/behavior_tree/nodes.gd").new()

func _ready() -> void:
	set_active(active)


func tick() -> void:
	for node in behavior_tree.nodes:
		Nodes.tick(node, subject)


func set_process_mode(to):
	process_mode = to
	set_active(active)


func set_active(to):
	active = to
	if active and process_mode != ProcessMode.MANUAL and not Engine.editor_hint:
		set_process(process_mode == ProcessMode.IDLE)
		set_physics_process(process_mode == ProcessMode.PHYSICS)
	else:
		set_physics_process(false)
		set_process(false)


func _process(_delta : float) -> void:
	tick()


func _physics_process(_delta : float) -> void:
	tick()
