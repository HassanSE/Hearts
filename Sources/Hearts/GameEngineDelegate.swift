//
//  GameEngineDelegate.swift
//
//
//  Created by Muhammad Hassan on 12/02/2026.
//

/// Delegate protocol for observing game events.
///
/// Every participant is identified by `Seat`; look up the profile with `game.players[seat]`.
/// All methods have default no-op implementations — conformers only need to
/// implement the events they care about.
public protocol GameEngineDelegate: AnyObject {
    /// Called whenever `Game.phase` changes, after the event that caused it (for example
    /// `didCompleteTrick` or `didEndHand`). Also fires on `undo()` and `restore(from:)`.
    func game(_ game: Game, didTransitionTo phase: GamePhase)

    /// Called after each card is played.
    func game(_ game: Game, didPlayCard card: Card, by seat: Seat)

    /// Called when a trick is completed, providing the winning seat and points scored.
    func game(_ game: Game, didCompleteTrick trick: Trick, winner: Seat, points: Int)

    /// Called the first time a heart is played (hearts broken).
    func game(_ game: Game, didBreakHearts card: Card, by seat: Seat)

    /// Called at the end of each hand with the settled round scores, new totals and moon shooter.
    /// This is the same value `Game.endHand()` returns, so observers need not snapshot scores beforehand.
    func game(_ game: Game, didEndHand result: HandResult)

    /// Called when the game ends, providing the winning seat.
    func game(_ game: Game, didEndGame winner: Seat)

    /// Called after `undo()` or `restore(from:)` has replaced the game's state wholesale, before the
    /// accompanying `didTransitionTo`. Unlike forward events, nothing incremental can be inferred:
    /// rebuild any view from `game`. Not called when `restore(from:)` rejects a snapshot.
    func game(_ game: Game, didRestoreTo phase: GamePhase)
}

public extension GameEngineDelegate {
    func game(_ game: Game, didTransitionTo phase: GamePhase) {}
    func game(_ game: Game, didPlayCard card: Card, by seat: Seat) {}
    func game(_ game: Game, didCompleteTrick trick: Trick, winner: Seat, points: Int) {}
    func game(_ game: Game, didBreakHearts card: Card, by seat: Seat) {}
    func game(_ game: Game, didEndHand result: HandResult) {}
    func game(_ game: Game, didEndGame winner: Seat) {}
    func game(_ game: Game, didRestoreTo phase: GamePhase) {}
}
