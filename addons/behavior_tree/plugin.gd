tool
extends EditorPlugin

var behavior_tree_graph_panel := preload("behavior_tree_graph/behavior_tree_graph_panel/behavior_tree_graph_panel.tscn").instance()
var create_behavior_node_dialog := preload("behavior_tree_graph/create_behavior_node_dialog/create_behavior_node_dialog.tscn").instance()
var editing_player : BehaviorTreePlayer
var bottom_panel_button : ToolButton

const BehaviorTreePlayer = preload("behavior_tree_player/behavior_tree_player.gd")
const BehaviorTree = preload("behavior_tree.gd")

func _enter_tree() -> void:
	add_custom_type("BehaviorTreePlayer", "Node", BehaviorTreePlayer,
			preload("behavior_tree_player/icon.svg"))
	get_editor_interface().get_base_control().add_child(create_behavior_node_dialog)
	behavior_tree_graph_panel.create_node_dialog = create_behavior_node_dialog
	behavior_tree_graph_panel.undo_redo = get_undo_redo()
	get_editor_interface().get_selection().connect("selection_changed", self, "_on_editor_selection_changed")
	bottom_panel_button = add_control_to_bottom_panel(behavior_tree_graph_panel, "Behavior Tree")
	bottom_panel_button.hide()


func _exit_tree() -> void:
	remove_custom_type("BehaviorTreePlayer")
	remove_control_from_bottom_panel(behavior_tree_graph_panel)
	behavior_tree_graph_panel.queue_free()
	create_behavior_node_dialog.queue_free()


func handles(object : Object) -> bool:
	return object is BehaviorTreePlayer


func edit(object : Object) -> void:
	editing_player = object
	if not editing_player.behavior_tree:
		editing_player.behavior_tree = BehaviorTree.new()
	behavior_tree_graph_panel.behavior_tree = editing_player.behavior_tree
	bottom_panel_button.show()
	make_bottom_panel_item_visible(behavior_tree_graph_panel)


func apply_changes() -> void:
	if editing_player:
		behavior_tree_graph_panel.save_graph()


func _on_editor_selection_changed() -> void:
	for node in get_editor_interface().get_selection().get_selected_nodes():
		if node is BehaviorTreePlayer:
			return
	if bottom_panel_button:
		bottom_panel_button.hide()
	hide_bottom_panel()
