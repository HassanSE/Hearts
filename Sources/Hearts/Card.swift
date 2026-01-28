//
//  Card.swift
//  
//
//  Created by Muhammad Hassan on 12/10/2023.
//

import Foundation

public struct Card {
    public let suit: Suit
    public let rank: Rank
    
    public enum Rank: Int, CaseIterable, Comparable {
        public static func < (lhs: Rank, rhs: Rank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        case two = 2, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    }
    
    public enum Suit: CaseIterable, Comparable {
        case spades
        case hearts
        case diamonds
        case clubs
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
    public static func < (lhs: Card, rhs: Card) -> Bool {
        lhs.rank < rhs.rank
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
