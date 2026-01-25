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

enum GameError: Error, Equatable {
    case notPlayersTurn
    case cardNotInHand
    case mustLeadWithTwoOfClubs
    case cannotPlayPointsOnFirstTrick
    case heartsNotBroken
    case handComplete
}

class Game {
    var players: [Player]
    var deck: Deck
    var roundNumber = 0

    // Trick-taking state
    var currentTrick: Trick = Trick()
    var completedTricks: [Trick] = []
    var heartsBroken: Bool = false
    var currentPlayerIndex: Int = 0
    
    convenience init() {
        let players = Player.makeBotPlayers()
        self.init(player1: players[0], player2: players[1], player3: players[2], player4: players[3])
    }
    
    var leader: Player? {
        players.filter{ $0.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }) }.first
    }

    var currentPlayer: Player {
        players[currentPlayerIndex]
    }

    var isHandComplete: Bool {
        completedTricks.count == 13
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

        // Set current player to whoever has 2 of clubs
        if let leaderIndex = players.firstIndex(where: { $0.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }) }) {
            currentPlayerIndex = leaderIndex
        }
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

    // MARK: - Trick-Taking Gameplay

    /// Play a card from a player's hand
    /// - Parameters:
    ///   - card: The card to play
    ///   - player: The player playing the card
    /// - Throws: GameError or TrickError if the play is invalid
    func playCard(_ card: Card, by player: Player) throws {
        // 1. Validate it's this player's turn
        guard player == currentPlayer else {
            throw GameError.notPlayersTurn
        }

        // 2. Validate hand is not complete
        guard !isHandComplete else {
            throw GameError.handComplete
        }

        // 3. Get player index and validate card is in hand
        guard let playerIndex = players.firstIndex(of: player) else {
            throw GameError.cardNotInHand
        }

        guard players[playerIndex].hand.contains(card) else {
            throw GameError.cardNotInHand
        }

        // 4. Validate first trick rules (must lead with 2♣, no points)
        if completedTricks.isEmpty && currentTrick.plays.isEmpty {
            // First card of first trick must be 2♣
            guard card.suit == .clubs && card.rank == .two else {
                throw GameError.mustLeadWithTwoOfClubs
            }
        }

        if completedTricks.isEmpty {
            // No points on first trick (unless no choice)
            if card.points > 0 {
                let hasNonPointCard = players[playerIndex].hand.contains(where: { $0.points == 0 })
                guard !hasNonPointCard else {
                    throw GameError.cannotPlayPointsOnFirstTrick
                }
            }
        }

        // 5. Validate hearts broken rule (only when leading)
        if currentTrick.plays.isEmpty && card.suit == .hearts {
            // Can't lead hearts until broken, unless only hearts in hand
            if !heartsBroken {
                let hasOnlyHearts = players[playerIndex].hand.allSatisfy { $0.suit == .hearts }
                guard hasOnlyHearts else {
                    throw GameError.heartsNotBroken
                }
            }
        }

        // 6. Play the card (Trick will validate follow-suit rules)
        try currentTrick.play(card, by: player, from: players[playerIndex].hand)

        // 7. Remove card from player's hand
        players[playerIndex].hand.removeAll { $0 == card }

        // 8. Update hearts broken state
        if card.suit == .hearts {
            heartsBroken = true
        }

        // 9. Check if trick is complete
        if currentTrick.isComplete {
            completeTrick()
        } else {
            // Advance to next player
            advanceTurn()
        }
    }

    private func completeTrick() {
        guard let winner = currentTrick.winner,
              let winnerIndex = players.firstIndex(of: winner) else {
            return
        }

        // Award points to winner
        players[winnerIndex].roundScore += currentTrick.points

        // Store completed trick
        completedTricks.append(currentTrick)

        // Start new trick with winner leading
        currentTrick = Trick()
        currentPlayerIndex = winnerIndex
    }

    private func advanceTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % 4
    }
}
