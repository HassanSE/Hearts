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

    /// Deals `handCount` hands of `cardsPerHand` cards each, round-robin from the top of the deck.
    /// - Returns: The dealt hands, or `nil` (leaving the deck untouched) if the deck holds too few cards.
    func deal(handCount: Int, cardsPerHand: Int) -> [[Card]]? {
        guard handCount > 0, cardsPerHand >= 0, count >= handCount * cardsPerHand else { return nil }
        var hands = Array(repeating: [Card](), count: handCount)
        for _ in 0..<cardsPerHand {
            for hand in 0..<handCount {
                guard let card = deal() else { return nil }
                hands[hand].append(card)
            }
        }
        return hands
    }
}
