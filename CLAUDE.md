# Hearts Game Engine

A pure Swift package implementing the complete game logic for Hearts. This package is designed to be UI-agnostic and can be consumed by any Apple platform application (iOS, macOS, tvOS, watchOS) or command-line tools.

## Project Overview

This is a Swift Package Manager (SPM) package that serves as the core engine for a Hearts card game. It contains all game rules, state management, AI logic, and validation—completely independent of any UI framework.

### Design Principles

- **Zero UI Dependencies**: No UIKit, AppKit, SwiftUI, or any presentation framework imports
- **Pure Swift**: Uses only Swift standard library and Foundation where necessary
- **Protocol-Oriented**: Favors protocols and composition over inheritance
- **Testable by Design**: All components are injectable and mockable
- **Platform Agnostic**: Runs on any Apple platform or Linux

### Target Test Coverage: 95%+

Every public API must have comprehensive test coverage. Edge cases, error conditions, and boundary scenarios must be tested.

## Architecture

Three SPM targets: the `Hearts` library (the engine), the `HeartsCLI` executable (a terminal
client that exercises it), and `HeartsTests`. The engine is small enough that its sources sit
flat in one directory, grouped by responsibility rather than by folder:

```
Sources/Hearts/
├── Card.swift, Deck.swift, Seat.swift, Player.swift, PlayerType.swift   # models: Card (+ Rank, Suit), Seat/SeatMap, player profiles
├── Trick.swift, PlayRules.swift, CardExchange.swift                     # rules: trick structure, the single play-validation oracle, passing
├── Game.swift, GamePhase.swift, GameSnapshot.swift, GameConfiguration.swift  # state: the engine, its phase machine, snapshots, rule variants
├── AIStrategy.swift                                                     # AI: AIStrategy, TrickContext, Random/Basic/Advanced strategies, BotDifficulty
├── Scoring.swift                                                        # scoring: Scoring, HandResult
├── GameEngineDelegate.swift                                             # events: delegate protocol with default no-ops
└── SeededRandomNumberGenerator.swift                                    # injectable randomness

Sources/HeartsCLI/main.swift          # terminal client (swift run HeartsCLI)

Tests/HeartsTests/
├── <Source>Tests.swift               # one per source file (CardTests, GameTests, ScoringTests, …)
├── Gameplay/HumanPlayer/Orchestration/History/SeatIdentity/Determinism/Codable/PluggableStrategyTests.swift
│                                     # cross-cutting suites
└── Mocks/                            # fixtures: Cards (Card.aceOfSpades …), Tricks, Games, DelegateSpy, SeatMapLiterals
```

The public surface is intentional: the package is consumed as a library, so types a client needs
(`Game`, `Card`, `Seat`, `GamePhase`, `GameError`, `AIStrategy`, `GameEngineDelegate`, …) are
`public`; helpers stay `internal` and tests use `@testable import` where they need them.

## Code Style Guidelines

### Naming Conventions

- Types: `PascalCase` (e.g., `GamePhase`, `PlayRules`)
- Functions/Methods: `camelCase` (e.g., `playCard()`, `calculateScore()`)
- Constants: `camelCase` (e.g., `maxHandSize`, `pointsToLose`)
- Protocols: Noun or adjective describing capability (e.g., `CardPlayable`, `ScoreCalculating`)

### Swift Conventions

- Use `struct` for value types (Card, Trick, HandResult, GameSnapshot)
- Use `class` only when reference semantics are required (`Game` is the only one)
- Use `enum` for finite sets (Suit, Rank, GamePhase)
- Prefer `let` over `var`
- Use `guard` for early exits
- Avoid force unwrapping (`!`) except in tests with known data

### Documentation

- All public APIs must have documentation comments
- Use `///` for documentation
- Include parameter descriptions and return value explanations
- Add code examples for complex APIs

```swift
/// Plays `card` from `seat`'s hand into the current trick.
/// - Parameters:
///   - card: The card to play
///   - seat: The seat attempting the play
/// - Throws: `GameError.wrongPhase` unless `phase` is `.awaitingPlay(seat)`;
///   `.cardNotInHand`, `.mustFollowSuit`, `.heartsNotBroken`, `.cannotPlayPointsOnFirstTrick`
///   or `.mustLeadWithTwoOfClubs` if the play violates game rules. Nothing changes on error.
public func playCard(_ card: Card, by seat: Seat) throws
```

## Testing Requirements

### Test Structure

- One test file per source file (e.g., `Card.swift` → `CardTests.swift`)
- Use descriptive test names: `test_methodName_condition_expectedResult()`
- Group related tests using `// MARK: -` comments
- Each test should test one behavior

### Test Naming Convention

```swift
func test_playCard_whenPlayerDoesNotHaveSuit_allowsAnyCard() { }
func test_calculateScore_withQueenOfSpades_returns13Points() { }
func test_passingPhase_withThreeCards_transitionsToPlayingPhase() { }
```

### What to Test

- All public methods and properties
- All error conditions and edge cases
- State transitions
- Boundary conditions (empty hands, full tricks, game end)
- AI decision-making logic
- Score calculations including "shooting the moon"

### Test Helpers

Create reusable test fixtures and builders:

```swift
// In Tests/HeartsTests/Mocks/ — all 52 cards exist as Card.<rank>Of<Suit>
extension Card {
    static let aceOfSpades = Card(suit: .spades, rank: .ace)
    static let queenOfSpades = Card(suit: .spades, rank: .queen)
}

// Games.swift: Game.seededBots(seed:), .seededHumanSouth(seed:), .fixedDeal([hands]), game.play([cards])
// Tricks.swift: Trick.mock([cards], leadingFrom: seat)
// DelegateSpy.swift: records every GameEngineDelegate callback in order
```

## Hearts Game Rules Reference

### Basic Rules

- 4 players, each receives 13 cards
- Players pass 3 cards before each hand (left, right, across, no pass—rotating)
- Player with 2 of clubs leads first trick
- Must follow suit if possible
- Hearts cannot be led until "broken" (played on another suit)
- No points on first trick (no hearts or Queen of Spades)

### Scoring

- Each heart: 1 point
- Queen of Spades: 13 points
- Shooting the Moon: Player takes all hearts + Queen of Spades = 0 points, others get 26
- Game ends when a player reaches 100 points (configurable)
- Lowest score wins

### Valid Play Rules

1. Must follow lead suit if able
2. Cannot lead hearts until broken (unless only hearts remain)
3. Cannot play points on first trick (unless no choice)
4. 2 of clubs must lead the first trick of each hand

## Common Tasks

### Adding a New Feature

1. Write failing tests first (TDD approach)
2. Implement the minimal code to pass tests
3. Refactor while keeping tests green
4. Ensure no UI framework imports
5. Update documentation

### Running Tests

```bash
swift test
swift test --enable-code-coverage
```

### Generating Coverage Report

```bash
swift test --enable-code-coverage
xcrun llvm-cov report .build/debug/HeartsPackageTests.xctest/Contents/MacOS/HeartsPackageTests \
  -instr-profile .build/debug/codecov/default.profdata \
  -ignore-filename-regex='Tests|HeartsCLI|\.build'
```

The `-ignore-filename-regex` keeps the report to `Sources/Hearts`; the CLI and the tests
themselves are not counted toward the 95% target.

## Error Handling

Use typed errors for game rule violations. The engine has one error enum, `GameError`
(`Sources/Hearts/Game.swift`); every rule violation, wrong-phase call, bad exchange selection,
bad fixed deal and rejected snapshot is a case of it, and a throwing call leaves the game
unchanged. Never trap: no `fatalError`, `precondition` or force unwrap in `Sources/Hearts`.

```swift
public enum GameError: Error, Equatable {
    case notPlayersTurn, cardNotInHand, mustLeadWithTwoOfClubs
    case mustFollowSuit(required: Card.Suit)
    case cannotPlayPointsOnFirstTrick, heartsNotBroken
    case wrongPhase(GamePhase)            // mutator not admitted by the current phase
    case humanInputRequired(seat: Seat)   // bot-only driver reached a human decision
    // … exchange, deal and snapshot cases
}
```

## State Management

`Game` is the single source of truth. Its state is `public internal(set)`; only its mutators
change it. State changes are:

- Driven by `GamePhase`: `game.phase` says which mutator is accepted next
  (`.awaitingExchange` → `performExchange`, `.awaitingPlay(seat)` → `playCard`,
  `.awaitingSettlement` → `endHand`, `.handComplete` → `startNewHand`, `.gameOver` terminal).
  Anything else throws `GameError.wrongPhase`. `advance()` runs every bot-only step and stops
  where a human must act.
- Validated before applying: a throwing call changes nothing.
- Keyed by `Seat`, never by `Player`: `Player` is an immutable profile; hands and scores are
  `SeatMap`s on `Game`.
- Observable via delegate/callback pattern (no Combine or other reactive frameworks). Every
  method has a default no-op:

```swift
public protocol GameEngineDelegate: AnyObject {
    func game(_ game: Game, didTransitionTo phase: GamePhase)
    func game(_ game: Game, didPlayCard card: Card, by seat: Seat)
    func game(_ game: Game, didCompleteTrick trick: Trick, winner: Seat, points: Int)
    func game(_ game: Game, didBreakHearts card: Card, by seat: Seat)
    func game(_ game: Game, didEndHand result: HandResult)
    func game(_ game: Game, didEndGame winner: Seat)
    func game(_ game: Game, didRestoreTo phase: GamePhase)
}
```

## AI Implementation

AI players should conform to a strategy protocol:

```swift
public protocol AIStrategy {
    func selectCardsToPass(from hand: [Card], direction: CardExchangeDirection) -> PassedCards
    func selectCardToPlay(context: TrickContext) -> Card
}
```

`TrickContext` carries the seat, hand, current and completed tricks, scores and a
`legalMoves` list computed by `PlayRules`; a strategy must return one of those. `Game` holds one
strategy instance per bot seat for the life of the game (pass overrides via `strategies:` in
any `Game` init), so a class conformer can remember what it has seen.

Difficulty levels (`BotDifficulty.makeStrategy`):

- `RandomAIStrategy` (`.easy`): Random legal plays, drawn from the game's random source
- `BasicAIStrategy` (`.medium`): Simple heuristics (avoid points)
- `AdvancedAIStrategy` (`.hard`): Card counting, void inference, moon pursuit

## Dependencies

**Allowed:**
- Swift Standard Library
- Foundation (minimal use—avoid platform-specific APIs)

**Not Allowed:**
- UIKit, AppKit, SwiftUI, WatchKit
- Combine, RxSwift, or reactive frameworks
- CoreGraphics, CoreAnimation, or graphics frameworks
- Any third-party packages (keep it dependency-free)

## Checklist Before Committing

- [ ] All tests pass (`swift test`)
- [ ] No UI framework imports
- [ ] Public APIs are documented
- [ ] Test coverage ≥ 95%
- [ ] No force unwraps in production code
- [ ] Error cases are handled with typed errors
- [ ] Code follows naming conventions
