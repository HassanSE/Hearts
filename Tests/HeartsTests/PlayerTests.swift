//
//  PlayerTests.swift
//
//
//  Created by Muhammad Hassan on 23/01/2026.
//

import XCTest
@testable import Hearts

final class PlayerTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_player_defaults_to_human_type() {
        let player = Player(name: "Alice")

        XCTAssertEqual(player.name, "Alice")
        XCTAssertTrue(player.type.isHuman)
        XCTAssertFalse(player.type.isBot)
    }

    func test_init_player_with_bot_type() {
        let player = Player(name: "BotPlayer", type: .bot(difficulty: .medium))

        XCTAssertTrue(player.type.isBot)
        XCTAssertFalse(player.type.isHuman)
        XCTAssertEqual(player.type.botDifficulty, .medium)
    }

    // MARK: - Equatable / Hashable Tests

    func test_players_with_same_profile_are_equal() {
        XCTAssertEqual(Player(name: "Hannah"), Player(name: "Hannah"))
        XCTAssertEqual(Player(name: "Bot", type: .bot(difficulty: .hard)), Player(name: "Bot", type: .bot(difficulty: .hard)))
    }

    func test_players_with_different_name_or_type_are_not_equal() {
        XCTAssertNotEqual(Player(name: "Hannah"), Player(name: "George"))
        XCTAssertNotEqual(Player(name: "Hannah"), Player(name: "Hannah", type: .bot(difficulty: .easy)))
    }

    func test_player_can_be_added_to_set() {
        let playerSet: Set<Player> = [Player(name: "Ian"), Player(name: "Jane"), Player(name: "Ian")]

        XCTAssertEqual(playerSet.count, 2, "Set should only contain 2 unique profiles")
    }

    // MARK: - Debug Description Tests

    func test_debugDescription_includes_name_and_type() {
        let human = Player(name: "Alice", type: .human)
        let bot = Player(name: "BotBob", type: .bot(difficulty: .hard))

        XCTAssertTrue(human.debugDescription.contains("Alice"))
        XCTAssertTrue(human.debugDescription.contains("human"))
        XCTAssertTrue(bot.debugDescription.contains("bot"))
        XCTAssertTrue(bot.debugDescription.contains("hard"))
    }

    // MARK: - Player Type Tests

    func test_playerType_human_properties() {
        let humanType = PlayerType.human

        XCTAssertTrue(humanType.isHuman)
        XCTAssertFalse(humanType.isBot)
        XCTAssertNil(humanType.botDifficulty)
    }

    func test_playerType_bot_easy_properties() {
        let botType = PlayerType.bot(difficulty: .easy)

        XCTAssertFalse(botType.isHuman)
        XCTAssertTrue(botType.isBot)
        XCTAssertEqual(botType.botDifficulty, .easy)
    }

    func test_playerType_bot_medium_properties() {
        let botType = PlayerType.bot(difficulty: .medium)

        XCTAssertFalse(botType.isHuman)
        XCTAssertTrue(botType.isBot)
        XCTAssertEqual(botType.botDifficulty, .medium)
    }

    func test_playerType_bot_hard_properties() {
        let botType = PlayerType.bot(difficulty: .hard)

        XCTAssertFalse(botType.isHuman)
        XCTAssertTrue(botType.isBot)
        XCTAssertEqual(botType.botDifficulty, .hard)
    }

    func test_makeBotPlayers_creates_medium_difficulty_by_default() {
        let bots = Player.makeBotPlayers()

        XCTAssertEqual(bots.count, 4)
        for bot in bots {
            XCTAssertTrue(bot.type.isBot)
            XCTAssertEqual(bot.type.botDifficulty, .medium)
        }
    }

    func test_makeBotPlayers_with_custom_difficulty() {
        let easyBots = Player.makeBotPlayers(difficulty: .easy)
        let hardBots = Player.makeBotPlayers(difficulty: .hard)

        for bot in easyBots {
            XCTAssertEqual(bot.type.botDifficulty, .easy)
        }

        for bot in hardBots {
            XCTAssertEqual(bot.type.botDifficulty, .hard)
        }
    }

    func test_botDifficulty_creates_correct_strategies() {
        let easyStrategy = BotDifficulty.easy.makeStrategy(randomSource: RandomSource(SystemRandomNumberGenerator()))
        let mediumStrategy = BotDifficulty.medium.makeStrategy(randomSource: RandomSource(SystemRandomNumberGenerator()))
        let hardStrategy = BotDifficulty.hard.makeStrategy(randomSource: RandomSource(SystemRandomNumberGenerator()))

        XCTAssertTrue(easyStrategy is RandomAIStrategy)
        XCTAssertTrue(mediumStrategy is BasicAIStrategy)
        XCTAssertTrue(hardStrategy is AdvancedAIStrategy)
    }
}
