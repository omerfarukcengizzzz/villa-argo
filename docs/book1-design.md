# Book 1 design: *The Door to Time* (Villa Argo hub)

Draft for approval. Turns book 1 into the first playable chapter: Villa Argo, the four keys, the Door, the passages below, and the Metis sailing for Egypt. Book 2 (Punt) is the first Door level and gets its own design.

Every step cites the story reference (`docs/ulysses-moore-books-1-6-reference.md`, "ref") and is marked **canon** (the books, per the ref's confidence label) or **adaptation** (invented for the game). Language: **English** (keys Owl, Porcupine, Elephant, Newt → OPEN; ref §6, MEDIUM).

## Ground rules

- **Jason** explores: only he can climb marked surfaces and push heavy furniture.
- **Julia** reads: ciphers, inscriptions and the Dictionary are drawn on her private layer, so only she sees what they say. Some steps reverse this (Jason sees something from a height she can't reach), so both players have to talk.
- **Rick Banner** is in every book 1 scene, but there are only two players. He appears as a simple NPC with a few lines and a hint when the twins are stuck; his book moments (seeing the acrostic) go to the twins. **Adaptation.**
- **Spoiler gates (ref §9):** no Oblivia, Manfred, map, other Doors or First Key in book 1. Nestor stays a gruff gardener; nothing hints he is Ulysses.
- Parents are off-screen (they leave for London, ref B1 scene 3).

## Places (gray-box)

There is no canon floor plan (ref §5), so the layout is **adaptation**; the rooms and their contents are canon where cited.

| Area | Contents | Source |
|---|---|---|
| Courtyard and garden | Iron gate, gravel, statue of a woman mending a net, Nestor's cottage (locked, B6 material) | canon (ref §5, HIGH) |
| Main hall | Venetian chandelier, Indian and African figures; stairs with portraits up to the tower | canon (HIGH) |
| Stone sitting room | East wall: scarred door with four keyholes, wardrobe in front of it | canon (HIGH; wardrobe MEDIUM) |
| Library | The *Dictionary of Forgotten Languages* | canon (HIGH) |
| Tower room | Mirror door; ship models and diaries | canon (HIGH) |
| Cliff path | Rocks below the house, a crevice with a box | canon (MEDIUM); path layout adaptation |
| Kilmore Cove post office | Tiny street level: post office counter | canon place (MEDIUM); layout adaptation |
| Behind the Door | Round room with four exits → dark stair → chamber with four turning floor stones → hatch → sea-cave beach with the Metis | canon sequence (MEDIUM) |

## Chapter flow

Each step is one GameState flag, so the chapter survives rejoins and can be resumed.

1. **Arrival.** Twins arrive in the courtyard. Nestor (NPC) shows them the scarred door and says it leads to an old cistern and its keys are lost. Journal: "The scarred door" (both). *Canon (B1 scene 1, HIGH).*
2. **Footsteps.** In the tower at night, Jason hears footsteps (toast and sound for Jason only); Julia hears nothing. Atmosphere, no puzzle. *Canon (B1 scene 2, HIGH); Jason-only is adaptation.*
3. **The cliff.** Jason climbs down the cliff path to a crevice. Some ledges crumble; **Julia, from the top, sees which ones are cracked** (her private layer) and calls them out. If Jason falls, he respawns at the top ("Julia and Rick pull him up"). In the crevice: the **box with glowing clay balls** (item) and a **coded parchment** (item). *Canon: fall, rescue, box and contents (MEDIUM). Cracked-ledge guidance is adaptation.*
4. **The first cipher.** In the library only Julia can read the *Dictionary*'s symbol table (private). The parchment's symbols are visible to both. Jason reads out symbols; Julia looks them up; she enters the decoded word at the Dictionary. The message points to **a dark cave and a ship**, and to "wood that hides a door". Journal entry (both). *Canon: decoded with the Dictionary, points to a cave and a ship (MEDIUM). Cipher alphabet and wording are adaptation (the ref says the alphabet is unknown).*
5. **Behind the wardrobe.** **Jason pushes the wardrobe** aside and reveals the four-keyhole door. *Canon: door behind the wardrobe (MEDIUM). Book: a pen rolls behind it; pushing is adaptation for Jason's role.*
6. **The tower diary.** A ship model sits on a high shelf. **Jason climbs up and lifts it**; under it is Ulysses's diary, and a **post-office receipt** falls out (item). Julia reads the diary's handwriting into the journal (her private entry, used in step 12). *Canon: model on diary, receipt (MEDIUM). Climbing is adaptation.*
7. **The post office.** Both twins go to Kilmore Cove (exit at the gate; both must be there). The clerk takes the receipt and hands over a **parcel: four animal keys** (Owl, Porcupine, Elephant, Newt) **and a second coded message**. Only Julia can read the message: a riddle about **four, three, two, one** and choosing a path. *Canon: parcel, keys, second message (MEDIUM). Wording is adaptation (ref: "exact wording unverified").*
8. **The four keys (OPEN).** Each lock takes one key; Jason places keys (pick a key at each lock). **The first try fails**: any order but the right one makes the locks spring back. The answer is **O-P-E-N** (Owl, Porcupine, Elephant, Newt) left to right. Julia's half of the second message contains the hint ("ask the door what it must do"); Rick's NPC hint after two failures: "Look at the first letters." *Canon: one-key-each fails, the initials spell OPEN (MEDIUM–HIGH). Lock-picking UI and hint wording are adaptation.*
9. **The round room.** Four exits; letters run together on the floor, drawn only for Julia. She splits them into words: "By night we move quickly, fearing the burning fire." Exits are marked sun, moon, flame and wave; the right one is **moon** (night, away from fire). Wrong exits lead round in a loop back to the room. *Canon: round room, four exits, run-together inscription (MEDIUM). Inscription is an English rendering of a LOW–MEDIUM quote; exit symbols and which exit is right are adaptation (ref: UNKNOWN).*
10. **The dark stair.** The candle goes out. The stair is pitch black except near **glowing clay balls**. Julia carries the clay and places balls on the steps (interact); Jason climbs ahead and calls out where the next gap is. *Canon: candle out, glowing clay lights the way (MEDIUM). The split is adaptation.*
11. **The floor stones.** Four numbered stones, each with an arrow. **Julia turns them** (90° per press). **Jason, standing on a ledge, sees the target arrows painted on the ceiling** (his private layer) and tells her which way each must point. The "four, three, two, one" riddle from step 7 gives the **order**: stone 4 first, then 3, 2, 1. Setting a stone out of order makes all four grind back to the start. When all four match, a hatch opens and **Julia jumps down first**. *Canon: Julia turns four stones 90° to open a hatch, jumps first (MEDIUM). Stone order and ceiling marks are adaptation (ref: order unknown).*
12. **The Metis.** A sea-cave beach and the ship. In the cabin, the captain's log. Julia's journal now shows that **its handwriting matches Ulysses's diary**. The log says the ship needs a chosen destination. *Canon (MEDIUM).*
13. **"Egypt!"** **Jason takes the helm** and chooses the destination; only Egypt is offered in book 1. The helm vibrates and the Metis sails: end of chapter, exit to Punt (book 2). *Canon: Jason shouts "Egypt!" (MEDIUM).*

## New mechanics this needs

| Mechanic | Used in | Notes |
|---|---|---|
| Jason-only climbing | Cliff, tower shelf, floor-stone ledge | Climbable surfaces marked in the level; Julia can't grab them. |
| Jason-only pushing | Wardrobe | Host-synced position, moves along a track. |
| Crumbling ledges + respawn | Cliff | Falling resets Jason to a checkpoint. |
| Picking an item at a slot | Key door | Cycle through held keys at each lock. |
| Text entry or symbol picker | Cipher | Small UI for Julia. |
| Rotating pieces | Floor stones | Host-synced rotation state. |
| Darkness and light sources | Dark stair | Unlit area; placed clay balls light it for both. |
| NPC lines | Nestor, Rick, the clerk | A label plus a toast; no dialogue system yet. |
| Choice at the helm | Metis | A simple list; only Egypt enabled. |

## Build order (proposal)

1. **Pass A, the house:** areas, steps 1–8, climbing, pushing, NPC lines, key-slot UI, post office level.
2. **Pass B, below the Door:** steps 9–13, darkness, floor stones, the Metis.
3. **Book 2 (Punt)** design document, then build.

Each pass is tested with the two-instance headless test before it's pushed, and replaces the `sandbox_*` levels once Pass A works.

## Open choices

- Rick as an NPC (above) or left out entirely?
- The night-time footsteps need a day/night switch; drop it if it's not worth it in gray-box.
- Step 11: the "four, three, two, one" riddle sets the order of the stones, and Jason's ceiling arrows set their directions. Fine as adaptation?
