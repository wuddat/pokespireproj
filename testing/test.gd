extends Sprite2D

func _ready() -> void:
	print("Type 1:")
	var test = [1,2,3]
	test.insert(0, test[test.size()-1])
	print(test)
	print("======")
	print("Type 2:")
	var test2 = [1,2,3]
	var replace = test2.pop_at(-1)
	test2.insert(0, replace)
	print(test2)
