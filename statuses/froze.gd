class_name Froze
extends Status


func initialize_status(target: Node) -> void:
	print("Froze status initialized for %s" % target)
	target.is_froze = true
	target.skip_turn = true
	
	

func apply_status(target: Node) -> void:
	print("Froze status applied to %s" % target)
	print("Target will be unable to act this turn")
	
	status_applied.emit(self)
