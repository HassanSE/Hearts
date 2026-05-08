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
print("Leading player: \(game.currentPlayer.name) (holds 2♣)")
print("Difficulty: \(difficulty)")
print("Jack of Diamonds bonus: \(configuration.jackOfDiamondsBonus)")
print("Winning score: \(configuration.winningScore)")
print("Moon shot variant: \(configuration.moonShotVariant)")
