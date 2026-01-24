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
    case mustFollowSuit(required: Card.Suit)
    case cardNotInHand
}

struct Trick {
    private(set) var plays: [(player: Player, card: Card)] = []

    /// The suit of the first card played in this trick
    var leadSuit: Card.Suit? {
        plays.first?.card.suit
    }

    /// Whether all 4 players have played a card
    var isComplete: Bool {
        plays.count == 4
    }

    /// Total points in this trick (hearts = 1 each, Q♠ = 13)
    var points: Int {
        plays.reduce(0) { $0 + $1.card.points }
    }

    /// The player who won this trick (highest card of lead suit)
    var winner: Player? {
        guard isComplete, let leadSuit = leadSuit else { return nil }
        return plays
            .filter { $0.card.suit == leadSuit }
            .max(by: { $0.card.rank < $1.card.rank })?
            .player
    }

    /// All cards played in this trick
    var cards: [Card] {
        plays.map { $0.card }
    }

    /// All players who have played in this trick
    var players: [Player] {
        plays.map { $0.player }
    }

    /// Check if a specific player has already played in this trick
    func hasPlayed(_ player: Player) -> Bool {
        plays.contains(where: { $0.player == player })
    }

    /// Play a card in this trick
    /// - Parameters:
    ///   - card: The card to play
    ///   - player: The player playing the card
    ///   - playerHand: The player's current hand (for validation)
    /// - Throws: TrickError if the play is invalid
    mutating func play(_ card: Card, by player: Player, from playerHand: [Card]) throws {
        // Validate trick is not complete
        guard !isComplete else {
            throw TrickError.trickAlreadyComplete
        }

        // Validate player hasn't already played
        guard !hasPlayed(player) else {
            throw TrickError.playerAlreadyPlayed
        }

        // Validate card is in player's hand
        guard playerHand.contains(card) else {
            throw TrickError.cardNotInHand
        }

        // Validate following suit if not leading
        if let leadSuit = leadSuit {
            let hasLeadSuit = playerHand.contains(where: { $0.suit == leadSuit })
            if hasLeadSuit && card.suit != leadSuit {
                throw TrickError.mustFollowSuit(required: leadSuit)
            }
        }

        plays.append((player: player, card: card))
    }
}

extension Trick: CustomDebugStringConvertible {
    var debugDescription: String {
        let playsDesc = plays.map { "\($0.player.name): \($0.card)" }.joined(separator: ", ")
        let winnerDesc = winner.map { " | Winner: \($0.name)" } ?? ""
        return "Trick[\(playsDesc)\(winnerDesc)]"
    }
}
