//
//  GameEngineDelegate.swift
//
//
//  Created by Muhammad Hassan on 12/02/2026.
//

/// Delegate protocol for observing game events.
///
/// All methods have default no-op implementations — conformers only need to
/// implement the events they care about.
public protocol GameEngineDelegate: AnyObject {
    /// Called after each card is played.
    func game(_ game: Game, didPlayCard card: Card, by player: Player)

    /// Called when a trick is completed, providing the winner and points scored.
    func game(_ game: Game, didCompleteTrick trick: Trick, winner: Player, points: Int)

    /// Called the first time a heart is played (hearts broken).
    func game(_ game: Game, didBreakHearts card: Card, by player: Player)

    /// Called at the end of each hand with the settled round scores, new totals and moon shooter.
    /// This is the same value `Game.endHand()` returns, so observers need not snapshot scores beforehand.
    func game(_ game: Game, didEndHand result: HandResult)

    /// Called when the game ends, providing the winning player.
    func game(_ game: Game, didEndGame winner: Player)
}

public extension GameEngineDelegate {
    func game(_ game: Game, didPlayCard card: Card, by player: Player) {}
    func game(_ game: Game, didCompleteTrick trick: Trick, winner: Player, points: Int) {}
    func game(_ game: Game, didBreakHearts card: Card, by player: Player) {}
    func game(_ game: Game, didEndHand result: HandResult) {}
    func game(_ game: Game, didEndGame winner: Player) {}
}
