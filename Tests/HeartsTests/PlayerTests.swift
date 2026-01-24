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

    func test_init_player_has_default_scores() {
        let player = Player(name: "Bilal")

        XCTAssertEqual(player.roundScore, 0)
        XCTAssertEqual(player.totalScore, 0)
    }

    func test_init_player_with_custom_scores() {
        let player = Player(name: "Khubaib", roundScore: 13, totalScore: 26)

        XCTAssertEqual(player.roundScore, 13)
        XCTAssertEqual(player.totalScore, 26)
    }

    func test_init_player_has_empty_hand_by_default() {
        let player = Player(name: "Charlie")

        XCTAssertTrue(player.hand.isEmpty)
        XCTAssertEqual(player.hand.count, 0)
    }

    func test_init_player_defaults_to_human_type() {
        let player = Player(name: "Alice")

        XCTAssertTrue(player.type.isHuman)
        XCTAssertFalse(player.type.isBot)
    }

    func test_init_player_with_bot_type() {
        let player = Player(name: "BotPlayer", type: .bot(difficulty: .medium))

        XCTAssertTrue(player.type.isBot)
        XCTAssertFalse(player.type.isHuman)
        XCTAssertEqual(player.type.botDifficulty, .medium)
    }

    // MARK: - Score Tracking Tests

    func test_roundScore_can_be_updated() {
        var player = Player(name: "Kashif")

        player.roundScore = 5
        XCTAssertEqual(player.roundScore, 5)

        player.roundScore += 8
        XCTAssertEqual(player.roundScore, 13)
    }

    func test_totalScore_can_be_updated() {
        var player = Player(name: "Tehreem")

        player.totalScore = 26
        XCTAssertEqual(player.totalScore, 26)

        player.totalScore += 13
        XCTAssertEqual(player.totalScore, 39)
    }

    func test_roundScore_and_totalScore_are_independent() {
        var player = Player(name: "Frank")

        player.roundScore = 10
        player.totalScore = 50

        XCTAssertEqual(player.roundScore, 10)
        XCTAssertEqual(player.totalScore, 50)

        player.roundScore = 0
        XCTAssertEqual(player.totalScore, 50, "Total score should not change when round score changes")
    }

    // MARK: - Equatable Tests

    func test_players_with_same_id_are_equal() {
        let player1 = Player(name: "George")
        let player2 = player1

        XCTAssertEqual(player1, player2)
    }

    func test_players_with_different_ids_are_not_equal() {
        let player1 = Player(name: "Hannah")
        let player2 = Player(name: "Hannah")

        XCTAssertNotEqual(player1, player2)
    }

    // MARK: - Hashable Tests

    func test_player_can_be_added_to_set() {
        let player1 = Player(name: "Ian")
        let player2 = Player(name: "Jane")
        let player3 = player1

        let playerSet: Set<Player> = [player1, player2, player3]

        XCTAssertEqual(playerSet.count, 2, "Set should only contain 2 unique players")
        XCTAssertTrue(playerSet.contains(player1))
        XCTAssertTrue(playerSet.contains(player2))
    }

    func test_player_can_be_used_as_dictionary_key() {
        let player1 = Player(name: "Kevin")
        let player2 = Player(name: "Laura")

        var scores: [Player: Int] = [:]
        scores[player1] = 26
        scores[player2] = 13

        XCTAssertEqual(scores[player1], 26)
        XCTAssertEqual(scores[player2], 13)
    }

    // MARK: - Debug Description Tests

    func test_debugDescription_includes_all_info() {
        let player = Player(name: "Mike", roundScore: 5, totalScore: 30)

        let description = player.debugDescription

        XCTAssertTrue(description.contains("Mike"))
        XCTAssertTrue(description.contains("5"))
        XCTAssertTrue(description.contains("30"))
    }

    // MARK: - Card Exchange Tests

    func test_acceptExchange_with_valid_hand_size() {
        // Simulates the player's state AFTER they've already passed 3 cards.
        let cards = [
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .four),
            Card(suit: .clubs, rank: .five),
            Card(suit: .clubs, rank: .six),
            Card(suit: .clubs, rank: .seven),
            Card(suit: .clubs, rank: .eight),
            Card(suit: .clubs, rank: .nine),
            Card(suit: .clubs, rank: .ten),
            Card(suit: .clubs, rank: .jack)
        ]
        var player = Player(name: "Nina", hand: cards)

        XCTAssertEqual(player.hand.count, 10, "Player should have 10 cards after passing 3")

        let exchangeCards: PassedCards = (
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .queen)
        )
        player.acceptExchange(cards: exchangeCards)

        XCTAssertEqual(player.hand.count, 13, "Player should have 13 cards after accepting 3")
        XCTAssertTrue(player.hand.contains(exchangeCards.first))
        XCTAssertTrue(player.hand.contains(exchangeCards.second))
        XCTAssertTrue(player.hand.contains(exchangeCards.third))
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
        let easyStrategy = BotDifficulty.easy.makeStrategy()
        let mediumStrategy = BotDifficulty.medium.makeStrategy()
        let hardStrategy = BotDifficulty.hard.makeStrategy()

        XCTAssertTrue(easyStrategy is RandomAIStrategy)
        XCTAssertTrue(mediumStrategy is BasicAIStrategy)
        XCTAssertTrue(hardStrategy is AdvancedAIStrategy)
    }

    func test_debugDescription_includes_player_type() {
        let human = Player(name: "Alice", type: .human)
        let bot = Player(name: "BotBob", type: .bot(difficulty: .hard))

        XCTAssertTrue(human.debugDescription.contains("human"))
        XCTAssertTrue(bot.debugDescription.contains("bot"))
        XCTAssertTrue(bot.debugDescription.contains("hard"))
    }
}
