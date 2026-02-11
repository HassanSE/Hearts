//
//  OrchestrationTests.swift
//
//
//  Created by Muhammad Hassan on 05/02/2026.
//

import XCTest
@testable import Hearts

final class OrchestrationTests: XCTestCase {

    // MARK: - Debug Tests

    func test_debug_game_setup() {
        let game = Game()

        // Basic assertions
        XCTAssertEqual(game.players.count, 4)
        XCTAssertTrue(game.currentPlayerIndex >= 0 && game.currentPlayerIndex < 4, "Should have valid index")
        XCTAssertFalse(game.currentPlayer.hand.isEmpty, "Current player should have cards")

        // Try to select a card for bot
        let card = game.selectCardForBotPlay(player: game.currentPlayer)
        XCTAssertTrue(game.currentPlayer.hand.contains(card), "Selected card should be in hand")

        // Try to play a complete trick manually
        for _ in 0..<4 {
            let currentPlayer = game.currentPlayer
            let selectedCard = game.selectCardForBotPlay(player: currentPlayer)
            try! game.playCard(selectedCard, by: currentPlayer)
        }

        // After 4 plays, trick should be complete
        XCTAssertEqual(game.completedTricks.count, 1, "Should have completed one trick")
    }

    // MARK: - playCompleteTrick Tests

    func test_playCompleteTrick_completes_one_trick() {
        let game = Game()  // All bots by default

        let initialTrickCount = game.completedTricks.count
        let winner = try! game.playCompleteTrick()

        // Should have completed one trick
        XCTAssertEqual(game.completedTricks.count, initialTrickCount + 1)

        // Current trick should be reset
        XCTAssertEqual(game.currentTrick.cards.count, 0)

        // Winner should be the current player (leads next trick)
        XCTAssertEqual(game.currentPlayer, winner)
    }

    func test_playCompleteTrick_plays_all_4_players() {
        let game = Game()

        let completedTrick = game.completedTricks.count
        try! game.playCompleteTrick()

        // Completed trick should have 4 cards
        let trick = game.completedTricks[completedTrick]
        XCTAssertEqual(trick.cards.count, 4)
    }

    func test_playCompleteTrick_first_card_is_two_of_clubs() {
        let game = Game()

        try! game.playCompleteTrick()

        // First trick should start with 2 of clubs
        let firstTrick = game.completedTricks[0]
        XCTAssertEqual(firstTrick.cards[0].suit, .clubs)
        XCTAssertEqual(firstTrick.cards[0].rank, .two)
    }

    // MARK: - playCompleteHand Tests

    func test_playCompleteHand_completes_13_tricks() {
        let game = Game()

        try! game.playCompleteHand()

        // Should have played all 13 tricks
        XCTAssertEqual(game.completedTricks.count, 13)
        XCTAssertTrue(game.isHandComplete)
    }

    func test_playCompleteHand_awards_points_to_players() {
        let game = Game()

        try! game.playCompleteHand()

        // Total points should be 26 (13 hearts + 13 for Q♠)
        let totalPoints = game.players.map { $0.totalScore }.reduce(0, +)
        XCTAssertEqual(totalPoints, 26, "Total points in hand should be 26")
    }

    func test_playCompleteHand_all_players_have_empty_hands() {
        let game = Game()

        try! game.playCompleteHand()

        // All players should have empty hands
        for player in game.players {
            XCTAssertEqual(player.hand.count, 0)
        }
    }

    // MARK: - playCompleteGame Tests

    func test_playCompleteGame_ends_when_player_reaches_winning_score() {
        let config = GameConfiguration(jackOfDiamondsBonus: false, winningScore: 26)
        let game = Game(configuration: config)

        let winner = try! game.playCompleteGame()

        // Game should be over
        XCTAssertTrue(game.isGameOver)

        // At least one player should have reached winning score
        XCTAssertTrue(game.players.contains(where: { $0.totalScore >= 26 }))

        // Winner should have lowest score
        XCTAssertEqual(winner, game.players.min(by: { $0.totalScore < $1.totalScore }))
    }

    func test_playCompleteGame_plays_multiple_hands() {
        let config = GameConfiguration(jackOfDiamondsBonus: false, winningScore: 30)
        let game = Game(configuration: config)

        try! game.playCompleteGame()

        // Round number should have incremented (multiple hands played)
        XCTAssertGreaterThan(game.roundNumber, 0)
    }

    func test_playCompleteGame_winner_has_lowest_score() {
        let game = Game()

        let winner = try! game.playCompleteGame()

        // Winner should have the lowest total score
        let lowestScore = game.players.map { $0.totalScore }.min()!
        XCTAssertEqual(winner.totalScore, lowestScore)
    }
}
