//
//  Trick.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import Foundation

enum TrickError: Error, Equatable {
    case trickAlreadyComplete
    case playerAlreadyPlayed
}

public struct Trick: Codable {
    /// A single card play within a trick, associating a player with the card they played.
    public struct Play: Codable {
        public let player: Player
        public let card: Card
    }

    public private(set) var plays: [Play] = []

    /// The suit of the first card played in this trick
    public var leadSuit: Card.Suit? {
        plays.first?.card.suit
    }

    /// Whether all 4 players have played a card
    public var isComplete: Bool {
        plays.count == 4
    }

    /// Total points in this trick (hearts = 1 each, Q♠ = 13)
    public var points: Int {
        plays.reduce(0) { $0 + $1.card.points }
    }

    /// The player who won this trick (highest card of lead suit)
    public var winner: Player? {
        guard isComplete, let leadSuit = leadSuit else { return nil }
        return plays
            .filter { $0.card.suit == leadSuit }
            .max(by: { $0.card.rank < $1.card.rank })?
            .player
    }

    /// All cards played in this trick
    public var cards: [Card] {
        plays.map { $0.card }
    }

    /// All players who have played in this trick
    public var players: [Player] {
        plays.map { $0.player }
    }

    /// Check if a specific player has already played in this trick
    public func hasPlayed(_ player: Player) -> Bool {
        plays.contains(where: { $0.player == player })
    }

    /// Play a card in this trick.
    /// Enforces only structural rules (trick completeness, duplicate plays).
    /// Card legality (card-in-hand, follow-suit) is validated by `Game` before this is called.
    /// - Parameters:
    ///   - card: The card to play
    ///   - player: The player playing the card
    /// - Throws: `TrickError.trickAlreadyComplete` or `TrickError.playerAlreadyPlayed`
    mutating func play(_ card: Card, by player: Player) throws {
        guard !isComplete else {
            throw TrickError.trickAlreadyComplete
        }

        guard !hasPlayed(player) else {
            throw TrickError.playerAlreadyPlayed
        }

        plays.append(Play(player: player, card: card))
    }
}

extension Trick: CustomDebugStringConvertible {
    public var debugDescription: String {
        let playsDesc = plays.map { "\($0.player.name): \($0.card)" }.joined(separator: ", ")
        let winnerDesc = winner.map { " | Winner: \($0.name)" } ?? ""
        return "Trick[\(playsDesc)\(winnerDesc)]"
    }
}
