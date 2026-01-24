//
//  Player.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

enum Direction {
    case left
    case right
    case across
}

// MARK: - Bot AI Strategy

protocol AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards
    func selectCardToPlay(from hand: Hand) -> Card
}

enum BotDifficulty {
    case easy
    case medium
    case hard

    func makeStrategy() -> AIStrategy {
        switch self {
        case .easy:
            return RandomAIStrategy()
        case .medium:
            return BasicAIStrategy()
        case .hard:
            return AdvancedAIStrategy()
        }
    }
}

// MARK: - AI Strategy Implementations

struct RandomAIStrategy: AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards {
        // Random strategy: just pick first 3 cards
        return (hand[0], hand[1], hand[2])
    }

    func selectCardToPlay(from hand: Hand) -> Card {
        // Random strategy: pick first valid card
        return hand[0]
    }
}

struct BasicAIStrategy: AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards {
        // Basic strategy: pass high cards
        // TODO: Implement smarter logic
        return (hand[0], hand[1], hand[2])
    }

    func selectCardToPlay(from hand: Hand) -> Card {
        // Basic strategy: simple heuristics
        // TODO: Implement smarter logic
        return hand[0]
    }
}

struct AdvancedAIStrategy: AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards {
        // Advanced strategy: card counting, shooting the moon detection
        // TODO: Implement advanced logic
        return (hand[0], hand[1], hand[2])
    }

    func selectCardToPlay(from hand: Hand) -> Card {
        // Advanced strategy: strategic play
        // TODO: Implement advanced logic
        return hand[0]
    }
}

// MARK: - Player Type

enum PlayerType: Equatable {
    case human
    case bot(difficulty: BotDifficulty)

    var isBot: Bool {
        if case .bot = self { return true }
        return false
    }

    var isHuman: Bool {
        if case .human = self { return true }
        return false
    }

    var botDifficulty: BotDifficulty? {
        if case .bot(let difficulty) = self { return difficulty }
        return nil
    }
}

struct Player {
    let id: UUID
    let name: String
    let type: PlayerType
    var hand: [Card]
    var roundScore: Int
    var totalScore: Int

    init(name: String, type: PlayerType = .human, hand: [Card] = [], roundScore: Int = 0, totalScore: Int = 0) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.hand = hand
        self.roundScore = roundScore
        self.totalScore = totalScore
    }

    mutating func acceptExchange(cards: PassedCards) {
        precondition(hand.count == 10, "Player must have exactly 10 cards before accepting exchange (13 dealt - 3 passed)")
        hand.append(cards.first)
        hand.append(cards.second)
        hand.append(cards.third)
        assert(hand.count == 13, "Player must have exactly 13 cards after accepting exchange")
    }
}

extension Player {
    static func makeBotPlayers(difficulty: BotDifficulty = .medium) -> [Player] {
        return [Player(name: "Watson", type: .bot(difficulty: difficulty)),
                Player(name: "Beth", type: .bot(difficulty: difficulty)),
                Player(name: "Cindy", type: .bot(difficulty: difficulty)),
                Player(name: "Max", type: .bot(difficulty: difficulty))]
    }
}

extension Player: Equatable {
    static func ==(lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
}

extension Player: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Player: CardExchangeStrategy { }

extension Player: CustomDebugStringConvertible {
    var debugDescription: String {
        let typeDescription: String
        switch type {
        case .human:
            typeDescription = "human"
        case .bot(let difficulty):
            typeDescription = "bot(\(difficulty))"
        }
        return "Player(id: \(id), name: \(name), type: \(typeDescription), roundScore: \(roundScore), totalScore: \(totalScore))"
    }
}
