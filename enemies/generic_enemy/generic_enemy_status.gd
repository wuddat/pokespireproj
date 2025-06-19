extends EnemyAction

@export var damage := 0
@export var splash_damage := 0
@export var self_damage := 0
@export var self_heal := 0
@export var status_effects: Array[Status] = []
@export var self_status: Array[Status] = []
@export var bonus_damage_if_target_has_status: String = ""
@export var bonus_damage_multiplier: float = 1.0
@export var damage_type: String = "normal"

func setup_from_data(data: Dictionary) -> void:
	status_effects = []
	self_status = []

	if data.has("status_effects"):
		status_effects.append_array(StatusData.get_status_effects_from_ids(Utils.to_typed_string_array(data["status_effects"])))
	if data.has("self_status"):
		self_status.append_array(StatusData.get_status_effects_from_ids(Utils.to_typed_string_array(data["self_status"])))

	damage = data.get("power", 0)
	splash_damage = data.get("splash_damage", 0)
	self_damage = data.get("self_damage", 0)
	self_heal = data.get("self_heal", 0)
	damage_type = data.get("type", "normal")
	bonus_damage_if_target_has_status = data.get("bonus_damage_if_target_has_status", "")
	bonus_damage_multiplier = data.get("bonus_damage_multiplier", 1.0)
	type = EnemyAction.Type.CHANCE_BASED
	chance_weight = 1.0

	var display_text = "%s"
	intent = Intent.new()
	intent.base_text = display_text
	intent.current_text = str(damage)
	intent.damage_type = damage_type
	#intent.icon = preload("res://art/statuseffects/status_star.png")
	#sound = preload("res://art/sounds/status_generic.wav")


func perform_action() -> void:
	var targets_to_hit: Array[Node] = []

	# Get valid targets
	if targets.size() > 0:
		for t in targets:
			if is_instance_valid(t):
				targets_to_hit.append(t)
	else:
		if not is_instance_valid(target):
			if enemy and enemy.enemy_action_picker:
				enemy.enemy_action_picker.select_valid_target()
				target = enemy.enemy_action_picker.target
		if is_instance_valid(target):
			targets_to_hit.append(target)
		else:
			Events.enemy_action_completed.emit(enemy)
			return

	if targets_to_hit.is_empty():
		return

	# Apply conditional bonus multiplier
	var final_multiplier := 1.0
	if bonus_damage_if_target_has_status != "":
		var handler := targets_to_hit[0].get_node_or_null("StatusHandler")
		if handler:
			for status in handler.get_statuses():
				if status.id == bonus_damage_if_target_has_status:
					final_multiplier *= bonus_damage_multiplier
					break

	# Apply status effects to targets
	for status_effect in status_effects:
		if status_effect:
			var status_to_apply := status_effect.duplicate()
			status_to_apply.stacks *= final_multiplier
			var effect := StatusEffect.new()
			effect.status = status_to_apply
			effect.execute(targets_to_hit)

	# Apply status effects to self
	if enemy and enemy.is_inside_tree():
		for self_stat in self_status:
			if self_stat:
				var status_to_apply := self_stat.duplicate()
				var effect := StatusEffect.new()
				effect.status = status_to_apply
				effect.execute([enemy])

	# Apply self damage if needed
	if self_damage > 0 and enemy:
		var self_dmg_effect := DamageEffect.new()
		self_dmg_effect.amount = self_damage
		self_dmg_effect.sound = null
		self_dmg_effect.execute([enemy])

	# Apply self heal if needed
	if self_heal > 0 and enemy:
		var self_heal_effect := HealEffect.new()
		self_heal_effect.amount = self_heal
		self_heal_effect.sound = null
		self_heal_effect.execute([enemy])


func update_intent_text() -> void:
	if not is_instance_valid(target):
		return

	intent.current_text = intent.base_text

	if enemy and enemy.status_handler.has_status("confused"):
		intent.target = preload("res://art/statuseffects/confused-effect.png")
		return

	if is_instance_valid(target) and target.has_method("stats"):
		intent.target = target.stats.icon
