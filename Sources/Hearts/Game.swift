//
//  Game.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

public enum CardExchangeDirection {
    case left
    case right
    case across
    case none
}

public enum GameError: Error, Equatable {
    case notPlayersTurn
    case cardNotInHand
    case mustLeadWithTwoOfClubs
    case mustFollowSuit(required: Card.Suit)
    case cannotPlayPointsOnFirstTrick
    case heartsNotBroken
    case handComplete
}

public class Game {
    public internal(set) var players: [Player]
    var deck: Deck
    public internal(set) var roundNumber = 0

    // Trick-taking state
    public internal(set) var currentTrick: Trick = Trick()
    public internal(set) var completedTricks: [Trick] = []
    public internal(set) var heartsBroken: Bool = false
    public internal(set) var currentPlayerIndex: Int = 0

    // Game configuration
    public let configuration: GameConfiguration

    /// Tracks whether the card exchange has been performed for the current hand.
    /// Prevents double-exchange and lets the UI drive timing for human players.
    private var hasExchanged = false

    /// Delegate to receive game event notifications.
    public weak var delegate: GameEngineDelegate?

    public var winningScore: Int {
        configuration.winningScore
    }

    public convenience init(configuration: GameConfiguration = .standard) {
        let players = Player.makeBotPlayers()
        self.init(player1: players[0], player2: players[1], player3: players[2], player4: players[3], configuration: configuration)
    }

    public var leader: Player? {
        players.filter{ $0.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }) }.first
    }

    public var currentPlayer: Player {
        players[currentPlayerIndex]
    }

    public var isHandComplete: Bool {
        completedTricks.count == 13
    }

    public var isGameOver: Bool {
        players.contains(where: { $0.totalScore >= winningScore })
    }

    public var isGameTied: Bool {
        guard isGameOver else { return false }
        let minScore = players.map(\.totalScore).min()!
        return players.filter({ $0.totalScore == minScore }).count > 1
    }

    public var gameWinner: Player? {
        guard isGameOver, !isGameTied else { return nil }
        return players.min(by: { $0.totalScore < $1.totalScore })
    }

    public var exchangeDirection: CardExchangeDirection {
        switch roundNumber % 4 {
        case 0: return .left
        case 1: return .right
        case 2: return .across
        default: return .none
        }
    }

    public init(player1: Player,
         player2: Player,
         player3: Player,
         player4: Player,
         configuration: GameConfiguration = .standard) {
        self.configuration = configuration
        self.players = [player1, player2, player3, player4]
        self.deck = Deck()
        deal()

        // Set current player to whoever has 2 of clubs
        if let leaderIndex = players.firstIndex(where: { $0.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }) }) {
            currentPlayerIndex = leaderIndex
        }
    }

    /// Returns the opponent of `player` in the given direction, or `nil` if direction is `.none`.
    func getOpponent(_ player: Player, direction: CardExchangeDirection) -> Player? {
        guard direction != .none else { return nil }
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

    /// Perform the card exchange for the current round.
    ///
    /// - Parameter humanCards: The 3 cards the human player wants to pass.
    ///   If `nil` and a human player is in the game, their first 3 cards are passed as a fallback.
    ///   Ignored when `exchangeDirection` is `.none`.
    ///
    /// Call this once per hand. Subsequent calls are no-ops until `startNewHand()` resets the state.
    /// For all-bot games this is called automatically by `playCompleteHand()`.
    /// For human games, call it explicitly after showing the human their hand:
    /// ```swift
    /// game.startNewHand()
    /// // show human game.players[humanIndex].hand, get selection…
    /// game.performExchange(humanCards: selected)
    /// ```
    public func performExchange(humanCards: PassedCards? = nil) {
        guard !hasExchanged else { return }
        hasExchanged = true

        guard exchangeDirection != .none else { return }

        let offset: Int
        switch exchangeDirection {
        case .left:   offset = 1
        case .right:  offset = 3
        case .across: offset = 2
        case .none:   return
        }

        // Phase 1: collect each player's 3 cards to pass (and remove them from their hand)
        var cardsToPass: [(toIndex: Int, cards: PassedCards)] = []
        for i in 0..<players.count {
            let toIndex = (i + offset) % 4
            let passingCards: PassedCards

            if players[i].type.isHuman, let selected = humanCards {
                // Human explicitly chose these 3 cards
                players[i].hand.removeAll { $0 == selected.first || $0 == selected.second || $0 == selected.third }
                passingCards = selected
            } else if players[i].type.isBot {
                // Bot uses its AI strategy to select 3 cards
                passingCards = selectCardsForBotExchange(player: players[i])
                players[i].hand.removeAll { $0 == passingCards.first || $0 == passingCards.second || $0 == passingCards.third }
            } else {
                // Human with no selection provided — fall back to first 3 cards (pure selection, no mutation)
                passingCards = players[i].selectCardsToPass()
                players[i].hand.removeAll { $0 == passingCards.first || $0 == passingCards.second || $0 == passingCards.third }
            }

            cardsToPass.append((toIndex: toIndex, cards: passingCards))
        }

        // Phase 2: distribute the collected cards
        for exchange in cardsToPass {
            players[exchange.toIndex].acceptExchange(cards: exchange.cards)
        }

        // Re-identify who holds 2♣ — exchange may have moved it to a different player
        if let leaderIndex = players.firstIndex(where: { $0.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }) }) {
            currentPlayerIndex = leaderIndex
        }
    }

    // MARK: - Trick-Taking Gameplay

    /// Play a card from a player's hand
    /// - Parameters:
    ///   - card: The card to play
    ///   - player: The player playing the card
    /// - Throws: GameError or TrickError if the play is invalid
    public func playCard(_ card: Card, by player: Player) throws {
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

        // 6. Validate follow-suit rule
        if let leadSuit = currentTrick.leadSuit {
            let hasLeadSuit = players[playerIndex].hand.contains(where: { $0.suit == leadSuit })
            if hasLeadSuit && card.suit != leadSuit {
                throw GameError.mustFollowSuit(required: leadSuit)
            }
        }

        // 7. Record the play (Trick enforces only structural rules)
        try currentTrick.play(card, by: player)

        // 8. Remove card from player's hand
        players[playerIndex].hand.removeAll { $0 == card }

        // 9. Update hearts broken state and fire delegate events
        let justBrokeHearts = !heartsBroken && card.suit == .hearts
        if card.suit == .hearts {
            heartsBroken = true
        }

        delegate?.game(self, didPlayCard: card, by: player)
        if justBrokeHearts {
            delegate?.game(self, didBreakHearts: card, by: player)
        }

        // 10. Check if trick is complete
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

        // Capture completed trick before resetting
        let completedTrick = currentTrick

        // Store completed trick
        completedTricks.append(currentTrick)

        // Start new trick with winner leading
        currentTrick = Trick()
        currentPlayerIndex = winnerIndex

        delegate?.game(self, didCompleteTrick: completedTrick, winner: winner, points: points)
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
    public func endHand() {
        // Detect moon shooter before applying scores (uses completedTricks)
        let moonShooter = detectMoonShooter()

        // Check for shooting the moon
        if let moonShooter = moonShooter {
            switch configuration.moonShotVariant {
            case .addToOthers:
                // Shooter gets 0 (or -10 with Jack bonus); all opponents receive 26
                for i in 0..<players.count {
                    if players[i].id == moonShooter.id {
                        let moonShooterScore = configuration.jackOfDiamondsBonus ? -10 : 0
                        players[i].totalScore += moonShooterScore
                    } else {
                        players[i].totalScore += 26
                    }
                    players[i].roundScore = 0
                }
            case .subtractFromSelf:
                // Shooter's score is reduced by 26; opponents are unaffected
                for i in 0..<players.count {
                    if players[i].id == moonShooter.id {
                        players[i].totalScore -= 26
                    } else {
                        players[i].totalScore += players[i].roundScore
                    }
                    players[i].roundScore = 0
                }
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

        // Fire end-of-hand delegate events
        let scores = Dictionary(uniqueKeysWithValues: players.map { ($0, $0.totalScore) })
        delegate?.game(self, didEndHand: scores, moonShooter: moonShooter)
        if isGameOver, let winner = gameWinner {
            delegate?.game(self, didEndGame: winner)
        }
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

    // MARK: - AI Integration

    /// Select cards for a bot player to pass during card exchange
    /// - Parameter player: The bot player
    /// - Returns: Three cards selected by the bot's AI strategy
    /// - Precondition: Player must be a bot
    func selectCardsForBotExchange(player: Player) -> PassedCards {
        precondition(player.type.isBot, "Player must be a bot to use AI selection")

        guard let difficulty = player.type.botDifficulty else {
            fatalError("Bot player must have difficulty level")
        }

        let strategy = difficulty.makeStrategy()
        return strategy.selectCardsToPass(from: player.hand, direction: exchangeDirection)
    }

    /// Select a card for a bot player to play
    /// - Parameter player: The bot player
    /// - Returns: A legal card selected by the bot's AI strategy
    /// - Precondition: Player must be a bot
    func selectCardForBotPlay(player: Player) -> Card {
        precondition(player.type.isBot, "Player must be a bot to use AI selection")

        guard let difficulty = player.type.botDifficulty else {
            fatalError("Bot player must have difficulty level")
        }

        let strategy = difficulty.makeStrategy()
        let context = TrickContext(
            hand: player.hand,
            currentTrick: currentTrick,
            heartsBroken: heartsBroken,
            isFirstTrick: completedTricks.isEmpty,
            completedTricks: completedTricks
        )

        return strategy.selectCardToPlay(context: context)
    }

    /// Advances bot plays in the current trick until it's a human player's turn or the trick completes.
    ///
    /// Safe to call in mixed human/bot games. Stops when:
    /// - The current player is human (waits for UI input via `playCard(_:by:)`)
    /// - The current trick completes naturally
    /// - The hand is already complete
    public func playBotTurnsUntilHumanTurn() throws {
        while !currentTrick.isComplete && !isHandComplete {
            let player = currentPlayer
            guard player.type.isBot else { return }
            let card = selectCardForBotPlay(player: player)
            try playCard(card, by: player)
        }
    }

    // MARK: - Game Orchestration

    /// Play one complete trick with all 4 players (auto-plays bot cards)
    /// - Throws: GameError if a human player's turn is encountered
    /// - Returns: The player who won the trick
    @discardableResult
    func playCompleteTrick() throws -> Player {
        precondition(!currentTrick.isComplete, "Cannot play trick - current trick is already complete")
        precondition(!isHandComplete, "Cannot play trick - hand is complete")

        let initialCompletedCount = completedTricks.count

        // Play 4 cards to complete the trick
        for _ in 0..<4 {
            let player = currentPlayer

            // If human player, we can't auto-play
            if player.type.isHuman {
                throw GameError.notPlayersTurn  // Reusing error for "need human input"
            }

            // Select card using AI
            let card = selectCardForBotPlay(player: player)

            // Play the card
            try playCard(card, by: player)
        }

        // Return the winner of the just-completed trick
        return completedTricks[initialCompletedCount].winner!
    }

    /// Play a complete hand (card exchange + 13 tricks)
    /// - Throws: GameError if a human player is encountered
    public func playCompleteHand() throws {
        precondition(!isHandComplete, "Hand is already complete")

        // Perform exchange for bots (no-op if already done or direction is .none)
        performExchange()

        // Play all 13 tricks
        while !isHandComplete {
            try playCompleteTrick()
        }

        // End the hand and calculate scores
        endHand()
    }

    /// Play a complete game (multiple hands until someone reaches winning score)
    /// - Throws: GameError if a human player is encountered
    /// - Returns: The winning player
    @discardableResult
    public func playCompleteGame() throws -> Player {
        while !isGameOver || isGameTied {
            // Check if we need to start a new hand
            if isHandComplete {
                startNewHand()
            }

            // Play the hand
            try playCompleteHand()
        }

        guard let winner = gameWinner else {
            preconditionFailure("Game is over and not tied, but gameWinner is nil")
        }
        return winner
    }

    // MARK: - Game Setup

    /// Start a new hand by dealing cards and performing exchange
    public func startNewHand() {
        // Clear all hands first
        for i in 0..<players.count {
            players[i].hand = []
        }

        // Reset deck and deal new cards
        deck = Deck()
        deal()

        // Reset exchange flag so performExchange() can run for the new hand.
        // For all-bot games playCompleteHand() calls it automatically.
        // For human games the UI calls performExchange(humanCards:) after showing the hand.
        hasExchanged = false

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
