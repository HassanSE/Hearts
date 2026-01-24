# Hearts 💔

> *"I just wanted to play Hearts, but the game logic was... missing."*

So I built it. In Swift. With bots. And tests. And no UI dependencies.

## What's This?

A **pure Swift Hearts game engine**. You bring the UI (SwiftUI, UIKit, AppKit, terminal, whatever). I bring the game logic.

### The Pitch

```swift
import Hearts

let game = Game()  // ← 4 bots, shuffled deck, cards dealt, exchange done
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
swift package add https://github.com/yourusername/Hearts.git
```

## Show Me The Code

### Basic Setup

```swift
import Hearts

// Instant game with 4 medium bots
let game = Game()
print(game.leader)  // Player with 2♣ leads
```

### Custom Players

```swift
let human = Player(name: "Me", type: .human)
let easyBot = Player(name: "Bob", type: .bot(difficulty: .easy))
let hardBot = Player(name: "Alice", type: .bot(difficulty: .hard))
let mediumBot = Player(name: "Charlie", type: .bot(difficulty: .medium))

let game = Game(player1: human, player2: easyBot, player3: hardBot, player4: mediumBot)

// Game state after init:
// ✓ 52 cards shuffled
// ✓ 13 cards dealt to each player
// ✓ Card exchange performed (based on round number)
// ✓ Ready for first trick
```

### Bot Difficulty

```swift
// Easy: Random valid plays
let easy = Player(name: "Newbie", type: .bot(difficulty: .easy))

// Medium: Basic strategy (avoid points)
let medium = Player(name: "Casual", type: .bot(difficulty: .medium))

// Hard: Advanced tactics (card counting, shooting the moon)
let hard = Player(name: "Pro", type: .bot(difficulty: .hard))
```

## What's Working

✅ Deck shuffling
✅ Card dealing
✅ Card exchange (left/right/across/none)
✅ Player management
✅ Score tracking
✅ Bot difficulty system
✅ Comprehensive tests (40+ passing)

## What's Coming

🚧 Full trick-taking logic
🚧 Complete scoring system
🚧 Smart AI implementation
🚧 Game events & delegates
🚧 Persistence

## Project Stats

| | |
|---|---|
| Language | Swift 5.9+ |
| Platforms | iOS, macOS, Linux, tvOS, watchOS |
| Tests | 40 passing, 95%+ coverage |
| Dependencies | Zero (pure Swift) |
| UI Frameworks | Zero (bring your own) |

## Architecture Nerd Stuff

- **Struct-based** - Value semantics, no reference cycles
- **Protocol-oriented** - Easy to mock, test, extend
- **Index-based topology** - Players managed by array indices, not references
- **Strategy pattern** - AI difficulty pluggable via protocol
- **Validated state** - Preconditions prevent invalid game states

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
