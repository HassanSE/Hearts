//
//  GameEngineDelegateTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

/// Every callback in `GameEngineDelegate`, observed through `DelegateSpy` on real games.
final class GameEngineDelegateTests: XCTestCase {

    /// A conformer that implements nothing relies entirely on the protocol's default no-ops.
    private final class Silent: GameEngineDelegate {}

    // MARK: - Default implementations

    func test_defaults_conformerImplementingNothing_receivesEveryEventWithoutCrashing() throws {
        let game = Game.seededBots(seed: 3, configuration: GameConfiguration(winningScore: 1))
        let silent = Silent()
        game.delegate = silent

        XCTAssertNoThrow(try game.playCompleteGame())
        XCTAssertTrue(game.isGameOver)
    }

    // MARK: - Delegate: didPlayCard

    func test_delegate_didPlayCard_isCalledAfterEachPlay() throws {
        let game = Game.seededBots(difficulty: .medium)
        let delegate = DelegateSpy()
        game.delegate = delegate
        try game.performExchange()

        let bot = game.currentSeat
        try game.playCard(Card.twoOfClubs, by: bot)

        XCTAssertEqual(delegate.plays.count, 1)
        XCTAssertEqual(delegate.plays[0].card, Card.twoOfClubs)
        XCTAssertEqual(delegate.plays[0].seat, bot)
    }

    func test_delegate_didPlayCard_isCalledForEveryCardInHand() throws {
        let game = Game.seededBots(difficulty: .medium)
        let delegate = DelegateSpy()
        game.delegate = delegate

        try game.playCompleteHand()

        // All-bot game: 4 players × 13 cards = 52 plays
        XCTAssertEqual(delegate.plays.count, 52)
    }

    // MARK: - Delegate: didCompleteTrick

    func test_delegate_didCompleteTrick_isCalledForEachTrick() throws {
        let game = Game.seededBots(difficulty: .medium)
        let delegate = DelegateSpy()
        game.delegate = delegate

        try game.playCompleteHand()

        // All-bot game: 13 tricks
        XCTAssertEqual(delegate.completedTricks.count, 13)
        // Each delegate call carries a complete trick
        for call in delegate.completedTricks {
            XCTAssertTrue(call.trick.isComplete)
            XCTAssertEqual(call.trick.plays.count, 4)
        }
    }

    func test_delegate_didCompleteTrick_providesCorrectWinner() throws {
        let game = Game.seededBots(difficulty: .medium)
        let delegate = DelegateSpy()
        game.delegate = delegate

        try game.playCompleteHand()

        // Each delegate call's winner should match the corresponding stored trick winner
        for (index, call) in delegate.completedTricks.enumerated() {
            XCTAssertEqual(call.winner, game.completedTricks[index].winner)
        }
    }

    // MARK: - Delegate: didBreakHearts

    func test_delegate_didBreakHearts_isCalledOnceWhenHeartsFirstPlayed() throws {
        // Set up a game where we can force a heart to be played
        let bot0 = Player.bot("Bot0")
        let bot1 = Player.bot("Bot1")
        let bot2 = Player.bot("Bot2")
        let bot3 = Player.bot("Bot3")
        let game = Game(player1: bot0, player2: bot1, player3: bot2, player4: bot3)

        // Give bot0 all clubs + one heart; bot1/2/3 have no clubs (forced to sluff hearts)
        game.hands[.south] = [Card.twoOfClubs, Card.threeOfHearts]
        game.hands[.west] = [Card.fourOfHearts, Card.fiveOfHearts]
        game.hands[.north] = [Card.sixOfHearts, Card.sevenOfHearts]
        game.hands[.east] = [Card.eightOfHearts, Card.nineOfHearts]
        game.currentSeat = .south
        game.currentTrick = Trick()
        game.completedTricks = []
        game.heartsBroken = false
        game.phase = .awaitingPlay(.south)

        let delegate = DelegateSpy()
        game.delegate = delegate

        // Play 2♣ — bot1/2/3 have no clubs, so they play hearts → hearts break
        try game.playCard(Card.twoOfClubs, by: .south)
        // Manually drive bot plays for the rest of the trick
        for _ in 0..<3 {
            let seat = game.currentSeat
            let card = game.hands[seat].first!
            try game.playCard(card, by: seat)
        }

        // Hearts should be broken now
        XCTAssertTrue(game.heartsBroken)
        // Delegate fired exactly once
        XCTAssertEqual(delegate.heartsBreaks.count, 1)
        XCTAssertEqual(delegate.heartsBreaks[0].card.suit, .hearts)
    }

    func test_delegate_didBreakHearts_isNotCalledWhenHeartsAlreadyBroken() throws {
        let bot0 = Player.bot("Bot0")
        let bot1 = Player.bot("Bot1")
        let bot2 = Player.bot("Bot2")
        let bot3 = Player.bot("Bot3")
        let game = Game(player1: bot0, player2: bot1, player3: bot2, player4: bot3)

        // Give bot0 only hearts so it's forced to play a heart as the first card
        game.hands[.south] = [Card.twoOfHearts, Card.threeOfHearts]
        game.hands[.west] = [Card.fourOfHearts, Card.fiveOfHearts]
        game.hands[.north] = [Card.sixOfHearts, Card.sevenOfHearts]
        game.hands[.east] = [Card.eightOfHearts, Card.nineOfHearts]
        game.currentSeat = .south
        game.currentTrick = Trick()
        // Hearts already broken, simulate at least one prior trick so we're not on trick 1
        var priorTrick = Trick()
        try! priorTrick.play(Card.twoOfClubs, by: .south)
        try! priorTrick.play(Card.threeOfClubs, by: .west)
        try! priorTrick.play(Card.fourOfClubs, by: .north)
        try! priorTrick.play(Card.fiveOfClubs, by: .east)
        game.completedTricks = [priorTrick]
        game.heartsBroken = true
        game.phase = .awaitingPlay(.south)

        let delegate = DelegateSpy()
        game.delegate = delegate

        // Play a heart — hearts already broken, delegate should NOT fire again
        try game.playCard(Card.twoOfHearts, by: .south)

        XCTAssertEqual(delegate.heartsBreaks.count, 0)
    }

    // MARK: - Delegate: didEndHand

    func test_delegate_didEndHand_isCalledAfterEndHand() throws {
        let game = Game.seededBots(difficulty: .medium)
        let delegate = DelegateSpy()
        game.delegate = delegate

        try game.playCompleteHand()

        XCTAssertEqual(delegate.handResults.count, 1)
    }

    func test_delegate_didEndHand_providesCorrectScores() throws {
        let game = Game.seededBots(difficulty: .medium)
        let delegate = DelegateSpy()
        game.delegate = delegate

        try game.playCompleteHand()

        let result = delegate.handResults[0]
        // One round score and one total per seat, matching the game's totals
        XCTAssertEqual(result.roundScores.values.count, 4)
        XCTAssertEqual(result.totalScores, game.totalScores)
    }

    func test_delegate_didEndHand_moonShooterIsNilWhenNoMoonShot() throws {
        let game = Game.seededBots(difficulty: .medium)
        let delegate = DelegateSpy()
        game.delegate = delegate

        try game.playCompleteHand()

        XCTAssertNil(delegate.handResults[0].moonShooter)
    }

    // MARK: - Delegate: didEndGame

    func test_delegate_didEndGame_isCalledWhenGameOver() throws {
        let game = Game()
        let delegate = DelegateSpy()
        game.delegate = delegate

        // Drive one player past the winning score threshold; give others distinct scores
        // so there is a clear winner (no tie) and gameWinner is non-nil.
        game.totalScores[.south] = 30   // Clear winner (lowest)
        game.totalScores[.west] = game.winningScore  // Triggers isGameOver
        game.totalScores[.north] = 60
        game.totalScores[.east] = 45

        // endHand on a complete hand — requires completedTricks to be full
        // Build 13 fake completed tricks (no points, so no moon shot)
        for i in 0..<13 {
            var trick = Trick()
            let rankOffset = i % 13
            let rank = Card.Rank.allCases[rankOffset]
            try! trick.play(Card(suit: .clubs, rank: rank), by: .south)
            try! trick.play(Card.threeOfClubs, by: .west)
            try! trick.play(Card.fourOfClubs, by: .north)
            try! trick.play(Card.fiveOfClubs, by: .east)
            game.completedTricks.append(trick)
        }
        game.phase = .awaitingSettlement

        try game.endHand()

        XCTAssertTrue(game.isGameOver)
        XCTAssertEqual(game.phase, .gameOver(winner: .south))
        XCTAssertEqual(delegate.gameWinners.count, 1)
        XCTAssertEqual(delegate.gameWinners[0], game.gameWinner)
    }

    func test_delegate_didEndGame_isNotCalledWhenGameNotOver() {
        let game = Game.seededBots(difficulty: .medium)
        let delegate = DelegateSpy()
        game.delegate = delegate

        // All scores are 0, game is not over
        try! game.playCompleteHand()

        XCTAssertFalse(game.isGameOver)
        XCTAssertEqual(delegate.gameWinners.count, 0)
    }
}
