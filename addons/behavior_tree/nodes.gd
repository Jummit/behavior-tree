enum NodeType {
	ROOT,
	GROUP,
	COMPOSITE,
	DECORATOR,
	LEAF,
}

const NODES := [
	{
		name = "Root",
		type = NodeType.ROOT,
	},
	{
		name = "Group",
		type = NodeType.GROUP,
	},
	{
		name = "Selector",
		type = NodeType.COMPOSITE,
	},
	{
		name = "Sequence",
		type = NodeType.COMPOSITE,
	},
	{
		name = "Condition",
		type = NodeType.LEAF,
		has_property = true,
	},
	{
		name = "Function",
		type = NodeType.LEAF,
		has_property = true,
	},
	{
		name = "Inverter",
		type = NodeType.DECORATOR,
	},
	{
		name = "Repeater",
		type = NodeType.DECORATOR,
		has_property = true,
	},
	{
		name = "Succeeder",
		type = NodeType.DECORATOR,
	},
	{
		name = "Failer",
		type = NodeType.DECORATOR,
	},
]

static func get_type_data(type_name : String) -> Dictionary:
	for type_data in NODES:
		if type_data.name == type_name:
			return type_data
	return {}


func tick_root(subject : Node, data : Dictionary) -> int:
	var result = tick(data.children.front(), subject)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	return result


func tick_selector(subject : Node, data : Dictionary) -> int:
	for child in data.children:
		var result = tick(child, subject)
		if result is GDScriptFunctionState:
			yield(result, "completed")
		if result == OK:
			return OK
	return FAILED


func tick_sequence(subject : Node, data : Dictionary) -> int:
	for child in data.children:
		var result = tick(child, subject)
		if result is GDScriptFunctionState:
			yield(result, "completed")
		if result == FAILED:
			return FAILED
	return OK


func tick_condition(subject : Node, data : Dictionary) -> int:
	var expression := Expression.new()
	expression.parse(data.property)
	return OK if expression.execute([], subject) else FAILED


func tick_function(subject : Node, data : Dictionary) -> int:
	return subject.call(data.property)


func tick_inverter(subject : Node, data : Dictionary) -> int:
	var result = tick(data.children.front(), subject)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	return OK if result == FAILED else OK


func tick_repeater(subject : Node, data : Dictionary) -> int:
	var amounts_left := int(data.property)
	while true:
		if data.property:
			amounts_left -= 1
			if not amounts_left:
				break
		var result = tick(data.children.front(), subject)
		if result is GDScriptFunctionState:
			yield(result, "completed")
		if result == FAILED:
			return FAILED
	return OK


func tick_succeeder(subject : Node, data : Dictionary) -> int:
	var result = tick(data.children.front(), subject)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	return OK


func tick_failer(subject : Node, data : Dictionary) -> int:
	var result = tick(data.children.front(), subject)
	if result is GDScriptFunctionState:
		yield(result, "completed")
	return FAILED


func tick(node : Dictionary, subject : Node) -> int:
	return call("tick_" + node.type.to_lower().replace(" ", "_"), subject, node)
