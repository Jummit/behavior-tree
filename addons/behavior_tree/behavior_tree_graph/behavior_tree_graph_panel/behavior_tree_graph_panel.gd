tool
extends Control

var behavior_tree : BehaviorTree setget set_behavior_tree
var create_node_dialog : ConfirmationDialog
var to_slot := -1
var to_node : String
var from_slot := -1
var from_node : String

var copied := []

const BehaviorTree = preload("res://addons/behavior_tree/behavior_tree.gd")
const BehaviorNode = preload("res://addons/behavior_tree/behavior_tree_graph/behavior_node/behavior_node.tscn")

onready var graph_edit : GraphEdit = $VBoxContainer/GraphEdit

func _ready() -> void:
	var create_node_button := Button.new()
	create_node_button.text = "Add Node..."
	create_node_button.connect("pressed", self, "_on_CreateNodeButton_pressed")
	create_node_button.flat = true
	graph_edit.get_zoom_hbox().add_child(create_node_button)
	graph_edit.get_zoom_hbox().move_child(create_node_button, 0)
	
	create_node_dialog.connect("node_selected", self,
			"_on_CreateBehaviorNodeDialog_node_selected")
	create_node_dialog.connect("hide", self, "_on_CreateBehaviorNodeDialog_hide")


func set_behavior_tree(to):
	behavior_tree = to
	for node in graph_edit.get_children():
		if node is GraphNode:
			node.queue_free()
	graph_edit.clear_connections()
	var store := {}
	add_nodes(behavior_tree.nodes, store)
	connect_nodes(behavior_tree.nodes, store)


func add_nodes(nodes : Array, store : Dictionary, select := false) -> void:
	for node in nodes:
		var new_node := BehaviorNode.instance()
		graph_edit.add_child(new_node)
		new_node.init(node)
		new_node.selected = select
		store[node] = new_node
		add_nodes(node.children, store, select)


func connect_nodes(nodes : Array, store : Dictionary, from := {}) -> void:
	for node_num in nodes.size():
		if from:
			graph_edit.connect_node(store[from].name, node_num,
					store[nodes[node_num]].name, 0)
		for child in nodes[node_num].children:
			connect_nodes(nodes[node_num].children, store, nodes[node_num])


func offset_nodes(nodes : Array, offset : Vector2) -> void:
	for node in nodes:
		node.position += offset
		offset_nodes(node.children, offset)


func _on_CreateNodeButton_pressed():
	show_create_dialog()


func _on_GraphEdit_connection_request(from : String, from_slot : int,
		to : String, to_slot : int) -> void:
	graph_edit.connect_node(from, from_slot, to, to_slot)


func _on_GraphEdit_connection_from_empty(to : String, _to_slot : int,
		release_position : Vector2) -> void:
	to_node = to
	to_slot = _to_slot
	show_create_dialog(true)


func _on_GraphEdit_connection_to_empty(from : String, _from_slot : int,
		_release_position : Vector2) -> void:
	from_node = from
	from_slot = _from_slot
	show_create_dialog(true)


func _on_CreateBehaviorNodeDialog_hide():
	from_node = ""
	from_slot = 1
	to_node = ""
	to_slot = -1


func _on_GraphEdit_delete_nodes_request() -> void:
	for node in graph_edit.get_children():
		if node is GraphNode and node.selected:
			node.queue_free()
	graph_edit.update()


func _on_GraphEdit_duplicate_nodes_request() -> void:
	var to_duplicate := []
	for node in graph_edit.get_children():
		if node is GraphNode:
			if node.selected:
				to_duplicate.append(node)
			node.selected = false
	var nodes := save(to_duplicate)
	var store := {}
	offset_nodes(nodes, Vector2.ONE * 30)
	add_nodes(nodes, store, true)
	connect_nodes(nodes, store)


func _on_GraphEdit_paste_nodes_request() -> void:
	if not copied:
		return
	for node in graph_edit.get_children():
		if node is GraphNode:
			node.selected = false
	var store := {}
	offset_nodes(copied, graph_edit.get_local_mouse_position()\
				+ graph_edit.scroll_offset)
	add_nodes(copied, store, true)
	connect_nodes(copied, store)
	offset_nodes(copied, -(graph_edit.get_local_mouse_position()\
				+ graph_edit.scroll_offset))


func _on_GraphEdit_popup_request(_position : Vector2) -> void:
	show_create_dialog(true)


func show_create_dialog(at_mouse := false) -> void:
	create_node_dialog.popup()
	if at_mouse:
		create_node_dialog.rect_position = get_viewport().get_mouse_position()


func _on_CreateBehaviorNodeDialog_node_selected(type : String) -> void:
	var new_node : GraphNode = BehaviorNode.instance()
	graph_edit.add_child(new_node)
	new_node.init({
		type = type,
		position = graph_edit.get_local_mouse_position() + graph_edit.scroll_offset
	})
	if from_node:
		graph_edit.connect_node(from_node, from_slot, new_node.name, 0)
	elif to_node:
		graph_edit.connect_node(new_node.name, 0, to_node, to_slot)


func _on_GraphEdit_disconnection_request(from : String, from_slot : int,
		to : String, to_slot : int) -> void:
	graph_edit.disconnect_node(from, from_slot, to, to_slot)


func _on_GraphEdit_copy_nodes_request() -> void:
	var min_pos := Vector2.INF
	var to_copy := []
	for node in graph_edit.get_children():
		if node is GraphNode and node.selected:
			to_copy.append(node)
			if node.offset < min_pos:
				min_pos = node.offset
	copied = save(to_copy)
	offset_nodes(copied, -min_pos)


func save(nodes := graph_edit.get_children()) -> Array:
	var data := {}
	var owned := {}
	for node in nodes:
		if node is GraphNode:
			data[node.name] = node.to_dictionary()
	for connection in graph_edit.get_connection_list():
		if connection.from in data and connection.to in data:
			data[connection.from].children.resize(connection.from_port + 1)
			data[connection.from].children[connection.from_port] =\
					data[connection.to]
			owned[connection.to] = true
	var root_nodes := []
	for node_name in data:
		if not node_name in owned:
			root_nodes.append(data[node_name])
	return root_nodes
