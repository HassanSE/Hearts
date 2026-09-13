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
    
    func test_deck_shuffling() {
        let deck = Deck()
        let ordered = deck.cards
        deck.shuffle()
        let afterFirstShuffle = deck.cards
        XCTAssertNotEqual(ordered, afterFirstShuffle)
        XCTAssertEqual(deck.count, 52)
        
        deck.shuffle()
        XCTAssertNotEqual(afterFirstShuffle, deck.cards)
        XCTAssertEqual(deck.count, 52)
    }
}

// MARK: - Dealing hands

extension DeckTests {
    func test_dealHands_withFullDeck_returnsFourHandsOfThirteenAndEmptiesDeck() {
        let deck = Deck()
        let hands = deck.deal(handCount: 4, cardsPerHand: 13)

        XCTAssertEqual(hands?.count, 4)
        XCTAssertEqual(hands?.map(\.count), [13, 13, 13, 13])
        XCTAssertEqual(deck.count, 0)
        let dealt = hands?.flatMap { $0 } ?? []
        XCTAssertEqual(dealt.count, 52)
        XCTAssertTrue(Deck().cards.allSatisfy { dealt.contains($0) }, "every card in the deck is dealt exactly once")
    }

    func test_dealHands_whenDeckIsTooShort_returnsNilWithoutCrashing() {
        let deck = Deck()
        _ = deck.deal()
        XCTAssertNil(deck.deal(handCount: 4, cardsPerHand: 13))
    }
}
