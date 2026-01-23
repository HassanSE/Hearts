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
        assignPositions()
        deal()
        performExchange()
    }
    
    func getOpponent(_ player: Player, direction: Direction) -> Player? {
        players.first { $0.id == player.id }?.getOpponent(direction: direction)
    }
    
    private func assignPositions() {
        players[0].assign(opponenets: [.left: players[1], .across: players[2], .right: players[3]])
        players[1].assign(opponenets: [.left: players[2], .across: players[3], .right: players[0]])
        players[2].assign(opponenets: [.left: players[3], .across: players[0], .right: players[1]])
        players[3].assign(opponenets: [.left: players[0], .across: players[1], .right: players[2]])
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
        players.forEach { performExchange(for: $0, exchangeDirection: exchangeDirection) }
    }
    
    private func performExchange(for player: Player, exchangeDirection: CardExchangeDirection) {
        var player = player
        let direction: Direction = exchangeDirection == .left ? .left : exchangeDirection == .right ? .right : .across
        let nextPlayer = getOpponent(player, direction: direction)
        let passingCards = player.pickCards()
        nextPlayer?.acceptExchange(cards: passingCards)
    }
}
