//
//  HumanPlayerTests.swift
//
//
//  Created by Muhammad Hassan on 12/02/2026.
//

import XCTest
@testable import Hearts

// MARK: - Mock Delegate

private class MockDelegate: GameEngineDelegate {
    var didPlayCardCalls: [(card: Card, seat: Seat)] = []
    var didCompleteTrickCalls: [(trick: Trick, winner: Seat, points: Int)] = []
    var didBreakHeartsCalls: [(card: Card, seat: Seat)] = []
    var didEndHandCalls: [HandResult] = []
    var didEndGameCalls: [Seat] = []

    func game(_ game: Game, didPlayCard card: Card, by seat: Seat) {
        didPlayCardCalls.append((card, seat))
    }

    func game(_ game: Game, didCompleteTrick trick: Trick, winner: Seat, points: Int) {
        didCompleteTrickCalls.append((trick, winner, points))
    }

    func game(_ game: Game, didBreakHearts card: Card, by seat: Seat) {
        didBreakHeartsCalls.append((card, seat))
    }

    func game(_ game: Game, didEndHand result: HandResult) {
        didEndHandCalls.append(result)
    }

    func game(_ game: Game, didEndGame winner: Seat) {
        didEndGameCalls.append(winner)
    }
}

// MARK: - Test Setup Helper

extension HumanPlayerTests {
    /// Creates a 3-card-per-player game with player0 as human and others as bots.
    /// Player 0 holds 2♣ and leads the first trick.
    func makeHumanBotGame() -> Game {
        let human = Player(name: "Human", type: .human)
        let bot1 = Player(name: "Bot1", type: .bot(difficulty: .easy))
        let bot2 = Player(name: "Bot2", type: .bot(difficulty: .easy))
        let bot3 = Player(name: "Bot3", type: .bot(difficulty: .easy))

        // Known deal (valid by construction): human has 2♣ and one other non-point card.
        let game = try! Game(player1: human, player2: bot1, player3: bot2, player4: bot3, hands: [
            [Card(suit: .clubs, rank: .two), Card(suit: .clubs, rank: .three)],
            [Card(suit: .clubs, rank: .five), Card(suit: .clubs, rank: .six)],
            [Card(suit: .clubs, rank: .eight), Card(suit: .clubs, rank: .nine)],
            [Card(suit: .clubs, rank: .jack), Card(suit: .clubs, rank: .queen)]
        ])
        // Two-card hands cannot be exchanged; the fixture starts in play.
        game.phase = .awaitingPlay(.south)

        return game
    }

    /// Creates a full 13-card all-bot game for automation tests.
    func makeMinimalBotGame() -> Game {
        return Game()  // Default init: 4 bots, 13 cards each, medium difficulty
    }
}

// MARK: - Tests

final class HumanPlayerTests: XCTestCase {

    // MARK: - Human Player Flow

    func test_humanPlayer_canPlayCard_viaPlayCard() throws {
        let game = makeHumanBotGame()
        let card = Card(suit: .clubs, rank: .two)

        XCTAssertNoThrow(try game.playCard(card, by: .south))
        XCTAssertFalse(game.hands[.south].contains(card), "Card should be removed from hand after playing")
    }

    func test_humanPlayer_advance_stopsAtHumanTurn() throws {
        let game = makeHumanBotGame()
        // Human (south) holds 2♣ and it's their turn — advance should return immediately
        XCTAssertTrue(game.currentPlayer.type.isHuman)

        try game.advance()

        XCTAssertEqual(game.phase, .awaitingPlay(.south))
        XCTAssertEqual(game.currentTrick.plays.count, 0, "No plays should have been made")
    }

    func test_humanPlayer_advance_playsBotsUntilTheHumanMustActAgain() throws {
        let game = makeHumanBotGame()

        // Human plays first (2♣ — required to open)
        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        XCTAssertTrue(game.currentPlayer.type.isBot)

        try game.advance()

        // The three bots finish the trick; east wins it (J♣/Q♣ beat 2♣) and leads the second
        // trick, so the human is next to act.
        XCTAssertEqual(game.completedTricks.count, 1)
        XCTAssertEqual(game.phase, .awaitingPlay(.south))
        XCTAssertEqual(game.currentTrick.plays.map(\.seat), [.east])
    }

    func test_humanPlayer_advance_completesTheHandIfNoHuman() throws {
        let game = Game(configuration: GameConfiguration(winningScore: 1))
        XCTAssertTrue(game.currentPlayer.type.isBot)

        try game.advance()

        // All 13 tricks are played and settled; a 1-point game is decided by the first hand or a tie-break.
        XCTAssertEqual(game.completedTricks.count, 13)
        XCTAssertTrue(game.isHandComplete)
        guard case .gameOver = game.phase else { return XCTFail("expected gameOver, got \(game.phase)") }
    }

    func test_humanPlayer_advance_isNoopWhenGameOver() throws {
        let game = Game(configuration: GameConfiguration(winningScore: 1))
        try game.advance()

        XCTAssertTrue(game.isHandComplete)
        let completedCount = game.completedTricks.count
        let trickPlaysCount = game.currentTrick.plays.count

        // Should be a no-op — no crash, no state mutation
        XCTAssertNoThrow(try game.advance())

        XCTAssertEqual(game.completedTricks.count, completedCount, "No new tricks should be added after hand is complete")
        XCTAssertEqual(game.currentTrick.plays.count, trickPlaysCount, "Current trick should not change")
    }

    // MARK: - Delegate: didPlayCard

    func test_delegate_didPlayCard_isCalledAfterEachPlay() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate
        try game.performExchange()

        let bot = game.currentSeat
        try game.playCard(Card(suit: .clubs, rank: .two), by: bot)

        XCTAssertEqual(delegate.didPlayCardCalls.count, 1)
        XCTAssertEqual(delegate.didPlayCardCalls[0].card, Card(suit: .clubs, rank: .two))
        XCTAssertEqual(delegate.didPlayCardCalls[0].seat, bot)
    }

    func test_delegate_didPlayCard_isCalledForEveryCardInHand() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playCompleteHand()

        // All-bot game: 4 players × 13 cards = 52 plays
        XCTAssertEqual(delegate.didPlayCardCalls.count, 52)
    }

    // MARK: - Delegate: didCompleteTrick

    func test_delegate_didCompleteTrick_isCalledForEachTrick() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playCompleteHand()

        // All-bot game: 13 tricks
        XCTAssertEqual(delegate.didCompleteTrickCalls.count, 13)
        // Each delegate call carries a complete trick
        for call in delegate.didCompleteTrickCalls {
            XCTAssertTrue(call.trick.isComplete)
            XCTAssertEqual(call.trick.plays.count, 4)
        }
    }

    func test_delegate_didCompleteTrick_providesCorrectWinner() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playCompleteHand()

        // Each delegate call's winner should match the corresponding stored trick winner
        for (index, call) in delegate.didCompleteTrickCalls.enumerated() {
            XCTAssertEqual(call.winner, game.completedTricks[index].winner)
        }
    }

    // MARK: - Delegate: didBreakHearts

    func test_delegate_didBreakHearts_isCalledOnceWhenHeartsFirstPlayed() throws {
        // Set up a game where we can force a heart to be played
        let bot0 = Player(name: "Bot0", type: .bot(difficulty: .easy))
        let bot1 = Player(name: "Bot1", type: .bot(difficulty: .easy))
        let bot2 = Player(name: "Bot2", type: .bot(difficulty: .easy))
        let bot3 = Player(name: "Bot3", type: .bot(difficulty: .easy))
        let game = Game(player1: bot0, player2: bot1, player3: bot2, player4: bot3)

        // Give bot0 all clubs + one heart; bot1/2/3 have no clubs (forced to sluff hearts)
        game.hands[.south] = [Card(suit: .clubs, rank: .two), Card(suit: .hearts, rank: .three)]
        game.hands[.west] = [Card(suit: .hearts, rank: .four), Card(suit: .hearts, rank: .five)]
        game.hands[.north] = [Card(suit: .hearts, rank: .six), Card(suit: .hearts, rank: .seven)]
        game.hands[.east] = [Card(suit: .hearts, rank: .eight), Card(suit: .hearts, rank: .nine)]
        game.currentSeat = .south
        game.currentTrick = Trick()
        game.completedTricks = []
        game.heartsBroken = false
        game.phase = .awaitingPlay(.south)

        let delegate = MockDelegate()
        game.delegate = delegate

        // Play 2♣ — bot1/2/3 have no clubs, so they play hearts → hearts break
        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        // Manually drive bot plays for the rest of the trick
        for _ in 0..<3 {
            let seat = game.currentSeat
            let card = game.hands[seat].first!
            try game.playCard(card, by: seat)
        }

        // Hearts should be broken now
        XCTAssertTrue(game.heartsBroken)
        // Delegate fired exactly once
        XCTAssertEqual(delegate.didBreakHeartsCalls.count, 1)
        XCTAssertEqual(delegate.didBreakHeartsCalls[0].card.suit, .hearts)
    }

    func test_delegate_didBreakHearts_isNotCalledWhenHeartsAlreadyBroken() throws {
        let bot0 = Player(name: "Bot0", type: .bot(difficulty: .easy))
        let bot1 = Player(name: "Bot1", type: .bot(difficulty: .easy))
        let bot2 = Player(name: "Bot2", type: .bot(difficulty: .easy))
        let bot3 = Player(name: "Bot3", type: .bot(difficulty: .easy))
        let game = Game(player1: bot0, player2: bot1, player3: bot2, player4: bot3)

        // Give bot0 only hearts so it's forced to play a heart as the first card
        game.hands[.south] = [Card(suit: .hearts, rank: .two), Card(suit: .hearts, rank: .three)]
        game.hands[.west] = [Card(suit: .hearts, rank: .four), Card(suit: .hearts, rank: .five)]
        game.hands[.north] = [Card(suit: .hearts, rank: .six), Card(suit: .hearts, rank: .seven)]
        game.hands[.east] = [Card(suit: .hearts, rank: .eight), Card(suit: .hearts, rank: .nine)]
        game.currentSeat = .south
        game.currentTrick = Trick()
        // Hearts already broken, simulate at least one prior trick so we're not on trick 1
        var priorTrick = Trick()
        try! priorTrick.play(Card(suit: .clubs, rank: .two), by: .south)
        try! priorTrick.play(Card(suit: .clubs, rank: .three), by: .west)
        try! priorTrick.play(Card(suit: .clubs, rank: .four), by: .north)
        try! priorTrick.play(Card(suit: .clubs, rank: .five), by: .east)
        game.completedTricks = [priorTrick]
        game.heartsBroken = true
        game.phase = .awaitingPlay(.south)

        let delegate = MockDelegate()
        game.delegate = delegate

        // Play a heart — hearts already broken, delegate should NOT fire again
        try game.playCard(Card(suit: .hearts, rank: .two), by: .south)

        XCTAssertEqual(delegate.didBreakHeartsCalls.count, 0)
    }

    // MARK: - Delegate: didEndHand

    func test_delegate_didEndHand_isCalledAfterEndHand() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playCompleteHand()

        XCTAssertEqual(delegate.didEndHandCalls.count, 1)
    }

    func test_delegate_didEndHand_providesCorrectScores() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playCompleteHand()

        let result = delegate.didEndHandCalls[0]
        // One round score and one total per seat, matching the game's totals
        XCTAssertEqual(result.roundScores.values.count, 4)
        XCTAssertEqual(result.totalScores, game.totalScores)
    }

    func test_delegate_didEndHand_moonShooterIsNilWhenNoMoonShot() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playCompleteHand()

        XCTAssertNil(delegate.didEndHandCalls[0].moonShooter)
    }

    // MARK: - Delegate: didEndGame

    func test_delegate_didEndGame_isCalledWhenGameOver() throws {
        let game = Game()
        let delegate = MockDelegate()
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
            try! trick.play(Card(suit: .clubs, rank: .three), by: .west)
            try! trick.play(Card(suit: .clubs, rank: .four), by: .north)
            try! trick.play(Card(suit: .clubs, rank: .five), by: .east)
            game.completedTricks.append(trick)
        }
        game.phase = .awaitingSettlement

        try game.endHand()

        XCTAssertTrue(game.isGameOver)
        XCTAssertEqual(game.phase, .gameOver(winner: .south))
        XCTAssertEqual(delegate.didEndGameCalls.count, 1)
        XCTAssertEqual(delegate.didEndGameCalls[0], game.gameWinner)
    }

    func test_delegate_didEndGame_isNotCalledWhenGameNotOver() {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        // All scores are 0, game is not over
        try! game.playCompleteHand()

        XCTAssertFalse(game.isGameOver)
        XCTAssertEqual(delegate.didEndGameCalls.count, 0)
    }

    // MARK: - performExchange

    func test_performExchange_humanCards_usesSpecifiedCards() throws {
        let game = makeHumanBotGame()
        game.phase = .awaitingExchange
        // Give the human a 13-card hand so exchange precondition is satisfied
        game.hands[.south] = [
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .four),
            Card(suit: .clubs, rank: .five),
            Card(suit: .clubs, rank: .six),
            Card(suit: .clubs, rank: .seven),
            Card(suit: .clubs, rank: .eight),
            Card(suit: .clubs, rank: .nine),
            Card(suit: .clubs, rank: .ten),
            Card(suit: .clubs, rank: .jack),
            Card(suit: .clubs, rank: .queen),
            Card(suit: .clubs, rank: .king),
            Card(suit: .clubs, rank: .ace)
        ]
        game.hands[.west] = Array(repeating: Card(suit: .diamonds, rank: .two), count: 0)
        // Give bots valid 13-card hands
        let botCards: [[Card]] = [
            [Card(suit: .diamonds, rank: .two), Card(suit: .diamonds, rank: .three),
             Card(suit: .diamonds, rank: .four), Card(suit: .diamonds, rank: .five),
             Card(suit: .diamonds, rank: .six), Card(suit: .diamonds, rank: .seven),
             Card(suit: .diamonds, rank: .eight), Card(suit: .diamonds, rank: .nine),
             Card(suit: .diamonds, rank: .ten), Card(suit: .diamonds, rank: .jack),
             Card(suit: .diamonds, rank: .queen), Card(suit: .diamonds, rank: .king),
             Card(suit: .diamonds, rank: .ace)],
            [Card(suit: .hearts, rank: .two), Card(suit: .hearts, rank: .three),
             Card(suit: .hearts, rank: .four), Card(suit: .hearts, rank: .five),
             Card(suit: .hearts, rank: .six), Card(suit: .hearts, rank: .seven),
             Card(suit: .hearts, rank: .eight), Card(suit: .hearts, rank: .nine),
             Card(suit: .hearts, rank: .ten), Card(suit: .hearts, rank: .jack),
             Card(suit: .hearts, rank: .queen), Card(suit: .hearts, rank: .king),
             Card(suit: .hearts, rank: .ace)],
            [Card(suit: .spades, rank: .two), Card(suit: .spades, rank: .three),
             Card(suit: .spades, rank: .four), Card(suit: .spades, rank: .five),
             Card(suit: .spades, rank: .six), Card(suit: .spades, rank: .seven),
             Card(suit: .spades, rank: .eight), Card(suit: .spades, rank: .nine),
             Card(suit: .spades, rank: .ten), Card(suit: .spades, rank: .jack),
             Card(suit: .spades, rank: .queen), Card(suit: .spades, rank: .king),
             Card(suit: .spades, rank: .ace)]
        ]
        game.hands[.west] = botCards[0]
        game.hands[.north] = botCards[1]
        game.hands[.east] = botCards[2]

        let card1 = Card(suit: .clubs, rank: .ace)
        let card2 = Card(suit: .clubs, rank: .king)
        let card3 = Card(suit: .clubs, rank: .queen)
        // roundNumber=0 → .left exchange (human passes to player at index 1)
        try game.performExchange(selections: [.south: [card1, card2, card3]])

        XCTAssertFalse(game.hands[.south].contains(card1), "Human should no longer hold the passed card1")
        XCTAssertFalse(game.hands[.south].contains(card2), "Human should no longer hold the passed card2")
        XCTAssertFalse(game.hands[.south].contains(card3), "Human should no longer hold the passed card3")
        XCTAssertTrue(game.hands[.west].contains(card1), "Bot1 should have received card1 from human")
        XCTAssertTrue(game.hands[.west].contains(card2), "Bot1 should have received card2 from human")
        XCTAssertTrue(game.hands[.west].contains(card3), "Bot1 should have received card3 from human")
        XCTAssertEqual(game.hands[.south].count, 13)
        XCTAssertEqual(game.hands[.west].count, 13)
    }

    func test_performExchange_preventedOnSecondCall() throws {
        let game = Game()  // all bots
        let handsBefore = game.hands

        try game.performExchange()
        let handsAfterFirst = game.hands

        // Second call must throw and leave hands untouched
        XCTAssertThrowsError(try game.performExchange()) { error in
            XCTAssertEqual(error as? GameError, .wrongPhase(.awaitingPlay(game.currentSeat)))
        }

        XCTAssertEqual(game.hands, handsAfterFirst, "Failed second exchange must not change hands")
        // First exchange should have changed hands
        XCTAssertNotEqual(handsBefore, handsAfterFirst, "First exchange should change hands")
    }

    func test_performExchange_allowedAfterStartNewHand() throws {
        let game = Game()  // all bots

        try game.playCompleteHand()

        // Start a new hand — it opens with a fresh exchange
        try game.startNewHand()
        let handsAfterNewHand = game.hands

        // Exchange again should work (hands change from fresh deal)
        try game.performExchange()
        let handsAfterSecondExchange = game.hands

        // After startNewHand the hands are re-dealt (not the same as before)
        // After the second exchange, some cards should have moved again
        XCTAssertNotEqual(handsAfterNewHand, handsAfterSecondExchange, "Exchange after startNewHand should change hands")
    }

    func test_performExchange_noPassRound_doesNothing() throws {
        let game = Game()  // all bots
        game.roundNumber = 3  // .none direction
        let handsBefore = game.hands

        try game.performExchange()  // should be a no-op (direction is .none)

        XCTAssertEqual(game.hands, handsBefore, "Hands should not change when direction is .none")
    }
}
