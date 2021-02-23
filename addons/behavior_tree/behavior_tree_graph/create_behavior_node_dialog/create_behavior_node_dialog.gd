tool
extends ConfirmationDialog

signal node_selected(node)

const NODES = preload("res://addons/behavior_tree/nodes.gd").NODES
const NodeType = preload("res://addons/behavior_tree/nodes.gd").NodeType

onready var search_edit : LineEdit = $VBoxContainer/SearchEdit
onready var node_list : Tree = $VBoxContainer/NodeList

var type_names := {
	NodeType.COMPOSITE: "Composites",
	NodeType.DECORATOR: "Decorators",
	NodeType.LEAF: "Leafs",
}

func _ready() -> void:
	search_edit.right_icon = get_icon("Search", "EditorIcons")


func update_list(search_term := "") -> void:
	node_list.clear()
	var root := node_list.create_item()
	var roots := {
		NodeType.ROOT: root,
		NodeType.GROUP: root,
	}
	var is_first := true
	for node in NODES:
		if search_term and not search_term.to_lower() in node.name.to_lower():
			continue
		if not node.type in roots:
			var new_root := node_list.create_item(root)
			new_root.set_selectable(0, false)
			new_root.set_text(0, type_names[node.type])
			roots[node.type] = new_root
		
		var new_item := node_list.create_item(roots[node.type])
		if search_term and is_first:
			new_item.select(0)
			is_first = false
		new_item.set_text(0, node.name)
		new_item.set_metadata(0, node.name)


func _on_NodeList_item_activated() -> void:
	emit_signal("node_selected", node_list.get_selected().get_metadata(0))
	hide()


func _on_SearchEdit_text_changed(new_text : String) -> void:
	update_list(new_text)


func _on_about_to_show() -> void:
	update_list()
	yield(get_tree(), "idle_frame")
	search_edit.clear()
	search_edit.grab_focus()


func _on_SearchEdit_text_entered(new_text: String) -> void:
	emit_signal("node_selected", node_list.get_selected().get_metadata(0))
	hide()
