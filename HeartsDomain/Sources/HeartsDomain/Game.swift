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
        self.players = Player.makeBotPlayers()
    }
    
    init(player1: Player,
         player2: Player,
         player3: Player,
         player4: Player) {
        self.players = [player1, player2, player3, player4]
    }
}
