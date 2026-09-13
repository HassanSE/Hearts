//
//  DelegateSpy.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import Hearts

/// A `GameEngineDelegate` that records every callback, in order, as an `Event`.
///
/// Assert on `events` for ordering, or on the per-callback views (`plays`, `handResults`, …)
/// when only one kind of event matters. Set `onEvent` to inspect the game as each callback fires.
final class DelegateSpy: GameEngineDelegate {
    enum Event: Equatable {
        case transition(GamePhase)
        case playCard(Card, by: Seat)
        case completeTrick(Trick, winner: Seat, points: Int)
        case breakHearts(Card, by: Seat)
        case endHand(HandResult)
        case endGame(winner: Seat)
        case restore(GamePhase)
    }

    private(set) var events: [Event] = []

    /// Called with the game and the event as each callback fires, before the event is recorded.
    var onEvent: ((Game, Event) -> Void)?

    /// Forgets everything recorded so far.
    func reset() {
        events = []
    }

    // MARK: Per-callback views

    var phases: [GamePhase] {
        events.compactMap { if case .transition(let phase) = $0 { return phase } else { return nil } }
    }

    var plays: [(card: Card, seat: Seat)] {
        events.compactMap { if case .playCard(let card, let seat) = $0 { return (card, seat) } else { return nil } }
    }

    var completedTricks: [(trick: Trick, winner: Seat, points: Int)] {
        events.compactMap {
            if case .completeTrick(let trick, let winner, let points) = $0 { return (trick, winner, points) } else { return nil }
        }
    }

    var heartsBreaks: [(card: Card, seat: Seat)] {
        events.compactMap { if case .breakHearts(let card, let seat) = $0 { return (card, seat) } else { return nil } }
    }

    var handResults: [HandResult] {
        events.compactMap { if case .endHand(let result) = $0 { return result } else { return nil } }
    }

    var gameWinners: [Seat] {
        events.compactMap { if case .endGame(let winner) = $0 { return winner } else { return nil } }
    }

    var restoredPhases: [GamePhase] {
        events.compactMap { if case .restore(let phase) = $0 { return phase } else { return nil } }
    }

    // MARK: GameEngineDelegate

    func game(_ game: Game, didTransitionTo phase: GamePhase) {
        record(.transition(phase), from: game)
    }

    func game(_ game: Game, didPlayCard card: Card, by seat: Seat) {
        record(.playCard(card, by: seat), from: game)
    }

    func game(_ game: Game, didCompleteTrick trick: Trick, winner: Seat, points: Int) {
        record(.completeTrick(trick, winner: winner, points: points), from: game)
    }

    func game(_ game: Game, didBreakHearts card: Card, by seat: Seat) {
        record(.breakHearts(card, by: seat), from: game)
    }

    func game(_ game: Game, didEndHand result: HandResult) {
        record(.endHand(result), from: game)
    }

    func game(_ game: Game, didEndGame winner: Seat) {
        record(.endGame(winner: winner), from: game)
    }

    func game(_ game: Game, didRestoreTo phase: GamePhase) {
        record(.restore(phase), from: game)
    }

    private func record(_ event: Event, from game: Game) {
        onEvent?(game, event)
        events.append(event)
    }
}
