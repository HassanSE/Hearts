//
//  Player.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

struct Player {
    let name: String
    var hand: [Card]
    var opponents: [Opponent]?
    
    init(name: String, hand: [Card] = []) {
        self.name = name
        self.hand = hand
    }
    
    mutating func assign(opponenets: [Opponent]) {
        self.opponents = opponenets
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

extension Player: Equatable { }

enum Opponent {
    case left(Player)
    case right(Player)
    case across(Player)
}

extension Opponent: Equatable {
    static func ==(lhs: Opponent, rhs: Opponent) -> Bool {
        switch (lhs, rhs) {
        case (.left(let player1), .left(let player2)):
            return player1 == player2
        case (.right(let player1), .right(let player2)):
            return player1 == player2
        case (.across(let player1), .across(let player2)):
            return player1 == player2
        default:
            return false
        }
    }
}
