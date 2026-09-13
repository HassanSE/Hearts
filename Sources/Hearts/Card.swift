//
//  Card.swift
//  
//
//  Created by Muhammad Hassan on 12/10/2023.
//

import Foundation

typealias Hand = [Card]

public struct Card: Codable {
    public let suit: Suit
    public let rank: Rank

    public init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
    }
    
    public enum Rank: Int, CaseIterable, Comparable, Codable {
        public static func < (lhs: Rank, rhs: Rank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        case two = 2, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    }
    
    /// The four suits.
    ///
    /// Suits are ordered for display as ♣ < ♦ < ♠ < ♥ (alternating colours,
    /// hearts last). This order has no gameplay meaning — Hearts has no trump —
    /// it exists so that sorting a hand groups cards the way a player expects
    /// to see them.
    public enum Suit: CaseIterable, Comparable, Codable {
        case spades
        case hearts
        case diamonds
        case clubs

        /// Position in the documented display order ♣ ♦ ♠ ♥.
        private var displayOrder: Int {
            switch self {
            case .clubs: return 0
            case .diamonds: return 1
            case .spades: return 2
            case .hearts: return 3
            }
        }

        public static func < (lhs: Suit, rhs: Suit) -> Bool {
            lhs.displayOrder < rhs.displayOrder
        }
    }
}

extension Card.Rank: CustomStringConvertible {
    var symbol: String {
        switch self {
        case .ace:
            return "A"
        case .king:
            return "K"
        case .queen:
            return "Q"
        case .jack:
            return "J"
        default:
            return String(rawValue)
        }
    }
    
    public var description: String {
        symbol
    }
}

extension Card.Suit: CustomStringConvertible {
    var symbol: String {
        switch self {
        case .hearts:
            return "♥"
        case .spades:
            return "♠"
        case .diamonds:
            return "♦"
        case .clubs:
            return "♣"
        }
    }
    
    public var description: String {
        symbol
    }
}

extension Card: Comparable {
    /// Total order over cards: by suit (♣ ♦ ♠ ♥, see `Suit`), then by rank
    /// within a suit. Consistent with `==`, so `sorted()` on a hand groups
    /// cards by suit in ascending rank. Trick resolution does not use this
    /// order; it compares `rank` within the lead suit only.
    public static func < (lhs: Card, rhs: Card) -> Bool {
        if lhs.suit != rhs.suit { return lhs.suit < rhs.suit }
        return lhs.rank < rhs.rank
    }
}

extension Card: CustomStringConvertible {
    public var description: String {
        "\(self.rank) \(self.suit)"
    }
}

extension Card {
    /// Standard Hearts point values (no variant rules)
    /// Hearts = 1 point, Queen of Spades = 13 points, all others = 0
    var points: Int {
        switch (rank, suit) {
        case (_, .hearts):
            return 1
        case (.queen, .spades):
            return 13
        default:
            return 0
        }
    }
}
