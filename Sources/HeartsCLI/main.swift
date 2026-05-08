import Foundation
import Hearts

func promptDifficulty() -> BotDifficulty {
    print("Select difficulty:")
    print("  1) Easy")
    print("  2) Medium")
    print("  3) Hard")
    print("> ", terminator: "")

    let input = readLine()?.trimmingCharacters(in: .whitespaces) ?? ""
    switch input {
    case "1": return .easy
    case "2": return .medium
    case "3": return .hard
    default:
        print("Invalid selection — defaulting to Medium.")
        return .medium
    }
}

func promptJackBonus() -> Bool {
    print("Enable Jack of Diamonds bonus? (y/N)")
    print("> ", terminator: "")
    let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
    return input == "y" || input == "yes"
}

func promptMoonShotVariant() -> MoonShotVariant {
    print("Moon shot variant:")
    print("  1) Add 26 to others (default)")
    print("  2) Subtract 26 from shooter")
    print("> ", terminator: "")
    let input = readLine()?.trimmingCharacters(in: .whitespaces) ?? ""
    switch input {
    case "2": return .subtractFromSelf
    default: return .addToOthers
    }
}

func promptWinningScore() -> Int {
    print("Winning score (default 100):")
    print("> ", terminator: "")
    let input = readLine()?.trimmingCharacters(in: .whitespaces) ?? ""
    if input.isEmpty { return 100 }
    if let value = Int(input), value > 0 { return value }
    print("Invalid score — defaulting to 100.")
    return 100
}

let suitOrder: [Card.Suit] = [.clubs, .diamonds, .spades, .hearts]

func sortedHand(_ hand: [Card]) -> [Card] {
    hand.sorted { lhs, rhs in
        if lhs.suit != rhs.suit {
            return suitOrder.firstIndex(of: lhs.suit)! < suitOrder.firstIndex(of: rhs.suit)!
        }
        return lhs.rank < rhs.rank
    }
}

func formatCard(_ card: Card) -> String {
    "\(card.rank)\(card.suit)"
}

func printNumberedHand(_ hand: [Card], label: String) {
    print(label)
    let cards = sortedHand(hand)
    let line = cards.enumerated()
        .map { "[\($0.offset + 1)] \(formatCard($0.element))" }
        .joined(separator: "  ")
    print("  \(line)")
}

func directionLabel(_ direction: CardExchangeDirection) -> String {
    switch direction {
    case .left: return "left"
    case .right: return "right"
    case .across: return "across"
    case .none: return "none"
    }
}

func runExchangePhase(game: Game) {
    let direction = game.exchangeDirection
    let humanHand = game.hand(for: game.players[0])

    if direction == .none {
        print("")
        print("No exchange this round.")
        game.performExchange()
        return
    }

    print("")
    printNumberedHand(humanHand, label: "Your hand:")

    let sortedCards = sortedHand(humanHand)
    while true {
        print("Select 3 cards to pass \(directionLabel(direction)). Enter card numbers (e.g. 1 5 9):")
        print("> ", terminator: "")
        let input = readLine()?.trimmingCharacters(in: .whitespaces) ?? ""
        let parts = input.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Int($0) }

        guard parts.count == 3 else {
            print("Please enter exactly 3 numbers.")
            continue
        }
        guard Set(parts).count == 3 else {
            print("Cards must be distinct.")
            continue
        }
        guard parts.allSatisfy({ $0 >= 1 && $0 <= sortedCards.count }) else {
            print("Numbers must be between 1 and \(sortedCards.count).")
            continue
        }

        let selected = parts.map { sortedCards[$0 - 1] }
        let passed: PassedCards = (selected[0], selected[1], selected[2])
        game.performExchange(humanCards: passed)
        printNumberedHand(game.hand(for: game.players[0]), label: "Your hand after exchange:")
        return
    }
}

func formatGameError(_ error: GameError) -> String {
    switch error {
    case .notPlayersTurn: return "It's not your turn."
    case .cardNotInHand: return "That card isn't in your hand."
    case .mustLeadWithTwoOfClubs: return "You must lead with the 2 of clubs."
    case .mustFollowSuit(let suit): return "You must follow suit (\(suit))."
    case .cannotPlayPointsOnFirstTrick: return "No points may be played on the first trick."
    case .heartsNotBroken: return "Hearts haven't been broken yet."
    case .handComplete: return "The hand is already complete."
    }
}

func printTrickState(_ trick: Trick) {
    print("")
    if trick.plays.isEmpty {
        print("Current trick: (you lead)")
    } else {
        print("Current trick:")
        for play in trick.plays {
            print("  \(play.player.name): \(formatCard(play.card))")
        }
    }
}

func promptHumanPlay(game: Game) {
    printTrickState(game.currentTrick)
    let humanHand = game.hand(for: game.players[0])
    printNumberedHand(humanHand, label: "Your hand:")
    let sortedCards = sortedHand(humanHand)

    while true {
        print("Your turn. Select a card to play (1-\(sortedCards.count)):")
        print("> ", terminator: "")
        let input = readLine()?.trimmingCharacters(in: .whitespaces) ?? ""
        guard let n = Int(input), n >= 1, n <= sortedCards.count else {
            print("Please enter a number between 1 and \(sortedCards.count).")
            continue
        }
        let card = sortedCards[n - 1]
        do {
            try game.playCard(card, by: game.players[0])
            return
        } catch let error as GameError {
            print("Invalid play: \(formatGameError(error))")
        } catch {
            print("Unexpected error: \(error)")
        }
    }
}

func runOneTrick(game: Game) throws {
    let preCount = game.completedTricks.count

    try game.playBotTurnsUntilHumanTurn()

    if game.completedTricks.count == preCount && !game.isHandComplete {
        promptHumanPlay(game: game)
        try game.playBotTurnsUntilHumanTurn()
    }

    if game.completedTricks.count > preCount {
        let trick = game.completedTricks[preCount]
        if let winner = trick.winner {
            print("")
            print("Completed trick \(preCount + 1):")
            for play in trick.plays {
                print("  \(play.player.name): \(formatCard(play.card))")
            }
            let pts = trick.points
            let suffix = pts == 1 ? "point" : "points"
            print("→ Won by \(winner.name) (+\(pts) \(suffix))")
        }
    }
}

func makeGame(difficulty: BotDifficulty, configuration: GameConfiguration) -> Game {
    let human = Player(name: "You", type: .human)
    let bot1 = Player(name: "Watson", type: .bot(difficulty: difficulty))
    let bot2 = Player(name: "Beth", type: .bot(difficulty: difficulty))
    let bot3 = Player(name: "Cindy", type: .bot(difficulty: difficulty))
    return Game(player1: human, player2: bot1, player3: bot2, player4: bot3, configuration: configuration)
}

print("Welcome to Hearts!")
let difficulty = promptDifficulty()
let configuration = GameConfiguration(
    jackOfDiamondsBonus: promptJackBonus(),
    winningScore: promptWinningScore(),
    moonShotVariant: promptMoonShotVariant()
)
let game = makeGame(difficulty: difficulty, configuration: configuration)

print("")
print("Game initialized.")
for (index, player) in game.players.enumerated() {
    print("  [\(index)] \(player.name) — \(player.type)")
}
print("Difficulty: \(difficulty)")
print("Jack of Diamonds bonus: \(configuration.jackOfDiamondsBonus)")
print("Winning score: \(configuration.winningScore)")
print("Moon shot variant: \(configuration.moonShotVariant)")

runExchangePhase(game: game)
print("")
print("Leading player: \(game.currentPlayer.name) (holds 2♣)")

try runOneTrick(game: game)
