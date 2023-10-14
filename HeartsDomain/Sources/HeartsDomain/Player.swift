//
//  Player.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

struct Player {
    let name: String
}

extension Player {
    static func makeBotPlayers() -> [Player] {
        return [Player(name: "Watson"),
                Player(name: "Beth"),
                Player(name: "Cindy"),
                Player(name: "Max")]
    }
}
