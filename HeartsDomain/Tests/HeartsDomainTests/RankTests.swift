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
}
