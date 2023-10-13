//
//  RankTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
@testable import HeartsDomain

final class RankTests: XCTestCase {
    
    func test_there_are_13_ranks() {
        let ranks = Card.Rank.allCases
        XCTAssertEqual(ranks.count, 13)
    }
    
    func test_ranks_order() {
        let ranks = Card.Rank.allCases.sorted(by: >)
        XCTAssertEqual(ranks.first, Card.Rank.ace)
        XCTAssertEqual(ranks.last, Card.Rank.two)
        XCTAssertEqual(ranks, [.ace, .king, .queen, .jack, .ten, .nine, .eight, .seven, .six, .five, .four, .three, .two])
    }
}
