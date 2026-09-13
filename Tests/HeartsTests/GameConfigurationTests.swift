//
//  GameConfigurationTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

final class GameConfigurationTests: XCTestCase {

    // MARK: - init

    func test_init_noArguments_isStandardHearts() {
        let configuration = GameConfiguration()

        XCTAssertFalse(configuration.jackOfDiamondsBonus)
        XCTAssertEqual(configuration.winningScore, 100)
        XCTAssertEqual(configuration.moonShotVariant, .addToOthers)
        XCTAssertEqual(configuration, .standard)
    }

    func test_init_customValues_storesEach() {
        let configuration = GameConfiguration(jackOfDiamondsBonus: true, winningScore: 50, moonShotVariant: .subtractFromSelf)

        XCTAssertTrue(configuration.jackOfDiamondsBonus)
        XCTAssertEqual(configuration.winningScore, 50)
        XCTAssertEqual(configuration.moonShotVariant, .subtractFromSelf)
    }

    // MARK: - Presets

    func test_withJackBonus_preset_differsFromStandardOnlyByJackBonus() {
        XCTAssertTrue(GameConfiguration.withJackBonus.jackOfDiamondsBonus)
        XCTAssertEqual(GameConfiguration.withJackBonus.winningScore, GameConfiguration.standard.winningScore)
        XCTAssertEqual(GameConfiguration.withJackBonus.moonShotVariant, GameConfiguration.standard.moonShotVariant)
    }

    func test_withSubtractMoonShot_preset_differsFromStandardOnlyByMoonShotVariant() {
        XCTAssertEqual(GameConfiguration.withSubtractMoonShot.moonShotVariant, .subtractFromSelf)
        XCTAssertFalse(GameConfiguration.withSubtractMoonShot.jackOfDiamondsBonus)
        XCTAssertEqual(GameConfiguration.withSubtractMoonShot.winningScore, GameConfiguration.standard.winningScore)
    }

    // MARK: - Equatable

    func test_equatable_differentWinningScore_isNotEqual() {
        XCTAssertNotEqual(GameConfiguration(winningScore: 100), GameConfiguration(winningScore: 50))
    }

    // MARK: - Game integration

    func test_game_withConfiguration_exposesItAndItsWinningScore() {
        let configuration = GameConfiguration(winningScore: 25)
        let game = Game.seededBots(configuration: configuration)

        XCTAssertEqual(game.configuration, configuration)
        XCTAssertEqual(game.winningScore, 25)
        XCTAssertEqual(game.scoring.configuration, configuration)
    }
}
