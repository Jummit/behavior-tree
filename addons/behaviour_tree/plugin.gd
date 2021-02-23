tool
extends EditorPlugin

var behaviour_tree_graph_panel := preload("behaviour_tree_graph/behaviour_tree_graph_panel/behaviour_tree_graph_panel.tscn").instance()
var create_behaviour_node_dialog := preload("behaviour_tree_graph/create_behaviour_node_dialog/create_behaviour_node_dialog.tscn").instance()
var editing_player : BehaviourTreePlayer
var bottom_panel_button : ToolButton

const BehaviourTreePlayer = preload("behaviour_tree_player/behaviour_tree_player.gd")
const BehaviourTree = preload("behaviour_tree.gd")

func _enter_tree() -> void:
	add_custom_type("BehaviourTreePlayer", "Node", BehaviourTreePlayer,
			preload("behaviour_tree_player/icon.svg"))
	get_editor_interface().get_base_control().add_child(create_behaviour_node_dialog)
	behaviour_tree_graph_panel.create_node_dialog = create_behaviour_node_dialog
	get_editor_interface().get_selection().connect("selection_changed", self, "_on_editor_selection_changed")
	bottom_panel_button = add_control_to_bottom_panel(behaviour_tree_graph_panel, "Behaviour Tree")
	bottom_panel_button.hide()


func _exit_tree() -> void:
	remove_custom_type("BehaviourTreePlayer")
	remove_control_from_bottom_panel(behaviour_tree_graph_panel)
	behaviour_tree_graph_panel.queue_free()
	create_behaviour_node_dialog.queue_free()


func handles(object : Object) -> bool:
	return object is BehaviourTreePlayer


func edit(object : Object) -> void:
	editing_player = object
	if not editing_player.behaviour_tree:
		editing_player.behaviour_tree = BehaviourTree.new()
	behaviour_tree_graph_panel.behaviour_tree = editing_player.behaviour_tree
	bottom_panel_button.show()
	make_bottom_panel_item_visible(behaviour_tree_graph_panel)


func apply_changes() -> void:
	if editing_player:
		editing_player.behaviour_tree.nodes = behaviour_tree_graph_panel.save()


func _on_editor_selection_changed():
	for node in get_editor_interface().get_selection().get_selected_nodes():
		if node is BehaviourTreePlayer:
			return
	if bottom_panel_button:
		bottom_panel_button.hide()
	hide_bottom_panel()
