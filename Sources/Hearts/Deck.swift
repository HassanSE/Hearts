//
//  Deck.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

/// A stack of cards, initially all 52 in suit-then-rank order, dealt from the top (the end of `cards`).
struct Deck {
    private(set) var cards: [Card] = []

    var count: Int { cards.count }

    init() {
        for suit in Card.Suit.allCases {
            for rank in Card.Rank.allCases {
                cards.append(Card(suit: suit, rank: rank))
            }
        }
    }

    /// Shuffles the deck with the system generator.
    mutating func shuffle() {
        var generator = SystemRandomNumberGenerator()
        shuffle(using: &generator)
    }

    /// Shuffles the deck with `generator`; the same generator state always yields the same order.
    mutating func shuffle<G: RandomNumberGenerator>(using generator: inout G) {
        cards.shuffle(using: &generator)
    }

    mutating func deal() -> Card? {
        cards.popLast()
    }

    /// Deals `handCount` hands of `cardsPerHand` cards each, round-robin from the top of the deck.
    /// - Returns: The dealt hands, or `nil` (leaving the deck untouched) if the deck holds too few cards.
    mutating func deal(handCount: Int, cardsPerHand: Int) -> [[Card]]? {
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
