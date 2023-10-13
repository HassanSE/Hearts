//
//  CardTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
@testable import HeartsDomain

final class CardTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
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

}
