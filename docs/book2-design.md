# Book 2 design: *The Long-Lost Map* (the Land of Punt)

Approved (decisions at the end). Turns book 2 into the first Door level: Punt, the hunt for the map in "the room that isn't there", and Julia defending Villa Argo. Same conventions as `docs/book1-design.md`: every step cites the story reference (`docs/ulysses-moore-books-1-6-reference.md`, "ref") and is marked **canon** or **adaptation**.

## The big decision: split the twins

In the book the party splits at the very start: a wall collapses in Punt, everyone runs for the Door, and **it closes after only Julia gets through** (ref B2 scene 1, MEDIUM). For most of the book **Jason and Rick are in Punt** while **Julia is at Villa Argo** with Nestor, holding the house against Manfred in a storm (ref B2 scenes 7 and 15). The reference itself flags this as a natural asymmetric co-op chapter (§8).

**Proposal: follow the book and split the players** for the middle of the chapter. Each twin plays a different place at the same time, and the two halves need each other: each holds information the other needs, passed on by talking, the same way private clues work now, but across two places. They reunite at the end when the boys come home through the Argo Door (canon, ✅).

The alternative is to keep both twins in Punt and give Julia the Argo scenes as flashbacks or skip them. It's simpler to build but drops one of the book's main storylines.

Splitting needs one engine change: **each twin can be in a different level**. The host (Jason) keeps both levels loaded, so it can still check every action and own all state; Julia's machine loads only hers. Everything else (state, interactables, journal) already works per twin.

## Ground rules

- **Spoiler gates (ref §9):** Oblivia and Manfred appear for the first time. **Oblivia takes the map at the end** (canon, HIGH): the twins lose it, and it must not end up with them. Keep hidden: other Doors (Oblivia leaves Punt "through a passage", never named as the Cat Door), the First Key, Nestor's identity, Penelope's origin.
- **Rick** stays an NPC with Jason in Punt and carries the *Dictionary* (canon: Rick uses it in Punt). **Nestor** is with Julia at Argo.
- **Language in Punt** (ref §3 rule 6): Punt people's speech is shown translated. Back home in book 3 it won't be.
- No date or pharaoh for Punt (ref §5).

## Places (gray-box)

| Area | Contents | Source |
|---|---|---|
| Punt: hidden harbour and Door | Where the Metis lands; the passage to the Door back to Argo | Metis and Door canon; layout adaptation |
| Punt: town | Hot streets, market, a collapsed wall, mastaba tombs | canon (HIGH/MEDIUM); layout adaptation |
| House of Life | Library and archive: papyri, statues, corridors, niches; guards Micerinus and Pipi | canon (HIGH; guards LOW) |
| Shop of forgotten maps | Old map-seller with swollen feet; his crocodile Talos | canon (MEDIUM) |
| Abandoned corridors | Statues and mirrors; light from above | canon (LOW); puzzle adaptation |
| The room that isn't there | Hidden altar, a lamp going out, snakes, the "sound key" | room HIGH; details LOW |
| Villa Argo at night, in a storm | The house from book 1, with windows and doors to shut | canon (MEDIUM); reuses `villa_argo` |

## Chapter flow

### Part 1: arrival, together (both twins)

1. **Landing.** The Metis reaches a hidden harbour in Punt. A chest on board holds **local clothes**; both twins and Rick change. In disguise, townsfolk ignore you; without it, people stare and guards turn you back. *Canon: clothes from a chest on the Metis (HIGH). Disguise gating is adaptation.*
2. **Mastaba.** Near the harbour, a low stone tomb. Rick looks it up in the *Dictionary*: "mastaba". Journal entry. *Canon (HIGH).*
3. **The wall.** In the town, a wall collapses. Everyone runs back to the Door; **Julia gets through and it slams shut**. From here the twins are split. *Canon (MEDIUM).*

### Part 2: split

**Jason in Punt (with Rick):**

4. **Maruk.** After the collapse, a local girl is pinned under a fallen beam. **Jason shifts the beam** (push). She is **Maruk**, and she becomes their guide. *Canon: the boys help her after a collapse (LOW–MEDIUM). Beam is adaptation.*
5. **The House of Life.** Guards Micerinus and Pipi bar the door; Maruk talks them round (her father is a scribe there). *Canon: Maruk gets them past the guards (HIGH setting; social LOW–MEDIUM).*
6. **The archive.** Papyri, statues, niches. Jason climbs to a high niche and finds a drawing of the Metis and **Ulysses's note: the map was moved to "the room that isn't there."** The note also tells whoever is stuck outside the house how the Door can be opened from the Argo side (**Jason must pass this to Julia**). *Canon: Metis drawing, note about the room (LOW/MEDIUM). Door instruction is adaptation, the link to Julia's half.*
7. **Oblivia in the market.** A rich foreign woman trades cheap **lighters** for gold. She asks about the map shop. NPC scene. *Canon (MEDIUM). First sight of Oblivia.*
8. **The map shop.** The old map-seller (swollen feet) and **Talos the crocodile**, who blocks the back room. Oblivia was here first. He'll trade what he knows for **errands**: a delivery to a sailor at the harbour and one to a doctor. *Canon: owner, Talos, errands for information (MEDIUM/LOW). Errand details LOW.*
9. **The legend.** Errands done, he tells of a **three-turtle symbol** and gives them the **Ballad of Two Lovers**. *Canon titles (HIGH); content LOW. Ballad text is adaptation.*
10. **The abandoned corridors.** A shaft of light from the roof, statues of the two lovers, and turning mirrors (some on high ledges, Jason climbs). The Ballad says the lovers must "see each other": the light has to run from one lover's eyes to the other's. **The Ballad's meaning comes from Julia** (step 14). When the beam joins them, a wall slides open. *Canon: mirrors and light, statues, corridors (LOW). Solution adaptation.*
11. **The room that isn't there.** A hidden altar; the lamp is going out (a time limit); snakes on the floor (touch one and you're back at the door). The altar opens with the **sound key**: bronze plates struck in an order. **Julia has the order** (step 14). Inside: **the map**. *Canon: room, altar, lamp, snakes, sound key (HIGH/LOW). Mechanisms adaptation.*
12. **Oblivia takes the map.** As Jason lifts it, Oblivia steps out of the dark, takes it and leaves "through a passage" with a smile. Unavoidable. *Canon (HIGH).*

**Julia at Villa Argo (with Nestor):**

13. **Alone at night.** Julia comes through the Door alone; it shuts behind her. A storm. Nestor finds her. He talks a little about Penelope, Ulysses's wife (no spoilers: just that she's gone). *Canon: Julia at Argo with Nestor; Nestor talks to Julia about Penelope (MEDIUM).*
14. **Ulysses's notes on Punt.** In the library, Ulysses's own copy of the Ballad, with notes in the margin, and a page about the "sound key". **Only Julia can read them** (she's the one at home). She passes on what the lovers' lines mean (step 10) and the order of the bronze plates (step 11). *Adaptation (the books don't say how the boys solve these).*
15. **The storm and Manfred.** A big man prowls round the house in the rain: **Manfred**. Julia runs from room to room **shutting windows and doors** before he reaches them; Nestor holds the front door. He gets in anyway at the last one, snatches **the Owl key** and runs for the cliff. *Canon: Manfred attacks in the rain, Julia shuts doors and windows, he steals a key (MEDIUM). Which key is adaptation.*
16. **The cliff.** Julia chases him through the garden. He slips and **falls off the cliff** (and survives); the key lands on a ledge, and Julia gets it back. *Canon: she gets the key back; he falls off the cliff and survives (MEDIUM).*
17. **Opening the Door from this side.** With all four keys again, Julia opens the Door from the house using the instruction Jason found in the archive (step 6). *Adaptation (link between the halves).*

### Part 3: home, together

18. **Return.** The boys say goodbye to Maruk and come home **through the Argo Door** to Julia (canon ✅). The map is gone: Oblivia has it (spoiler gate: end of B2). Journal: what each twin saw.

## How the halves depend on each other

| Who needs it | What | Who has it |
|---|---|---|
| Jason (step 10) | What the Ballad's lines mean for the mirrors | Julia (step 14) |
| Jason (step 11) | The order of the bronze plates | Julia (step 14) |
| Julia (step 17) | How to open the Door from the Argo side | Jason (step 6) |

Pacing: Julia's storm (step 15) starts when Jason reaches the map shop, so neither twin waits too long.

## New mechanics this needs

| Mechanic | Used in | Notes |
|---|---|---|
| **Twins in different levels** | Part 2 | Host loads both; each player's own camera and level; reunite after. The one big engine change. |
| Disguise flag | Step 1 | Townsfolk and guards check it. |
| Moving NPCs | Manfred, Oblivia, Maruk | Waypoints driven by host state, interpolated on each peer. |
| Timed challenge | Windows (15), lamp (11) | Host timer; failure resets the attempt. |
| Light beam and mirrors | Step 10 | Grid-based beam computed from mirror states, drawn on both screens. |
| Hazards | Snakes | Touch: respawn at the room's door. |
| Errand items | Step 8 | Pickups and NPC lines, already supported. |
| Ordered plates | Step 11 | Like the floor stones. |

## Build order (proposal)

1. **Pass A:** the split engine change, Part 1 (harbour, mastaba, the wall), and Julia's whole half (steps 13–17) on a storm version of Villa Argo.
2. **Pass B:** Jason's half up to the legend (steps 4–9): town, Maruk, House of Life, Oblivia in the market, the map shop and errands.
3. **Pass C:** the corridors, the room that isn't there, Oblivia taking the map, and the return (steps 10–12, 18).

Each pass is tested with headless two-player playthroughs (in `tests/`) before it's pushed.

## Decisions

1. The twins split, as in the book.
2. Oblivia taking the map is unavoidable.
3. Julia's half is shorter and more action; Jason's is longer and more exploring.

## Status

- **Pass A done:** split engine (`Game.move_twin`, level origins), `scripts/levels/punt.gd` (harbour, chest of clothes, guards, the Door hall, the town street, mastaba, the wall), and Julia's half in `scripts/levels/villa_argo.gd` (Nestor, Ulysses's notes, six windows that Manfred tries in a fixed order, 7 s apart, the stolen Owl key, the chase, the Door opened backwards: Newt, Elephant, Porcupine, Owl).
- **Pass B done:** in `scripts/levels/punt.gd`, the fallen wall opens the lane to the House of Life: Maruk under the beam (Jason heaves it), guards Micerinus and Pipi (Maruk talks them round), the archive (drawing of the Metis; Ulysses's note in a high niche Jason climbs to: the map moved to the room that isn't there, and "ask it backwards"), Oblivia trading lighters in the market (she leaves before Jason reaches the shop), the map-seller's errands (a parcel to the sailor on the quay, ointment to the doctor), then the legend and the Ballad. Talos moves off the back-room steps, which lead to Pass C. Julia's storm now waits until Jason reaches the map shop. All Punt journal entries are Jason's only.
- **Pass C done:** `scripts/levels/punt_corridors.gd`, down the steps behind Talos. The mirror hall is a 7×7 grid of 3 m cells: SHE (west, facing east) and HE (facing north), five one-sided mirrors (three on the path, two decoys); the light must leave her face, turn at exactly three mirrors and reach his face from the north, which opens the west wall. The room that isn't there: a lamp that burns for 60 s once Jason is inside (out = back to the hall, sequence reset), three snakes sliding across the room (touch = back to the door), bronze plates SUN, MOON, STAR struck MOON, SUN, STAR, SUN to open the altar, then the map, and Oblivia takes it. Back in the Door hall, Maruk says goodbye; the Door home only opens once Julia has opened it from the house. Coming home sets the twins together again at Villa Argo, morning after the storm, with a shared "Home again" journal entry.
