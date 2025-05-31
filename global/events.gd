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

#Battle-related Events
signal battle_over_screen_requested(text: String, type: BattleOverPanel.Type)
signal battle_won

#Map-related Events
signal map_exited

#Shop-related Events
signal shop_exited

#Rest-related Events
signal pokecenter_exited

#Battle Reward-related Events
signal battle_reward_exited

#Treasure-related Events
signal treasure_room_exited
