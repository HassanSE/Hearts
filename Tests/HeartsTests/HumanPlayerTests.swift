//
//  HumanPlayerTests.swift
//
//
//  Created by Muhammad Hassan on 12/02/2026.
//

import XCTest
@testable import Hearts

final class HumanPlayerTests: XCTestCase {

    // MARK: - Human Player Flow

    func test_humanPlayer_canPlayCard_viaPlayCard() throws {
        let game = Game.humanSouthTwoCardDeal()
        let card = Card.twoOfClubs

        XCTAssertNoThrow(try game.playCard(card, by: .south))
        XCTAssertFalse(game.hands[.south].contains(card), "Card should be removed from hand after playing")
    }

    func test_humanPlayer_advance_stopsAtHumanTurn() throws {
        let game = Game.humanSouthTwoCardDeal()
        // Human (south) holds 2♣ and it's their turn — advance should return immediately
        XCTAssertTrue(game.currentPlayer.type.isHuman)

        try game.advance()

        XCTAssertEqual(game.phase, .awaitingPlay(.south))
        XCTAssertEqual(game.currentTrick.plays.count, 0, "No plays should have been made")
    }

    func test_humanPlayer_advance_playsBotsUntilTheHumanMustActAgain() throws {
        let game = Game.humanSouthTwoCardDeal()

        // Human plays first (2♣ — required to open)
        try game.playCard(Card.twoOfClubs, by: .south)
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

    // MARK: - performExchange

    func test_performExchange_humanCards_usesSpecifiedCards() throws {
        let game = Game.humanSouthTwoCardDeal()
        game.phase = .awaitingExchange
        // Give the human a 13-card hand so exchange precondition is satisfied
        game.hands[.south] = [
            Card.twoOfClubs,
            Card.threeOfClubs,
            Card.fourOfClubs,
            Card.fiveOfClubs,
            Card.sixOfClubs,
            Card.sevenOfClubs,
            Card.eightOfClubs,
            Card.nineOfClubs,
            Card.tenOfClubs,
            Card.jackOfClubs,
            Card.queenOfClubs,
            Card.kingOfClubs,
            Card.aceOfClubs
        ]
        game.hands[.west] = Array(repeating: Card.twoOfDiamonds, count: 0)
        // Give bots valid 13-card hands
        let botCards: [[Card]] = [
            [Card.twoOfDiamonds, Card.threeOfDiamonds,
             Card.fourOfDiamonds, Card.fiveOfDiamonds,
             Card.sixOfDiamonds, Card.sevenOfDiamonds,
             Card.eightOfDiamonds, Card.nineOfDiamonds,
             Card.tenOfDiamonds, Card.jackOfDiamonds,
             Card.queenOfDiamonds, Card.kingOfDiamonds,
             Card.aceOfDiamonds],
            [Card.twoOfHearts, Card.threeOfHearts,
             Card.fourOfHearts, Card.fiveOfHearts,
             Card.sixOfHearts, Card.sevenOfHearts,
             Card.eightOfHearts, Card.nineOfHearts,
             Card.tenOfHearts, Card.jackOfHearts,
             Card.queenOfHearts, Card.kingOfHearts,
             Card.aceOfHearts],
            [Card.twoOfSpades, Card.threeOfSpades,
             Card.fourOfSpades, Card.fiveOfSpades,
             Card.sixOfSpades, Card.sevenOfSpades,
             Card.eightOfSpades, Card.nineOfSpades,
             Card.tenOfSpades, Card.jackOfSpades,
             Card.queenOfSpades, Card.kingOfSpades,
             Card.aceOfSpades]
        ]
        game.hands[.west] = botCards[0]
        game.hands[.north] = botCards[1]
        game.hands[.east] = botCards[2]

        let card1 = Card.aceOfClubs
        let card2 = Card.kingOfClubs
        let card3 = Card.queenOfClubs
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

    func test_performExchange_secondCall_throwsWrongPhase() throws {
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

    func test_performExchange_afterStartNewHand_succeeds() throws {
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
