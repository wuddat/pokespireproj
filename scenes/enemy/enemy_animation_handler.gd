extends Node2D
const PKMN_SWITCH_ANIMATION = preload("res://scenes/animations/pkmn_switch_animation.tscn")

func _ready() -> void:
	if not is_inside_tree():
		await ready
func trainer_spawn_animation(pkmn: Enemy) -> void:
	var world_position = pkmn.global_position
	var canvas_position = get_canvas_transform().affine_inverse() * world_position
	var switch_animation = PKMN_SWITCH_ANIMATION.instantiate()
	switch_animation.end_pos = canvas_position
	add_child(switch_animation)
	switch_animation.pkmn_sprite.texture = pkmn.stats.art
	await switch_animation.animation_player.animation_finished
