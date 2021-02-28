tool
extends Control

"""
The behavior graph panel
"""

var behavior_tree : BehaviorTree setget set_behavior_tree
var graph : String setget set_graph
var create_node_dialog : ConfirmationDialog
var to_node : String
var from_node : String
var at_position : Vector2
var undo_redo : UndoRedo

var copied := []

const BehaviorTree = preload("res://addons/behavior_tree/behavior_tree.gd")
const BehaviorNode = preload("res://addons/behavior_tree/behavior_tree_graph/behavior_node/behavior_node.tscn")

onready var graph_edit : GraphEdit = $VBoxContainer/GraphEdit
onready var navigation_buttons : HBoxContainer = $VBoxContainer/TopBar/NavigationButtonsContainer

func _ready() -> void:
	var create_node_button := Button.new()
	create_node_button.text = "Add Node..."
	create_node_button.connect("pressed", self, "_on_CreateNodeButton_pressed")
	create_node_button.flat = true
	create_node_button.hint_tooltip = "Open the node creation dialog"
	graph_edit.get_zoom_hbox().add_child(create_node_button)
	graph_edit.get_zoom_hbox().move_child(create_node_button, 0)
	
	create_node_dialog.connect("node_selected", self,
			"_on_CreateBehaviorNodeDialog_node_selected")
	create_node_dialog.connect("hide", self, "_on_CreateBehaviorNodeDialog_hide")


func set_behavior_tree(to):
	behavior_tree = to
	clear_navigation_buttons()
	add_navigation_button("Main")
	set_graph("Main")


func set_graph(to):
	graph = to
	for node in graph_edit.get_children():
		if node is GraphNode:
			node.queue_free()
	graph_edit.clear_connections()
	if not graph in behavior_tree.graphs:
		behavior_tree.graphs[graph] = [{type = "Root"}]
	add_nodes(behavior_tree.graphs[graph])


func save_graph() -> void:
	behavior_tree.graphs[graph] = save()
	behavior_tree.remove_unused_graphs()


func add_nodes(nodes : Array, select := false, offset := Vector2()) -> void:
	var graph_nodes := {}
	for node in BehaviorTree.get_flat_nodes(nodes):
		var new_node := BehaviorNode.instance()
		graph_edit.add_child(new_node)
		new_node.connect("close_request", self,
				"_on_BehaviourNode_close_request", [new_node])
		new_node.connect("offset_changed", self,
				"_on_BehaviourNode_offset_changed", [new_node])
		new_node.connect("resize_request", self,
				"_on_BehaviourNode_resize_request", [new_node])
		new_node.connect("group_edited", self, "_on_BehaviourNode_group_edited")
		new_node.connect("group_name_changed", self,
				"_on_BehaviourNode_group_name_changed")
		new_node.init(node)
		new_node.offset += offset
		new_node.selected = select
		graph_nodes[node] = new_node.name
	for node in BehaviorTree.get_flat_nodes(nodes):
		for child in node.get("children", []):
			graph_edit.connect_node(graph_nodes[node], 0, graph_nodes[child], 0)


func _on_BehaviourNode_close_request(node : GraphNode) -> void:
	node.queue_free()
	save_graph()
	set_graph(graph)


func _on_BehaviourNode_offset_changed(node : GraphNode) -> void:
	node.data.position = node.offset


func _on_BehaviourNode_resize_request(new_minsize : Vector2, node : GraphNode) -> void:
	node.rect_size = new_minsize
	node.data.size = new_minsize


func _on_BehaviourNode_group_edited(group : String) -> void:
	add_navigation_button(group)
	save_graph()
	set_graph(group)


func _on_BehaviourNode_group_name_changed(from : String, to : String) -> void:
	if from in behavior_tree.graphs:
		behavior_tree.graphs[to] = behavior_tree.graphs[from]
		behavior_tree.graphs.erase(from)


func add_navigation_button(group : String) -> void:
	var navigation_button := Button.new()
	navigation_button.text = group
	navigation_button.connect("pressed", self, "_on_NavigationButton_pressed",
			[navigation_button])
	navigation_buttons.add_child(navigation_button)


func _on_NavigationButton_pressed(button : Button) -> void:
	for child_num in navigation_buttons.get_child_count() - button.get_index() - 1:
		navigation_buttons.get_child(button.get_index() + 1).free()
	save_graph()
	set_graph(button.text)


func clear_navigation_buttons() -> void:
	for navigation_button in navigation_buttons.get_children():
		navigation_button.queue_free()


func _on_CreateNodeButton_pressed():
	show_create_dialog()


func _on_GraphEdit_connection_request(from : String, from_slot : int,
		to : String, to_slot : int) -> void:
	graph_edit.connect_node(from, from_slot, to, to_slot)


func _on_GraphEdit_connection_from_empty(to : String, _to_slot : int,
		release_position : Vector2) -> void:
	to_node = to
	show_create_dialog(true)


func _on_GraphEdit_connection_to_empty(from : String, _from_slot : int,
		_release_position : Vector2) -> void:
	from_node = from
	show_create_dialog(true)


func _on_CreateBehaviorNodeDialog_hide():
	from_node = ""
	to_node = ""


func _on_GraphEdit_delete_nodes_request() -> void:
	for node in graph_edit.get_children():
		if node is GraphNode and node.selected:
			graph_edit.remove_child(node)
			node.queue_free()
	save_graph()
	set_graph(graph)


func _on_GraphEdit_duplicate_nodes_request() -> void:
	var to_duplicate := []
	for node in graph_edit.get_children():
		if node is GraphNode:
			if node.selected:
				to_duplicate.append(node)
			node.selected = false
	var nodes := save(to_duplicate)
	add_nodes(nodes, true, Vector2.ONE * 30)


func _on_GraphEdit_paste_nodes_request() -> void:
	if not copied:
		return
	for node in graph_edit.get_children():
		if node is GraphNode:
			node.selected = false
	add_nodes(copied, true, graph_edit.get_local_mouse_position()\
			+ graph_edit.scroll_offset)


func _on_GraphEdit_popup_request(_position : Vector2) -> void:
	show_create_dialog(true)


func show_create_dialog(at_mouse := false) -> void:
	create_node_dialog.popup()
	if at_mouse:
		create_node_dialog.rect_position = get_viewport().get_mouse_position()
		at_position = graph_edit.get_local_mouse_position() +\
			graph_edit.scroll_offset


func _on_CreateBehaviorNodeDialog_node_selected(type : String) -> void:
	var new_node : GraphNode = BehaviorNode.instance()
	graph_edit.add_child(new_node)
	new_node.connect("group_edited", self, "_on_BehaviourNode_group_edited")
	new_node.init({
		type = type,
	})
	if from_node and new_node.is_slot_enabled_left(0):
		graph_edit.connect_node(from_node, 0, new_node.name, 0)
	elif to_node and new_node.is_slot_enabled_right(0):
		graph_edit.connect_node(new_node.name, 0, to_node, 0)
	if type == "Comment":
		new_node.comment_label.hide()
		new_node.property_edit.show()
	if at_position:
		new_node.offset = at_position
	if is_instance_valid(new_node.property_edit):
		new_node.property_edit.call_deferred("grab_focus")


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
	for node in BehaviorTree.get_flat_nodes(copied):
		node.position -= min_pos

class YSorter:
	static func _sort(a : Dictionary, b : Dictionary) -> bool:
		return a.position.y < b.position.y

func save(nodes := graph_edit.get_children()) -> Array:
	var data := {}
	for node in nodes:
		if not node is GraphNode or node.is_queued_for_deletion():
			continue
		data[node.name] = node.data
		# clear children array because it will be repopulated later
		node.data.erase("children")
	var root_nodes := data.values()
	for connection in graph_edit.get_connection_list():
		var from : String = connection.from
		var to : String = connection.to
		if not (from in data and to in data):
			continue
		if not "children" in data[from]:
			data[from].children = []
		data[from].children.append(data[to])
		root_nodes.erase(data[to])
	# sort the nodes by height to make execution order correct
	for node in BehaviorTree.get_flat_nodes(root_nodes):
		node.get("children", []).sort_custom(YSorter, "_sort")
	return root_nodes
