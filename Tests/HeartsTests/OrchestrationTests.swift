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

    func test_debug_game_setup() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))
        try game.performExchange()

        // Basic assertions
        XCTAssertEqual(game.players.values.count, 4)
        XCTAssertFalse(game.hands[game.currentSeat].isEmpty, "Current seat should have cards")

        // Try to select a card for bot
        let card = try XCTUnwrap(game.selectCardForBotPlay(seat: game.currentSeat))
        XCTAssertTrue(game.hands[game.currentSeat].contains(card), "Selected card should be in hand")

        // Try to play a complete trick manually
        for _ in 0..<4 {
            let seat = game.currentSeat
            let selectedCard = try XCTUnwrap(game.selectCardForBotPlay(seat: seat))
            try! game.playCard(selectedCard, by: seat)
        }

        // After 4 plays, trick should be complete
        XCTAssertEqual(game.completedTricks.count, 1, "Should have completed one trick")
    }

    // MARK: - playCompleteTrick Tests

    func test_playCompleteTrick_allBots_completesOneTrick() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))  // All bots by default
        try game.performExchange()

        let initialTrickCount = game.completedTricks.count
        let winner = try! game.playCompleteTrick()

        // Should have completed one trick
        XCTAssertEqual(game.completedTricks.count, initialTrickCount + 1)

        // Current trick should be reset
        XCTAssertEqual(game.currentTrick.cards.count, 0)

        // Winner should be the current seat (leads next trick)
        XCTAssertEqual(game.currentSeat, winner)
    }

    func test_playCompleteTrick_allBots_playsAllFourSeats() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))
        try game.performExchange()

        let completedTrick = game.completedTricks.count
        try! game.playCompleteTrick()

        // Completed trick should have 4 cards, one per seat
        let trick = game.completedTricks[completedTrick]
        XCTAssertEqual(trick.cards.count, 4)
        XCTAssertEqual(Set(trick.seats), Set(Seat.allCases))
    }

    func test_playCompleteTrick_firstTrick_leadsTwoOfClubs() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))
        try game.performExchange()

        try! game.playCompleteTrick()

        // First trick should start with 2 of clubs
        let firstTrick = game.completedTricks[0]
        XCTAssertEqual(firstTrick.cards[0].suit, .clubs)
        XCTAssertEqual(firstTrick.cards[0].rank, .two)
    }

    // MARK: - playCompleteHand Tests

    func test_playCompleteHand_allBots_completesThirteenTricks() {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))

        try! game.playCompleteHand()

        // Should have played all 13 tricks
        XCTAssertEqual(game.completedTricks.count, 13)
        XCTAssertTrue(game.isHandComplete)
    }

    func test_playCompleteHand_allBots_awardsPointsToSeats() {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))

        try! game.playCompleteHand()

        // Total points should be 26 (13 hearts + 13 for Q♠)
        let totalPoints = game.totalScores.values.reduce(0, +)
        XCTAssertEqual(totalPoints, 26, "Total points in hand should be 26")
    }

    func test_playCompleteHand_allBots_emptiesEveryHand() {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))

        try! game.playCompleteHand()

        XCTAssertEqual(game.hands, SeatMap(repeating: []))
    }

    // MARK: - playCompleteGame Tests

    func test_playCompleteGame_allBots_endsWhenSeatReachesWinningScore() {
        let config = GameConfiguration(jackOfDiamondsBonus: false, winningScore: 26)
        let game = Game(configuration: config, using: SeededRandomNumberGenerator(seed: 1))

        let winner = try! game.playCompleteGame()

        // Game should be over
        XCTAssertTrue(game.isGameOver)

        // At least one seat should have reached winning score
        XCTAssertTrue(game.totalScores.values.contains(where: { $0 >= 26 }))

        // Winner should have lowest score
        XCTAssertEqual(winner, game.totalScores.min(by: { $0.value < $1.value })?.seat)
    }

    func test_playCompleteGame_allBots_playsMultipleHands() {
        let config = GameConfiguration(jackOfDiamondsBonus: false, winningScore: 30)
        let game = Game(configuration: config, using: SeededRandomNumberGenerator(seed: 1))

        try! game.playCompleteGame()

        // Round number should have incremented (multiple hands played)
        XCTAssertGreaterThan(game.roundNumber, 0)
    }

    func test_playCompleteGame_allBots_returnsLowestScoringSeat() {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))

        let winner = try! game.playCompleteGame()

        // Winner should have the lowest total score
        let lowestScore = game.totalScores.values.min()!
        XCTAssertEqual(game.totalScores[winner], lowestScore)
    }
}
