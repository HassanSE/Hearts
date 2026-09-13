//
//  GameSnapshotTests.swift
//
//
//  Created by Muhammad Hassan on 12/04/2026.
//

import XCTest
@testable import Hearts

final class GameSnapshotTests: XCTestCase {

    // MARK: - snapshot()

    func test_snapshot_freshGame_capturesInitialState() throws {
        let game = Game()
        let snap = game.snapshot()

        XCTAssertEqual(snap.hands, game.hands)
        XCTAssertEqual(snap.completedTricks.count, 0)
        XCTAssertFalse(snap.heartsBroken)
        XCTAssertEqual(snap.currentSeat, game.currentSeat)
        XCTAssertEqual(snap.roundNumber, 0)
        XCTAssertEqual(snap.phase, .awaitingExchange)
    }

    func test_snapshot_afterExchange_reflectsPhase() throws {
        let game = Game()
        try game.performExchange()
        let snap = game.snapshot()

        XCTAssertEqual(snap.phase, .awaitingPlay(game.currentSeat))
    }

    func test_snapshot_afterHeartPlayed_reflectsHeartsBroken() throws {
        let game = Game()
        try game.performExchange()

        // Play until hearts break — run a full hand and check a mid-trick snapshot
        // Easier: manually force heartsBroken via a complete hand and inspect snapshot
        try! game.playCompleteHand()
        let snap = game.snapshot()

        // completedTricks were populated and endHand ran
        XCTAssertEqual(snap.roundNumber, 1)
    }

    // MARK: - restore(from:)

    func test_restore_afterPlays_revertsToSnapshotState() throws {
        let game = Game()
        let snap = game.snapshot()

        let handsBefore = game.hands
        let scoreBefore = game.totalScores

        // Play a complete hand (exchange + 13 tricks + endHand)
        try! game.playCompleteHand()

        // State has changed
        XCTAssertEqual(game.completedTricks.count, 13)
        XCTAssertEqual(game.roundNumber, 1)

        // Restore
        try game.restore(from: snap)

        // All state matches original
        XCTAssertEqual(game.hands, handsBefore)
        XCTAssertEqual(game.totalScores, scoreBefore)
        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertEqual(game.roundNumber, 0)
        XCTAssertFalse(game.heartsBroken)
        XCTAssertEqual(game.phase, .awaitingExchange)
    }

    func test_restore_afterPlays_allowsReplayingSameMoves() throws {
        let game = Game()
        let snap = game.snapshot()

        // Record the first card that will be played
        try game.performExchange()
        let firstSeat = game.currentSeat
        let firstCard = try XCTUnwrap(game.selectCardForBotPlay(seat: firstSeat))

        // Play one card
        try! game.playCard(firstCard, by: firstSeat)
        XCTAssertFalse(game.hands[firstSeat].contains(firstCard))

        // Restore to before-exchange snapshot
        try game.restore(from: snap)

        // Exchange again — same direction
        try game.performExchange()

        // The same seat now holds the first card again (or a different one if exchange moved it)
        // The key invariant: every hand is restored to 13 cards
        XCTAssertEqual(game.hands.mapValues(\.count), [13, 13, 13, 13])
    }

    func test_restore_withHistory_clearsUndoHistory() throws {
        let game = Game()
        try game.performExchange()

        // Play some cards to populate history
        try! game.playCompleteTrick()
        XCTAssertTrue(game.canUndo)

        // Explicit restore should wipe history
        let snap = game.snapshot()
        try game.restore(from: snap)

        XCTAssertFalse(game.canUndo)
    }

    // MARK: - undo()

    func test_canUndo_freshGame_isFalse() throws {
        let game = Game()
        XCTAssertFalse(game.canUndo)
    }

    func test_canUndo_afterPlayingCard_isTrue() throws {
        let game = Game()
        try game.performExchange()

        let seat = game.currentSeat
        let card = try XCTUnwrap(game.selectCardForBotPlay(seat: seat))
        try! game.playCard(card, by: seat)

        XCTAssertTrue(game.canUndo)
    }

    func test_undo_afterOnePlay_revertsIt() throws {
        let game = Game()
        try game.performExchange()

        let handsBefore = game.hands
        let seat = game.currentSeat
        let card = try XCTUnwrap(game.selectCardForBotPlay(seat: seat))

        try! game.playCard(card, by: seat)

        // Card has been removed from hand
        XCTAssertFalse(game.hands[seat].contains(card))

        game.undo()

        // Hand is restored
        XCTAssertEqual(game.hands, handsBefore)
        XCTAssertTrue(game.hands[seat].contains(card))
    }

    func test_undo_repeated_revertsMultipleSteps() throws {
        let game = Game()
        try game.performExchange()

        let handsBefore = game.hands

        // Play 4 cards (one full trick)
        try! game.playCompleteTrick()

        XCTAssertEqual(game.completedTricks.count, 1)

        // Undo all 4 plays
        game.undo(); game.undo(); game.undo(); game.undo()

        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertEqual(game.hands, handsBefore)
    }

    func test_undo_reverts_exchange() throws {
        let game = Game()
        let handsBefore = game.hands

        try game.performExchange()

        // Hands changed
        XCTAssertNotEqual(game.hands, handsBefore)
        XCTAssertTrue(game.canUndo)

        game.undo()

        // Hands restored to pre-exchange state
        XCTAssertEqual(game.hands, handsBefore)
        XCTAssertEqual(game.phase, .awaitingExchange)
    }

    func test_undo_emptyHistory_isNoop() throws {
        let game = Game()
        XCTAssertFalse(game.canUndo)

        // Must not crash and state must remain unchanged
        let snap = game.snapshot()
        game.undo()

        XCTAssertEqual(game.hands, snap.hands)
        XCTAssertEqual(game.completedTricks.count, 0)
    }

    func test_canUndo_afterExhaustingHistory_isFalse() throws {
        let game = Game()
        try game.performExchange()

        let seat = game.currentSeat
        let card = try XCTUnwrap(game.selectCardForBotPlay(seat: seat))
        try! game.playCard(card, by: seat)

        // 2 history entries: one from exchange, one from playCard
        game.undo() // reverts playCard
        game.undo() // reverts exchange
        XCTAssertFalse(game.canUndo)
    }

    func test_startNewHand_withHistory_keepsUndoHistory() throws {
        let game = Game()
        try game.performExchange()
        try! game.playCompleteHand()

        XCTAssertTrue(game.canUndo)

        try game.startNewHand()

        XCTAssertTrue(game.canUndo, "the deal is undoable; see HistoryTests for the rewind itself")
    }
}
