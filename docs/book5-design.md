# Book 5 design: *The Stone Guardians* (Clark Beamish Station and the Garden)

Approved (decisions at the end). Status: Pass A (steps 1–5) done; level `school` (origin x 21000), the rest in `villa_argo` and `kilmore_cove`; test `tests/book5_pass_a.gd`. Pass B (steps 6–11) done: Fred and the town hall in `kilmore_cove`, level `station` (origin x 24000); test `tests/book5_pass_b.gd`. Adaptation choices in Pass B: the board's mystery train (25:00, platform 3, code MI-RA-SO 3, readable only by Julia); the ticket's route (Old Mill, Quarry, Tunnel: levers right, right, left); the points move only while the red valve is open and lock when it's closed again with blue open (so Fred's routine is the locked resting state); the firebox takes coal (Jason) and bellows (Julia) in turn, the same twice chokes it, and the fire dies down if nobody tends it. Same conventions as books 1–4: every step cites the story reference (`docs/ulysses-moore-books-1-6-reference.md`, "ref") and is marked **canon** or **adaptation**.

Book 5 follows the lead from book 4: **find Black Vulcano**, believed to hold the First Key, before Oblivia and Manfred do (ref B5 scene 1, HIGH ✅). It moves from school trouble in Kilmore Cove to the abandoned **Clark Beamish Station**, the best-described place in the whole reference (the overgrown hall, the 1936 perpetual timetable, the moving bookstand, Dedalus's ticket printer, the control room with red levers and red and blue valves; ref §5, HIGH), and ends with the twins arriving in the medieval **Garden of Prester John** (ref B5 scenes 10–11).

Note on the English edition: there is **no English book 5** (ref §2), so all names and wording come from Italian sources; English renderings are ours.

## Ground rules

- **Together, not split.** In book 5 the twins (and Rick) stay together. The asymmetry is private information and split roles within the same place, as in book 3: at school, **Jason sneaks out while Julia covers for him**; at the station, **Julia sets things off and reads, Jason climbs and works the machines**.
- **Rick** is an NPC with the twins throughout (canon: Rick examines the station machinery). **Fred Dormiveglia**, the sleepy clerk with all the keys, is a new NPC (canon, HIGH).
- **Spoiler gates (ref §9):** players may learn about **Fred, the station, the timetable, the valves, the 1958 "Great Summer" group**, and that **the Garden can be reached**. **Keep hidden:** that the Black Vulcano lead is false (book 6), Nestor is Ulysses, Black Vulcano is Oblivia's father, Rick's father. The station's **Horse Door** is seen but **not used** (canon: it's used in book 6 by others).
- **How the twins reach the Garden:** through the **Villa Argo Door**, with Oblivia and Manfred going there too (ref ✅ correction: not by the station train). The station's train "comes back to life" (canon ✅) but nobody rides it in book 5.
- **Jason jealous of Julia and Rick** (canon, MEDIUM) shows up only in a few lines of dialogue.

## Places (gray-box)

| Area | Contents | Source |
|---|---|---|
| Kilmore Cove school | Classroom, the headteacher's office, the restroom window | canon (MEDIUM); layout adaptation |
| Kilmore Cove (existing level) | Chubber's pastry shop; the lighthouse (Minaxo) | canon (MEDIUM) |
| Clark Beamish Station | The overgrown hall (glass-and-iron roof lantern, a chandelier with birds nesting in it, flowers through the marble, iron benches, ticket windows, a giant iron timetable board on chains), the ticket office, the control room, the dead-end tunnel to the Horse Door | canon (HIGH; tunnel MEDIUM) |
| The Garden of Prester John | Medieval: stone guardians, a garden gate, the corridor of death, a cloister | canon (HIGH setting; contents are chapter titles) |

## Chapter flow

### Part 1: school trouble

1. **The new goal.** At Villa Argo, the twins and Rick decide: find Black Vulcano before Oblivia does. Nestor grunts that Black Vulcano used to drive the trains (canon: former train driver/stationmaster, HIGH). Journal. *Canon (HIGH ✅).*
2. **School.** The twins have to go to school in Kilmore Cove (a new level). **Jason sneaks out to the lighthouse** to ask Minaxo about Black Vulcano; **Julia covers for him** in class (when the teacher checks, Julia answers for him, using a seating chart only she can see, adaptation). *Canon: Jason sneaks to the lighthouse, Julia covers (MEDIUM).*
3. **The lighthouse.** Minaxo, gruff, finally talks: in the **"Great Summer" of 1958**, Ulysses, Peter Dedalus, Black Vulcano, Clio Biggles, Minaxo himself and others found the Doors and swore to protect them: the Imaginary Travellers (canon, MEDIUM; exact members LOW, so the game names only the ones we've met plus Black Vulcano). Black Vulcano ran the trains at **Clark Beamish Station**, now shut. Only **Fred**, at the town hall, has the keys. *Canon.*
4. **Caught.** On the way back Jason hides in **Chubber's pastry shop**, nearly runs into his father, and climbs back in through the **restroom window** (Jason climbs). But he's caught anyway: the headteacher **confiscates the four Argo keys, the half-burned photo and the Egyptian charm** (canon, MEDIUM). *Adaptation: the charm is the amulet Maruk gave (one report, LOW).*
5. **Getting them back.** The confiscated things are in the headteacher's office. **Julia keeps the headteacher talking** at the office door (choices in a conversation; pick wrong and she ends it) while **Jason climbs in through the office window** and takes them back. *Adaptation: the book says they're confiscated; how they're recovered is unknown.*

### Part 2: Clark Beamish Station

6. **Fred.** Sleepy Fred Dormiveglia opens the chained station with a ring of ordinary keys, yawning (canon, HIGH). He mentions he turns the valves twice a week, **red closed, blue open**, paid in advance by Black Vulcano, and he has no idea why (canon, HIGH).
7. **The hall.** The ruined hall: roof lantern, the chandelier full of birds, flowers through the marble, and the giant iron timetable board hanging on chains, too high to read (canon, HIGH).
8. **The ticket office.** The **perpetual timetable of all trains to, from and through Kilmore Cove, in force from 18 January 1936** (canon, HIGH). **Julia sets off the moving iron bookstand**, which lowers the big timetable board in the hall; **Rick works out why** (canon: Julia sets it off, Rick works it out, HIGH). On the board, only Julia (the reader) can make sense of the columns: one train, at a time that doesn't exist, has no destination. *The board's contents are adaptation.*
9. **The ticket printer.** Dedalus's ticket printer has keys marked with odd syllables and the numbers 1–3 (canon, HIGH). Using the timetable's mystery train (Julia reads it out) and the syllables (Jason types), it prints a ticket. *Mechanism adaptation (ref: unknown).*
10. **The control room.** A model of the tracks with red switch levers, and red and blue pipes with valves (canon, HIGH). **Jason** climbs among the pipes to the valves; **Julia** reads the track model. Fred's routine (red closed, blue open) is the start, not the answer (ref: its purpose is unknown, don't treat it as the solution). Set the levers to the ticket's route.
11. **The riddle.** On the locomotive in the tunnel: a verse, *"half of sand and half of wind… fill your heart… at least a hundred"* (canon fragments, LOW–MEDIUM; the game's English wording is our own, not a translation of a full text). The heart is the firebox: fill it with coal and wind (the bellows) until the gauge passes a hundred. **The Train of Eternal Youth** wakes, steaming, in front of the boarded **Horse Door** (canon ✅). Nobody gets on: Rick says they'd need the Horse key, and Black Vulcano has the keys. *The firebox puzzle is adaptation (ref: possible meaning, LOW).*

### Part 3: to the Garden

12. **Oblivia moves first.** Back at Villa Argo, the Door is open and the Metis's cabin smells of perfume: Oblivia and Manfred have gone ahead, to the **Garden of Prester John**. The helm now offers the Garden. The twins follow; **Rick stays behind** to keep watch (sets up book 6, where Rick is in Kilmore Cove). *Canon: the twins, Oblivia and Manfred reach the Garden through the Argo Door (✅); Rick stays (B6 HIGH).*
13. **The Garden.** A medieval walled garden: the **stone guardians** at the gate (statues that move when not watched: each twin can only watch one at a time, so they cover each other's backs), the **corridor of death** (a timed trap corridor), the **cloister**. At the end the twins are inside the Garden, and the gate closes behind them. *Canon: chapter titles Castaway, Corridor of Death, Intruders, Guardians of Time, Cloister, Truth (HIGH); contents adaptation.*

Book 5 ends with the twins in the Garden (canon). Book 6 continues there.

## Asymmetry at a glance

| Who | What only they do or see |
|---|---|
| Julia | Covers in class (her seating chart); talks the headteacher round; sets off the bookstand; reads the timetable board and the track model |
| Jason | Sneaks to the lighthouse; climbs the restroom and office windows; types on the ticket printer; climbs to the valves; works the bellows |

## New mechanics this needs

| Mechanic | Used in | Notes |
|---|---|---|
| Conversation choices with failure | Steps 2, 5 | `ChoicePoint` with a running "patience" count. |
| Raising and lowering objects | Step 8 | The timetable board on chains (a tweened platform). |
| Gauges | Step 11 | A Dial-like gauge filled by repeated use. |
| Watched statues | Step 13 | Stone guardians that move only when no twin is looking at them (the reverse of `Level.sees`). |
| Timed trap corridor | Step 13 | Hazards, as in books 3–4. |

## Build order (proposal)

1. **Pass A:** the goal, school, the lighthouse and the 1958 group, the pastry shop and the window, the confiscation and getting the things back (steps 1–5).
2. **Pass B:** Clark Beamish Station: Fred, the hall, the ticket office, the printer, the control room, the riddle and the train (steps 6–11).
3. **Pass C:** to the Garden: Oblivia ahead, the Metis, the stone guardians, the corridor of death, the cloister (steps 12–13).

## Decisions

1. School is a playable level.
2. Rick stays behind at the end of book 5.
3. Stone guardians that move only when unwatched: yes.
4. Black Vulcano stays offstage until book 6.
