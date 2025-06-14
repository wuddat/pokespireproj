extends Node

static func print_resource(resource: Resource) -> void:
	if resource == null:
		print("Resource is null.")
		return

	print("----- Resource Properties -----")
	for prop in resource.get_property_list():
		var name = prop.name
		var value = resource.get(name)
		print("%s: %s" % [name, value])
	print("------------------------------")

func to_typed_string_array(input: Array) -> Array[String]:
	var result: Array[String] = []
	for item in input:
		result.append(str(item))
	return result


static func print_node(node: Node) -> void:
	if node == null:
		print("Node is null.")
		return
	
	print("===== Node Debug Info (%s) =====" % node.name)

	# Print exported and internal properties
	var property_list := node.get_property_list()
	for prop in property_list:
		var name = prop.name
		var value = node.get(name)
		print("%s: %s" % [name, value])
