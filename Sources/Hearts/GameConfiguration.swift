//
//  GameConfiguration.swift
//
//
//  Created by Muhammad Hassan on 29/01/2026.
//

import Foundation

/// Configuration options for Hearts game variants
///
/// Use this to customize game rules when initializing a Game instance.
///
/// Example usage:
/// ```swift
/// // Standard Hearts (no Jack of Diamonds bonus)
/// let game = Game(player1: p1, player2: p2, player3: p3, player4: p4)
///
/// // With Jack of Diamonds bonus variant
/// let game = Game(player1: p1, player2: p2, player3: p3, player4: p4, configuration: .withJackBonus)
///
/// // Custom configuration
/// let customConfig = GameConfiguration(jackOfDiamondsBonus: true, winningScore: 50)
/// let game = Game(player1: p1, player2: p2, player3: p3, player4: p4, configuration: customConfig)
/// ```
struct GameConfiguration {
    /// When true, the Jack of Diamonds reduces the trick winner's score by 10 points.
    ///
    /// This is a popular Hearts variant. When combined with shooting the moon:
    /// - Shooting the moon is detected by capturing all 13 hearts + Queen of Spades (regardless of other cards)
    /// - If a player shoots the moon with this bonus enabled, they get -10 points (instead of 0)
    /// - Other players still get 26 points each
    ///
    /// Example: Player captures all hearts, Q♠, and J♦ = shooter gets -10, others get 26 each
    let jackOfDiamondsBonus: Bool

    /// Target score to end the game. First player to reach or exceed this score loses.
    /// The player with the lowest total score at game end wins.
    let winningScore: Int

    /// Standard Hearts rules (no Jack of Diamonds bonus, game ends at 100 points)
    static let standard = GameConfiguration(
        jackOfDiamondsBonus: false,
        winningScore: 100
    )

    /// Hearts variant with Jack of Diamonds bonus rule (game ends at 100 points)
    static let withJackBonus = GameConfiguration(
        jackOfDiamondsBonus: true,
        winningScore: 100
    )
}
