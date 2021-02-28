tool
extends GraphNode

"""
A node in a behavior tree

The layout is configured depending on the node type.
"""

signal group_name_changed(from, to)
signal group_edited(group)

var data : Dictionary
var type : int

const NODES = preload("res://addons/behavior_tree/nodes.gd").NODES
const NodeType = preload("res://addons/behavior_tree/nodes.gd").NodeType
const Nodes = preload("res://addons/behavior_tree/nodes.gd")

onready var property_edit : LineEdit = $PropertyEdit
onready var edit_button : Button = $EditButton
onready var comment_label : Label = $CommentLabel

func init(_data : Dictionary) -> void:
	data = _data
	var type_data := Nodes.get_type_data(data.type)
	type = type_data.type
	title = type_data.name
	if type != NodeType.GROUP:
		edit_button.free()
	if not "has_property" in type_data:
		property_edit.free()
	else:
		property_edit.text = data.get("property", "")
	if type != NodeType.COMMENT:
		comment_label.free()
	else:
		property_edit.hide()
		comment_label.text = data.get("property", "Click to edit comment")
		property_edit.expand_to_text_length = false
		comment = true
		resizable = true
	offset = data.get("position", Vector2())
	if not get_child_count():
		var control := Label.new()
		control.rect_min_size.y = 20
		add_child(control)
	if type != NodeType.COMMENT:
		set_slot(0, type != NodeType.ROOT, 0, Color.white,
				type != NodeType.LEAF and type != NodeType.GROUP,
				0, Color.white)
	set_deferred("rect_size", data.get("size", Vector2()))


func _on_close_request() -> void:
	queue_free()


func _on_EditButton_pressed() -> void:
	if property_edit.text:
		emit_signal("group_edited", property_edit.text)


func _on_CommentLabel_gui_input(event : InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and\
			event.button_index == BUTTON_LEFT:
		comment_label.hide()
		property_edit.show()
		property_edit.call_deferred("grab_focus")


func _on_resize_request(new_minsize : Vector2) -> void:
	rect_size = new_minsize
	data.size = rect_size


func _on_PropertyEdit_focus_exited() -> void:
	exit_comment_edit()


func _on_PropertyEdit_text_entered(_new_text : String) -> void:
	exit_comment_edit()


func exit_comment_edit() -> void:
	if type == NodeType.COMMENT:
		comment_label.text = property_edit.text if property_edit.text else "Click to edit text."
		comment_label.show()
		property_edit.hide()


func _on_PropertyEdit_text_changed(new_text: String) -> void:
	if type == NodeType.GROUP:
		emit_signal("group_name_changed", data.get("property", ""), new_text)
	data.property = new_text


func _on_offset_changed() -> void:
	data.position = offset
