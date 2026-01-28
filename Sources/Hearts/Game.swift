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

    // Game configuration
    let configuration: GameConfiguration

    var winningScore: Int {
        configuration.winningScore
    }
    
    convenience init(configuration: GameConfiguration = .standard) {
        let players = Player.makeBotPlayers()
        self.init(player1: players[0], player2: players[1], player3: players[2], player4: players[3], configuration: configuration)
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

    var isGameOver: Bool {
        players.contains(where: { $0.totalScore >= winningScore })
    }

    var gameWinner: Player? {
        guard isGameOver else { return nil }
        return players.min(by: { $0.totalScore < $1.totalScore })
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
         player4: Player,
         configuration: GameConfiguration = .standard) {
        self.configuration = configuration
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

        // Award points to winner based on configuration
        let points = calculateTrickPoints(currentTrick)
        players[winnerIndex].roundScore += points

        // Store completed trick
        completedTricks.append(currentTrick)

        // Start new trick with winner leading
        currentTrick = Trick()
        currentPlayerIndex = winnerIndex
    }

    /// Calculate points for a trick based on game configuration
    /// - Parameter trick: The completed trick
    /// - Returns: Total points (may be negative with Jack of Diamonds bonus)
    private func calculateTrickPoints(_ trick: Trick) -> Int {
        var points = 0

        for (_, card) in trick.plays {
            if card.suit == .hearts {
                points += 1
            } else if card.suit == .spades && card.rank == .queen {
                points += 13
            } else if configuration.jackOfDiamondsBonus && card.suit == .diamonds && card.rank == .jack {
                points -= 10
            }
        }

        return points
    }

    private func advanceTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % 4
    }

    // MARK: - Multi-Round Management

    /// End the current hand and transfer round scores to total scores
    func endHand() {
        // Check for shooting the moon
        if let moonShooter = detectMoonShooter() {
            // Moon shooter gets special score, everyone else gets 26
            for i in 0..<players.count {
                if players[i].id == moonShooter.id {
                    // If Jack of Diamonds bonus is enabled, shooter gets -10
                    // Otherwise, shooter gets 0
                    let moonShooterScore = configuration.jackOfDiamondsBonus ? -10 : 0
                    players[i].totalScore += moonShooterScore
                } else {
                    players[i].totalScore += 26
                }
                players[i].roundScore = 0
            }
        } else {
            // Normal scoring: transfer round scores to total scores
            for i in 0..<players.count {
                players[i].totalScore += players[i].roundScore
                players[i].roundScore = 0
            }
        }

        // Increment round number for next hand
        roundNumber += 1
    }

    /// Detect if any player shot the moon (captured all 13 hearts + Queen of Spades)
    /// - Returns: The player who shot the moon, or nil if no one did
    private func detectMoonShooter() -> Player? {
        for player in players {
            let capturedCards = getCardsCaptured(by: player)

            // Check if player has all 13 hearts
            let hearts = capturedCards.filter { $0.suit == .hearts }
            let hasAllHearts = hearts.count == 13

            // Check if player has Queen of Spades
            let hasQueenOfSpades = capturedCards.contains { $0.suit == .spades && $0.rank == .queen }

            if hasAllHearts && hasQueenOfSpades {
                return player
            }
        }

        return nil
    }

    /// Get all cards captured by a player during the current hand
    /// - Parameter player: The player to check
    /// - Returns: Array of cards the player won in tricks
    private func getCardsCaptured(by player: Player) -> [Card] {
        var capturedCards: [Card] = []

        for trick in completedTricks {
            if let winner = trick.winner, winner.id == player.id {
                capturedCards.append(contentsOf: trick.cards)
            }
        }

        return capturedCards
    }

    /// Start a new hand by dealing cards and performing exchange
    func startNewHand() {
        // Clear all hands first
        for i in 0..<players.count {
            players[i].hand = []
        }

        // Reset deck and deal new cards
        deck = Deck()
        deal()

        // Perform card exchange based on round number
        performExchange()

        // Reset game state
        currentTrick = Trick()
        completedTricks = []
        heartsBroken = false

        // Set current player to whoever has 2 of clubs
        if let leaderIndex = players.firstIndex(where: { $0.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }) }) {
            currentPlayerIndex = leaderIndex
        }
    }
}
