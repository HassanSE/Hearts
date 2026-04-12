# Hearts Engine – Master Todo List

This is a living document. Each item is self-contained: it describes what to do, where to do it, why it matters, and how to verify it is done. Work through items in phase order. Check off items as they are completed.

---

## Phase 1 — Critical Correctness

These are bugs or design flaws that could cause incorrect behavior or future regressions.

---

### [x] 1.1 Fix duplicate validation between `Game` and `Trick`

**What:** Both `Game.playCard(_:by:)` and `Trick.play(_:by:from:)` validate (a) card-in-hand and (b) must-follow-suit. They use different error types for the same violations: `GameError.cardNotInHand` vs `TrickError.cardNotInHand`, and `GameError` has no follow-suit case while `Trick` has `TrickError.mustFollowSuit`.

**Where:** `Sources/Hearts/Game.swift` (the `playCard` method) and `Sources/Hearts/Trick.swift` (the `play` method).

**Why it matters:** Two sources of truth for the same rules drift independently. A rule change in one place is silently missed in the other.

**How to fix:** Remove the card-in-hand and follow-suit checks from `Trick.play`. Keep `Trick` as a dumb recorder that only enforces trick-structural rules (trick already complete, player already played). Let `Game.playCard` be the sole authority for game-rule validation. This means `Game.playCard` must run all rule checks before calling `currentTrick.play(card, by: player, from: hand)`.

**Verification:** All existing tests in `GameplayTests.swift` and `TrickTests.swift` must still pass. Add a test in `TrickTests` that directly calling `trick.play` with an out-of-suit card on a hand that has the lead suit does NOT throw (because Trick no longer enforces this — Game does). Confirm `GameplayTests.test_playCard_throws_when_not_following_suit` (or equivalent) still passes.

---

### [x] 1.2 Fix `CardExchangeStrategy.pickCards()` side-effect mutation

**What:** The default implementation of `pickCards()` in `CardExchangeStrategy` (file: `Sources/Hearts/CardExchangeStrategy.swift`) removes the first 3 cards from `self.hand` as a side effect, before the exchange has occurred. This means the player's hand is modified at selection time, not at exchange time, which is incorrect.

**Where:** `Sources/Hearts/CardExchangeStrategy.swift` (default `pickCards()` implementation) and `Sources/Hearts/Game.swift` (`performExchange` method).

**How to fix:**
1. Rename the protocol method to `selectCardsToPass() -> PassedCards` (pure — returns cards without mutating).
2. Remove the hand mutation from the default implementation.
3. In `Game.performExchange`, after collecting all players' selected cards, apply the hand mutation explicitly: remove the 3 passed cards from the sender's hand as part of the exchange logic.
4. Update all call sites and protocol conformers (`Player`, and any AI strategy that conforms).

**Verification:** After calling `selectCardsToPass()`, the player's hand count must still be 13. The hand shrinks to 10 only after `performExchange` runs the removal step. Add a test asserting this.

---

### [x] 1.3 Fix `gameWinner` tie case

**What:** `Game.gameWinner` (computed property in `Sources/Hearts/Game.swift`) returns the first player in the array with the minimum `totalScore` when `isGameOver == true`. If two players are tied at the minimum score, it silently returns the first one found rather than signaling a tie. In standard Hearts, play continues when scores are tied at the end of a hand.

**Where:** `Sources/Hearts/Game.swift` — `gameWinner` computed property and `isGameOver` computed property.

**How to fix:**
1. Add a computed property `isGameTied: Bool` that returns `true` when `isGameOver` is true AND two or more players share the minimum score.
2. Update `gameWinner` to return `nil` when `isGameTied` is true.
3. The game loop (callers of `isGameOver`) should check `isGameTied` and continue play if true.

**Verification:** Write a test where two players both end a hand at 100 total score with the same minimum — assert `gameWinner == nil` and `isGameTied == true`. Write a separate test where one player has a unique minimum and assert `gameWinner` returns the correct player.

---

### [x] 1.4 Add regression test: Q♠ does not break hearts

**What:** The code correctly does not set `heartsBroken = true` when Q♠ is played. However, there is no test asserting this. A future refactor (e.g., changing the `heartsBroken` update logic) could silently break this without any test failing.

**Where:** Add to `Tests/HeartsTests/GameplayTests.swift`.

**How to fix:** Add a test that:
1. Sets up a game where hearts have NOT been broken.
2. Plays a trick where Q♠ is legally played (e.g., someone is void in the lead suit and plays Q♠).
3. Asserts `game.heartsBroken == false` after the Q♠ is played.

The existing `makeHumanBotGame()` or `makeTestGame()` helpers may be usable, or a new targeted setup may be needed.

**Verification:** Test passes and `game.heartsBroken` is confirmed `false` after Q♠ play.

---

### [x] 1.5 Fix and test bidirectional exchange correctness

**What:** `GameTests.test_exchange_cards` verifies that one player received the correct cards, but does not verify that ALL 4 players received the correct cards from the correct senders. For a pass-left exchange, player 0's passed cards must appear in player 1's hand, player 1's in player 2's, player 2's in player 3's, and player 3's in player 0's.

**Where:** `Tests/HeartsTests/GameTests.swift` — strengthen the existing exchange test.

**How to fix:** In the exchange test, before calling `performExchange`, record what each player passes (call `selectCardsToPass` or control the human cards). After exchange, for each of the 4 players, assert that the 3 cards they passed are now in the next player's hand (according to the exchange direction), and that their own hand no longer contains those cards.

**Verification:** All 4 exchange mappings are verified (sender → correct recipient).

---

## Phase 2 — Completeness

Features that are missing or incomplete per the Hearts rules or the project's stated design goals.

---

### [x] 2.1 Pass `CardExchangeDirection` to `AIStrategy.selectCardsToPass`

**What:** `AIStrategy.selectCardsToPass(from hand: Hand)` receives only the hand. The direction of the pass (who receives the cards) is not provided. A strategic AI should consider who it is passing to — e.g., avoid giving Q♠ to a known aggressive player on the right, or try to void a suit when passing across.

**Where:**
- `Sources/Hearts/AIStrategy.swift` — `AIStrategy` protocol and all conformers (`RandomAIStrategy`, `BasicAIStrategy`, `AdvancedAIStrategy`)
- `Sources/Hearts/Game.swift` — `selectCardsForBotExchange(player:)` method

**How to fix:**
1. Update the `AIStrategy` protocol: `func selectCardsToPass(from hand: Hand, direction: CardExchangeDirection) -> PassedCards`
2. Update all three conformers to accept the new parameter (they may choose to ignore it initially).
3. Update `Game.selectCardsForBotExchange(player:)` to pass `self.exchangeDirection` as the direction argument.

**Verification:** All existing tests compile and pass. The signature change is backward-compatible in behavior; strategies can ignore the direction for now. Add a test asserting the direction is passed correctly.

---

### [x] 2.2 Add `completedTricks` to `TrickContext`

**What:** `TrickContext` (in `Sources/Hearts/AIStrategy.swift`) is the snapshot given to AI when asking it to play a card. It currently contains: `hand`, `currentTrick`, `heartsBroken`, `isFirstTrick`. It does NOT include the history of completed tricks, so the AI cannot know which cards have already been played.

**Where:** `Sources/Hearts/AIStrategy.swift` — `TrickContext` struct and `Game.selectCardForBotPlay(player:)`.

**How to fix:**
1. Add `completedTricks: [Trick]` to `TrickContext`.
2. Update `Game.selectCardForBotPlay(player:)` to populate `completedTricks: game.completedTricks` when constructing the context.
3. `TrickContext` can expose a helper: `var playedCards: [Card]` that flattens all cards from `completedTricks`.

**Verification:** Existing AI strategy tests still pass (they don't use `completedTricks` yet but must still compile). Add a test that constructs a `TrickContext` with completed tricks and verifies `playedCards` returns the correct flat list.

---

### [x] 2.3 Implement card counting in `AdvancedAIStrategy`

**Prerequisite:** Item 2.2 must be complete.

**What:** `AdvancedAIStrategy.selectCardToPlay(context:)` currently ignores `completedTricks`. A hard-difficulty AI should use knowledge of played cards to make better decisions: e.g., if all spades above Q♠ have been played, holding Q♠ is less dangerous; if a player has voided a suit, leading that suit is risky.

**Where:** `Sources/Hearts/AIStrategy.swift` — `AdvancedAIStrategy.selectCardToPlay(context:)`

**How to fix:** Use `context.playedCards` (from item 2.2) to:
1. Detect when it is safe to lead Q♠ (all A♠ and K♠ have been played by others).
2. Detect when leading hearts is risky (opponent has played many hearts already — they may be trying to shoot).
3. Avoid leading suits that opponents have voided (infer from when they played off-suit).

These are heuristics, not perfect inferences. Start with (1) as it has the clearest implementation path.

**Verification:** Add a test where all spades above Q♠ are in `completedTricks` and verify `AdvancedAI` is willing to lead Q♠ in a situation where `BasicAI` would avoid it.

---

### [x] 2.4 Implement moon-shooting pursuit in `AdvancedAIStrategy`

**What:** No AI strategy currently attempts to shoot the moon. All three strategies play defensively (avoid collecting points). A hard AI should detect early in the hand when it has a dominant heart holding + Q♠ and switch to a "capture everything" strategy.

**Where:** `Sources/Hearts/AIStrategy.swift` — `AdvancedAIStrategy`

**How to fix:**
1. Define a `shouldAttemptMoonShot(context: TrickContext) -> Bool` helper. Return true when: the player holds 7+ hearts AND Q♠ AND (hearts-in-hand + hearts-already-captured) ≥ 10. Tune threshold through testing.
2. If moon-shot mode is active: when leading, lead the highest heart or Q♠ to force captures. When following, play high to win the trick and capture points.
3. Moon-shot mode should abort if the player realizes they cannot capture all remaining hearts (e.g., another player captures a heart trick).

**Verification:** Add a test where the player holds A♥, K♥, Q♥, J♥, 10♥, 9♥, 8♥, 7♥, 6♥, 5♥, 4♥, 3♥, Q♠ (all hearts + Q♠) and assert the AI leads hearts aggressively rather than avoiding them.

---

### [x] 2.5 Add "subtract 26 from shooter" moon-shot variant

**What:** Many Hearts rule sets allow the moon shooter to choose: either add 26 to all opponents OR subtract 26 from their own score. Currently only the add-26-to-others variant is implemented.

**Where:**
- `Sources/Hearts/GameConfiguration.swift` — add variant option
- `Sources/Hearts/Game.swift` — `endHand()` / moon-shot scoring logic

**How to fix:**
1. Add `enum MoonShotVariant { case addToOthers, subtractFromSelf }` (or `addToOthers` / `chooseBest` where the engine picks whichever is better for the shooter).
2. Add `moonShotVariant: MoonShotVariant = .addToOthers` to `GameConfiguration`.
3. In `Game.endHand()`, when a moon shot is detected, branch on the variant: if `.subtractFromSelf`, subtract 26 from the shooter's total score (allowing negative totals); if `.addToOthers`, existing behavior.
4. Add a static factory `GameConfiguration.withSubtractMoonShot` for convenience.

**Verification:** Add tests mirroring the existing moon-shot tests but with the new variant. Assert shooter's score decreases by 26 and opponents' scores are unchanged.

---

### [x] 2.6 Add AI strategy determinism tests

**What:** `BasicAIStrategy` and `AdvancedAIStrategy` should be deterministic: the same hand + context should always produce the same card selection. If randomness is accidentally introduced (e.g., using `.shuffled()` instead of `.sorted()`), tests would become flaky without any signal.

**Where:** `Tests/HeartsTests/AIStrategyTests.swift`

**How to fix:** For both `BasicAIStrategy` and `AdvancedAIStrategy`:
1. Construct a fixed hand and a fixed `TrickContext`.
2. Call `selectCardToPlay(context:)` twice.
3. Assert the two results are identical.
4. Do the same for `selectCardsToPass(from:direction:)` (after item 2.1 is done).

**Verification:** Tests pass deterministically on repeated runs.

---

### [x] 2.7 Add test: `exchangeDirection` full 4-round wraparound

**What:** The exchange direction cycles via `roundNumber % 4`. The existing test verifies rounds 0–3 but does not verify round 4 returns to `.left`. This is a modular arithmetic assumption that could break if the formula changes.

**Where:** `Tests/HeartsTests/GameTests.swift`

**How to fix:** After verifying rounds 0–3, set `game.roundNumber = 4` and assert `game.exchangeDirection == .left`.

**Verification:** Test passes.

---

### [x] 2.8 Add test: `playBotTurnsUntilHumanTurn` after hand complete

**What:** The behavior of `playBotTurnsUntilHumanTurn()` when `isHandComplete == true` is undefined and untested. It should be a no-op (no crash, no state mutation).

**Where:** `Tests/HeartsTests/HumanPlayerTests.swift`

**How to fix:**
1. Using `makeMinimalBotGame()` (all-bot, 13 cards), call `playCompleteHand()` to complete the hand.
2. Call `playBotTurnsUntilHumanTurn()`.
3. Assert no exception is thrown and the game state is unchanged.

**Verification:** Test passes without crash.

---

## Phase 3 — Quality & Refactor

Non-behavioral improvements that reduce technical debt and improve maintainability.

---

### [x] 3.1 Merge `Direction` and `CardExchangeDirection` enums

**What:** Two direction enums exist:
- `Direction` (internal, `Sources/Hearts/Player.swift`): `.left`, `.right`, `.across`
- `CardExchangeDirection` (public, `Sources/Hearts/Game.swift`): `.left`, `.right`, `.across`, `.none`

`Direction` is a strict subset. `getOpponent(_:direction:)` in `Game` takes `Direction` while exchange logic uses `CardExchangeDirection`. This is a leaky abstraction requiring conversion between the two.

**Where:** `Sources/Hearts/Player.swift`, `Sources/Hearts/Game.swift`

**How to fix:**
1. Delete the `Direction` enum from `Player.swift`.
2. Update `Game.getOpponent(_:direction:)` to accept `CardExchangeDirection`. Handle the `.none` case by returning `nil` or the player itself (document the behavior clearly).
3. Update all call sites of `getOpponent`.

**Verification:** Project compiles. All tests pass.

---

### [x] 3.2 Relocate `typealias Hand` to `Card.swift`

**What:** `typealias Hand = [Card]` is defined in `Sources/Hearts/Game.swift` but is used across `CardExchangeStrategy`, `AIStrategy`, `TrickContext`, and `Player`. Its location implies it belongs to `Game`, which is misleading.

**Where:** Move from `Sources/Hearts/Game.swift` to `Sources/Hearts/Card.swift` (or a new `Sources/Hearts/Types.swift` if `Card.swift` becomes too long).

**How to fix:** Cut the line from `Game.swift`, paste it at the top of `Card.swift`. Verify the module still compiles (since both files are in the same module, visibility is unchanged).

**Verification:** Project compiles. All tests pass. No behavior change.

---

### [x] 3.3 Remove stored `deck` property from `Game`

**What:** `Game` stores `var deck: Deck` as a persistent property. After `deal()` runs, the deck is empty and unused until `startNewHand()` re-creates it. The stale empty deck is unneeded state.

**Where:** `Sources/Hearts/Game.swift`

**How to fix:**
1. Remove `var deck: Deck` from `Game`'s stored properties.
2. In the private `deal()` method, instantiate `let deck = Deck()` locally, shuffle it, and deal from it. No stored reference needed.
3. Update `startNewHand()` if it referenced `deck` directly.

**Verification:** Project compiles. All tests pass. No behavior change.

---

### [x] 3.4 Add canonical score and hand accessors on `Game`

**What:** Because `Player` is a struct, any local copy held by a caller becomes stale after `game.playCard` or `game.endHand` mutates the player in the `players` array. This is a known footgun. Callers should use `Game` as the authoritative source for current state.

**Where:** `Sources/Hearts/Game.swift` — add new methods.

**How to fix:** Add the following computed helpers:
```swift
func totalScore(for player: Player) -> Int
func roundScore(for player: Player) -> Int
func hand(for player: Player) -> [Card]
```
Each method looks up the player by `id` in `game.players` and returns the live value. Return 0 / empty array if the player ID is not found (shouldn't happen in normal use, but prevents crashes).

**Verification:** Add tests asserting that `game.hand(for: player)` returns the correct live hand after a card is played (while a local copy of `player` would be stale).

---

### [x] 3.5 Strengthen `acceptExchange` test assertions

**What:** `PlayerTests.test_acceptExchange_with_valid_hand_size` calls `acceptExchange(cards:)` but does not verify that the received cards appear in the player's hand afterward, nor that the total hand count is correct (10 initial + 3 received = 13).

**Where:** `Tests/HeartsTests/PlayerTests.swift`

**How to fix:** After calling `player.acceptExchange(cards: passedCards)`, assert:
1. `player.hand.count == 13` (assuming player had 10 cards before).
2. `player.hand.contains(passedCards.first)` — and for `.second` and `.third`.

**Verification:** Assertions added and passing.

---

### [x] 3.6 Strengthen `test_cards_points` with discrete assertions

**What:** `CardTests.test_cards_points` iterates the deck and checks non-point cards return 0. It does not explicitly assert the special cards' exact values by name.

**Where:** `Tests/HeartsTests/CardTests.swift`

**How to fix:** Add explicit assertions:
```swift
XCTAssertEqual(Card(suit: .spades, rank: .queen).points, 13)
XCTAssertEqual(Card(suit: .hearts, rank: .ace).points, 1)
XCTAssertEqual(Card(suit: .hearts, rank: .two).points, 1)
XCTAssertEqual(Card(suit: .diamonds, rank: .jack).points, 0) // base — Jack bonus handled by Game
XCTAssertEqual(Card(suit: .clubs, rank: .ace).points, 0)
```

**Verification:** Assertions pass.

---

## Phase 4 — Advanced Features / Polish

These items improve the project's depth and portfolio quality but are not required for correctness.

---

### [x] 4.1 Seedable randomness for full deterministic replay

**What:** `Deck.shuffle()` and `RandomAIStrategy` use system randomness (`shuffled()`, `randomElement()`). This makes full game replays non-reproducible, which complicates debugging and integration testing.

**Where:** `Sources/Hearts/Deck.swift`, `Sources/Hearts/AIStrategy.swift`

**How to fix:**
1. Define an internal protocol `RandomSource` (or use Swift's `RandomNumberGenerator`).
2. Give `Deck` an optional `randomSource` parameter in its `shuffle()` method.
3. Give `RandomAIStrategy` an optional `randomSource` property.
4. In tests, inject a seeded `SystemRandomNumberGenerator`-compatible source (e.g., a deterministic LCG) to produce reproducible games.

**Verification:** With the same seed, two `Game` runs produce identical deal orders and `RandomAIStrategy` decisions.

---

### [x] 4.2 `Codable` conformance on all value types

**What:** `Card`, `Player`, `Trick`, `GameConfiguration`, and `GameState` (if added) have no serialization support. Adding `Codable` would allow game state persistence, networked play, and replay storage.

**Where:** `Sources/Hearts/Card.swift`, `Sources/Hearts/Player.swift`, `Sources/Hearts/Trick.swift`, `Sources/Hearts/GameConfiguration.swift`

**How to fix:** Add `: Codable` to each struct/enum. Most will be auto-synthesized since all stored properties are already `Codable`-compatible primitives (Int, String, UUID, Bool, arrays). Verify `UUID` round-trips correctly.

**Note:** `Game` is a class with delegate and strategy references — it should NOT directly conform to `Codable`. Instead, add a `GameSnapshot: Codable` value type that captures serializable state.

**Verification:** All value types encode to JSON and decode back without data loss. Add round-trip tests.

---

### [ ] 4.3 Game state snapshot (undo support)

**What:** The current `Game` class mutates state in place with no history. There is no way to undo a play or replay a game from a checkpoint. This is valuable for a portfolio project demonstrating thoughtful design.

**Where:** `Sources/Hearts/Game.swift` — add snapshot mechanism.

**How to fix:**
1. Define a `GameSnapshot` struct that captures all serializable state: `players`, `completedTricks`, `currentTrick`, `heartsBroken`, `roundNumber`, `currentPlayerIndex`, `hasExchanged`.
2. Add `func snapshot() -> GameSnapshot` to `Game`.
3. Add `func restore(from snapshot: GameSnapshot)` to `Game`.
4. Optionally maintain a `private var history: [GameSnapshot]` and expose `func undo()`.

**Prerequisite:** Item 4.2 (`Codable`) is recommended first so snapshots are serializable.

**Verification:** After taking a snapshot, play several cards, restore the snapshot, and assert game state matches the pre-play state exactly.

---

### [x] 4.4 `AdvancedAIStrategy` opponent modeling

**What:** The current hard AI makes decisions only based on its own hand and the current trick. A truly advanced AI would track what cards opponents have played, infer their holdings, and factor that into passing and play decisions.

**Prerequisite:** Items 2.2 and 2.3 must be complete.

**Where:** `Sources/Hearts/AIStrategy.swift` — `AdvancedAIStrategy`

**How to fix:**
1. From `context.completedTricks`, infer when an opponent has voided a suit (they played off-suit when they could have followed — this requires knowing their original hand, which is not available, but you can infer by observing discards).
2. Track which high cards (A♠, K♠, A♥, K♥, etc.) have been played and adjust aggressiveness accordingly.
3. Avoid leading suits where an opponent is likely void (they will discard Q♠ or high hearts).

**Verification:** Add tests constructing scenarios where opponent suit-voiding is detectable and assert the AI adjusts its lead accordingly.

---

## Phase 5 — Architectural Overhaul

Major structural changes that require broad refactoring across source and tests.

---

### [ ] 5.1 Convert `Player` from struct to class (reference semantics)

**What:** `Player` is currently a value type (`struct`). Every assignment or function argument creates an independent copy. Any mutation through `Game` (e.g. `playCard`, `endHand`) updates the canonical copy in `game.players`, but any local copy held by a caller becomes silently stale. The accessor helpers added in 3.4 mitigate this, but do not eliminate the footgun — callers who reach for `player.hand` directly will still get burned.

**Why it matters:** The fundamental fix is reference semantics: every reference to a `Player` points to the same object, so mutations are immediately visible everywhere. This removes an entire class of subtle bugs.

**Where:** `Sources/Hearts/Player.swift` and every file that touches `Player`.

**How to fix:**
1. Change `struct Player` to `final class Player` and update all mutating methods to regular methods.
2. Remove `public internal(set)` on stored properties where they relied on struct copy semantics for safety — use access control instead.
3. Update `Equatable` / `Hashable` conformance to use identity (`===` / `ObjectIdentifier`) since two `Player` objects with the same `id` are the same player.
4. Audit all call sites: remove defensive `game.players[i]` lookups that were workarounds for stale copies.
5. Remove the accessor helpers added in 3.4 (`hand(for:)`, `totalScore(for:)`, `roundScore(for:)`) if they are no longer needed.
6. Update all tests that assumed copy semantics.

**Note:** This is a broad, high-risk change. Do it on a branch with full test coverage as the safety net. `Codable` conformance (item 4.2) should be re-verified after this change since class-based `Codable` requires explicit `init(from:)`.

**Verification:** All 188+ tests pass. No `game.players[i]` workaround lookups remain in tests.

---

### Analysis: Should we migrate? (Evaluated 2026-04-12)

**Decision: Keep `Player` as a struct. Migration is not worth the cost.**

#### What migration would fix
- **Stale copy footgun** — `game.currentPlayer` returns a struct copy that goes stale after any mutation. With a class, all references point to the same object.
- **Conceptual alignment** — Player already uses ID-based `Equatable`/`Hashable` (`lhs.id == rhs.id`), which is reference-type behavior on a value type.
- **Trick.Play** — would store a live reference instead of a frozen snapshot at play time.

#### What migration would break

**Snapshot/Undo system — CATASTROPHIC (deal-breaker)**

`Game.snapshot()` captures `players: players`. With structs this is a deep copy. With classes it copies references to the same 4 objects:

```swift
// With class: snapshot shares references
history.append(snapshot())    // stores references to same 4 objects
game.playCard(card, by: p)    // mutates player — snapshot is ALSO mutated ✗
// undo() becomes a silent no-op
```

Fix would require a `Player.copy()` method and deep-copy logic in `snapshot()`, `applySnapshot()`, and every `Trick.Play` — essentially reimplementing value semantics by hand.

**Codable round-trips** — decoding creates new Player instances, causing identity mismatches between `snapshot.players` and `snapshot.completedTricks[i].plays[j].player`. Needs custom serialization with identity resolution.

**~30 tests** that depend on value-copy semantics would need updates.

#### Cost-benefit

| Factor | Struct (current) | Class (proposed) |
|--------|-----------------|------------------|
| Stale copies | Managed with `hand(for:)` etc. accessors | Eliminated |
| Snapshot/Undo | Works naturally (value copy) | Requires manual deep-copy everywhere |
| Codable | Auto-synthesized, clean | Needs custom identity resolution |
| Trick.Play | Frozen snapshot at play time | Live reference |
| Test impact | 227 tests pass today | ~20-40 tests need updates |

**Why not worth it:** The 3 accessor methods (`hand(for:)`, `roundScore(for:)`, `totalScore(for:)`) already solve the stale copy problem with 15 lines of code. The migration would unravel the 4.2 (Codable) and 4.3 (Snapshot/Undo) systems just implemented. The player count is fixed at 4, so O(n) accessor lookups are O(4) in practice. Estimated effort: 4-6 hours of high-risk refactoring for marginal ergonomic gain.

**Revisit only if:** The snapshot/undo system is removed or fundamentally redesigned.
