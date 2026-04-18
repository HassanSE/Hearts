# CLI Interface — Implementation Plan

> Living document for the `feature/cli-interface` branch.
> Update status markers as work progresses so we can resume after context clears.

## Goal

Build an interactive CLI executable (1 human vs 3 bots) that exercises the full
Hearts engine end-to-end. Primary purpose: detect missing pieces or bugs in the
engine under real gameplay conditions.

## Branching Strategy

- **Epic branch:** `feature/cli-interface` — all work merges here.
- **Step branches:** Each phase/step gets its own branch off the epic branch,
  e.g. `cli/phase-0-engine-gaps` (using `cli/` prefix since git disallows
  path extensions of existing branch names).
- Step branches are merged into `feature/cli-interface` via **pull requests**
  so the user can review changes before they land on the epic branch.
- Once the full CLI is done, `feature/cli-interface` merges into `main`.

---

## Status Key

- [ ] Not started
- [~] In progress
- [x] Completed

---

## Phase 0: Engine Gaps (fix before CLI work)

These are things the CLI needs that the engine doesn't currently expose.

- ~~**0.1** Expose legal moves publicly on `Game`~~ — **Dropped.**
  The CLI will use try/catch on `Game.playCard(_:by:)` instead. The engine
  already validates and throws typed `GameError`s. This keeps the engine's
  internal design intact and also exercises the error paths during testing.

- [x] **0.2** Make `Card` initializable from the CLI target
  - Added explicit `public init(suit:rank:)` to `Card`.

> **Note:** Track any additional engine gaps discovered during CLI implementation
> in this section. Each gets its own numbered item.

---

## Phase 1: Package Structure

- [x] **1.1** Add executable target `HeartsCLI` to `Package.swift`
  - Target depends on `Hearts` library.
  - Source directory: `Sources/HeartsCLI/`.

- [x] **1.2** Create `Sources/HeartsCLI/main.swift` with a minimal "Hello Hearts" entry point
  - Verified: builds and runs with `swift run HeartsCLI`.

---

## Phase 2: Game Setup (pre-game menu)

- [ ] **2.1** Difficulty selection prompt
  - Display: "Select difficulty: 1) Easy  2) Medium  3) Hard"
  - Parse input, default to Medium on invalid input.

- [ ] **2.2** Configuration options
  - Jack of Diamonds bonus: "Enable Jack of Diamonds bonus? (y/N)"
  - Moon shot variant: "Moon shot variant: 1) Add 26 to others (default)  2) Subtract 26 from shooter"
  - Winning score: "Winning score (default 100):"

- [ ] **2.3** Initialize `Game` with 1 human + 3 bots using selected config
  - Human player at index 0.
  - 3 bot players with chosen difficulty.

---

## Phase 3: Core Game Loop

- [ ] **3.1** Card exchange phase
  - Display the human player's 13-card hand (sorted by suit, then rank).
  - If exchange direction is `.none`, print "No exchange this round" and skip.
  - Otherwise prompt: "Select 3 cards to pass [direction]. Enter card numbers:"
  - Show numbered list of cards, accept 3 space-separated numbers.
  - Validate selection (exactly 3, valid indices, no duplicates).
  - Call `game.performExchange(humanCards:)`.
  - Show updated hand after exchange.

- [ ] **3.2** Trick-play loop (single trick)
  - Before human's turn: call `game.playBotTurnsUntilHumanTurn()` to auto-play
    any bots before the human.
  - Display current trick state (cards played so far by whom).
  - Display human's hand with legal moves highlighted/numbered.
  - Prompt: "Your turn. Select a card to play:"
  - Validate input and call `game.playCard(_:by:)`.
  - After human plays: call `game.playBotTurnsUntilHumanTurn()` again to
    finish the trick if bots follow.
  - Display completed trick result (winner, points).

- [ ] **3.3** Hand loop (13 tricks)
  - Repeat 3.2 until `game.isHandComplete`.
  - Call `game.endHand()`.
  - Display end-of-hand scoreboard (round scores + total scores).

- [ ] **3.4** Game loop (multiple hands)
  - After each hand, check `game.isGameOver`.
  - If not over: call `game.startNewHand()`, go back to 3.1.
  - If over: display final results and winner.

---

## Phase 4: Display Formatting

- [ ] **4.1** Hand display — cards sorted by suit (clubs, diamonds, spades, hearts), then rank
  - Format: `[1] 2♣  [2] 5♣  [3] J♦  ...`

- [ ] **4.2** Trick display — show each play as `PlayerName: Card`
  - Show lead suit indicator.

- [ ] **4.3** Scoreboard — table with columns: Player | Round | Total

- [ ] **4.4** Game over display — final standings sorted by score, winner announcement.

---

## Phase 5: Edge Cases & Polish

- [ ] **5.1** Handle first trick correctly
  - Human must lead 2♣ if they have it (engine enforces, CLI should show only
    2♣ as playable).
  - No points playable on first trick (engine enforces, CLI should reflect in
    legal moves).

- [ ] **5.2** Hearts broken notification — print a message when hearts are broken.

- [ ] **5.3** Shooting the moon notification — print a special message if it happens.

- [ ] **5.4** Input validation & error handling
  - Non-numeric input, out-of-range indices, repeated invalid input.
  - Graceful retry loop with clear error messages.

---

## Phase 6: Integration Testing via Gameplay

- [ ] **6.1** Play through at least one complete game manually via the CLI.
- [ ] **6.2** Document any engine bugs or missing features found during play.
- [ ] **6.3** Fix engine issues and re-test.

---

## Engine Issues Found During CLI Work

> Add entries here as they come up during implementation/testing.

| # | Description | Status | Fix |
|---|-------------|--------|-----|
|   |             |        |     |

---

## File Inventory

| File | Purpose |
|------|---------|
| `Sources/HeartsCLI/main.swift` | Entry point, game loop |
| `Package.swift` | Added HeartsCLI executable target |
| `CLI_PLAN.md` | This document |

---

## Resuming After Context Clear

When resuming work on this branch:

1. Read this file first: `CLI_PLAN.md`
2. Check which items are completed vs in-progress.
3. Read the files listed in the File Inventory.
4. Continue from the first unchecked item.

## Before Clearing Context / Exiting

**User:** Before you clear the context or end the session, ask me to do the following:

1. Confirm all recent changes are committed (or stashed).
2. Update this doc — mark completed items with `[x]`, in-progress with `[~]`.
3. Add any decisions, gotchas, or context to the "Session Notes" section below
   that would be lost if only the code existed (e.g., "we chose X over Y
   because...", "watch out for Z when implementing the next item").

**Assistant:** Before the user clears context, proactively:

1. Summarize what was done in the session.
2. Update this plan doc with completion status and session notes.
3. Remind the user to commit if there are uncommitted changes.
4. State clearly what the next item to work on is.

---

## Session Notes

> Append notes at the end of each work session. Label with the date.

### 2026-04-18 — Session 1: Planning

- Created `feature/cli-interface` branch.
- Wrote this plan doc.
- No code changes yet. Phase 0 is next.
