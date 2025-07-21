# base_enemy_action.gd
class_name BaseEnemyAction
extends EnemyAction

@export var damage := 0
@export var splash_damage := 0
@export var self_damage := 0
@export var self_heal := 0
@export var self_block := 0
@export var status_effects: Array[Status] = []
@export var self_status: Array[Status] = []
@export var bonus_damage_if_target_has_status: String = ""
@export var bonus_damage_multiplier: float = 1.0
@export var damage_type: String = "normal"
@export var requires_status: String = ""
@export var shift_enabled: int = 0
@export var target_damage_percent_hp: float = 0.0
@export var block_amount := 0

# Shared setup logic
func setup_from_data(data: Dictionary) -> void:
	intent = Intent.new()
	_setup_basic_data(data)
	_setup_effects(data)
	_setup_intent(data)
	_setup_audio(data)

func _setup_basic_data(data: Dictionary) -> void:
	damage = data.get("power", 0)
	splash_damage = data.get("splash_damage", 0)
	self_damage = data.get("self_damage", 0)
	self_heal = data.get("self_heal", 0)
	self_block = data.get("self_block", 0)
	block_amount = data.get("power", 0)  # For block actions
	damage_type = data.get("type", "normal")
	bonus_damage_if_target_has_status = data.get("bonus_damage_if_target_has_status", "")
	bonus_damage_multiplier = data.get("bonus_damage_multiplier", 1.0)
	shift_enabled = data.get("shift_enabled", 0)
	requires_status = data.get("requires_status", "")
	target_damage_percent_hp = data.get("target_damage_percent_hp", 0.0)
	type = EnemyAction.Type.CHANCE_BASED
	chance_weight = 1.0
	action_name = data.get("name", "SOMETHING!")

func _setup_effects(data: Dictionary) -> void:
	status_effects.clear()
	if data.has("status_effects"):
		status_effects.append_array(StatusData.get_status_effects_from_ids(Utils.to_typed_string_array(data["status_effects"])))
	
	self_status.clear()
	if data.has("self_status"):
		self_status.append_array(StatusData.get_status_effects_from_ids(Utils.to_typed_string_array(data["self_status"])))

func _setup_intent(data: Dictionary) -> void:
	intent.targets_all = data.get("target") in ["all_enemies", "all"]
	intent.particles_on = status_effects.size() > 0
	intent.damage_type = damage_type
	
	var damage_display = "%s"
	intent.base_text = damage_display
	intent.current_text = str(damage)
	if damage <= 0:
		intent.current_text = intent.base_text % " "

func _setup_audio(data: Dictionary) -> void:
	if data.has("sound_path"):
		sound = load(data["sound_path"]) as AudioStream
	else:
		match intent_type:
			"Attack":
				sound = load("res://art/axe.ogg")
			"Block":
				sound = load("res://art/block.ogg")
			"Status":
				sound = load("res://art/sounds/VineWhip2.wav")

# Shared target validation
func get_valid_targets() -> Array[Node]:
	var targets_to_hit: Array[Node] = []

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
			return []

	return _filter_targets_by_requirements(targets_to_hit)

func _filter_targets_by_requirements(targets_to_check: Array[Node]) -> Array[Node]:
	if requires_status == "":
		return targets_to_check
		
	var valid_targets: Array[Node] = []
	for t in targets_to_check:
		if not is_instance_valid(t):
			continue

		var skip := false
		if requires_status == "sleep":
			if not t.has_method("is_asleep") or not t.is_asleep:
				skip = true
		else:
			var handler = t.get_node_or_null("StatusHandler")
			if not handler or not handler.has_status(requires_status):
				skip = true

		if not skip:
			valid_targets.append(t)

	return valid_targets

# Shared damage calculation
func calculate_damage(target: Node) -> int:
	var final_damage = damage
	
	if target and target_damage_percent_hp > 0:
		final_damage = round(target.stats.health * target_damage_percent_hp)
	
	# Apply status bonus
	if bonus_damage_if_target_has_status != "" and target:
		var handler = target.get_node_or_null("StatusHandler")
		if handler:
			for status in handler.get_statuses():
				if status.id == bonus_damage_if_target_has_status:
					final_damage *= bonus_damage_multiplier
					break

	# Apply modifiers
	if enemy and enemy.modifier_handler:
		final_damage = enemy.modifier_handler.get_modified_value(final_damage, Modifier.Type.DMG_DEALT)
	
	return final_damage

# Shared self effects application
func apply_self_effects(total_damage_dealt: int = 0) -> void:
	EffectExecutor.execute_self_effects(
		enemy,
		self_damage,
		0.0,
		self_heal,
		self_block,
		self_status,
		enemy.modifier_handler,
		total_damage_dealt
	)

# Shared intent text logic
func update_intent_text() -> void:
	if not is_instance_valid(target):
		return
		
	intent.current_text = intent.base_text
	
	var target_pkmn := target
	if not target_pkmn:
		return
		
	intent.target = target_pkmn.stats.icon
	intent.particles_on = status_effects.size() > 0
	
	if enemy and enemy.status_handler.has_status("confused"):
		intent.target = preload("res://art/statuseffects/confused-effect.png")
		return
	
	_update_intent_damage_display(target_pkmn)

func _update_intent_damage_display(target_pkmn: Node) -> void:
	# Override in subclasses for specific damage display logic
	var modified_dmg: int = target_pkmn.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_TAKEN)
	if modified_dmg > 0:
		intent.current_text = intent.base_text % modified_dmg
	else: 
		intent.current_text = intent.base_text % " "
