# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Read GAME.md before starting any work.

## Current state

Milestone 1 built (not yet tested over Tailscale). Milestone 2 in progress: book 1 is being built per `docs/book1-design.md`. Pass A (Villa Argo and the Kilmore Cove post office, steps 1–8) and Pass B (behind the Door: round room, dark stair, floor stones, the Metis, steps 9–13) are done, so book 1 plays start to finish; book 2 (Punt) is next. All story content follows `docs/ulysses-moore-books-1-6-reference.md`: respect its confidence labels and spoiler gates, and label invented lore as adaptation. Godot 4.7.2 (standard, GDScript). There is no linter. `tests/` holds headless two-process playthroughs: run `<godot> --headless --path . -s tests/book1_pass_a.gd -- host` and, two seconds later in a second shell, the same with `-- client`; each prints PASS/FAIL lines and exits non-zero on failure. Otherwise run by opening the folder in Godot and pressing F5. The Godot exes sit in the project folder (git-ignored); `Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 60` is a quick check for script errors. Controls: WASD, mouse (or arrows), Space jump, E interact, J journal; gamepad: left stick, right stick, A jump, X interact, Back journal.

To test networking on one PC, run two instances (Debug > Customize Run Instances > Enable Multiple Instances), host in one and join `127.0.0.1` in the other. Launch arguments `--host` and `--join=IP` (after `--`, or per instance in that dialog) skip the menu. Jason climbs green surfaces by walking into them.

## Architecture

- `scripts/net.gd` (autoload `Net`): ENet host/join on port 7777 (max 1 client), `my_role()` (host = Jason), and registration of the input actions in code (keyboard + gamepad), not in `project.godot`.
- `scripts/game_state.gd` (autoload `GameState`): all host-authoritative state: flags, the twins' shared inventory, journal entries (each with `who`: both/jason/julia). Only the host writes (`set_flag`, `give_item`, `add_journal`); writes are broadcast by RPC and a (re)joining client gets `send_snapshot`. Anything that must survive a level change or rejoin lives here, never in a level. `check(cond)` evaluates condition strings (`"flag"`, `"item:id"`, `"!..."`) used by interactables and NPC lines. Story flags are namespaced by place (`argo.*`, `argo_door.*`).
- `scripts/main_menu.gd`: UI built in code. Host goes straight to the game; join waits for `connected_to_server`.
- `scripts/game.gd` (`Game`, scene `game.tscn`, `Game.current`): session root. Owns the twins (`Players` + `MultiplayerSpawner`), the current level (node `Game/Level`), the HUD (prompt, stacked toasts via host-only `say(text, who)`), the text box (`ask_text`), the choice list (`ask_choice`) and the journal UI. The client sends `_client_ready` after loading; the host replies with the state snapshot, the current level and only then spawns both twins (host = Jason, peer 1; client = Julia). `change_level(path, entry)` (host) loads the level on every peer and teleports both twins to the entry point.
- `scripts/level.gd` (`Level`): base for levels built in code (`_build` on every peer, `_host_setup` on the host, `entries` for spawn points, `fall_y`/`respawn_point` for falls, `set_night`, and `add_box`/`add_ramp`/`add_climb_wall`/`add_label`/`place` helpers). Levels live in `scenes/levels/` + `scripts/levels/`: `villa_argo` (start), `kilmore_cove` and `argo_underground`.
- `scripts/interactable.gd` (`Interactable`) and `scripts/interactables/`: things a twin uses with interact (`Door`, `Pickup`, `Pushable`, `KeyLock`, `CodeEntry`, `Helm`, `FloorStone`, `LightSocket`, `Npc`, `SymbolButton`, `JournalNote`, `LevelExit`). `who` restricts which twin may use one, `requires` is a GameState condition, and `on_used` is a host-only story hook levels attach (journal entries, flags). The owning player shows a prompt for the nearest one; the press goes to the host, which validates role and distance, then `_host_interact` changes `GameState`; every peer redraws in `refresh()`. Interactables need stable node names (use `Level.place`) so RPCs resolve on both peers.
- `scripts/player.gd`: each peer is authority over its own player, simulates movement locally, and replicates `position` and `rotation:y` through a `MultiplayerSynchronizer` created in code. Only the owning peer gets a camera, input and interaction. `teleport` is a host-only RPC. Jason climbs inside `Climbable` zones (`scripts/climbable.gd`); a twin below the level's `fall_y` is put back at `respawn_point`.
- `scripts/vis.gd` (`Vis`): private per-twin visuals. Render layer 2 is Julia-only, layer 3 Jason-only; each camera culls the other twin's layer, and `Vis.make_private` also turns shadows off so nothing leaks. (Privacy is visual: the host's machine holds all state.)
- `scripts/journal_ui.gd` (`JournalUI`): Ulysses' journal overlay, showing only entries for this twin plus the shared inventory. Opening it blocks player input (`Game.input_blocked`).
- Scenes (`*.tscn`) are deliberately minimal (a root node plus script); most nodes are created in script.

## Constraints from GAME.md that shape all code

- **Engine:** Godot 4, GDScript. Keep scenes and scripts as plain text.
- **Networked from day one:** 2-player online co-op using Godot's high-level multiplayer API (ENet), one host and one client joining by IP (over Tailscale). Every interactive object (doors, levers, keys, puzzle pieces) must sync its state. The host is authoritative for puzzle/world state.
- **Asymmetric views:** each player sees only their own twin's view (Jason: explorer/climber; Julia: reads clues only she can see). Private per-player information is a core design tool, so visibility of puzzle info must be per-peer, not global.
- **Current scope:** Milestone 1 is a gray-box prototype with no art: Host/Join menu, capsule players with third-person cameras (keyboard + controller), synced movement, and one co-op puzzle room.

## Working agreements

- Claude Code is a candidate for the single "main" coding agent (still an open question in GAME.md); other tools act as reviewers only.
