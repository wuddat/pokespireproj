class_name AttackPower
extends Status

var member_var := 0


func initialize_status(target: Node) -> void:
	status_changed.connect(_on_status_changed)
	_on_status_changed()
	

func _on_status_changed() -> void:
	print("muscle status functioning check")
