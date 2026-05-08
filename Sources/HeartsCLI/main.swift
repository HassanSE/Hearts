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

print("Welcome to Hearts!")
let difficulty = promptDifficulty()
print("Difficulty: \(difficulty)")
