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
    var opponents: [Direction: Player] = [:]
    
    init(name: String, hand: [Card] = []) {
        self.id = UUID()
        self.name = name
        self.hand = hand
    }
    
    mutating func assign(opponenets: [Direction: Player]) {
        self.opponents = opponenets
    }
    
    func getOpponent(direction: Direction) -> Player? {
        opponents[direction]
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

extension Player: CardExchangeStrategy { }

extension Player: CustomDebugStringConvertible {
    var debugDescription: String {
        "Player(id: \(id), name: \(name)"
    }
}
