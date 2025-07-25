#events.gd
extends Node

#Card-related Events
signal card_drag_started(card_ui: CardUI)
signal card_drag_ended(card_ui: CardUI)
signal card_aim_started(card_ui: CardUI)
signal card_aim_ended(card_ui: CardUI)
signal card_played(card: Card)
signal card_tooltip_requested(card: Card)
signal tooltip_hide_requested()

#Item-related Events
signal item_aim_started(item: Item)
signal item_aim_ended(item: Item)
signal item_used(item: Item)
signal item_added(item: Item)

#Player-related Events
signal player_hand_drawn
signal player_hand_discarded
signal player_turn_ended
signal player_hit
signal player_died
signal card_play_initiated
signal card_play_completed
signal card_draw_requested(amount: int)


#Enemy-related Events
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_fainted(enemy: Enemy)
signal enemy_seeded(seeded: Status)


#Battle-related Events
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won
signal status_tooltip_requested(statuses: Array[Status])
signal status_tooltip_hide_requested()
signal pokemon_captured(stats: PokemonStats)
signal party_shifted
signal add_leveled_pkmn_to_rewards(pkmn_stats: PokemonStats)
signal return_to_main_menu
signal battle_text_requested(text: String)
signal battle_text_completed()
signal camera_shake_requested(damage: int, intensity: float)
signal card_added_to_hand(card: Card)

#Cutscene-related Events
signal mewtwo_phase_2_requested
signal pokemon_reward_requested(pkmn: PokemonStats)
signal pokemon_reward_completed

#Pokemon-related Events
signal party_pokemon_fainted(pokemon: PokemonBattleUnit)
signal player_pokemon_start_status_applied(pokemon: PokemonBattleUnit)
signal player_pokemon_end_status_applied(pokemon: PokemonBattleUnit)
signal added_pkmn_to_party(pokemon: PokemonBattleUnit)
signal player_pokemon_switch_requested(uid_out: String, uid_in: String)
signal player_pokemon_switch_completed(pkmn: PokemonStats)
signal evolution_triggered(pkmn: PokemonStats)
signal evolution_completed

#Map-related Events
signal map_exited(room: Room)
signal save_game(on_map: bool)

#Shop-related Events
signal shop_exited
signal shop_card_bought(card: Card, gold_cost: int)
signal shop_pkmn_bought(pkmn: PokemonStats, gold_cost: int)
signal shop_pkmn_clicked(pkmn: PokemonStats)

#Rest-related Events
signal pokecenter_exited

#Battle Reward-related Events
signal battle_reward_exited

#Treasure-related Events
signal treasure_room_exited

#RandomEvent-related Events
signal event_room_exited
