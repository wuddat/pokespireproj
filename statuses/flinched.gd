class_name Flinched
extends Status


func initialize_status(target: Node) -> void:
	print("Flinched status initialized for %s" % target)
	

func apply_status(target: Node) -> void:
	print("Flinched status applied to %s" % target)
	print("Target will be unable to act this turn")
	
	status_applied.emit(self)
