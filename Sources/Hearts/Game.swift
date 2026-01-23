//
//  Game.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

typealias Hand = [Card]

enum CardExchangeDirection {
    case left
    case right
    case across
    case none
}

class Game {
    var players: [Player]
    var deck: Deck
    var roundNumber = 0
    
    convenience init() {
        let players = Player.makeBotPlayers()
        self.init(player1: players[0], player2: players[1], player3: players[2], player4: players[3])
    }
    
    var leader: Player? {
        players.filter{ $0.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }) }.first
    }
    
    var exchangeDirection: CardExchangeDirection {
        switch roundNumber % 4 {
        case 0: return .left
        case 1: return .right
        case 2: return .across
        default: return .none
        }
    }
    
    init(player1: Player,
         player2: Player,
         player3: Player,
         player4: Player) {
        self.players = [player1, player2, player3, player4]
        self.deck = Deck()
        deal()
        performExchange()
    }
    
    func getOpponent(_ player: Player, direction: Direction) -> Player? {
        guard let index = players.firstIndex(where: { $0.id == player.id }) else { return nil }
        let offset = direction == .left ? 1 : direction == .right ? 3 : 2
        return players[(index + offset) % 4]
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
    
    func performExchange() {
        guard exchangeDirection != .none else { return }

        let direction: Direction = exchangeDirection == .left ? .left : exchangeDirection == .right ? .right : .across
        let offset = direction == .left ? 1 : direction == .right ? 3 : 2

        // Collect cards from all players first
        var cardsToPass: [(fromIndex: Int, toIndex: Int, cards: PassedCards)] = []
        for i in 0..<players.count {
            let passingCards = players[i].pickCards()
            let toIndex = (i + offset) % 4
            cardsToPass.append((fromIndex: i, toIndex: toIndex, cards: passingCards))
        }

        // Then distribute them
        for exchange in cardsToPass {
            players[exchange.toIndex].acceptExchange(cards: exchange.cards)
        }
    }
}
