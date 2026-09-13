//
//  Game.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

/// A serializable snapshot of all game state, suitable for persistence or undo support.
public struct GameSnapshot: Codable {
    public let players: [Player]
    public let roundNumber: Int
    public let currentTrick: Trick
    public let completedTricks: [Trick]
    public let heartsBroken: Bool
    public let currentPlayerIndex: Int
    public let configuration: GameConfiguration
    public let hasExchanged: Bool

    public init(
        players: [Player],
        roundNumber: Int,
        currentTrick: Trick,
        completedTricks: [Trick],
        heartsBroken: Bool,
        currentPlayerIndex: Int,
        configuration: GameConfiguration,
        hasExchanged: Bool
    ) {
        self.players = players
        self.roundNumber = roundNumber
        self.currentTrick = currentTrick
        self.completedTricks = completedTricks
        self.heartsBroken = heartsBroken
        self.currentPlayerIndex = currentPlayerIndex
        self.configuration = configuration
        self.hasExchanged = hasExchanged
    }
}

public enum GameError: Error, Equatable {
    case notPlayersTurn
    case cardNotInHand
    case mustLeadWithTwoOfClubs
    case mustFollowSuit(required: Card.Suit)
    case cannotPlayPointsOnFirstTrick
    case heartsNotBroken
    case handComplete
    /// A trick winner was requested before the trick had received all four cards.
    case trickIncomplete
    /// A card was played into a trick that already holds all four cards.
    case trickAlreadyComplete
    /// `performExchange` was called a second time in the same hand.
    case exchangeAlreadyPerformed
    /// `performExchange` was called after a card had already been played this hand.
    case exchangeNotAllowedAfterPlay
    /// An exchange selection was keyed by a seat index outside `0..<players.count`.
    case invalidSeat(Int)
    /// A human seat was given no exchange selection.
    case missingPassSelection(seat: Int)
    /// A seat's exchange selection did not contain exactly three cards.
    case wrongPassCount(seat: Int, count: Int)
    /// A seat's exchange selection contained the same card more than once.
    case duplicatePassCards(seat: Int)
    /// A seat's exchange selection included a card that seat does not hold.
    case passedCardNotInHand(seat: Int, card: Card)
    /// A fixed deal did not supply one hand per player, or listed the same card twice.
    case invalidDeal
}

public class Game {
    public internal(set) var players: [Player]
    public internal(set) var roundNumber = 0

    // Trick-taking state
    public internal(set) var currentTrick: Trick = Trick()
    public internal(set) var completedTricks: [Trick] = []
    public internal(set) var heartsBroken: Bool = false
    public internal(set) var currentPlayerIndex: Int = 0

    // Game configuration
    public let configuration: GameConfiguration

    /// The point rules this game plays by, derived from `configuration`.
    /// Use it to value a trick or explain a `HandResult` without driving the engine.
    public let scoring: Scoring

    /// Tracks whether the card exchange has been performed for the current hand.
    /// Prevents double-exchange and lets the UI drive timing for human players.
    private var hasExchanged = false

    /// Undo history: each entry is a snapshot taken before a state-mutating action.
    private var history: [GameSnapshot] = []

    /// The single source of randomness for this game (deck shuffles and random bot decisions).
    /// Not part of snapshots: undoing a play does not rewind the generator.
    private var randomSource: RandomSource

    /// Delegate to receive game event notifications.
    public weak var delegate: GameEngineDelegate?

    public var winningScore: Int {
        configuration.winningScore
    }

    /// Creates an all-bot game of four medium-difficulty players.
    /// - Parameters:
    ///   - configuration: Rule variants and the winning score.
    ///   - generator: Source of randomness for every deal and every random-strategy decision in this
    ///     game. Pass a `SeededRandomNumberGenerator` for a reproducible game.
    public convenience init(configuration: GameConfiguration = .standard,
                            using generator: some RandomNumberGenerator = SystemRandomNumberGenerator()) {
        let players = Player.makeBotPlayers()
        self.init(player1: players[0], player2: players[1], player3: players[2], player4: players[3],
                  configuration: configuration, using: generator)
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

    /// Whether some player has reached `winningScore`.
    public var isGameOver: Bool {
        scoring.isGameOver(totalScores: players.map(\.totalScore))
    }

    /// Whether the game is over but more than one player shares the lowest total (another hand is needed).
    public var isGameTied: Bool {
        scoring.isTied(totalScores: players.map(\.totalScore))
    }

    /// The player with the unique lowest total once the game is over; `nil` while it is in progress or tied.
    public var gameWinner: Player? {
        scoring.winner(totalScores: players.map(\.totalScore)).map { players[$0] }
    }

    /// Returns the live hand for `player` from the authoritative `players` array.
    /// Use this instead of `player.hand` directly, as local `Player` copies go stale after mutations.
    public func hand(for player: Player) -> [Card] {
        players.first(where: { $0.id == player.id })?.hand ?? []
    }

    /// Returns the cards in `player`'s hand that are legal to play right now.
    /// Returns an empty array if it isn't `player`'s turn or the hand is complete.
    public func legalMoves(for player: Player) -> [Card] {
        guard player == currentPlayer, !isHandComplete else { return [] }
        return playRules(forSeat: currentPlayerIndex).legalMoves()
    }

    /// The rules oracle for the player in `seat`, built from the live hand and trick state.
    private func playRules(forSeat seat: Int) -> PlayRules {
        PlayRules(
            hand: players[seat].hand,
            currentTrick: currentTrick,
            heartsBroken: heartsBroken,
            isFirstTrick: completedTricks.isEmpty
        )
    }

    /// Returns the live round score for `player` from the authoritative `players` array.
    public func roundScore(for player: Player) -> Int {
        players.first(where: { $0.id == player.id })?.roundScore ?? 0
    }

    /// Returns the live total score for `player` from the authoritative `players` array.
    public func totalScore(for player: Player) -> Int {
        players.first(where: { $0.id == player.id })?.totalScore ?? 0
    }

    public var exchangeDirection: CardExchangeDirection {
        switch roundNumber % 4 {
        case 0: return .left
        case 1: return .right
        case 2: return .across
        default: return .none
        }
    }

    // MARK: - Snapshot / Restore

    /// Returns a snapshot of the complete current game state.
    /// Use `restore(from:)` to rewind to this point, or `undo()` for step-by-step revert.
    public func snapshot() -> GameSnapshot {
        GameSnapshot(
            players: players,
            roundNumber: roundNumber,
            currentTrick: currentTrick,
            completedTricks: completedTricks,
            heartsBroken: heartsBroken,
            currentPlayerIndex: currentPlayerIndex,
            configuration: configuration,
            hasExchanged: hasExchanged
        )
    }

    /// Restores game state from a snapshot and clears the undo history.
    /// - Note: `configuration` is not restored (it is immutable on `Game`).
    public func restore(from snapshot: GameSnapshot) {
        applySnapshot(snapshot)
        history = []
    }

    /// Whether there is a prior state available to undo to.
    public var canUndo: Bool { !history.isEmpty }

    /// Reverts to the state before the last `playCard` or `performExchange` call.
    /// No-op if history is empty.
    public func undo() {
        guard !history.isEmpty else { return }
        applySnapshot(history.removeLast())
    }

    private func applySnapshot(_ snapshot: GameSnapshot) {
        players = snapshot.players
        roundNumber = snapshot.roundNumber
        currentTrick = snapshot.currentTrick
        completedTricks = snapshot.completedTricks
        heartsBroken = snapshot.heartsBroken
        currentPlayerIndex = snapshot.currentPlayerIndex
        hasExchanged = snapshot.hasExchanged
    }

    /// Creates a game and deals the first hand.
    /// - Parameters:
    ///   - player1: The seat that is dealt to first (seat 0); the others follow clockwise.
    ///   - configuration: Rule variants and the winning score.
    ///   - generator: Source of randomness for every deal and every random-strategy decision in this
    ///     game. Pass a `SeededRandomNumberGenerator` for a reproducible game.
    public init(player1: Player,
         player2: Player,
         player3: Player,
         player4: Player,
         configuration: GameConfiguration = .standard,
         using generator: some RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.configuration = configuration
        self.scoring = Scoring(configuration: configuration)
        self.players = [player1, player2, player3, player4]
        self.randomSource = RandomSource(generator)
        deal()

        seatLeader()
    }

    /// Creates a game whose first hand is exactly `hands` instead of a shuffled deal.
    ///
    /// Intended for tests and scripted scenarios: hands may be partial (fewer than 13 cards) or empty,
    /// but every card may appear only once. `startNewHand()` deals subsequent hands from `generator`
    /// as usual; the fixed deal consumes no randomness.
    ///
    /// - Parameters:
    ///   - hands: One hand per seat, in seat order (`hands[0]` goes to `player1`).
    ///   - configuration: Rule variants and the winning score.
    ///   - generator: Source of randomness for later deals and random-strategy decisions.
    /// - Throws: `GameError.invalidDeal` if `hands.count` is not four or a card appears twice.
    public init(player1: Player,
                player2: Player,
                player3: Player,
                player4: Player,
                hands: [[Card]],
                configuration: GameConfiguration = .standard,
                using generator: some RandomNumberGenerator = SystemRandomNumberGenerator()) throws {
        let players = [player1, player2, player3, player4]
        let sortedCards = hands.flatMap { $0 }.sorted()
        let hasDuplicate = zip(sortedCards, sortedCards.dropFirst()).contains { $0 == $1 }
        guard hands.count == players.count, !hasDuplicate else {
            throw GameError.invalidDeal
        }
        self.configuration = configuration
        self.scoring = Scoring(configuration: configuration)
        self.players = players
        self.randomSource = RandomSource(generator)
        for (seat, hand) in hands.enumerated() {
            self.players[seat].hand = hand
        }
        seatLeader()
    }

    /// Makes whoever holds 2♣ the current player; leaves the index unchanged if nobody does.
    private func seatLeader() {
        if let leaderIndex = players.firstIndex(where: { $0.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }) }) {
            currentPlayerIndex = leaderIndex
        }
    }

    /// Returns the opponent of `player` in the given direction, or `nil` if direction is `.none`.
    func getOpponent(_ player: Player, direction: CardExchangeDirection) -> Player? {
        guard let index = players.firstIndex(where: { $0.id == player.id }),
              let recipient = direction.recipient(of: index, seatCount: players.count) else { return nil }
        return players[recipient]
    }

    private func deal() {
        let numberOfCardsPerHand = 13
        var deck = Deck()
        deck.shuffle(using: &randomSource)
        // A fresh deck always holds enough cards; a short deck leaves hands untouched rather than crashing.
        guard let hands = deck.deal(handCount: players.count, cardsPerHand: numberOfCardsPerHand) else { return }
        for (index, hand) in hands.enumerated() {
            players[index].hand.append(contentsOf: hand)
        }
    }

    /// Performs the card exchange for the current hand.
    ///
    /// Every seat passes three cards in `exchangeDirection`. Bot seats choose their own cards;
    /// every human seat must appear in `selections`. Any mix of human and bot seats is supported.
    /// When `exchangeDirection` is `.none`, `selections` is ignored and no cards move, but the
    /// exchange still counts as performed for this hand.
    ///
    /// On any error nothing changes: no hand is modified and the exchange can be retried.
    ///
    /// ```swift
    /// game.startNewHand()
    /// // show the human game.hand(for: human), collect three cards…
    /// try game.performExchange(selections: [0: chosen])
    /// ```
    ///
    /// - Parameter selections: Three distinct cards to pass, keyed by seat index (`0..<4`).
    ///   Entries for bot seats override the bot's own choice.
    /// - Throws: `GameError.exchangeAlreadyPerformed` if called twice in one hand;
    ///   `.exchangeNotAllowedAfterPlay` if any card has been played this hand;
    ///   `.invalidSeat` for a key outside `0..<players.count`;
    ///   `.missingPassSelection` for a human seat with no entry;
    ///   `.wrongPassCount`, `.duplicatePassCards`, or `.passedCardNotInHand` for a bad selection.
    public func performExchange(selections: [Int: [Card]] = [:]) throws {
        guard !hasExchanged else { throw GameError.exchangeAlreadyPerformed }
        guard currentTrick.plays.isEmpty && completedTricks.isEmpty else {
            throw GameError.exchangeNotAllowedAfterPlay
        }

        // Validate and compute before touching any state so a failed exchange is a no-op.
        var newHands = players.map(\.hand)
        if exchangeDirection != .none {
            var allSelections = selections
            for (seat, player) in players.enumerated() where allSelections[seat] == nil && player.type.isBot {
                let passed = selectCardsForBotExchange(player: player)
                allSelections[seat] = [passed.first, passed.second, passed.third]
            }
            newHands = try CardExchange.apply(hands: newHands, selections: allSelections, direction: exchangeDirection)
        }

        history.append(snapshot())
        for (seat, hand) in newHands.enumerated() {
            players[seat].hand = hand
        }
        hasExchanged = true

        // Re-identify who holds 2♣ — exchange may have moved it to a different player
        seatLeader()
    }

    // MARK: - Trick-Taking Gameplay

    /// Play a card from a player's hand
    /// - Parameters:
    ///   - card: The card to play
    ///   - player: The player playing the card
    /// - Throws: `GameError` if the play is invalid:
    ///   `.notPlayersTurn`, `.handComplete`, `.cardNotInHand`, `.mustLeadWithTwoOfClubs`,
    ///   `.cannotPlayPointsOnFirstTrick`, `.heartsNotBroken`, `.mustFollowSuit(required:)`.
    ///   This is the only error type this method throws.
    public func playCard(_ card: Card, by player: Player) throws {
        // 1. Validate it's this player's turn
        guard player == currentPlayer else {
            throw GameError.notPlayersTurn
        }

        // 2. Validate hand is not complete
        guard !isHandComplete else {
            throw GameError.handComplete
        }

        // 3. Resolve the seat, then let the rules oracle check card-in-hand and the four play rules
        guard let playerIndex = players.firstIndex(of: player) else {
            throw GameError.cardNotInHand
        }
        try playRules(forSeat: playerIndex).validate(card)

        // 4. Save state to history for undo support, then record the play
        history.append(snapshot())
        try currentTrick.play(card, by: player)

        // 5. Remove card from player's hand
        players[playerIndex].hand.removeAll { $0 == card }

        // 6. Update hearts broken state and fire delegate events
        let justBrokeHearts = !heartsBroken && card.suit == .hearts
        if card.suit == .hearts {
            heartsBroken = true
        }

        delegate?.game(self, didPlayCard: card, by: player)
        if justBrokeHearts {
            delegate?.game(self, didBreakHearts: card, by: player)
        }

        // 7. Check if trick is complete
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
        let points = scoring.points(in: currentTrick)
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

    /// Points a trick is worth under this game's configuration; shorthand for `scoring.points(in:)`.
    ///
    /// This is the value awarded to the trick winner and delivered via
    /// `GameEngineDelegate.game(_:didCompleteTrick:winner:points:)`.
    /// - Parameter trick: The trick to score (complete or partial)
    /// - Returns: Total points (negative when the trick contains J♦ and the bonus is enabled)
    public func points(in trick: Trick) -> Int {
        scoring.points(in: trick)
    }

    private func advanceTurn() {
        currentPlayerIndex = (currentPlayerIndex + 1) % 4
    }

    // MARK: - Multi-Round Management

    /// Ends the current hand: settles the completed tricks into total scores and advances the round.
    ///
    /// Round scores are derived from the tricks each seat won, valued by `scoring`, so the result
    /// always agrees with the points reported per trick. The same result is delivered to
    /// `GameEngineDelegate.game(_:didEndHand:)`, followed by `game(_:didEndGame:)` if a winner emerged.
    ///
    /// - Precondition (by contract, not enforced until phases exist): all 13 tricks have been played.
    ///   Calling it earlier scores whatever tricks are complete.
    /// - Returns: Per-seat round scores (after any moon-shot adjustment), the new totals, and the moon shooter.
    @discardableResult
    public func endHand() -> HandResult {
        let result = scoring.settleHand(capturedCards: capturedCards(), totalScores: players.map(\.totalScore))

        for seat in players.indices {
            players[seat].totalScore = result.totalScores[seat]
            players[seat].roundScore = 0
        }
        roundNumber += 1

        delegate?.game(self, didEndHand: result)
        if let winner = gameWinner {
            delegate?.game(self, didEndGame: winner)
        }
        return result
    }

    /// The cards each seat has won in completed tricks this hand, indexed by seat.
    private func capturedCards() -> [[Card]] {
        var captured = Array(repeating: [Card](), count: players.count)
        for trick in completedTricks {
            guard let winner = trick.winner, let seat = players.firstIndex(of: winner) else { continue }
            captured[seat].append(contentsOf: trick.cards)
        }
        return captured
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

        let strategy = difficulty.makeStrategy(randomSource: randomSource)
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

        let strategy = difficulty.makeStrategy(randomSource: randomSource)
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
        guard initialCompletedCount < completedTricks.count,
              let winner = completedTricks[initialCompletedCount].winner else {
            throw GameError.trickIncomplete
        }
        return winner
    }

    /// Play a complete hand (card exchange + 13 tricks)
    /// - Throws: GameError if a human player is encountered
    public func playCompleteHand() throws {
        precondition(!isHandComplete, "Hand is already complete")

        // Exchange for bots unless the caller already did it this hand
        if !hasExchanged {
            try performExchange()
        }

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

        // Deal new cards
        deal()

        // Reset exchange flag so performExchange() can run for the new hand.
        // For all-bot games playCompleteHand() calls it automatically.
        // For human games the UI calls performExchange(humanCards:) after showing the hand.
        hasExchanged = false

        // Reset game state
        currentTrick = Trick()
        completedTricks = []
        heartsBroken = false
        history = []

        seatLeader()
    }
}
