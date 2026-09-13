//
//  DeckTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
@testable import Hearts

final class DeckTests: XCTestCase {
    func test_init_deck_has_52_cards() {
        let deck = Deck()
        XCTAssertEqual(deck.count, 52)
    }
    
    func test_deck_has_4_suits_of_cards() {
        let deck = Deck()
        let spades = deck.cards.filter { $0.suit == .spades }
        let hearts = deck.cards.filter { $0.suit == .hearts }
        let diamonds = deck.cards.filter { $0.suit == .diamonds }
        let clubs = deck.cards.filter { $0.suit == .clubs }
        
        XCTAssertEqual(spades.count, 13)
        XCTAssertEqual(hearts.count, 13)
        XCTAssertEqual(diamonds.count, 13)
        XCTAssertEqual(clubs.count, 13)
    }
    
    func test_shuffle_usingSeededGenerator_matchesStandardLibraryShuffleWithSameSeed() {
        var deck = Deck()
        var deckGenerator = SeededRandomNumberGenerator(seed: 42)
        deck.shuffle(using: &deckGenerator)

        var referenceGenerator = SeededRandomNumberGenerator(seed: 42)
        let expected = Deck().cards.shuffled(using: &referenceGenerator)

        XCTAssertEqual(deck.cards, expected)
        XCTAssertEqual(deck.count, 52)
    }

    func test_shuffle_usingDifferentSeeds_producesDifferentOrders() {
        var first = Deck()
        var second = Deck()
        var g1 = SeededRandomNumberGenerator(seed: 1)
        var g2 = SeededRandomNumberGenerator(seed: 2)
        first.shuffle(using: &g1)
        second.shuffle(using: &g2)

        XCTAssertNotEqual(first.cards, second.cards)
        XCTAssertEqual(first.cards.sorted(), second.cards.sorted(), "shuffling permutes without losing cards")
    }

    func test_shuffle_withSystemGenerator_keepsAll52Cards() {
        var deck = Deck()
        deck.shuffle()
        XCTAssertEqual(deck.cards.sorted(), Deck().cards.sorted())
    }
}

// MARK: - Dealing hands

extension DeckTests {
    func test_dealHands_withFullDeck_returnsFourHandsOfThirteenAndEmptiesDeck() {
        var deck = Deck()
        let hands = deck.deal(handCount: 4, cardsPerHand: 13)

        XCTAssertEqual(hands?.count, 4)
        XCTAssertEqual(hands?.map(\.count), [13, 13, 13, 13])
        XCTAssertEqual(deck.count, 0)
        let dealt = hands?.flatMap { $0 } ?? []
        XCTAssertEqual(dealt.count, 52)
        XCTAssertTrue(Deck().cards.allSatisfy { dealt.contains($0) }, "every card in the deck is dealt exactly once")
    }

    func test_dealHands_whenDeckIsTooShort_returnsNilWithoutCrashing() {
        var deck = Deck()
        _ = deck.deal()
        XCTAssertNil(deck.deal(handCount: 4, cardsPerHand: 13))
    }
}
