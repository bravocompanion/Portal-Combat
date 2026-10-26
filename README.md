# Portal Combat — v1.0

**Portal Combat** is a playable Godot 4.7.x **single-player FPS roguelike battle-royale prototype** set in a procedural low-poly jungle. It is the technical foundation for a future multiplayer FPS with a Dota-style talent/item economy and tactical portal combat.

> **Scope:** v1.0 is an offline game against AI bots, **not yet online multiplayer**, and the visuals use built-in procedural meshes rather than final game assets. It has not been exported as an EXE or APK.

## Features in v1.0

- First-person WASD movement, mouse aim, jump, sprint, rifle fire, and reloading.
- An explorable 3D jungle with tree trunk cover, bushes, ruins, rocks, ramps, and two elevated towers.
- Three pairs of glowing two-way teleport portals; player and bots can use them.
- 11 AI jungle hunters that can fight the player **and one another**; last fighter standing wins.
- Shrinking storm circle that damages fighters outside the safe zone.
- **Q — Rift Blink** and **E — Rift Pulse** abilities, each with cooldowns.
- Collectible Rift Shards, ammo, health, and XP.
- Roguelike talent offers at levels 2, 4, 6, 8, and 10.
- Eight talents: Predator, Swiftstep, Bloodroot, Deep Magazine, Rift Battery, Reinforced Vest, Regrowth, and Vital Roots.
- HUD for health, armor, ammunition, level, XP, opponents, storm, and cooldowns.
- Victory/defeat overlay and Play Again button.
- Zero third-party add-ons, paid assets, or external texture dependencies.

## Requirements

- **Godot Engine 4.7.2 Standard** (GDScript version, not the .NET build).
- Windows, Linux, or macOS.
- Keyboard and mouse. Designed for desktop play.

Official download: https://godotengine.org/download/

## Connect GitHub to Godot / Open the project

### Option A — GitHub Desktop (easy, recommended)

1. Install **GitHub Desktop** and **Godot Engine 4.7.2**.
2. In GitHub Desktop: **File → Clone repository → URL**.
3. Enter `https://github.com/bravocompanion/Portal-Combat.git`.
4. Choose a local folder and click **Clone**.
5. Open **Godot Project Manager** → **Import**.
6. Browse to the downloaded `Portal-Combat` folder and select **project.godot**.
7. Choose **Import & Edit**, then press **F6** on the main scene or **F5** to run the project.
8. Future updates: open GitHub Desktop and use **Fetch origin / Pull origin**.
9. To send your own Godot changes back to GitHub: **Commit to main → Push origin**.

### Option B — Git command line

```bash
git clone https://github.com/bravocompanion/Portal-Combat.git
```

In Godot Project Manager, select **Import** and point it at `Portal-Combat/project.godot`.

**Important:** Godot doesn't remotely run your GitHub files inside the editor. You work from a **local cloned folder**, and GitHub syncs the source files through Git.

## Controls

| Control | Action |
|---|---|
| WASD | Move |
| Mouse | Aim |
| Left click | Shoot |
| Shift | Sprint |
| Space | Jump |
| R | Reload |
| Q | Rift Blink (short teleport) |
| E | Rift Pulse (area damage + stun) |
| H | Spend 25 Rift Shards to heal |
| Esc | Release / capture the mouse |
| Walk into a portal | Teleport to its linked exit |
| Click talent choice | Apply a roguelike upgrade |

## Core project files

```text
Portal-Combat/
├── project.godot
├── scenes/
│   └── main.tscn
├── scripts/
│   ├── main.gd       # world, storm, loot, portals, bots, HUD, talents
│   ├── player.gd     # FPS, rifle, movement, skills, health, leveling
│   ├── enemy.gd      # AI targeting, shooting, death
│   └── portal.gd     # two-way teleport and visible portals
├── .gitignore
└── README.md
```

## Roadmap

- **v1.0 (current):** desktop offline FPS playable prototype.
- **v1.1:** improved level art, audio, hit feedback, portal VFX, proper weapon/item slots, talent balance.
- **v1.2:** inventory, shop shrines, neutral jungle monsters, more hero archetypes, procedural match variants.
- **v2.0 (planned, not implemented):** authoritative server multiplayer, squads, matchmaking, lobby, anticheat, and full battle royale.

## Current limitations

The prototype has no networking, no exported executable, no Android controls, no save file, no original artwork/audio, and no full Dota-style item crafting shop. Portal travel teleports actors; it does **not** render the other side of a portal or allow bullets to travel across the portal opening. Visual bush cover is not automatically bulletproof; trunks, cliffs, rocks, and ruin geometry provide physical cover.

Created for **Portal Combat**. Version 1.0.
