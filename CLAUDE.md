# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Read GAME.md before starting any work.

## Current state

Milestone 1 in progress: Godot 4.7.2 (standard, GDScript) project with Host/Join menu, synced capsule players, and the gray-box symbol puzzle room. Not yet tested over Tailscale. There is no linter or test suite; run by opening the folder in Godot and pressing F5. The Godot exes sit in the project folder (git-ignored); `Godot_v4.7.2-stable_win64_console.exe --headless --path . --quit-after 60` is a quick check for script errors. Controls: WASD, mouse (or arrows), Space jump, E interact; gamepad: left stick, right stick, A jump, X interact.

To test networking on one PC, run two instances (Debug > Customize Run Instances > Enable Multiple Instances), host in one and join `127.0.0.1` in the other.

## Architecture

- `scripts/net.gd` (autoload `Net`): ENet host/join on port 7777 (max 1 client) and registration of the input actions in code (keyboard + gamepad), not in `project.godot`.
- `scripts/main_menu.gd`: UI built in code. Host goes straight to the world; join waits for `connected_to_server`.
- `scripts/world.gd`: builds the gray room in code and owns the `MultiplayerSpawner`. The client sends a `_client_ready` RPC after loading the scene, and only then does the host spawn both twins (host = Jason, peer 1; client = Julia). This avoids spawn packets arriving before the client's spawner exists.
- `scripts/player.gd`: each peer is authority over its own player, simulates movement locally, and replicates `position` and `rotation:y` through a `MultiplayerSynchronizer` created in code. Only the owning peer gets a camera and input.
- `scripts/puzzle.gd`: the symbol puzzle (node `World/Puzzle`). The host picks the target shape and broadcasts it via the `start` RPC (also on Julia's rejoin, with the solved flag). Julia's clue mesh is on render layer 2 and Jason's camera culls that layer in `player.gd`, so the private information is never drawn for Jason, and has shadows off so it can't leak that way. Only the host (Jason) can press buttons; it validates the press and broadcasts `feedback` / `open_door`.
- Scenes (`*.tscn`) are deliberately minimal (a root node plus script); most nodes are created in script.

## Constraints from GAME.md that shape all code

- **Engine:** Godot 4, GDScript. Keep scenes and scripts as plain text.
- **Networked from day one:** 2-player online co-op using Godot's high-level multiplayer API (ENet), one host and one client joining by IP (over Tailscale). Every interactive object (doors, levers, keys, puzzle pieces) must sync its state. The host is authoritative for puzzle/world state.
- **Asymmetric views:** each player sees only their own twin's view (Jason: explorer/climber; Julia: reads clues only she can see). Private per-player information is a core design tool, so visibility of puzzle info must be per-peer, not global.
- **Current scope:** Milestone 1 is a gray-box prototype with no art: Host/Join menu, capsule players with third-person cameras (keyboard + controller), synced movement, and one co-op puzzle room.

## Working agreements

- Claude Code is a candidate for the single "main" coding agent (still an open question in GAME.md); other tools act as reviewers only.
