//
//  Game.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

/// A serializable snapshot of all game state, suitable for persistence or undo support.
///
/// Per-seat state (hands and scores) is stored once, keyed by seat; tricks reference seats only.
public struct GameSnapshot: Codable {
    public let players: SeatMap<Player>
    public let hands: SeatMap<[Card]>
    public let roundScores: SeatMap<Int>
    public let totalScores: SeatMap<Int>
    public let roundNumber: Int
    public let currentTrick: Trick
    public let completedTricks: [Trick]
    public let heartsBroken: Bool
    public let currentSeat: Seat
    public let configuration: GameConfiguration
    /// Which mutator the game accepts next; see `GamePhase`.
    public let phase: GamePhase

    public init(
        players: SeatMap<Player>,
        hands: SeatMap<[Card]>,
        roundScores: SeatMap<Int>,
        totalScores: SeatMap<Int>,
        roundNumber: Int,
        currentTrick: Trick,
        completedTricks: [Trick],
        heartsBroken: Bool,
        currentSeat: Seat,
        configuration: GameConfiguration,
        phase: GamePhase
    ) {
        self.players = players
        self.hands = hands
        self.roundScores = roundScores
        self.totalScores = totalScores
        self.roundNumber = roundNumber
        self.currentTrick = currentTrick
        self.completedTricks = completedTricks
        self.heartsBroken = heartsBroken
        self.currentSeat = currentSeat
        self.configuration = configuration
        self.phase = phase
    }
}

public enum GameError: Error, Equatable {
    case notPlayersTurn
    case cardNotInHand
    case mustLeadWithTwoOfClubs
    case mustFollowSuit(required: Card.Suit)
    case cannotPlayPointsOnFirstTrick
    case heartsNotBroken
    /// A mutator was called in a phase that does not accept it; carries the phase the game was in.
    /// See `GamePhase` for which mutator each phase admits.
    case wrongPhase(GamePhase)
    /// A bot-only driver (`playCompleteHand`, `playCompleteGame`) reached a decision that `seat`,
    /// a human, must make. Use `advance()` to stop at human decisions instead.
    case humanInputRequired(seat: Seat)
    /// A trick winner was requested before the trick had received all four cards.
    case trickIncomplete
    /// A card was played into a trick that already holds all four cards.
    case trickAlreadyComplete
    /// A human seat was given no exchange selection.
    case missingPassSelection(seat: Seat)
    /// A seat's exchange selection did not contain exactly three cards.
    case wrongPassCount(seat: Seat, count: Int)
    /// A seat's exchange selection contained the same card more than once.
    case duplicatePassCards(seat: Seat)
    /// A seat's exchange selection included a card that seat does not hold.
    case passedCardNotInHand(seat: Seat, card: Card)
    /// A fixed deal did not supply one hand per player, or listed the same card twice.
    case invalidDeal
}

public class Game {
    /// Who sits where. Fixed for the life of the game.
    public let players: SeatMap<Player>

    /// The cards each seat currently holds.
    public internal(set) var hands: SeatMap<[Card]>

    /// Points each seat has taken in tricks so far this hand (raw, before moon-shot settlement).
    public internal(set) var roundScores: SeatMap<Int>

    /// Each seat's running total across settled hands.
    public internal(set) var totalScores: SeatMap<Int>

    public internal(set) var roundNumber = 0

    // Trick-taking state
    public internal(set) var currentTrick: Trick = Trick()
    public internal(set) var completedTricks: [Trick] = []
    public internal(set) var heartsBroken: Bool = false

    /// The seat whose turn it is to play.
    public internal(set) var currentSeat: Seat = .south

    // Game configuration
    public let configuration: GameConfiguration

    /// The point rules this game plays by, derived from `configuration`.
    /// Use it to value a trick or explain a `HandResult` without driving the engine.
    public let scoring: Scoring

    /// Where the game is in its lifecycle: the single source of truth for which mutator is accepted next.
    /// Every change is reported through `GameEngineDelegate.game(_:didTransitionTo:)`.
    public internal(set) var phase: GamePhase = .awaitingExchange

    /// Undo history: each entry is a snapshot taken before a state-mutating action.
    private var history: [GameSnapshot] = []

    /// The single source of randomness for this game (deck shuffles and random bot decisions).
    /// Not part of snapshots: undoing a play does not rewind the generator.
    private var randomSource: RandomSource

    /// One strategy per bot seat, held for the life of the game so a strategy can remember what it
    /// has seen. Human seats have no entry.
    private let strategies: [Seat: AIStrategy]

    /// Delegate to receive game event notifications.
    public weak var delegate: GameEngineDelegate?

    public var winningScore: Int {
        configuration.winningScore
    }

    /// Creates an all-bot game of four medium-difficulty players.
    /// - Parameters:
    ///   - configuration: Rule variants and the winning score.
    ///   - strategies: Custom strategies for bot seats; see `init(player1:player2:player3:player4:configuration:strategies:using:)`.
    ///   - generator: Source of randomness for every deal and every random-strategy decision in this
    ///     game. Pass a `SeededRandomNumberGenerator` for a reproducible game.
    public convenience init(configuration: GameConfiguration = .standard,
                            strategies: [Seat: AIStrategy] = [:],
                            using generator: some RandomNumberGenerator = SystemRandomNumberGenerator()) {
        let players = Player.makeBotPlayers()
        self.init(player1: players[0], player2: players[1], player3: players[2], player4: players[3],
                  configuration: configuration, strategies: strategies, using: generator)
    }

    /// The seat holding 2♣ — the one that leads the first trick of the hand — or `nil` once it has been played.
    public var leader: Seat? {
        hands.first { $0.value.contains(Card(suit: .clubs, rank: .two)) }?.seat
    }

    /// The profile of the seat whose turn it is.
    public var currentPlayer: Player {
        players[currentSeat]
    }

    /// Seats played by humans, in seat order. These are the seats that need input via
    /// `playCard(_:by:)` and `performExchange(selections:)`.
    public var humanSeats: [Seat] {
        players.filter { $0.value.type.isHuman }.map(\.seat)
    }

    /// Seats played by bots, in seat order.
    public var botSeats: [Seat] {
        players.filter { $0.value.type.isBot }.map(\.seat)
    }

    /// Whether every card of the current hand has been played (settled or not).
    public var isHandComplete: Bool {
        switch phase {
        case .awaitingSettlement, .handComplete, .gameOver: return true
        case .awaitingExchange, .awaitingPlay: return false
        }
    }

    /// Whether some seat has reached `winningScore`.
    public var isGameOver: Bool {
        scoring.isGameOver(totalScores: totalScores)
    }

    /// Whether the game is over but more than one seat shares the lowest total (another hand is needed).
    public var isGameTied: Bool {
        scoring.isTied(totalScores: totalScores)
    }

    /// The seat with the unique lowest total once the game is over; `nil` while it is in progress or tied.
    public var gameWinner: Seat? {
        scoring.winner(totalScores: totalScores)
    }

    /// Returns the cards in `seat`'s hand that are legal to play right now.
    /// Returns an empty array unless the phase is `.awaitingPlay(seat)`.
    /// - Parameter seat: The seat asking.
    public func legalMoves(for seat: Seat) -> [Card] {
        guard phase == .awaitingPlay(seat) else { return [] }
        return playRules(for: seat).legalMoves()
    }

    /// The rules oracle for `seat`, built from the live hand and trick state.
    private func playRules(for seat: Seat) -> PlayRules {
        PlayRules(
            hand: hands[seat],
            currentTrick: currentTrick,
            heartsBroken: heartsBroken,
            isFirstTrick: completedTricks.isEmpty
        )
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
            hands: hands,
            roundScores: roundScores,
            totalScores: totalScores,
            roundNumber: roundNumber,
            currentTrick: currentTrick,
            completedTricks: completedTricks,
            heartsBroken: heartsBroken,
            currentSeat: currentSeat,
            configuration: configuration,
            phase: phase
        )
    }

    /// Restores game state (including `phase`) from a snapshot and clears the undo history.
    /// The delegate receives `game(_:didTransitionTo:)` for the restored phase.
    /// - Note: `players` and `configuration` are not restored (they are immutable on `Game`).
    public func restore(from snapshot: GameSnapshot) {
        applySnapshot(snapshot)
        history = []
    }

    /// Whether there is a prior state available to undo to.
    public var canUndo: Bool { !history.isEmpty }

    /// Reverts to the state before the last `playCard`, `performExchange` or `endHand` call.
    /// No-op if history is empty. The delegate receives `game(_:didTransitionTo:)` for the restored phase.
    public func undo() {
        guard !history.isEmpty else { return }
        applySnapshot(history.removeLast())
    }

    private func applySnapshot(_ snapshot: GameSnapshot) {
        hands = snapshot.hands
        roundScores = snapshot.roundScores
        totalScores = snapshot.totalScores
        roundNumber = snapshot.roundNumber
        currentTrick = snapshot.currentTrick
        completedTricks = snapshot.completedTricks
        heartsBroken = snapshot.heartsBroken
        currentSeat = snapshot.currentSeat
        transition(to: snapshot.phase)
    }

    /// The only place `phase` changes: records the new phase and notifies the delegate.
    private func transition(to newPhase: GamePhase) {
        phase = newPhase
        delegate?.game(self, didTransitionTo: newPhase)
    }

    /// Creates a game and deals the first hand.
    /// - Parameters:
    ///   - player1: The profile for `Seat.south`; `player2`…`player4` take west, north and east.
    ///   - configuration: Rule variants and the winning score.
    ///   - strategies: Strategies to use instead of the one implied by a bot seat's `BotDifficulty`.
    ///     Entries for human seats are ignored. Each instance is kept for the life of the game.
    ///   - generator: Source of randomness for every deal and every random-strategy decision in this
    ///     game. Pass a `SeededRandomNumberGenerator` for a reproducible game.
    public init(player1: Player,
         player2: Player,
         player3: Player,
         player4: Player,
         configuration: GameConfiguration = .standard,
         strategies: [Seat: AIStrategy] = [:],
         using generator: some RandomNumberGenerator = SystemRandomNumberGenerator()) {
        self.configuration = configuration
        self.scoring = Scoring(configuration: configuration)
        self.players = Game.seatPlayers(player1, player2, player3, player4)
        self.hands = SeatMap(repeating: [])
        self.roundScores = SeatMap(repeating: 0)
        self.totalScores = SeatMap(repeating: 0)
        let randomSource = RandomSource(generator)
        self.randomSource = randomSource
        self.strategies = Game.seatStrategies(players: players, overrides: strategies, randomSource: randomSource)
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
    ///   - hands: One hand per seat, in seat order (`hands[0]` goes to `player1` at south).
    ///   - configuration: Rule variants and the winning score.
    ///   - strategies: Strategies to use instead of the one implied by a bot seat's `BotDifficulty`.
    ///     Entries for human seats are ignored. Each instance is kept for the life of the game.
    ///   - generator: Source of randomness for later deals and random-strategy decisions.
    /// - Throws: `GameError.invalidDeal` if `hands.count` is not four or a card appears twice.
    public init(player1: Player,
                player2: Player,
                player3: Player,
                player4: Player,
                hands: [[Card]],
                configuration: GameConfiguration = .standard,
                strategies: [Seat: AIStrategy] = [:],
                using generator: some RandomNumberGenerator = SystemRandomNumberGenerator()) throws {
        let sortedCards = hands.flatMap { $0 }.sorted()
        let hasDuplicate = zip(sortedCards, sortedCards.dropFirst()).contains { $0 == $1 }
        guard hands.count == Seat.allCases.count, !hasDuplicate else {
            throw GameError.invalidDeal
        }
        self.configuration = configuration
        self.scoring = Scoring(configuration: configuration)
        self.players = Game.seatPlayers(player1, player2, player3, player4)
        self.hands = SeatMap { hands[$0.rawValue] }
        self.roundScores = SeatMap(repeating: 0)
        self.totalScores = SeatMap(repeating: 0)
        let randomSource = RandomSource(generator)
        self.randomSource = randomSource
        self.strategies = Game.seatStrategies(players: players, overrides: strategies, randomSource: randomSource)
        seatLeader()
    }

    /// One strategy per bot seat: the caller's override if given, else the difficulty's built-in.
    private static func seatStrategies(players: SeatMap<Player>, overrides: [Seat: AIStrategy],
                                       randomSource: RandomSource) -> [Seat: AIStrategy] {
        var strategies: [Seat: AIStrategy] = [:]
        for (seat, player) in players {
            guard let difficulty = player.type.botDifficulty else { continue }
            strategies[seat] = overrides[seat] ?? difficulty.makeStrategy(randomSource: randomSource)
        }
        return strategies
    }

    private static func seatPlayers(_ player1: Player, _ player2: Player, _ player3: Player, _ player4: Player) -> SeatMap<Player> {
        let profiles = [player1, player2, player3, player4]
        return SeatMap { profiles[$0.rawValue] }
    }

    /// Makes whoever holds 2♣ the current seat; leaves it unchanged if nobody does.
    private func seatLeader() {
        if let leader = leader {
            currentSeat = leader
        }
    }

    private func deal() {
        let numberOfCardsPerHand = 13
        var deck = Deck()
        deck.shuffle(using: &randomSource)
        // A fresh deck always holds enough cards; a short deck leaves hands untouched rather than crashing.
        guard let dealt = deck.deal(handCount: Seat.allCases.count, cardsPerHand: numberOfCardsPerHand) else { return }
        hands = SeatMap { dealt[$0.rawValue] }
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
    /// // show the human game.hands[seat], collect three cards…
    /// try game.performExchange(selections: [seat: chosen])
    /// ```
    ///
    /// - Parameter selections: Three distinct cards to pass, keyed by seat.
    ///   Entries for bot seats override the bot's own choice.
    /// - Throws: `GameError.wrongPhase` unless `phase` is `.awaitingExchange`;
    ///   `.missingPassSelection` for a human seat with no entry;
    ///   `.wrongPassCount`, `.duplicatePassCards`, or `.passedCardNotInHand` for a bad selection.
    public func performExchange(selections: [Seat: [Card]] = [:]) throws {
        guard phase == .awaitingExchange else { throw GameError.wrongPhase(phase) }

        // Validate and compute before touching any state so a failed exchange is a no-op.
        var newHands = hands
        if exchangeDirection != .none {
            var allSelections = selections
            for seat in botSeats where allSelections[seat] == nil {
                guard let passed = selectCardsForBotExchange(seat: seat) else { continue }
                allSelections[seat] = [passed.first, passed.second, passed.third]
            }
            newHands = try CardExchange.apply(hands: newHands, selections: allSelections, direction: exchangeDirection)
        }

        history.append(snapshot())
        hands = newHands

        // Re-identify who holds 2♣ — exchange may have moved it to a different seat
        seatLeader()
        transition(to: .awaitingPlay(currentSeat))
    }

    // MARK: - Trick-Taking Gameplay

    /// Play a card from a seat's hand
    /// - Parameters:
    ///   - card: The card to play
    ///   - seat: The seat playing the card
    /// - Throws: `GameError` if the play is invalid:
    ///   `.wrongPhase` unless `phase` is `.awaitingPlay`, `.notPlayersTurn`, `.cardNotInHand`,
    ///   `.mustLeadWithTwoOfClubs`, `.cannotPlayPointsOnFirstTrick`, `.heartsNotBroken`,
    ///   `.mustFollowSuit(required:)`. This is the only error type this method throws.
    public func playCard(_ card: Card, by seat: Seat) throws {
        // 1. Validate the game is waiting for a card from this seat
        guard case .awaitingPlay(let seatToPlay) = phase else {
            throw GameError.wrongPhase(phase)
        }
        guard seat == seatToPlay else {
            throw GameError.notPlayersTurn
        }

        // 3. Let the rules oracle check card-in-hand and the four play rules
        try playRules(for: seat).validate(card)

        // 4. Save state to history for undo support, then record the play
        history.append(snapshot())
        try currentTrick.play(card, by: seat)

        // 5. Remove card from the seat's hand
        hands[seat].removeAll { $0 == card }

        // 6. Update hearts broken state and fire delegate events
        let justBrokeHearts = !heartsBroken && card.suit == .hearts
        if card.suit == .hearts {
            heartsBroken = true
        }

        delegate?.game(self, didPlayCard: card, by: seat)
        if justBrokeHearts {
            delegate?.game(self, didBreakHearts: card, by: seat)
        }

        // 7. Resolve the trick or pass the turn, then report where the game now stands
        if currentTrick.isComplete {
            completeTrick()
        } else {
            advanceTurn()
        }
        if hands.values.allSatisfy(\.isEmpty) {
            transition(to: .awaitingSettlement)
        } else {
            transition(to: .awaitingPlay(currentSeat))
        }
    }

    private func completeTrick() {
        guard let winner = currentTrick.winner else {
            return
        }

        // Award points to winner based on configuration
        let points = scoring.points(in: currentTrick)
        roundScores[winner] += points

        // Capture completed trick before resetting
        let completedTrick = currentTrick

        // Store completed trick
        completedTricks.append(currentTrick)

        // Start new trick with winner leading
        currentTrick = Trick()
        currentSeat = winner

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
        currentSeat = currentSeat.next
    }

    // MARK: - Multi-Round Management

    /// Ends the current hand: settles the completed tricks into total scores and advances the round.
    ///
    /// Round scores are derived from the tricks each seat won, valued by `scoring`, so the result
    /// always agrees with the points reported per trick. The same result is delivered to
    /// `GameEngineDelegate.game(_:didEndHand:)`, followed by `game(_:didEndGame:)` if a winner emerged.
    ///
    /// Moves to `.gameOver(winner:)` if a seat has reached the winning score with a unique lowest total,
    /// otherwise to `.handComplete(result)` — including when the game is tied and another hand is needed.
    ///
    /// - Throws: `GameError.wrongPhase` unless `phase` is `.awaitingSettlement`.
    /// - Returns: Per-seat round scores (after any moon-shot adjustment), the new totals, and the moon shooter.
    @discardableResult
    public func endHand() throws -> HandResult {
        guard phase == .awaitingSettlement else { throw GameError.wrongPhase(phase) }
        let result = scoring.settleHand(capturedCards: capturedCards(), totalScores: totalScores)

        history.append(snapshot())
        totalScores = result.totalScores
        roundScores = SeatMap(repeating: 0)
        roundNumber += 1

        delegate?.game(self, didEndHand: result)
        if let winner = gameWinner {
            delegate?.game(self, didEndGame: winner)
            transition(to: .gameOver(winner: winner))
        } else {
            transition(to: .handComplete(result))
        }
        return result
    }

    /// The cards each seat has won in completed tricks this hand.
    private func capturedCards() -> SeatMap<[Card]> {
        var captured = SeatMap<[Card]>(repeating: [])
        for trick in completedTricks {
            guard let winner = trick.winner else { continue }
            captured[winner].append(contentsOf: trick.cards)
        }
        return captured
    }

    // MARK: - AI Integration

    /// Select cards for a bot seat to pass during card exchange
    /// - Parameter seat: The bot seat
    /// - Returns: Three cards selected by the seat's strategy, or `nil` for a human seat
    func selectCardsForBotExchange(seat: Seat) -> PassedCards? {
        strategies[seat]?.selectCardsToPass(from: hands[seat], direction: exchangeDirection)
    }

    /// Select a card for a bot seat to play
    /// - Parameter seat: The bot seat
    /// - Returns: A legal card selected by the seat's strategy, or `nil` for a human seat
    func selectCardForBotPlay(seat: Seat) -> Card? {
        strategies[seat]?.selectCardToPlay(context: trickContext(for: seat))
    }

    /// The decision context for `seat`, built from the live game state.
    private func trickContext(for seat: Seat) -> TrickContext {
        TrickContext(
            seat: seat,
            hand: hands[seat],
            currentTrick: currentTrick,
            heartsBroken: heartsBroken,
            isFirstTrick: completedTricks.isEmpty,
            completedTricks: completedTricks,
            roundScores: roundScores,
            totalScores: totalScores,
            roundNumber: roundNumber
        )
    }

    // MARK: - Game Orchestration

    /// Performs every step that needs no human input and stops when one does, or when the game is over.
    ///
    /// Bot seats exchange and play, complete hands are settled, and the next hand is dealt, until:
    /// - `phase` is `.awaitingExchange` and a human seat must choose cards (never when
    ///   `exchangeDirection` is `.none`: that exchange is performed automatically);
    /// - `phase` is `.awaitingPlay(seat)` and `seat` is human;
    /// - `phase` is `.gameOver`.
    ///
    /// An all-bot game therefore runs to completion in one call. A UI loop is just:
    /// ```swift
    /// while true {
    ///     try game.advance()
    ///     switch game.phase {
    ///     case .awaitingExchange: try game.performExchange(selections: [seat: askForThree()])
    ///     case .awaitingPlay(let seat): try game.playCard(askForCard(), by: seat)
    ///     case .gameOver: return
    ///     default: continue
    ///     }
    /// }
    /// ```
    /// - Throws: `GameError` only if a bot strategy produces an illegal play.
    public func advance() throws {
        _ = try step(until: { _ in false })
    }

    /// Runs the current hand to settlement: exchange (if pending), every trick, and `endHand()`.
    /// - Throws: `GameError.wrongPhase` unless the hand is in progress (`.awaitingExchange`,
    ///   `.awaitingPlay` or `.awaitingSettlement`); `.humanInputRequired` if a human seat must act.
    public func playCompleteHand() throws {
        switch phase {
        case .awaitingExchange, .awaitingPlay, .awaitingSettlement: break
        case .handComplete, .gameOver: throw GameError.wrongPhase(phase)
        }
        if let seat = try step(until: { $0.isHandSettled }) {
            throw GameError.humanInputRequired(seat: seat)
        }
    }

    /// Plays hands until the game is decided, starting from whatever phase the game is in.
    /// Returns immediately if the game is already over.
    /// - Throws: `GameError.humanInputRequired` if a human seat must act.
    /// - Returns: The winning seat.
    @discardableResult
    public func playCompleteGame() throws -> Seat {
        if let seat = try step(until: { _ in false }) {
            throw GameError.humanInputRequired(seat: seat)
        }
        guard case .gameOver(let winner) = phase else { throw GameError.wrongPhase(phase) }
        return winner
    }

    /// Plays bot turns until the current trick is complete.
    /// - Throws: `GameError.wrongPhase` unless `phase` is `.awaitingPlay`;
    ///   `.humanInputRequired` if a human seat's turn is reached.
    /// - Returns: The seat that won the trick
    @discardableResult
    func playCompleteTrick() throws -> Seat {
        guard case .awaitingPlay = phase else { throw GameError.wrongPhase(phase) }
        let initialCompletedCount = completedTricks.count
        if let seat = try step(until: { _ in self.completedTricks.count > initialCompletedCount }) {
            throw GameError.humanInputRequired(seat: seat)
        }
        guard let winner = completedTricks[initialCompletedCount].winner else {
            throw GameError.trickIncomplete
        }
        return winner
    }

    /// The single stepper behind every driver: performs bot-only steps until `shouldStop(phase)`
    /// holds, the game is over, or a human must act.
    /// - Returns: The human seat whose input is needed, or `nil` if it stopped for another reason.
    private func step(until shouldStop: (GamePhase) -> Bool) throws -> Seat? {
        while !shouldStop(phase) {
            switch phase {
            case .awaitingExchange:
                if exchangeDirection != .none, let human = humanSeats.first { return human }
                try performExchange()
            case .awaitingPlay(let seat):
                guard let card = selectCardForBotPlay(seat: seat) else { return seat }
                try playCard(card, by: seat)
            case .awaitingSettlement:
                try endHand()
            case .handComplete:
                try startNewHand()
            case .gameOver:
                return nil
            }
        }
        return nil
    }

    // MARK: - Game Setup

    /// Deals the next hand and moves to `.awaitingExchange`. Clears the undo history.
    /// - Throws: `GameError.wrongPhase` unless `phase` is `.handComplete`.
    public func startNewHand() throws {
        guard case .handComplete = phase else { throw GameError.wrongPhase(phase) }

        deal()

        currentTrick = Trick()
        completedTricks = []
        heartsBroken = false
        history = []

        seatLeader()
        transition(to: .awaitingExchange)
    }
}
