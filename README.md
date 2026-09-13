# Hearts 💔

> *"I just wanted to play Hearts, but the game logic was... missing."*

So I built it. In Swift. With bots. And tests. And no UI dependencies.

## What's This?

A **pure Swift Hearts game engine**. You bring the UI (SwiftUI, UIKit, AppKit, terminal, whatever). I bring the game logic.

### The Pitch

```swift
import Hearts

let game = Game()          // ← 4 bots, shuffled deck, cards dealt
try game.playCompleteGame() // ← exchange, 13 tricks a hand, scoring, until someone hits 100
```

That's it. You've got a working Hearts game. Now make it pretty.

## Why Should I Care?

Because writing card game logic is tedious:

- ❌ Shuffling algorithms
- ❌ Card passing rules (left/right/across/none rotation??)
- ❌ Scoring calculations
- ❌ AI opponent logic
- ❌ Rule validation

**OR** you could:

```bash
swift package add https://github.com/HassanSE/Hearts.git
```

## Show Me The Code

### Basic Setup

```swift
import Hearts

// Instant game with 4 medium bots
let game = Game()
print(game.leader)  // Seat holding 2♣ — leads the first trick
print(game.phase)   // .awaitingExchange
```

### Custom Players

```swift
let human = Player(name: "Me", type: .human)
let easyBot = Player(name: "Bob", type: .bot(difficulty: .easy))
let hardBot = Player(name: "Alice", type: .bot(difficulty: .hard))
let mediumBot = Player(name: "Charlie", type: .bot(difficulty: .medium))

let game = Game(player1: human, player2: easyBot, player3: hardBot, player4: mediumBot)
// player1 sits south, then west, north, east clockwise

// Game state after init:
// ✓ 52 cards shuffled
// ✓ 13 cards dealt to each seat
// ✓ phase == .awaitingExchange — waiting for the human's three cards
```

### Driving a Game With a Human

`Game.phase` says what happens next. `advance()` does everything that needs no
human input (bot exchanges, bot plays, settling hands, dealing the next one) and
stops when a human must act or the game is over:

```swift
let me = game.humanSeats[0]

while true {
    try game.advance()
    switch game.phase {
    case .awaitingExchange:
        try game.performExchange(selections: [me: pickThreeCards(from: game.hands[me])])
    case .awaitingPlay(let seat):
        try game.playCard(pickOne(from: game.legalMoves(for: seat)), by: seat)
    case .gameOver(let winner):
        print("\(game.players[winner].name) wins!")
        return
    default:
        continue
    }
}
```

Illegal plays throw a typed `GameError` (`.mustFollowSuit`, `.heartsNotBroken`,
`.wrongPhase`, …) and leave the game untouched, so a UI can just retry.

### Observing Events

```swift
final class Logger: GameEngineDelegate {
    func game(_ game: Game, didCompleteTrick trick: Trick, winner: Seat, points: Int) {
        print("\(game.players[winner].name) takes the trick for \(points)")
    }
    func game(_ game: Game, didEndHand result: HandResult) {
        if let shooter = result.moonShooter { print("\(game.players[shooter].name) shot the moon!") }
    }
}
game.delegate = logger  // every method has a default no-op; implement what you need
```

### Rule Variants, Determinism, Undo

```swift
let config = GameConfiguration(jackOfDiamondsBonus: true,      // J♦ is −10
                               winningScore: 50,
                               moonShotVariant: .subtractFromSelf)

let game = Game(configuration: config, using: SeededRandomNumberGenerator(seed: 42))
// same seed → same deals and same random-bot decisions, every time

let snapshot = game.snapshot()        // Codable — persist it
try game.playCompleteHand()
try game.restore(from: snapshot)      // validated: a tampered snapshot is rejected
game.undo()                           // or step back one action at a time
```

### Bot Difficulty

```swift
// Easy: Random valid plays
let easy = Player(name: "Newbie", type: .bot(difficulty: .easy))

// Medium: Basic strategy (avoid points)
let medium = Player(name: "Casual", type: .bot(difficulty: .medium))

// Hard: Advanced tactics (card counting, void inference, shooting the moon)
let hard = Player(name: "Pro", type: .bot(difficulty: .hard))

// Or bring your own: anything conforming to AIStrategy, one instance per seat
let game = Game(player1: human, player2: easyBot, player3: hardBot, player4: mediumBot,
                strategies: [.north: MyStrategy()])
```

## What's Working

- ✅ Shuffling and dealing, with injectable randomness for reproducible games
- ✅ Card exchange (left/right/across/none, rotating by hand)
- ✅ Full trick-taking: follow suit, hearts breaking, no points on the first trick, 2♣ leads
- ✅ Scoring: hearts, Q♠, shooting the moon (add-to-others or subtract-from-shooter), optional J♦ bonus, configurable winning score, ties play on
- ✅ Three bot levels plus a public `AIStrategy` protocol for your own
- ✅ Any mix of human and bot seats, driven through a `GamePhase` state machine
- ✅ `GameEngineDelegate` events for every play, trick, hand, phase change and restore
- ✅ `Codable` snapshots, validated restore, and multi-step undo
- ✅ A terminal client (`swift run HeartsCLI`) that plays a full game against the bots
- ✅ Every public declaration documented; every value type `Sendable`, so it builds clean in Swift 6 language mode
- ✅ 380 tests, ~99% line coverage, run on macOS and Linux in CI

## Project Stats

| | |
|---|---|
| Language | Swift 5.7+ (Swift 6 mode clean) |
| Platforms | iOS, macOS, Linux, tvOS, watchOS |
| Tests | 380 passing, ~99% line coverage |
| Dependencies | Zero (pure Swift) |
| UI Frameworks | Zero (bring your own) |

## Architecture Nerd Stuff

- **Struct-based** - `Card`, `Trick`, `Player`, `GameSnapshot` are values; only `Game` is a class
- **Protocol-oriented** - `AIStrategy` and `GameEngineDelegate` are the two seams; easy to mock
- **Seat-based topology** - `Seat` (south/west/north/east) identifies everyone; `SeatMap<T>` holds one value per seat with no optionals
- **Phase state machine** - `GamePhase` is the single source of "what next"; each phase accepts exactly one mutator, everything else throws `GameError.wrongPhase`
- **Typed errors, no traps** - no `fatalError`, `precondition` or force unwrap in the engine; every rule violation is a `GameError` and leaves state untouched
- **Single rules oracle** - `PlayRules` validates plays and lists legal moves for the engine, the bots and the CLI alike

## Can I Help?

YES! This is a side project for learning. All contributions welcome:

- 🐛 Found a bug? Open an issue
- 💡 Have an idea? Start a discussion
- 🔧 Want to contribute? Submit a PR
- 📖 Docs unclear? Tell me where

## License

MIT - Do whatever you want with it.

---

Made with ☕ and Swift
*Because sometimes you just want to play Hearts*
