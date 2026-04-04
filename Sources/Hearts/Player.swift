//
//  Player.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

public struct Player {
    public let id: UUID
    public let name: String
    public let type: PlayerType
    public internal(set) var hand: [Card]
    public internal(set) var roundScore: Int
    public internal(set) var totalScore: Int

    public init(name: String, type: PlayerType = .human, hand: [Card] = [], roundScore: Int = 0, totalScore: Int = 0) {
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
    public static func ==(lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
}

extension Player: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Player: CardExchangeStrategy { }

extension Player: CustomDebugStringConvertible {
    public var debugDescription: String {
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
