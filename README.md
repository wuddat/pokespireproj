# PokéSpire

**A Pokémon deckbuilding roguelike in the spirit of Slay the Spire — built with Godot 4.4**

## 🎮 About the Game

**PokéSpire** blends the strategic deckbuilding of *Slay the Spire* with the world and mechanics of *Pokémon*. Fight wild Pokémon, catch them, build a party of up to 6, and use their unique moves as cards to battle your way to victory. Evolve your team, unlock powerful combos, and explore a procedurally generated map filled with battles, events, and surprises.

## 🔧 Features

* 🃏 **Deckbuilding Combat**: Each Pokémon in your party contributes unique cards to your deck based on its moveset. Catching a Pokémon adds 10 cards tied to that Pokémon’s UID.
* ⚔️ **Turn-Based Battles**: Engage in tactical, card-driven combat against wild Pokémon, trainers, and bosses.
* 🧠 **Enemy AI**: Opponents play cards just like you, using modular effects and targeting logic.
* 🌍 **Procedural Map Generation**: Explore branching paths with battles, PokéCenters, shops, treasures, and narrative events.
* 🧪 **Status Effects**: Fully modular system with effects like Poison, Sleep, Confuse, Burn, Dodge, Paralyze, and more.
* 🔁 **Evolution System**: Pokémon evolve mid-run based on XP, offering new card rewards and evolutions with branching logic.
* 🎯 **Targeting System**: Supports multi-target moves (e.g., Razor Leaf), splash effects, and enemy positioning.
* 🎭 **Dynamic Events**: JSON-driven event system with choices like Move Tutors, forgetting or transforming cards, and catching scripted Pokémon.
* 🛍️ **Shops & TMs**: Buy cards, gold, and learnable moves. Use TMs to teach specific moves mid-run.
* 🧳 **Party System**: Switch active Pokémon during battle. If a Pokémon faints, its cards are exhausted from your deck.
* 💾 **Data-Driven**: Built from JSON-powered Pokédex and move databases for all 151 Gen I Pokémon.
* ✨ **Visual Polish**: Status icons, tooltips, animations, audio cues, and shaders for battle effects and UI feedback.

## 📦 Built With

* [Godot 4.4](https://godotengine.org/)
* GDScript
* JSON-based data loaders
* Modular resource architecture for `Cards`, `Statuses`, `Pokemon`, `Moves`, etc.

## 🗺️ Game Loop

1. Choose a starter.
2. Progress through a procedurally generated map.
3. Battle wild Pokémon and trainers.
4. Catch new Pokémon and evolve your team.
5. Collect cards, gold, and items.
6. Face a powerful boss with unique mechanics and phases.
7. Win... or try again with a new run.

## 📁 Project Structure (Highlights)

```
/art
  /music            → beats
  /sfx              → boops
/custom_resources
  /cards            → Card resources (with modular EffectBlocks)
  /status_effects   → PoisonedStatus, SleepStatus, etc.
  /pokemon          → Pokédex + move data in JSON
/scenes
  /animations       → cutscenes and the like
  /battle           → Battle scene and UI
  /event            → custom event rooms
  /map              → Procedural room map and navigation
  /ui               → Tooltip, CardUI, Status Icons, Reward Selection
/scripts
  /battle           → Combat logic, turn manager, modifiers
  /map              → MapGenerator, Room, PathLogic
  /effects          → handler for damage, shift, heal, status effects and more
```

## 🧠 Design Philosophy

This project merges two deep systems — Pokémon and Slay the Spire — by focusing on:

* **UID-based linking** of cards and Pokémon.
* **Composable battle effects** through modular data blocks.
* **Scalable architecture** for new content (e.g., Gen II+ support, new relics/items, trainer archetypes).
* **User-friendly UI/UX** with clear tooltips, visual feedback, and snappy interactions.

## 🚧 In Progress

* Lots of polishing
* Wave Function Collapse for map pathing
* More dynamic events
* Expanded relic/item system
* Save/load functionality for long-term progression

## 🤝 Contributing

This is a personal project and currently not open for PRs, but feel free to fork and explore!

## 📷 Screenshots

*(Coming soon!)*

## 📜 License

This is a fan-made project not affiliated with Nintendo, Game Freak, or Slay the Spire creators. Intended for educational and personal use only. All Pokémon-related content is © their respective owners.
