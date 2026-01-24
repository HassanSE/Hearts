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

struct Player {
    let id: UUID
    let name: String
    var hand: [Card]
    var roundScore: Int
    var totalScore: Int

    init(name: String, hand: [Card] = [], roundScore: Int = 0, totalScore: Int = 0) {
        self.id = UUID()
        self.name = name
        self.hand = hand
        self.roundScore = roundScore
        self.totalScore = totalScore
    }

    mutating func acceptExchange(cards: PassedCards) {
      hand.append(cards.first)
      hand.append(cards.second)
      hand.append(cards.third)
    }
}

extension Player {
    static func makeBotPlayers() -> [Player] {
        return [Player(name: "Watson"),
                Player(name: "Beth"),
                Player(name: "Cindy"),
                Player(name: "Max")]
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
        "Player(id: \(id), name: \(name), roundScore: \(roundScore), totalScore: \(totalScore))"
    }
}
