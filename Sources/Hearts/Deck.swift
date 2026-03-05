//
//  Deck.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

class Deck {
    var cards: [Card] = []

    var count: Int { cards.count }

    init() {
        for suit in Card.Suit.allCases {
            for rank in Card.Rank.allCases {
                cards.append(Card(suit: suit, rank: rank))
            }
        }
    }

    func shuffle() {
        cards.shuffle()
    }

    func deal() -> Card? {
        cards.popLast()
    }
}
