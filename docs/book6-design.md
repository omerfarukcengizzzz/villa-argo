# Book 6 design: *The First Key* (the Garden, and Nestor's secret)

Approved (decisions at the end). Status: Pass A (steps 1–3) done: book 6 starts in the `garden` cloister, level `maze_town` (origin x 30000); test `tests/book6_pass_a.gd`. Adaptation choices in Pass A: the maze (a grid of streets with one way through, plus a dead-end branch and a loop), Jason's watchtower by the town gate with the view and the portcullis winch, Julia caught on entering the bell-tower square and shut in a little room at the bottom of the tower. Pass B (steps 4–12) done: the split starts 6 s after Julia is caught (`maze_town`); Rick's cottage, photo and Ulysses in `villa_argo`, Minaxo in `kilmore_cove`, the Horse key and the train in `station`; Jason's court of Prester John (guards, Black Vulcano, the knot) in `maze_town`; test `tests/book6_pass_b.gd`. Adaptation choices in Pass B: Rick's avatar (colour and a name tag; still the `julia` role underneath), a rain barrel under the cottage's back window, the coat, ship in a bottle and letters signed U., the photo puzzle (match Nestor's anchor ring and hand scar to the tall young man marked U.M.), Ulysses has the Horse key (Black Vulcano left it with him), two guards walking the court with hedges for cover, and Black Vulcano's lines. Pass C (steps 13–16) done: the reunion, the knot and the truth in `maze_town`, the epilogue in `kilmore_cove`; test `tests/book6_pass_c.gd`. Book 6 plays start to finish. Adaptation choices in Pass C: the train comes out of a Horse Door in the square's west wall; Jason takes a sword from the guards' rack; the cut is a choice (one stroke through the middle, from the legend only Rick reads); after the cut the journals are shared again; the truth scene needs both twins at Black Vulcano's pavilion; Manfred quits on the spot; the train takes everyone home to Kilmore Cove; the epilogue has Manfred and Gwendaline through the Cat Door when the twins come near Miss Biggles's house, Rick asking Julia for a walk, Minaxo asking Calypso to dinner (the players give him a push), and Fred asleep on a bench with a three-turtle key on his ring that only the players notice. Same conventions as books 1–5: every step cites the story reference (`docs/ulysses-moore-books-1-6-reference.md`, "ref") and is marked **canon** or **adaptation**.

Book 6 picks up where book 5 ends: the twins are shut in the medieval **Garden of Prester John** with Oblivia and Manfred, while **Rick is in Kilmore Cove** (ref B6 scene 1, HIGH). Rick **breaks into Nestor's cottage and finds out that Nestor is Ulysses Moore** (HIGH ✅), with an **old photograph** at the heart of it (HIGH ✅). He then goes to the Garden **through the station Door with Ulysses** (MEDIUM ✅). In the Garden: a labyrinthine medieval town (HIGH), Black Vulcano (MEDIUM), the **truth that nobody ever had the First Key** (MEDIUM), and a **Gordian knot** (MEDIUM, use unknown). It ends with Manfred running off to Punt with Gwendaline (✅), Julia and Rick together (MEDIUM), and the First Key, unknown to everyone, on **Fred's** key ring (MEDIUM ✅).

Note on the English edition: there is **no English book 6** (ref §2); names and wording are ours.

## Ground rules

- **Spoiler gates (ref §9):** book 6 is where the big secrets come out, so everything may now be revealed: **Nestor is Ulysses Moore**, **Black Vulcano never had the First Key**, **Black Vulcano is Oblivia's father** (✅), **Rick's father died searching for the First Key with Minaxo** (MEDIUM). **Keep hidden:** Penelope's fate and anything from books 7+ (other Doors, Atlantis and so on).
- **Rick is in Kilmore Cove at the start**, not in the Garden (ref §9 mistake 7).
- **Black Vulcano does not have the First Key**, and nobody finds it in the Garden (ref §9 mistake 6).
- **Zan-Zan and Phoenix Smith** also go through the station Door in the book (✅), but nothing is known about who they are (LOW). See open question 2.

## The split (needs your decision, question 1)

The book splits the party (ref §8 co-op note): the twins in the Garden, Rick in Kilmore Cove. With two players, the proposal is:

- **Julia is caught** in the Garden's maze-town by Manfred and locked up in a tower (*adaptation*). While she's held, **Julia's player plays Rick** in Kilmore Cove.
- **Jason's player** stays in the Garden, alone, looking for his sister.
- The two storylines run at the same time, as in books 2 and 4. **Only Rick's player sees the Nestor reveal** when it happens. Jason's player finds out when Ulysses walks into the Garden. That's private information at its biggest.
- Rick reaches the Garden, and together Rick and Jason free Julia. From then on the client is Julia again.

Technically the client keeps the `julia` role. While `b6.playing_rick` is set, the avatar is Rick (name, colour) and the journal entries go to that player as Rick's notes.

## Places (gray-box)

| Area | Contents | Source |
|---|---|---|
| The Garden: the maze-town | Narrow medieval streets, rooftops, a bell tower, the tower where Julia is held | canon (HIGH: "labyrinthine medieval town"); layout adaptation |
| The Garden: the court of Prester John | Where Black Vulcano lives | canon (Prester John HIGH; Black Vulcano in the Garden MEDIUM); contents adaptation |
| Villa Argo grounds: Nestor's cottage | Locked; inside, Ulysses Moore's things | canon (HIGH ✅); contents adaptation |
| Kilmore Cove: the lighthouse | Minaxo, about Rick's father | canon (MEDIUM ✅); scene adaptation |
| Clark Beamish Station | The Train of Eternal Youth and the Horse Door, opened this time | canon (the station Door is used in B6, MEDIUM ✅); riding the train through it is adaptation |

## Chapter flow

### Part 1: together in the Garden

1. **Out of the cloister.** Oblivia and Manfred have slipped away. A door from the cloister opens onto the **maze-town**. Journal. *Canon setting; scene adaptation.*
2. **The maze-town.** A co-op maze: **Jason** climbs onto the rooftops and sees the streets from above (a private view); **Julia**, in the streets, follows his directions toward the bell tower. *Adaptation (ref: the maze is to be invented).*
3. **Caught.** At the foot of the bell tower, Manfred grabs Julia and drags her into a tower; the door is tied shut with a huge, impossible knot. Jason is on the roofs and can't get down in time. **The split starts.** *Adaptation.*

### Part 2: split (Jason in the Garden, Rick in Kilmore Cove)

**Rick (Julia's player), in Kilmore Cove:**

4. **Rick on his own.** Book 6 opens on Rick in Kilmore Cove (canon). The twins haven't come back. Nestor won't say anything and has gone off somewhere. Rick still has the half-burned 1958 photo (*adaptation: he was looking at it when the twins left*).
5. **Nestor's cottage.** Rick breaks in (canon ✅): the door is locked, so he gets in through a back window. Inside are things a gardener shouldn't have: a captain's coat, a ship in a bottle, letters signed "U." and **the other half of the 1958 photo**. *Contents adaptation.*
6. **The photo.** Rick puts the two halves together. Now he can see the face of the young man next to Black Vulcano. The puzzle is matching that face to things Rick knows about Nestor (for example the scar on his hand and the way he stands). Once it fits: **Nestor is Ulysses Moore.** *Canon reveal (HIGH ✅); the matching puzzle is adaptation (ref: how the photo is used is unknown).*
7. **Ulysses.** Nestor comes back and finds Rick, and doesn't deny it. He explains in short lines: he disguised himself to keep the Doors safe and to see whether the twins were the right people to find them (*the why is partly adaptation*). He tells Rick to go and see Minaxo.
8. **The lighthouse.** Minaxo tells Rick that his father died searching for the First Key, with Minaxo beside him (canon MEDIUM ✅). *Scene adaptation.*
9. **The station.** Ulysses has the Horse key (*adaptation*). He and Rick fire up the Train of Eternal Youth (woken in book 5) and ride it through the Horse Door into the Garden. *Canon: Ulysses and Rick use the station Door (MEDIUM ✅); riding the train is adaptation (the CLIO ride claim is LOW).*

**Jason (Jason's player), in the Garden at the same time:**

10. **Alone.** Jason searches the maze-town for a way into Julia's tower. The streets are watched by Prester John's guards (patrols, as in books 4 and 5). *Adaptation.*
11. **Black Vulcano.** In the court of Prester John, Jason finds an old man who used to drive the trains: **Black Vulcano** (MEDIUM). Jason asks him for the First Key. **"I never had it. None of us ever found it."** (canon MEDIUM). And Oblivia? **She's his daughter** ("Fathers and Daughters", LOW title; the fact is ✅ MEDIUM). *Dialogue adaptation.*
12. **The knot.** Black Vulcano tells Jason what's on Julia's tower door: a **Gordian knot** that no one can untie. *Canon: a Gordian knot appears (MEDIUM); its use is adaptation.*

### Part 3: together again

13. **Reunion.** The train bursts out of the Horse Door into the Garden. Rick and **Ulysses Moore** step down. Jason's player sees Nestor, and Rick's player gets to watch him find out. *Canon: they arrive through the station Door (MEDIUM ✅).*
14. **The Gordian knot.** At the tower door, **Rick** (still Julia's player) reads the legend: Alexander the Great didn't untie the knot, he cut it. **Jason** fetches a blade from the guardhouse and cuts it. Julia is free, and the client is Julia again. *Adaptation.*
15. **The truth.** In the court, everyone together: Black Vulcano and Ulysses, two old friends from 1958; Oblivia, his daughter; the First Key nobody ever found. Manfred has had enough of Oblivia. Black Vulcano stays in the Garden (*adaptation*). Everyone else goes home on the train. *Canon: the truth (MEDIUM); Oblivia comes back (LOW).*
16. **Epilogue in Kilmore Cove.**
    - Manfred and Gwendaline the hairdresser slip into Miss Biggles's house and through the **Cat Door to Punt** (✅, two wikis).
    - Julia and Rick, together (MEDIUM).
    - Fred dozes on a bench, and on his huge ring of keys hangs a small one with **three turtles** on it. The players see it; nobody in the story notices (✅ Fred has the First Key, MEDIUM; how he got it, LOW, is not told).
    - End of book 6.

## Asymmetry at a glance

| Who | What only they do or see |
|---|---|
| Jason | The rooftop view of the maze; alone in the Garden; Black Vulcano's truth; cutting the knot |
| Julia | Following Jason's directions through the streets; reading the legend once freed (the client plays Rick in between) |
| Rick (Julia's player) | Nestor's cottage, the photo, the reveal; Minaxo and his father; the train through the Horse Door |

## New mechanics this needs

| Mechanic | Used in | Notes |
|---|---|---|
| The client plays Rick | Steps 4–14 | Same `julia` role; avatar, name and journal switch on `b6.playing_rick`. |
| Rooftop view | Step 2 | A Jason-only overhead layout (Vis layer 3) of the streets. |
| Photo matching | Step 6 | A ChoicePoint over the faces in the joined photo. |
| Guards on patrol | Step 10 | `Level.sees`, as in books 4–5. |

## Build order (proposal)

1. **Pass A:** out of the cloister, the maze-town together, Julia caught (steps 1–3).
2. **Pass B:** the split: Rick in Kilmore Cove (cottage, photo, Ulysses, Minaxo, the train) and Jason in the Garden (guards, Black Vulcano, the knot) (steps 4–12).
3. **Pass C:** the reunion, the Gordian knot, the truth, home, the epilogue (steps 13–16).

## Decisions

1. The split: yes. Julia's player plays Rick while Julia is held.
2. Zan-Zan and Phoenix Smith are left out.
3. Black Vulcano stays in the Garden at the end.
4. Minaxo and Calypso get a full scene in the epilogue (LOW–MEDIUM, labelled as such).
