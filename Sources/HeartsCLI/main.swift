import Foundation
import Hearts

setbuf(stdout, nil)

func readLineOrExit() -> String {
    guard let line = readLine() else {
        print("")
        print("Input closed — exiting.")
        exit(0)
    }
    return line.trimmingCharacters(in: .whitespaces)
}

func promptDifficulty() -> BotDifficulty {
    print("Select difficulty:")
    print("  1) Easy")
    print("  2) Medium")
    print("  3) Hard")
    print("> ", terminator: "")

    let input = readLineOrExit()
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
    let input = readLineOrExit().lowercased()
    return input == "y" || input == "yes"
}

func promptMoonShotVariant() -> MoonShotVariant {
    print("Moon shot variant:")
    print("  1) Add 26 to others (default)")
    print("  2) Subtract 26 from shooter")
    print("> ", terminator: "")
    let input = readLineOrExit()
    switch input {
    case "2": return .subtractFromSelf
    default: return .addToOthers
    }
}

func promptWinningScore() -> Int {
    print("Winning score (default 100):")
    print("> ", terminator: "")
    let input = readLineOrExit()
    if input.isEmpty { return 100 }
    if let value = Int(input), value > 0 { return value }
    print("Invalid score — defaulting to 100.")
    return 100
}

func formatCard(_ card: Card) -> String {
    "\(card.rank)\(card.suit)"
}

func printNumberedHand(_ hand: [Card], label: String) {
    print(label)
    let cards = hand.sorted()
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

func runExchangePhase(game: Game, humanSeat: Seat) throws {
    let direction = game.exchangeDirection
    let humanHand = game.hands[humanSeat]

    if direction == .none {
        print("")
        print("No exchange this round.")
        try game.performExchange()
        return
    }

    print("")
    printNumberedHand(humanHand, label: "Your hand:")

    let sortedCards = humanHand.sorted()
    while true {
        print("Select 3 cards to pass \(directionLabel(direction)). Enter card numbers (e.g. 1 5 9):")
        print("> ", terminator: "")
        let input = readLineOrExit()
        let parts = input.split(whereSeparator: { $0 == " " || $0 == "," }).compactMap { Int($0) }

        // Only index parsing lives here; the engine validates the selection itself.
        guard parts.allSatisfy({ $0 >= 1 && $0 <= sortedCards.count }) else {
            print("Numbers must be between 1 and \(sortedCards.count).")
            continue
        }

        let selected = parts.map { sortedCards[$0 - 1] }
        do {
            try game.performExchange(selections: [humanSeat: selected])
        } catch let error as GameError {
            print("Invalid selection: \(formatGameError(error))")
            continue
        }
        printNumberedHand(game.hands[humanSeat], label: "Your hand after exchange:")
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
    case .trickIncomplete: return "The trick isn't finished yet."
    case .trickAlreadyComplete: return "The trick is already complete."
    case .exchangeAlreadyPerformed: return "Cards have already been passed this hand."
    case .exchangeNotAllowedAfterPlay: return "Cards can't be passed once play has started."
    case .missingPassSelection: return "You must choose cards to pass."
    case .wrongPassCount(_, let count): return "Please enter exactly 3 numbers (got \(count))."
    case .duplicatePassCards: return "Cards must be distinct."
    case .passedCardNotInHand(_, let card): return "\(formatCard(card)) isn't in your hand."
    case .invalidDeal: return "The deal must give each seat a hand with no card repeated."
    }
}

func formatSuit(_ suit: Card.Suit) -> String {
    "\(suit)"
}

func printTrickState(_ trick: Trick, game: Game) {
    print("")
    if trick.plays.isEmpty {
        print("Current trick: (you lead)")
    } else {
        let leadSuit = trick.leadSuit.map { " — lead suit: \(formatSuit($0))" } ?? ""
        print("Current trick:\(leadSuit)")
        for play in trick.plays {
            print("  \(game.players[play.seat].name): \(formatCard(play.card))")
        }
    }
}

func promptHumanPlay(game: Game, humanSeat: Seat) throws {
    printTrickState(game.currentTrick, game: game)
    printNumberedHand(game.hands[humanSeat], label: "Your hand:")

    let legal = game.legalMoves(for: humanSeat)
    let sortedCards = legal.sorted()
    printNumberedHand(legal, label: "Legal moves:")

    while true {
        print("Your turn. Select a card to play (1-\(sortedCards.count)):")
        print("> ", terminator: "")
        let input = readLineOrExit()
        guard let n = Int(input), n >= 1, n <= sortedCards.count else {
            print("Please enter a number between 1 and \(sortedCards.count).")
            continue
        }
        let card = sortedCards[n - 1]
        do {
            try game.playCard(card, by: humanSeat)
            return
        } catch let error as GameError {
            // playCard throws only GameError; anything else propagates to the caller.
            print("Invalid play: \(formatGameError(error))")
        }
    }
}

func runOneTrick(game: Game, humanSeat: Seat) throws {
    let preCount = game.completedTricks.count

    try game.playBotTurnsUntilHumanTurn()

    if game.completedTricks.count == preCount && !game.isHandComplete {
        try promptHumanPlay(game: game, humanSeat: humanSeat)
        try game.playBotTurnsUntilHumanTurn()
    }

    if game.completedTricks.count > preCount {
        let trick = game.completedTricks[preCount]
        if let winner = trick.winner {
            print("")
            print("Completed trick \(preCount + 1):")
            for play in trick.plays {
                print("  \(game.players[play.seat].name): \(formatCard(play.card))")
            }
            let pts = game.points(in: trick)
            let suffix = abs(pts) == 1 ? "point" : "points"
            let signed = pts < 0 ? "\(pts)" : "+\(pts)"
            print("→ Won by \(game.players[winner].name) (\(signed) \(suffix))")
        }
    }
}

func padRight(_ s: String, _ width: Int) -> String {
    s.count >= width ? s : s + String(repeating: " ", count: width - s.count)
}

func padLeft(_ s: String, _ width: Int) -> String {
    s.count >= width ? s : String(repeating: " ", count: width - s.count) + s
}

func printScoreboard(game: Game, result: HandResult, handNumber: Int) {
    print("")
    print("Scoreboard after hand \(handNumber):")
    print("  \(padRight("Player", 10)) \(padLeft("Round", 6))  \(padLeft("Total", 6))")
    print("  \(String(repeating: "-", count: 26))")
    for (seat, player) in game.players {
        print("  \(padRight(player.name, 10)) \(padLeft("\(result.roundScores[seat])", 6))  \(padLeft("\(result.totalScores[seat])", 6))")
    }
}

func printGameResult(game: Game) {
    print("")
    print(String(repeating: "=", count: 32))
    print("           GAME OVER")
    print(String(repeating: "=", count: 32))
    let standings = game.totalScores.sorted { $0.value < $1.value }
    print("  Final standings:")
    for (seat, score) in standings {
        print("    \(padRight(game.players[seat].name, 10)) \(padLeft("\(score)", 4))")
    }
    print("")
    if let winner = game.gameWinner {
        let score = game.totalScores[winner]
        let suffix = score == 1 ? "point" : "points"
        print("Winner: \(game.players[winner].name) with \(score) \(suffix)")
    } else if game.isGameTied {
        print("Game tied — should continue, but exiting.")
    }
}

func runHand(game: Game, humanSeat: Seat, handNumber: Int) throws {
    print("")
    print(String(repeating: "=", count: 32))
    print("  Hand \(handNumber) (round \(game.roundNumber))")
    print(String(repeating: "=", count: 32))

    try runExchangePhase(game: game, humanSeat: humanSeat)
    print("")
    print("Leading player: \(game.currentPlayer.name) (holds 2♣)")

    while !game.isHandComplete {
        try runOneTrick(game: game, humanSeat: humanSeat)
    }

    let result = game.endHand()
    printScoreboard(game: game, result: result, handNumber: handNumber)
}

func runGame(game: Game, humanSeat: Seat) throws {
    var handNumber = 1
    while !game.isGameOver || game.isGameTied {
        try runHand(game: game, humanSeat: humanSeat, handNumber: handNumber)
        handNumber += 1
        if !game.isGameOver || game.isGameTied {
            game.startNewHand()
        }
    }
    printGameResult(game: game)
}

func makeGame(difficulty: BotDifficulty, configuration: GameConfiguration) -> Game {
    let human = Player(name: "You", type: .human)
    let bot1 = Player(name: "Watson", type: .bot(difficulty: difficulty))
    let bot2 = Player(name: "Beth", type: .bot(difficulty: difficulty))
    let bot3 = Player(name: "Cindy", type: .bot(difficulty: difficulty))
    return Game(player1: human, player2: bot1, player3: bot2, player4: bot3, configuration: configuration)
}

final class CLIEventLogger: GameEngineDelegate {
    func game(_ game: Game, didBreakHearts card: Card, by seat: Seat) {
        print("")
        print("♥  Hearts have been broken — \(game.players[seat].name) played \(formatCard(card)).")
    }

    func game(_ game: Game, didEndHand result: HandResult) {
        guard let seat = result.moonShooter else { return }
        let shooter = game.players[seat]
        print("")
        print("🌙 \(shooter.name) shot the moon!")
        switch game.configuration.moonShotVariant {
        case .addToOthers:
            print("   Every other player takes 26 points.")
        case .subtractFromSelf:
            print("   \(shooter.name) subtracts 26 from their own score.")
        }
    }
}

print("Welcome to Hearts!")
let difficulty = promptDifficulty()
let configuration = GameConfiguration(
    jackOfDiamondsBonus: promptJackBonus(),
    winningScore: promptWinningScore(),
    moonShotVariant: promptMoonShotVariant()
)
let game = makeGame(difficulty: difficulty, configuration: configuration)
let eventLogger = CLIEventLogger()
game.delegate = eventLogger

print("")
print("Game initialized.")
for (seat, player) in game.players {
    print("  [\(seat.rawValue)] \(player.name) — \(player.type)")
}
print("Difficulty: \(difficulty)")
print("Jack of Diamonds bonus: \(configuration.jackOfDiamondsBonus)")
print("Winning score: \(configuration.winningScore)")
print("Moon shot variant: \(configuration.moonShotVariant)")

// The engine knows which seats are human; this CLI drives exactly one of them.
guard let humanSeat = game.humanSeats.first else {
    print("No human seat in this game — nothing to play.")
    exit(1)
}
try runGame(game: game, humanSeat: humanSeat)
