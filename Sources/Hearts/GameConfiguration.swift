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
    /// This is a popular Hearts variant. Note that if a player attempts to shoot the moon
    /// and also captures the Jack of Diamonds, their total will be 16 points (13 hearts + 13 Q♠ - 10 J♦),
    /// which does NOT qualify as shooting the moon (requires exactly 26 points).
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
