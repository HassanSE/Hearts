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
    
    init(name: String, hand: [Card] = []) {
        self.name = name
        self.hand = hand
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
