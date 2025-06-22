#generic_enemy_status.gd
class_name EnemyStatus
extends EnemyAction

const STATUS_ICON := preload("res://art/status_effects/status_1.png")

@export var damage := 2
@export var splash_damage := 0
@export var self_damage := 0
@export var self_heal := 0
@export var status_effects: Array[Status] = []
@export var self_status: Array[Status] = []
@export var bonus_damage_if_target_has_status: String = ""
@export var bonus_damage_multiplier: float = 1.0
@export var damage_type: String

func setup_from_data(data: Dictionary) -> void:
	intent = Intent.new()
	
	status_effects = []
	if data.has("status_effects"):
		status_effects.append_array(StatusData.get_status_effects_from_ids(Utils.to_typed_string_array(data["status_effects"])))
	if data.has("self_status"):
		self_status.append_array(StatusData.get_status_effects_from_ids(Utils.to_typed_string_array(data["self_status"])))
		
	damage = 0
	splash_damage = data.get("splash_damage", 0)
	self_damage = data.get("self_damage", 0)
	self_heal = data.get("self_heal", 0)
	damage_type = data.get("type", "normal")
	bonus_damage_if_target_has_status = data.get("bonus_damage_if_target_has_status", "")
	bonus_damage_multiplier = data.get("bonus_damage_multiplier", 1.0)
	type = EnemyAction.Type.CHANCE_BASED
	chance_weight = 1.0
	action_name = data.get("name", "SOMETHING!")
	
	var damage_display = "%s"

	intent.particles_on = status_effects.size() > 0
	print("is intent on?: ", intent.particles_on)
	intent.base_text = damage_display
	intent.current_text = intent.base_text % damage
	if damage <= 0:
		intent.current_text = intent.base_text % " "
	intent.damage_type = damage_type

	if sound == null:
		sound = preload("res://art/sounds/VineWhip2.wav")
func perform_action() -> void:
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
			Events.enemy_action_completed.emit(enemy)
			return

	if targets_to_hit.is_empty():
		return

	# Animate to targets and let that handle the full effect chain
	var final_damage = 0
	if bonus_damage_if_target_has_status != "":
		var handler = targets_to_hit[0].get_node_or_null("StatusHandler")
		if handler:
			for status in handler.get_statuses():
				if status.id == bonus_damage_if_target_has_status:
					final_damage *= 0
					break

	if enemy and enemy.modifier_handler:
		final_damage = 0
	
	
	animate_to_targets(
	targets_to_hit,
	0,
	final_damage,
	splash_damage,
	status_effects,
	self_damage,
	self_heal,
	self_status,
	enemy,
	damage_type
)

func update_intent_text() -> void:
	if not is_instance_valid(target):
		return
		
	intent.current_text = intent.base_text #default
	intent.particles_on = status_effects.size() > 0
	
	var target_pkmn := target
	if not target_pkmn:
		return
	
	intent.target = target_pkmn.stats.icon
	
	var modified_dmg: int = target_pkmn.modifier_handler.get_modified_value(damage, Modifier.Type.DMG_TAKEN)
	if modified_dmg > 0:
		intent.current_text = intent.base_text % modified_dmg
	else: 
		intent.current_text = intent.base_text % " "

	if enemy and enemy.status_handler.has_status("confused"):
		intent.target = preload("res://art/statuseffects/confused-effect.png")
		return
