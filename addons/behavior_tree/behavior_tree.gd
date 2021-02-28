tool
extends Resource

"""
Resource that stores a behavior tree
"""

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


func get_first_node() -> Dictionary:
	for node in graphs.Main:
		if node.type != "Comment":
			return node
	return {}


func strip_all_comments() -> void:
	for graph in graphs.values():
		for node in graph:
			if node.type == "Comment":
				graph.erase(node)


static func get_flat_nodes(nodes : Array, array := []) -> Array:
	for node in nodes:
		array.append(node)
		array += get_flat_nodes(node.get("children", []), array)
	return array


static func is_group_used(nodes : Array, group : String) -> bool:
	for node in get_flat_nodes(nodes):
		if Nodes.get_type_data(node.type).type == Nodes.NodeType.GROUP and\
				node.property == group:
			return true
	return false
