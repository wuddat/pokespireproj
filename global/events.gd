extends Node

#Card-related Events
signal card_drag_started(card_ui: CardUI)
signal card_drag_ended(card_ui: CardUI)
signal card_aim_started(card_ui: CardUI)
signal card_aim_ended(card_ui: CardUI)
signal card_played(card: Card)
signal card_tooltip_requested(card: Card)
signal tooltip_hide_requested()

#Player-related Events
signal player_hand_drawn
signal player_hand_discarded
signal player_turn_ended
signal player_hit
signal player_died


#Enemy-related Events
signal enemy_action_completed(enemy: Enemy)
signal enemy_turn_ended
signal enemy_fainted(enemy: Enemy)


#Battle-related Events
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won
signal status_tooltip_requested(statuses: Array[Status])
signal status_tooltip_hide_requested()
signal pokemon_captured(stats: PokemonStats)

#Pokemon-related Events
signal party_pokemon_fainted(pokemon: PokemonBattleUnit)
signal player_pokemon_start_status_applied(pokemon: PokemonBattleUnit)
signal player_pokemon_end_status_applied(pokemon: PokemonBattleUnit)
signal added_pkmn_to_party
signal player_pokemon_switch_requested(uid_out: String, uid_in: String)
signal player_pokemon_switch_completed(pkmn: PokemonStats)

#Map-related Events
signal map_exited(room: Room)

#Shop-related Events
signal shop_exited
signal shop_card_bought(card: Card, gold_cost: int)
signal shop_pkmn_bought(pkmn: PokemonStats, gold_cost: int)

#Rest-related Events
signal pokecenter_exited

#Battle Reward-related Events
signal battle_reward_exited

#Treasure-related Events
signal treasure_room_exited
