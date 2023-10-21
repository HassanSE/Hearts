//
//  Game.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

typealias Hand = [Card]

class Game {
    var players: [Player]
    var deck: Deck
    
    convenience init() {
        let players = Player.makeBotPlayers()
        self.init(player1: players[0], player2: players[1], player3: players[2], player4: players[3])
    }
    
    init(player1: Player,
         player2: Player,
         player3: Player,
         player4: Player) {
        self.players = [player1, player2, player3, player4]
        deck = Deck()
        deal()
    }
    
    private func deal() {
        let numberOfCardsPerHand = 13
        deck.shuffle()
        for _ in 0..<numberOfCardsPerHand {
            players[0].hand.append(deck.deal()!)
            players[1].hand.append(deck.deal()!)
            players[2].hand.append(deck.deal()!)
            players[3].hand.append(deck.deal()!)
        }
    }
}
