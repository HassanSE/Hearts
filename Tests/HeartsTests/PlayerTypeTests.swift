//
//  PlayerTypeTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

final class PlayerTypeTests: XCTestCase {

    func test_isHuman_human_isTrueAndNotBot() {
        let humanType = PlayerType.human

        XCTAssertTrue(humanType.isHuman)
        XCTAssertFalse(humanType.isBot)
        XCTAssertNil(humanType.botDifficulty)
    }

    func test_isBot_easyBot_isTrueWithEasyDifficulty() {
        let botType = PlayerType.bot(difficulty: .easy)

        XCTAssertFalse(botType.isHuman)
        XCTAssertTrue(botType.isBot)
        XCTAssertEqual(botType.botDifficulty, .easy)
    }

    func test_isBot_mediumBot_isTrueWithMediumDifficulty() {
        let botType = PlayerType.bot(difficulty: .medium)

        XCTAssertFalse(botType.isHuman)
        XCTAssertTrue(botType.isBot)
        XCTAssertEqual(botType.botDifficulty, .medium)
    }

    func test_isBot_hardBot_isTrueWithHardDifficulty() {
        let botType = PlayerType.bot(difficulty: .hard)

        XCTAssertFalse(botType.isHuman)
        XCTAssertTrue(botType.isBot)
        XCTAssertEqual(botType.botDifficulty, .hard)
    }
}
