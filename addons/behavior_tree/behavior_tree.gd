tool
extends Resource

export var graphs : Dictionary

const Nodes = preload("res://addons/behavior_tree/nodes.gd")

func remove_unused_graphs() -> void:
	for graph in graphs:
		if graph == "Main":
			continue
		var used := false
		for graph_to_search in graphs:
			if is_group_used(graphs[graph_to_search], graph):
				used = true
				break
		if not used:
			graphs.erase(graph)


static func is_group_used(nodes : Array, group : String) -> bool:
	for node in nodes:
		if Nodes.get_type_data(node.type).type == Nodes.NodeType.GROUP and\
				node.property == group:
			return true
		if is_group_used(node.children, group):
			return true
	return false
