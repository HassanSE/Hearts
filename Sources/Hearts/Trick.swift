//
//  Trick.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

/// The cards played in one round of the table, in play order, each tagged with the seat that played it.
public struct Trick: Codable, Equatable, Sendable {
    /// A single card play within a trick: which seat played which card.
    public struct Play: Codable, Equatable, Sendable {
        /// The seat that played `card`.
        public let seat: Seat
        /// The card played.
        public let card: Card
    }

    /// The plays made so far, in play order; the first is the lead. Never more than four.
    public private(set) var plays: [Play] = []

    /// The suit of the first card played in this trick, or `nil` if nothing has been played yet.
    public var leadSuit: Card.Suit? {
        plays.first?.card.suit
    }

    /// Whether all four seats have played a card.
    public var isComplete: Bool {
        plays.count == 4
    }

    /// Raw points in this trick (hearts = 1 each, Q♠ = 13), ignoring rule variants.
    /// Internal on purpose: consumers must use `Scoring.points(in:)` / `Game.points(in:)`,
    /// which apply the configured J♦ bonus and therefore match what the winner is awarded.
    var points: Int {
        plays.reduce(0) { $0 + $1.card.points }
    }

    /// The seat that won this trick (highest card of the lead suit), or `nil` until it is complete.
    public var winner: Seat? {
        guard isComplete, let leadSuit = leadSuit else { return nil }
        return plays
            .filter { $0.card.suit == leadSuit }
            .max(by: { $0.card.rank < $1.card.rank })?
            .seat
    }

    /// The cards played in this trick, in play order.
    public var cards: [Card] {
        plays.map { $0.card }
    }

    /// The seats that have played in this trick, in play order.
    public var seats: [Seat] {
        plays.map { $0.seat }
    }

    /// Whether `seat` has already played in this trick.
    /// - Parameter seat: The seat to check.
    public func hasPlayed(_ seat: Seat) -> Bool {
        plays.contains(where: { $0.seat == seat })
    }

    /// Play a card in this trick.
    /// Enforces only structural rules (trick completeness, duplicate plays).
    /// Card legality (card-in-hand, follow-suit) is validated by `Game` before this is called.
    /// - Parameters:
    ///   - card: The card to play
    ///   - seat: The seat playing the card
    /// - Throws: `GameError.trickAlreadyComplete` if the trick already holds four cards,
    ///   or `GameError.notPlayersTurn` if this seat has already played in it
    mutating func play(_ card: Card, by seat: Seat) throws {
        guard !isComplete else {
            throw GameError.trickAlreadyComplete
        }

        guard !hasPlayed(seat) else {
            throw GameError.notPlayersTurn
        }

        plays.append(Play(seat: seat, card: card))
    }
}

extension Trick: CustomDebugStringConvertible {
    /// `"Trick[south: 2 ♣, west: K ♣, … | Winner: west]"`; the winner is omitted until the trick is complete.
    public var debugDescription: String {
        let playsDesc = plays.map { "\($0.seat): \($0.card)" }.joined(separator: ", ")
        let winnerDesc = winner.map { " | Winner: \($0)" } ?? ""
        return "Trick[\(playsDesc)\(winnerDesc)]"
    }
}
