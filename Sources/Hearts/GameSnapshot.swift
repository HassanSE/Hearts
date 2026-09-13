//
//  GameSnapshot.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

/// A serializable snapshot of all game state, suitable for persistence or undo support.
///
/// Per-seat state (hands and scores) is stored once, keyed by seat; tricks reference seats only.
/// Snapshots come only from `Game.snapshot()` (or by decoding one that did); `Game.restore(from:)`
/// checks that a snapshot describes a consistent state of the same game before applying it.
public struct GameSnapshot: Equatable, Codable {
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

    init(
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

extension GameSnapshot {
    /// Throws `GameError.inconsistentSnapshot` unless this snapshot describes a state the engine could
    /// have reached: a full deck spread over hands and tricks with each seat having played once per
    /// trick, `heartsBroken` matching the plays, and a phase that agrees with the cards and scores.
    func checkConsistency(scoring: Scoring) throws {
        let tricks = completedTricks + [currentTrick]
        let inPlay = hands.values.flatMap { $0 } + tricks.flatMap { $0.plays.map(\.card) }
        let handsAreEven = Seat.allCases.allSatisfy { seat in
            hands[seat].count + tricks.filter { $0.hasPlayed(seat) }.count == 13
        }
        let heartPlayed = tricks.contains { $0.plays.contains { $0.card.suit == .hearts } }
        guard inPlay.sorted() == Deck().cards.sorted(), handsAreEven,
              completedTricks.allSatisfy(\.isComplete), heartsBroken == heartPlayed else {
            throw GameError.inconsistentSnapshot
        }

        let allPlayed = hands.values.allSatisfy(\.isEmpty) && currentTrick.plays.isEmpty
        let phaseAgrees: Bool
        switch phase {
        case .awaitingExchange:
            phaseAgrees = tricks.allSatisfy { $0.plays.isEmpty }
        case .awaitingPlay(let seat):
            phaseAgrees = seat == currentSeat && !currentTrick.hasPlayed(seat) && !hands[seat].isEmpty
        case .awaitingSettlement:
            phaseAgrees = allPlayed
        case .handComplete(let result):
            phaseAgrees = allPlayed && result.totalScores == totalScores
        case .gameOver(let winner):
            phaseAgrees = allPlayed && scoring.winner(totalScores: totalScores) == winner
        }
        guard phaseAgrees else { throw GameError.inconsistentSnapshot }
    }
}
