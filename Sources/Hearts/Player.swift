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
    var opponents: [Opponent]?
    
    init(name: String, hand: [Card] = []) {
        self.id = UUID()
        self.name = name
        self.hand = hand
    }
    
    mutating func assign(opponenets: [Opponent]) {
        self.opponents = opponenets
    }
    
    func getOpponent(direction: Direction) -> Player? {
        switch direction {
        case .left:
            if case let .left(player) = opponents?[0] {
                return player
            }
        case .across:
            if case let .across(player) = opponents?[1] {
                return player
            }
        case .right:
            if case let .right(player) = opponents?[2] {
                return player
            }
        }
        return nil
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

extension Player: CardExchangeStrategy { }

extension Player: CustomDebugStringConvertible {
    var debugDescription: String {
        "Player(id: \(id), name: \(name)"
    }
}
