//
//  CardTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
@testable import Hearts

final class CardTests: XCTestCase {
    
    func test_init_card_has_suit_and_rank() {
        let card = Card(suit: .clubs, rank: .ace)
        XCTAssertEqual(card.suit, Card.Suit.clubs)
        XCTAssertEqual(card.rank, Card.Rank.ace)
    }
    
    func test_cards_with_same_suit_are_comparable() {
        let aceOfClubs = Card(suit: .clubs, rank: .ace)
        let jackOfClubs = Card(suit: .clubs, rank: .jack)
        let twoOfClubs = Card(suit: .clubs, rank: .two)
        XCTAssertGreaterThan(aceOfClubs, jackOfClubs)
        XCTAssertGreaterThan(jackOfClubs, twoOfClubs)
        XCTAssertLessThan(twoOfClubs, aceOfClubs)
    }
    
    func test_cards_points() {
        let deck = Deck()
        for card in deck.cards {
            if card.suit == .hearts {
                XCTAssertEqual(card.points, 1)
            } else if card.suit == .spades && card.rank == .queen {
                XCTAssertEqual(card.points, 13)
            } else {
                XCTAssertEqual(card.points, 0)
            }
        }
    }

}
