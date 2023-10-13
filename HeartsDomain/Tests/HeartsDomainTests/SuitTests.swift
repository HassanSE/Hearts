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
}
