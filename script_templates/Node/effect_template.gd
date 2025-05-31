# meta-name: Effect
# meta-description: Create effect to be applied to a target
class_name PlaceEffectNameHere
extends Effect

var member_var := 0


func execute(targets: Array[Node]) -> void:
	print("Effect targets: %s" % targets)
	print("It does %s whatever" % member_var)
