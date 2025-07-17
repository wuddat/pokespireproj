extends EnemyAction

@export var block := 2
@export var description: String
@export var status_effects: Array[Stats] = []
@export var self_status: Array[Stats] = []
@export var self_damage: int
@export var self_heal: int
@export var shift_enabled: int
@export var requires_status: String = ""

func setup_from_data(data: Dictionary) -> void:
	intent = Intent.new()
	block = data.get("power", 1)
	sound = preload("res://art/block.ogg")
	type = EnemyAction.Type.CHANCE_BASED
	intent.icon = preload("res://art/tile_0102.png")  # 🛡️ block icon
	intent.particles_on = false
	intent_type = "Block"
	if data.has("status_effects"):
		status_effects.append_array(StatusData.get_status_effects_from_ids(Utils.to_typed_string_array(data["status_effects"])))
	if data.has("self_status"):
		self_status.append_array(StatusData.get_status_effects_from_ids(Utils.to_typed_string_array(data["self_status"])))
	intent.targets_all = data.get("target") in ["all_enemies", "all"]
	self_damage = data.get("self_damage", 0)
	self_heal = data.get("self_heal", 0)
	chance_weight = 1.0
	action_name = data.get("name", "SOMETHING!")
	description = data.get("description", "hopefully something happens!")
	shift_enabled = data.get("shift_enabled", 0)
	requires_status = data.get("requires_status", "")
	sound = preload("res://art/block.ogg")
	
	var block_display = ""
	if status_effects.size() > 0:
		intent.particles_on = true
	intent.base_text = block_display
	intent.current_text = ""
	
func perform_action() -> void:
	if not enemy or not is_instance_valid(target):
		if enemy and enemy.enemy_action_picker:
			enemy.enemy_action_picker.select_valid_target()
			target = enemy.enemy_action_picker.target

		if not is_instance_valid(target):
			Events.enemy_action_completed.emit(enemy)
			return

	var block_effect := BlockEffect.new()
	block_effect.amount = enemy.modifier_handler.get_modified_value(block, Modifier.Type.BLOCK_GAINED)
	block_effect.base_block = block
	block_effect.sound = sound
	print("block targets are: ", [targets])
	block_effect.execute([enemy])

	get_tree().create_timer(0.6, false).timeout.connect(
		func(): Events.enemy_action_completed.emit(enemy)
	)

func update_intent_text() -> void:
	var target_pkmn := target
	if not target_pkmn:
		return
	intent.target = target_pkmn.stats.icon

	if enemy and enemy.status_handler.has_status("confused"):
		intent.target = preload("res://art/statuseffects/confused-effect.png")
		return
	
