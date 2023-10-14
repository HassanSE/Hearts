//
//  Game.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

class Game {
    var players: [Player]

    init() {
        players = Player.makeBotPlayers()
    }
}
