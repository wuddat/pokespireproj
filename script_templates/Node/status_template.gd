# meta-name: Status
# meta-description: Create a Status to be applied to a target
class_name StatusNameHere
extends Status

var member_var := 0


func initialize_status(target: Node) -> void:
	print("Initialize this status for target %s" % target)
	

func apply_status(target: Node) -> void:
	print("My status targets %s" % target)
	print("It does %s something" % member_var)
	
	status_applied.emit(self)
