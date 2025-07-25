# effect_executor.gd
class_name EffectExecutor
extends RefCounted

static func execute_damage(
	amount: int, 
	targets: Array[Node], 
	source: Node, 
	modifiers: ModifierHandler,
	damage_type: String = "normal",
	sound: AudioStream = null,
	is_splash: bool = false,
) -> int:
	var total_damage_dealt = 0
	
	for target in targets:
		if not is_instance_valid(target) or target.stats.health <= 0:
			continue
			
		if target.has_method("dodge_check") and target.dodge_check():
			continue
			
		var type_multiplier = TypeChart.get_multiplier(damage_type, target.stats.type)
		var modified_damage = modifiers.get_modified_value(amount, Modifier.Type.DMG_DEALT)
		var final_damage = round(modified_damage * type_multiplier)
		
		var damage_effect = DamageEffect.new()
		damage_effect.amount = final_damage
		if sound:
			damage_effect.sound = sound
		
		# Set sound based on effectiveness
		if type_multiplier > 1:
			damage_effect.sound = preload("res://art/sounds/sfx/supereffective.wav")
			damage_effect.super_effective = true
		elif type_multiplier < 1:
			damage_effect.sound = preload("res://art/sounds/not_effective.wav")
		
		damage_effect.execute([target])
		total_damage_dealt += final_damage
		
	return total_damage_dealt

static func execute_status_effects(
	status_effects: Array[Status], 
	targets: Array[Node], 
	source: Node,
	effect_chance: float = 1.0,
	sound: AudioStream = null
) -> void:
	for status_effect in status_effects:
		if not status_effect:
			continue
			
		var applied = RNG.instance.randf() <= effect_chance
		if applied:
			var stat_effect = StatusEffect.new()
			stat_effect.source = source
			stat_effect.status = status_effect.duplicate(true)
			if sound:
				stat_effect.sound = sound
			stat_effect.execute(targets)


static func execute_block(
	amount: int,
	targets: Array[Node],
	source: Node,
	modifiers: ModifierHandler = null,
	sound: AudioStream = null
) -> void:
	for target in targets:
		if not is_instance_valid(target):
			continue
			
		var modified_amount = amount
		if modifiers:
			modified_amount = modifiers.get_modified_value(amount, Modifier.Type.BLOCK_GAINED)
		
		if modified_amount <= 0:
			modified_amount = 0
			
		var block_effect = BlockEffect.new()
		block_effect.amount = modified_amount
		block_effect.base_block = amount
		if sound:
			block_effect.sound = sound
		block_effect.execute([target])


static func execute_self_effects(
	source: Node,
	self_damage: int = 0,
	self_damage_percent: float = 0.0,
	self_heal: int = 0,
	self_block: int = 0,
	self_status: Array[Status] = [],
	modifiers: ModifierHandler = null,
	total_damage_dealt: int = 0
) -> void:
	# Self damage
	if self_damage > 0:
		var damage_effect = DamageEffect.new()
		damage_effect.amount = self_damage
		damage_effect.sound = null
		damage_effect.execute([source])
		
	if self_damage_percent > 0:
		var damage_effect = DamageEffect.new()
		damage_effect.amount = round(source.stats.max_health * self_damage_percent)
		damage_effect.sound = null
		damage_effect.execute([source])
		
	# Self block
	if self_block > 0:
		var block_effect = BlockEffect.new()
		block_effect.amount = modifiers.get_modified_value(self_block, Modifier.Type.BLOCK_GAINED) if modifiers else self_block
		block_effect.base_block = self_block
		block_effect.execute([source])
		
	# Self heal
	if self_heal > 0:
		var heal_effect = HealEffect.new()
		heal_effect.amount = total_damage_dealt / 2
		heal_effect.sound = null
		heal_effect.execute([source])
		
	# Self status effects
	execute_status_effects(self_status, [source], source, 1.0)

# Add this improved version to effect_executor.gd
static func execute_shift(targets: Array[Node], source: Node, amount: int = 1) -> void:
	if amount <= 0:
		return
		
	var tree = source.get_tree()
	if not tree:
		push_warning("ShiftEffect could not find parent TREE")
		return
		
	# Handle player Pokemon shifting
	if targets.size() > 0 and targets[0] is PokemonBattleUnit:
		var party_handler = tree.get_first_node_in_group("party_handler")
		if party_handler:
			for i in amount:
				party_handler.shift_active_party()
		Events.party_shifted.emit()
		
	# Handle enemy shifting
	elif targets.size() > 0 and targets[0] is Enemy:
		var enemy_handler = tree.get_first_node_in_group("enemy_handler")
		if enemy_handler:
			enemy_handler.shift_enemies()
			Events.party_shifted.emit()


# Add this to effect_executor.gd
static func execute_enemy_damage(
	amount: int,
	targets: Array[Node], 
	source: Node,
	damage_type: String = "normal",
	sound: AudioStream = null,
	animate: bool = true
) -> int:
	var total_damage_dealt = 0
	
	for target in targets:
		if not is_instance_valid(target) or target.stats.health <= 0:
			continue
			
		if target.has_method("dodge_check") and target.dodge_check():
			continue
			
		var type_multiplier = TypeChart.get_multiplier(damage_type, target.stats.type)
		var final_damage = round(amount * type_multiplier)
		
		var damage_effect = DamageEffect.new()
		if sound:
			damage_effect.sound = sound
		damage_effect.amount = final_damage
		
		# Set sound based on effectiveness
		if type_multiplier > 1:
			damage_effect.sound = preload("res://art/sounds/sfx/supereffective.wav")
		elif type_multiplier < 1:
			damage_effect.sound = preload("res://art/sounds/not_effective.wav")
		
		damage_effect.execute([target])
		total_damage_dealt += final_damage
		
	return total_damage_dealt

static func execute_enemy_animation(
	source: Node,
	targets: Array[Node],
	total_damage: int = 0
) -> void:
	if targets.is_empty():
		return
		
	var target = targets[0]
	if not is_instance_valid(target):
		return
		
	var start_pos = source.global_position
	var end_pos = target.global_position + Vector2.RIGHT * 32
	
	if total_damage <= 0:
		end_pos = source.global_position + Vector2.LEFT * 32
	
	var tween = source.create_tween().set_trans(Tween.TRANS_QUINT)
	tween.tween_property(source, "global_position", end_pos, 0.3)
	tween.tween_interval(0.2)
	tween.tween_property(source, "global_position", start_pos, 0.3)
	
	await tween.finished
	
static func execute_card_draw(amount: int) -> void:
	Events.card_draw_requested.emit(amount)
