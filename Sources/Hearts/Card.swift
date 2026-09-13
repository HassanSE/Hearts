//
//  Card.swift
//  
//
//  Created by Muhammad Hassan on 12/10/2023.
//

typealias Hand = [Card]

/// One of the 52 playing cards: a `Suit` and a `Rank`.
///
/// A value type with no identity beyond its two components, so two `Card`s are equal exactly when
/// they name the same card. Cards are `Hashable`, so they can key dictionaries and populate sets,
/// and `Comparable` for display sorting only (see `<`); trick
/// resolution compares `rank` within the lead suit and is handled by `Trick`.
public struct Card: Codable, Hashable, Sendable {
    /// The card's suit.
    public let suit: Suit
    /// The card's rank, 2 (lowest) through ace (highest).
    public let rank: Rank

    /// Creates the card of `rank` in `suit`.
    /// - Parameters:
    ///   - suit: The card's suit.
    ///   - rank: The card's rank.
    public init(suit: Suit, rank: Rank) {
        self.suit = suit
        self.rank = rank
    }
    
    /// The thirteen ranks, ordered 2 < 3 < … < 10 < J < Q < K < A.
    ///
    /// `rawValue` is the pip count (2…10) or 11…14 for jack, queen, king and ace, which is also
    /// the order used to decide the winner of a trick.
    public enum Rank: Int, CaseIterable, Comparable, Codable, Sendable {
        /// Orders ranks by `rawValue`, so 2 is the lowest and ace the highest.
        public static func < (lhs: Rank, rhs: Rank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        /// Two, the lowest rank; 2♣ leads the first trick of every hand.
        case two = 2
        /// Three.
        case three
        /// Four.
        case four
        /// Five.
        case five
        /// Six.
        case six
        /// Seven.
        case seven
        /// Eight.
        case eight
        /// Nine.
        case nine
        /// Ten.
        case ten
        /// Jack (11); J♦ is worth −10 under `GameConfiguration.jackOfDiamondsBonus`.
        case jack
        /// Queen (12); Q♠ is worth 13 points.
        case queen
        /// King (13).
        case king
        /// Ace (14), the highest rank.
        case ace
    }
    
    /// The four suits.
    ///
    /// Suits are ordered for display as ♣ < ♦ < ♠ < ♥ (alternating colours,
    /// hearts last). This order has no gameplay meaning — Hearts has no trump —
    /// it exists so that sorting a hand groups cards the way a player expects
    /// to see them.
    public enum Suit: CaseIterable, Comparable, Codable, Sendable {
        /// ♠ — holds Q♠, the 13-point card.
        case spades
        /// ♥ — every heart is worth 1 point; hearts may not be led until broken.
        case hearts
        /// ♦ — no points unless the J♦ bonus variant is enabled.
        case diamonds
        /// ♣ — no points; 2♣ leads the first trick of every hand.
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

        /// Orders suits by the display order ♣ < ♦ < ♠ < ♥.
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
    
    /// The rank's short symbol: `"2"`…`"10"`, `"J"`, `"Q"`, `"K"` or `"A"`.
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
    
    /// The suit's symbol: `"♣"`, `"♦"`, `"♠"` or `"♥"`.
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
    /// The rank symbol followed by the suit symbol, separated by a space, e.g. `"Q ♠"`.
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
