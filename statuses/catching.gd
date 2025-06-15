class_name Catching
extends Status

var member_var := 0


func initialize_status(target: Node) -> void:
	if target is Enemy:
		target.is_catchable = true
		target.skip_turn = true
		target.enter_catching_state()
	

func apply_status(target: Node) -> void:
	super(target)  # keep emitting status_applied
	if can_expire and duration <= 0:
		if target is Enemy:
			print("mark_as_caught run from status")
			target.mark_as_caught()
