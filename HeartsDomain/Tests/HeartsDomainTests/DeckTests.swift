//
//  DeckTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
import HeartsDomain

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
}
