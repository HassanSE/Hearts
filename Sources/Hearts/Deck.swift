//
//  Deck.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

public class Deck {
    public var cards: [Card] = []
    
    public var count: Int { cards.count }
    
    public init() {
        for suit in Card.Suit.allCases {
            for rank in Card.Rank.allCases {
                cards.append(Card(suit: suit, rank: rank))
            }
        }
    }
    
    public func shuffle() {
        cards.shuffle()
    }
    
    public func deal() -> Card? {
        cards.popLast()
    }
}
