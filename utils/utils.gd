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
