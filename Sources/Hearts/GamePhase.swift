//
//  GamePhase.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

/// Where a `Game` is in its lifecycle, and therefore which mutator it will accept next.
///
/// `Game.phase` is the single source of truth for "what happens next". Each phase admits exactly
/// one mutator; calling any other throws `GameError.wrongPhase`. `Game.advance()` walks the
/// phases automatically until a human must act or the game is over.
///
/// ```
/// awaitingExchange ──performExchange──▶ awaitingPlay(seat) ──playCard×52──▶ awaitingSettlement
///        ▲                                                                        │ endHand
///        └──────────── startNewHand ◀──── handComplete(result) ◀─────────────────┤
///                                                                                └─▶ gameOver(winner)
/// ```
public enum GamePhase: Equatable, Codable {
    /// Cards are dealt; waiting for `performExchange(selections:)`.
    /// When `Game.exchangeDirection` is `.none` the call moves no cards but is still required.
    case awaitingExchange
    /// Waiting for `seat` to play a card via `playCard(_:by:)`.
    case awaitingPlay(Seat)
    /// Every card has been played; waiting for `endHand()` to settle the scores.
    case awaitingSettlement
    /// The hand has been settled with `result`; waiting for `startNewHand()`.
    /// The game may be tied at this point (`Game.isGameTied`), in which case another hand decides it.
    case handComplete(HandResult)
    /// `winner` holds the unique lowest total after some seat reached the winning score. Terminal.
    case gameOver(winner: Seat)
}

extension GamePhase {
    /// Whether the last hand has been settled: `.handComplete` or `.gameOver`.
    var isHandSettled: Bool {
        switch self {
        case .handComplete, .gameOver: return true
        case .awaitingExchange, .awaitingPlay, .awaitingSettlement: return false
        }
    }
}
