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

    func test_init_nameOnly_defaultsToHuman() {
        let player = Player(name: "Alice")

        XCTAssertEqual(player.name, "Alice")
        XCTAssertTrue(player.type.isHuman)
        XCTAssertFalse(player.type.isBot)
    }

    func test_init_botType_storesDifficulty() {
        let player = Player(name: "BotPlayer", type: .bot(difficulty: .medium))

        XCTAssertTrue(player.type.isBot)
        XCTAssertFalse(player.type.isHuman)
        XCTAssertEqual(player.type.botDifficulty, .medium)
    }

    // MARK: - Equatable / Hashable Tests

    func test_equatable_sameProfile_isEqual() {
        XCTAssertEqual(Player(name: "Hannah"), Player(name: "Hannah"))
        XCTAssertEqual(Player(name: "Bot", type: .bot(difficulty: .hard)), Player(name: "Bot", type: .bot(difficulty: .hard)))
    }

    func test_equatable_differentNameOrType_isNotEqual() {
        XCTAssertNotEqual(Player(name: "Hannah"), Player(name: "George"))
        XCTAssertNotEqual(Player(name: "Hannah"), Player(name: "Hannah", type: .bot(difficulty: .easy)))
    }

    func test_hashable_duplicateProfilesInSet_collapseToOne() {
        let playerSet: Set<Player> = [Player(name: "Ian"), Player(name: "Jane"), Player(name: "Ian")]

        XCTAssertEqual(playerSet.count, 2, "Set should only contain 2 unique profiles")
    }

    // MARK: - Debug Description Tests

    func test_debugDescription_anyPlayer_includesNameAndType() {
        let human = Player(name: "Alice", type: .human)
        let bot = Player(name: "BotBob", type: .bot(difficulty: .hard))

        XCTAssertTrue(human.debugDescription.contains("Alice"))
        XCTAssertTrue(human.debugDescription.contains("human"))
        XCTAssertTrue(bot.debugDescription.contains("bot"))
        XCTAssertTrue(bot.debugDescription.contains("hard"))
    }

    // MARK: - makeBotPlayers

    func test_makeBotPlayers_default_createsFourMediumBots() {
        let bots = Player.makeBotPlayers()

        XCTAssertEqual(bots.count, 4)
        for bot in bots {
            XCTAssertTrue(bot.type.isBot)
            XCTAssertEqual(bot.type.botDifficulty, .medium)
        }
    }

    func test_makeBotPlayers_customDifficulty_appliesToAll() {
        let easyBots = Player.makeBotPlayers(difficulty: .easy)
        let hardBots = Player.makeBotPlayers(difficulty: .hard)

        for bot in easyBots {
            XCTAssertEqual(bot.type.botDifficulty, .easy)
        }

        for bot in hardBots {
            XCTAssertEqual(bot.type.botDifficulty, .hard)
        }
    }
}
