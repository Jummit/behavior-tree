"""
Node metadata and tick functions
"""

enum NodeType {
	ROOT,
	GROUP,
	COMMENT,
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
		has_property = true,
	},
	{
		name = "Comment",
		type = NodeType.COMMENT,
		has_property = true,
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
		name = "Randomizer",
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
		name = "Expression",
		type = NodeType.LEAF,
		has_property = true,
	},
	{
		name = "Wait",
		type = NodeType.LEAF,
		has_property = true,
	},
	{
		name = "Breakpoint",
		type = NodeType.LEAF,
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
		name = "Repeat Until Failed",
		type = NodeType.DECORATOR,
	},
	{
		name = "Repeat Until Succeeded",
		type = NodeType.DECORATOR,
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


func tick_root(subject : Node, data : Dictionary, tree : Resource) -> int:
	var result = tick(data.children.front(), subject, tree)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return result


func tick_group(subject : Node, data : Dictionary, tree : Resource) -> int:
	for child in tree.graphs[data.property]:
		var result = tick(child, subject, tree)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == OK:
			return OK
	return FAILED


func tick_selector(subject : Node, data : Dictionary, tree : Resource) -> int:
	for child in data.children:
		var result = tick(child, subject, tree)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == OK:
			return OK
	return FAILED


func tick_sequence(subject : Node, data : Dictionary, tree : Resource) -> int:
	for child in data.children:
		var result = tick(child, subject, tree)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == FAILED:
			return FAILED
	return OK


func tick_randomizer(subject : Node, data : Dictionary, tree : Resource) -> int:
	var shuffled : Array = data.children.duplicate()
	shuffled.shuffle()
	for child in shuffled:
		var result = tick(child, subject, tree)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == FAILED:
			return FAILED
	return OK


func tick_condition(subject : Node, data : Dictionary, tree : Resource) -> int:
	var expression := Expression.new()
	expression.parse(data.property)
	var result = expression.execute([], subject)
	if expression.has_execute_failed():
		push_error("Expression '%s' failed with error '%s' " % 
				[data.property, expression.get_error_text()])
	return OK if result else FAILED


func tick_function(subject : Node, data : Dictionary, tree : Resource) -> int:
	var args : PoolStringArray = data.property.split(" ")
	var function := args[0]
	args.remove(0)
	return subject.callv(function, args)


func tick_expression(subject : Node, data : Dictionary, tree : Resource) -> int:
	var expression := Expression.new()
	expression.parse(data.property)
	expression.execute([], subject)
	return OK


func tick_wait(subject : Node, data : Dictionary, tree : Resource) -> int:
	yield(subject.get_tree().create_timer(float(data.property)), "timeout")
	return OK


func tick_breakpoint(_subject : Node, _data : Dictionary, tree : Resource) -> int:
	breakpoint
	return OK


func tick_inverter(subject : Node, data : Dictionary, tree : Resource) -> int:
	var result = tick(data.children.front(), subject, tree)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return OK if result == FAILED else FAILED


func tick_repeater(subject : Node, data : Dictionary, tree : Resource) -> int:
	var amounts_left := int(data.property)
	while true:
		if data.property:
			amounts_left -= 1
			if not amounts_left:
				break
		var result = tick(data.children.front(), subject, tree)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == FAILED:
			return FAILED
	return OK


func tick_repeat_until_failed(subject : Node, data : Dictionary, tree : Resource) -> int:
	while true:
		var result = tick(data.children.front(), subject, tree)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == FAILED:
			return OK
	return OK


func tick_repeat_until_succeeded(subject : Node, data : Dictionary, tree : Resource) -> int:
	while true:
		var result = tick(data.children.front(), subject, tree)
		if result is GDScriptFunctionState:
			result = yield(result, "completed")
		if result == OK:
			return OK
	return OK


func tick_succeeder(subject : Node, data : Dictionary, tree : Resource) -> int:
	var result = tick(data.children.front(), subject, tree)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return OK


func tick_failer(subject : Node, data : Dictionary, tree : Resource) -> int:
	var result = tick(data.children.front(), subject, tree)
	if result is GDScriptFunctionState:
		result = yield(result, "completed")
	return FAILED


func tick(node : Dictionary, subject : Node, tree : Resource) -> int:
	return call("tick_" + node.type.to_lower().replace(" ", "_"), subject, node, tree)
