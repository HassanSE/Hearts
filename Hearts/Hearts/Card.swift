//
//  Card.swift
//  Hearts
//
//  Created by Muhammad Hassan on 12/10/2023.
//

import Foundation

struct Card {
    let suit: Suit
    let rank: Rank
    
    enum Rank: Int, CaseIterable, Comparable {
        static func < (lhs: Rank, rhs: Rank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        case two = 2, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    }
    
    enum Suit: CaseIterable, Comparable {
        case hearts
        case spades
        case diamonds
        case clubs
    }
}
