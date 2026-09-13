# Hearts Codebase Analysis & Refresher

> **Historical — do not use as a description of the current code.** This snapshot was taken in
> January 2026, before trick-taking, scoring, AI, delegates, phases and snapshots existed. Every
> "❌ Missing" and "🔶 Partial" below has since been implemented, and the line references no
> longer point anywhere meaningful. It is kept only as a record of the starting point. For the
> current architecture read `CLAUDE.md` and `README.md`; for the current API read `Sources/Hearts`.

*Generated: January 2026*

## 1. What's Already Implemented

### Core Game Rules

| Rule | Status | Notes |
|------|--------|-------|
| 52-card deck | ✅ Complete | `Deck.swift:9-17` - Creates all 4 suits × 13 ranks |
| Card point values | ✅ Complete | `Card.swift:82-95` - Hearts=1pt, Q♠=13pt, J♦=-10pt |
| 4 players | ✅ Complete | Game enforces exactly 4 players |
| Deal 13 cards each | ✅ Complete | `Game.swift:48-57` |
| Leader is 2♣ holder | ✅ Complete | `Game.swift:22-24` - Computed property |
| Passing direction | 🔶 Partial | `Direction` enum exists; pass logic empty |
| Card exchange | ❌ Stub | `performExchange()` at `Game.swift:59-61` is empty |
| Following suit | ❌ Missing | No trick validation |
| Hearts breaking | ❌ Missing | No tracking |
| Shoot the moon | ❌ Missing | No detection |
| Trick winner | ❌ Missing | No trick-taking logic |
| Scoring | ❌ Missing | Points defined but not aggregated |

### Game Flow

| Phase | Status |
|-------|--------|
| Initialization | ✅ Works |
| Shuffle & Deal | ✅ Works |
| Position Assignment | ✅ Works (circular seating) |
| Card Passing | ❌ Empty stub |
| Trick Taking | ❌ Not implemented |
| Round Scoring | ❌ Not implemented |
| Game End | ❌ Not implemented |

### Player Logic

- **Human vs AI**: No distinction exists. All players are `Player` structs.
- **CardExchangeStrategy**: Protocol exists with naive default (first 3 cards from hand) - `CardExchangeStrategy.swift:15-18`
- **Bot players**: `Player.makeBotPlayers()` creates 4 named players (Watson, Beth, Cindy, Max) with no intelligence

### UI / Rendering

**None.** This is a pure domain library with no UI code.

### Architecture (High-Level)

```
Sources/Hearts/
├── Card.swift              # Value type: rank + suit + points
├── Deck.swift              # Reference type: 52 cards, shuffle, deal
├── Player.swift            # Value type: id, name, hand, opponents
├── CardExchangeStrategy.swift  # Protocol for passing strategy
└── Game.swift              # Reference type: orchestrates setup
```

**Design approach**: Domain-Driven Design with clean separation. Value types for immutable concepts (Card, Player), reference type for stateful game orchestration.

---

## 2. Current State Assessment

### Is the game playable end-to-end?

**No.** The game cannot be played at all beyond the initial deal.

### Where exactly does it break down?

1. **Game creates → shuffles → deals → calls `performExchange()`** → that's empty
2. No way to play a card
3. No turn management
4. No trick resolution
5. No scoring calculation
6. No game loop

### Known Issues & Technical Debt

| Issue | Location | Severity |
|-------|----------|----------|
| Typo: `opponenets` | `Player.swift:28` | Minor |
| Force unwrap in deal | `Game.swift:52-55` | Medium - will crash on empty deck |
| Player is struct but mutated after creation | `assignPositions()` modifies structs in array | Medium - confusing semantics |
| `hand` property naming collision | `Game.hand` (Int) vs `Player.hand` ([Card]) | Medium - confusing |
| Empty test: `test_exchange_cards` | `GameTests.swift` | Minor |
| No error handling | Throughout | Medium |

---

## 3. MVP Definition

### What an MVP Hearts Game Needs

A playable game where you can complete one full round against 3 bots.

**Minimum Rules:**
- [x] Deal 13 cards to 4 players
- [ ] Pass 3 cards (one direction at a time: left → right → across → hold)
- [ ] 2♣ leads first trick
- [ ] Must follow suit if possible
- [ ] Highest card of led suit wins trick
- [ ] Can't lead hearts until broken
- [ ] Calculate points at end of round
- [ ] Declare winner (lowest score)

**Safely Postponed:**
- Multi-round games (100-point target)
- Shoot the moon
- J♦ bonus variant (you have it, but it's optional)
- Smart AI (random legal play is fine for MVP)
- Network/multiplayer
- Persistent score history
- UI (console output is fine)

**Assumptions:**
- Single-player only
- Local execution
- Console/test-based interaction
- Random AI decisions
- Single round constitutes "complete"

---

## 4. Gap Analysis (MVP Checklist)

| # | Feature | Complexity | Dependencies | Status |
|---|---------|------------|--------------|--------|
| 1 | **Trick struct** | Small | None | ❌ |
| 2 | **Round struct** | Medium | Trick | ❌ |
| 3 | **Card passing logic** | Medium | CardExchangeStrategy | ❌ |
| 4 | **Legal move validation** | Medium | Trick (leading suit) | ❌ |
| 5 | **Trick winner determination** | Small | None | ❌ |
| 6 | **Hearts broken tracking** | Small | Round state | ❌ |
| 7 | **Turn order management** | Medium | Trick winner | ❌ |
| 8 | **Round scoring** | Small | Card.points exists | ❌ |
| 9 | **Basic AI play** | Medium | Legal moves | ❌ |
| 10 | **Game loop** | Medium | All above | ❌ |

### Dependency Graph

```
Card passing (3)
       ↓
Legal move validation (4) ← Trick (1)
       ↓
Trick winner (5) → Turn order (7) → Round (2)
       ↓                              ↓
Hearts broken (6)               Round scoring (8)
       ↓                              ↓
   Basic AI (9) ──────────────→ Game loop (10)
```

---

## 5. Code Quality & Refactor Guidance

### Hard to Reason About

1. **Value type mutation**: `Player` is a struct but `assignPositions()` mutates it after being added to an array. This works because Swift copies, but the semantics are confusing. The `opponents` relationship is set *after* players are in the array.

2. **`hand` naming**: `Game.hand` is an Int (round counter), `Player.hand` is `[Card]`. Rename `Game.hand` → `Game.roundNumber` or `Game.handNumber`.

3. **Circular references in value types**: `Player.opponents` contains `Player` copies, not references. If a player's hand changes, the copies in opponents are stale. This will become problematic during gameplay.

### Suggested Refactors (Pragmatic)

| Refactor | Why | Effort |
|----------|-----|--------|
| Rename `Game.hand` → `Game.roundNumber` | Clarity | 5 min |
| Fix typo `opponenets` → `opponents` | Correctness | 2 min |
| Make `Player` a class OR store player IDs instead of Player copies in opponents | Fix stale data issue | 30 min |
| Replace force unwraps with guard in `deal()` | Safety | 10 min |
| Add `Trick` type | Foundation for gameplay | 20 min |

### Recommendation on Player struct vs class

For a learning project, convert `Player` to a **class**. The current design will cause bugs when:
- Player A passes cards to Player B
- Player A has a stale copy of Player B in `opponents`
- You try to check Player B's hand through A's opponents dict

Alternative: Store only `UUID` in opponents and look up via `Game.players`.

---

## 6. Suggested Next Steps

### Recommended Order of Work

1. **Fix structural issues** (naming, Player reference problem) [Done]
2. **Add Trick type** - foundation for all gameplay [Done]
3. **Implement card passing** - complete the setup phase [Done]
4. **Implement trick-taking** - core gameplay loop [Done]
5. **Add scoring** - complete a round [Done]
6. **Add basic AI** - make it playable
7. **Wire up game loop** - tie it together

### 3-5 Concrete Tasks to Pick Up Immediately

1. **Rename `Game.hand` → `Game.roundNumber`** - [Done]
   - Trivial change, removes confusion immediately
   - Update tests that reference it

2. **Convert `Player` to a class (or use ID-based lookups)**
   - This unblocks future work on passing and trick-taking
   - Update `Equatable` implementation accordingly

3. **Create `Trick` type**
   ```swift
   struct Trick {
       let leadingSuit: Card.Suit
       var plays: [(player: Player, card: Card)]
       func winner() -> Player { ... }
   }
   ```

4. **Implement `performExchange()`**
   - Use `CardExchangeStrategy.pickCards()` (already exists)
   - Transfer cards based on `hand % 4` (left/right/across/hold)
   - This completes the setup phase

5. **Add `playCard(player:card:)` to Game**
   - Validates legal move
   - Adds to current trick
   - Determines if trick is complete
   - This is the heart of the game

---

## Quick Wins (15 min cleanup)

```
[ ] Fix typo: opponenets → opponents in Player.swift:28
[ ] Rename: Game.hand → Game.roundNumber
[ ] Fill in test_exchange_cards or delete it
[ ] Remove force unwraps in deal() with guard
```

---

## File Reference

| File | Lines | Purpose |
|------|-------|---------|
| `Card.swift` | 95 | Card value type with rank, suit, points |
| `Deck.swift` | ~30 | 52-card deck with shuffle/deal |
| `Player.swift` | 59 | Player with hand and opponent tracking |
| `CardExchangeStrategy.swift` | 19 | Protocol for card passing logic |
| `Game.swift` | 62 | Game orchestration (incomplete) |
