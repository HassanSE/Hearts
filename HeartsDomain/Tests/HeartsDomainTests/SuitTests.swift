//
//  SuitTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
@testable import HeartsDomain

final class SuitTests: XCTestCase {
    
    func test_there_are_4_suits() {
        let suits = Card.Suit.allCases
        XCTAssertEqual(suits.count, 4)
    }
    
    func test_suits_order() {
        let suits = Card.Suit.allCases.sorted(by: >)
        XCTAssertEqual(suits.first, Card.Suit.clubs)
        XCTAssertEqual(suits.last, Card.Suit.spades)
        XCTAssertEqual(suits, [.clubs, .diamonds, .hearts, .spades])
    }
}
