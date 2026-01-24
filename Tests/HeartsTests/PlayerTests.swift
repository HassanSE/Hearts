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
}
