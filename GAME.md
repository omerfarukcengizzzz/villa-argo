# Villa Argo — Game Design & Project Notes

Personal hobby project: a 3D online co-op game inspired by the *Ulysses Moore* book series,
made for two players (Omer and his girlfriend). Not for publishing or sale.

## Core idea
Two players play the Covenant twins, **Jason** and **Julia**, who discover the Doors to Time
in Villa Argo, an old house in the coastal town of Kilmore Cove, Cornwall. Each door leads to
a different era/place. They follow clues left by the house's previous owner, Ulysses Moore,
while racing a villain, **Oblivia Newton**, who wants the doors for herself.
Supporting characters: **Rick Banner** (local friend), **Nestor** (the villa's gardener).

## Core mechanic: asymmetric co-op
Each twin has abilities and information the other doesn't. Players must talk to solve puzzles.
- **Jason** — the explorer: climbing, running, jumping, pushing/pulling heavy objects.
- **Julia** — the thinker: reads symbols and clues only she can see, decodes, spots hidden patterns.
- Each player sees ONLY their own twin's view. Private information is a key design tool.

## Structure
- **Hub:** Villa Argo. Explore rooms between chapters, find keys that unlock new doors.
- **Levels:** each Door to Time = one level with its own look and puzzles.
- **Ulysses' journal:** in-game UI that fills with maps, riddles and hints as you play.
- **Pressure:** Oblivia's people chase the twins or race them to the next key.

## Tech decisions
- **Engine:** Godot 4 (GDScript). Chosen because scenes/scripts are plain text and work well with AI coding tools.
- **Multiplayer:** online, 2 players, host/client using Godot's high-level multiplayer API (ENet).
  - One player hosts, the other joins by IP.
  - Players connect through **Tailscale** (virtual private network) to avoid router port forwarding.
  - **Networked from day one.** Every interactive object (doors, levers, keys, puzzle pieces) must sync state.
  - Host is authoritative for puzzle/world state.
- **Version control:** Git from the first commit.

## Art direction
- Stylized (not realistic). Final style TBD from three test options:
  A) stylized soft/rounded, B) low-poly flat shaded, C) hand-painted storybook.
- Pipeline: concept/character sheets (AI image tool) → image-to-3D tool (e.g. Meshy, Tripo, Hunyuan3D)
  → cleanup in Blender → rig + animations via Mixamo → import into Godot.
- Environments/props: free asset packs first (Kenney, Quaternius, Poly Haven); AI-generate only hero pieces
  like the Doors to Time.

## AI tool roles
- **Claude (Goose):** design, architecture, puzzle design, planning, code review, debugging.
- **One main coding agent** in the repo (Claude Code, Codex, or Antigravity). Others as reviewers only.
- **Gemini / ChatGPT (Hornet):** concept art, character sheets, textures, journal art. Use one tool consistently.
- **Grok:** brainstorming, puzzle variations, dialogue drafts.

## Scope: first milestone (vertical slice)
### Milestone 1 — Networked gray-box prototype (no art)
1. Godot 4 project + Git repo.
2. Main menu: Host / Join (enter IP).
3. Two player characters (capsules), third-person camera per player, keyboard + controller input.
4. Player movement synced over the network.
5. One gray-box room with one co-op puzzle:
   Julia sees a symbol on the wall that is invisible to Jason; Jason must climb up and press the matching
   symbol among several options. Correct press opens a door.
6. Test over Tailscale between two PCs.

### Milestone 2 — Villa Argo hub + first door
- A few hub rooms, the first Door to Time, one full level (ancient Egypt suggested).
- Journal UI (first version).

### Milestone 3 — Art pass
- Final art style, character models, environment assets.

### Later
- Story, dialogue, cutscenes, music/SFX, more doors, playtesting after each level.

## Open questions
- Final art style (A/B/C).
- Which coding agent is "main".
- Character looks and names of first-level puzzles.