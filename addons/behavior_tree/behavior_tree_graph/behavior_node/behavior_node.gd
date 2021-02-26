tool
extends GraphNode

signal group_edited(group)

var data : Dictionary
var outputs : int

const NODES = preload("res://addons/behavior_tree/nodes.gd").NODES
const NodeType = preload("res://addons/behavior_tree/nodes.gd").NodeType
const Nodes = preload("res://addons/behavior_tree/nodes.gd")

onready var property_edit : LineEdit = $PropertyEdit
onready var output_buttons : HBoxContainer = $OutputButtons
onready var remove_output_button : Button = $OutputButtons/RemoveOutputButton
onready var edit_button : Button = $EditButton
onready var comment_label : Label = $CommentLabel

func init(_data : Dictionary) -> void:
	data = _data
	var type_data := Nodes.get_type_data(data.type)
	title = type_data.name
	if type_data.type != NodeType.COMPOSITE:
		output_buttons.free()
	if type_data.type != NodeType.GROUP:
		edit_button.free()
	if not type_data.get("has_property"):
		property_edit.free()
	else:
		property_edit.text = data.get("property", "")
	if type_data.type != NodeType.COMMENT:
		comment_label.free()
	else:
		property_edit.hide()
		comment_label.text = data.get("property", "")
		comment = true
		resizable = true
	offset = data.position
	outputs = data.get("outputs", 2)
	if type_data.type == NodeType.COMPOSITE:
		for output_num in range(outputs, 0, -1):
			var label := Label.new()
			label.text = str(output_num) + "."
			add_child(label)
			move_child(label, 0)
			set_slot(output_num - 1, output_num == 1, 0, Color.white, true, 0,
				Color.white)
	if not get_child_count():
		var control := Label.new()
		control.rect_min_size.y = 20
		add_child(control)
	if type_data.type != NodeType.COMMENT:
		set_slot(0, type_data.type != NodeType.ROOT, 0, Color.white,
			type_data.type != NodeType.LEAF and type_data.type != NodeType.GROUP,
			0, Color.white)
	set_deferred("rect_size", data.get("size", Vector2()))


func to_dictionary() -> Dictionary:
	data = {
		type = data.type,
		position = offset,
		children = [],
	}
	if Nodes.get_type_data(data.type).type == NodeType.COMPOSITE:
		data.outputs = outputs
	if Nodes.get_type_data(data.type).type == NodeType.COMMENT:
		data.size = rect_size
	if is_instance_valid(property_edit):
		data.property = property_edit.text
	return data


func _on_AddOutputButton_pressed() -> void:
	outputs += 1
	remove_output_button.disabled = outputs == 1
	var label := Label.new()
	label.text = str(outputs) + "."
	add_child(label)
	move_child(label, outputs - 1)
	set_slot(outputs - 1, outputs == 1, 0, Color.white, true, 0,
		Color.white)


func _on_RemoveOutputButton_pressed() -> void:
	outputs -= 1
	get_child(outputs).free()
	remove_output_button.disabled = outputs == 1
	set_slot(outputs, false, 0, Color.white, false, 0,
		Color.white)
	rect_size = Vector2()


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


func _on_CommentLabel_focus_exited() -> void:
	comment_label.text = property_edit.text
	comment_label.show()
	property_edit.hide()


func _on_BehaviorNode_resize_request(new_minsize : Vector2) -> void:
	rect_size = new_minsize
