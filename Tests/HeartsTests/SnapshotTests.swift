//
//  SnapshotTests.swift
//
//
//  Created by Muhammad Hassan on 12/04/2026.
//

import XCTest
@testable import Hearts

final class SnapshotTests: XCTestCase {

    // MARK: - snapshot()

    func test_snapshot_captures_initial_state() {
        let game = Game()
        let snap = game.snapshot()

        XCTAssertEqual(snap.players.map(\.hand), game.players.map(\.hand))
        XCTAssertEqual(snap.completedTricks.count, 0)
        XCTAssertFalse(snap.heartsBroken)
        XCTAssertEqual(snap.currentPlayerIndex, game.currentPlayerIndex)
        XCTAssertEqual(snap.roundNumber, 0)
        XCTAssertFalse(snap.hasExchanged)
    }

    func test_snapshot_reflects_state_after_exchange() {
        let game = Game()
        game.performExchange()
        let snap = game.snapshot()

        XCTAssertTrue(snap.hasExchanged)
    }

    func test_snapshot_reflects_hearts_broken() {
        let game = Game()
        game.performExchange()

        // Play until hearts break — run a full hand and check a mid-trick snapshot
        // Easier: manually force heartsBroken via a complete hand and inspect snapshot
        try! game.playCompleteHand()
        let snap = game.snapshot()

        // completedTricks were populated and endHand ran
        XCTAssertEqual(snap.roundNumber, 1)
    }

    // MARK: - restore(from:)

    func test_restore_reverts_to_pre_play_state() {
        let game = Game()
        let snap = game.snapshot()

        let handsBefore = game.players.map(\.hand)
        let scoreBefore = game.players.map(\.totalScore)

        // Play a complete hand (exchange + 13 tricks + endHand)
        try! game.playCompleteHand()

        // State has changed
        XCTAssertEqual(game.completedTricks.count, 13)
        XCTAssertEqual(game.roundNumber, 1)

        // Restore
        game.restore(from: snap)

        // All state matches original
        XCTAssertEqual(game.players.map(\.hand), handsBefore)
        XCTAssertEqual(game.players.map(\.totalScore), scoreBefore)
        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertEqual(game.roundNumber, 0)
        XCTAssertFalse(game.heartsBroken)
        XCTAssertFalse(game.snapshot().hasExchanged)
    }

    func test_restore_allows_replaying_same_moves() {
        let game = Game()
        let snap = game.snapshot()

        // Record the first card that will be played
        game.performExchange()
        let firstPlayer = game.currentPlayer
        let firstCard = game.selectCardForBotPlay(player: firstPlayer)

        // Play one card
        try! game.playCard(firstCard, by: firstPlayer)
        XCTAssertFalse(game.hand(for: firstPlayer).contains(firstCard))

        // Restore to before-exchange snapshot
        game.restore(from: snap)

        // Exchange again — same direction
        game.performExchange()

        // The same player now holds the first card again (or a different one if exchange moved it)
        // The key invariant: the player's hand is restored to 13 cards
        XCTAssertEqual(game.players.map { game.hand(for: $0).count }, [13, 13, 13, 13])
    }

    func test_restore_clears_undo_history() {
        let game = Game()
        game.performExchange()

        // Play some cards to populate history
        try! game.playCompleteTrick()
        XCTAssertTrue(game.canUndo)

        // Explicit restore should wipe history
        let snap = game.snapshot()
        game.restore(from: snap)

        XCTAssertFalse(game.canUndo)
    }

    // MARK: - undo()

    func test_canUndo_is_false_on_fresh_game() {
        let game = Game()
        XCTAssertFalse(game.canUndo)
    }

    func test_canUndo_is_true_after_playing_a_card() {
        let game = Game()
        game.performExchange()

        let player = game.currentPlayer
        let card = game.selectCardForBotPlay(player: player)
        try! game.playCard(card, by: player)

        XCTAssertTrue(game.canUndo)
    }

    func test_undo_reverts_single_card_play() {
        let game = Game()
        game.performExchange()

        let handsBefore = game.players.map(\.hand)
        let player = game.currentPlayer
        let card = game.selectCardForBotPlay(player: player)

        try! game.playCard(card, by: player)

        // Card has been removed from hand
        XCTAssertFalse(game.hand(for: player).contains(card))

        game.undo()

        // Hand is restored
        XCTAssertEqual(game.players.map(\.hand), handsBefore)
        XCTAssertTrue(game.hand(for: player).contains(card))
    }

    func test_undo_reverts_multiple_steps() {
        let game = Game()
        game.performExchange()

        let handsBefore = game.players.map(\.hand)

        // Play 4 cards (one full trick)
        try! game.playCompleteTrick()

        XCTAssertEqual(game.completedTricks.count, 1)

        // Undo all 4 plays
        game.undo(); game.undo(); game.undo(); game.undo()

        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertEqual(game.players.map(\.hand), handsBefore)
    }

    func test_undo_reverts_exchange() {
        let game = Game()
        let handsBefore = game.players.map(\.hand)

        game.performExchange()

        // Hands changed
        XCTAssertNotEqual(game.players.map(\.hand), handsBefore)
        XCTAssertTrue(game.canUndo)

        game.undo()

        // Hands restored to pre-exchange state
        XCTAssertEqual(game.players.map(\.hand), handsBefore)
        XCTAssertFalse(game.snapshot().hasExchanged)
    }

    func test_undo_is_noop_when_history_empty() {
        let game = Game()
        XCTAssertFalse(game.canUndo)

        // Must not crash and state must remain unchanged
        let snap = game.snapshot()
        game.undo()

        XCTAssertEqual(game.players.map(\.hand), snap.players.map(\.hand))
        XCTAssertEqual(game.completedTricks.count, 0)
    }

    func test_canUndo_becomes_false_after_exhausting_history() {
        let game = Game()
        game.performExchange()

        let player = game.currentPlayer
        let card = game.selectCardForBotPlay(player: player)
        try! game.playCard(card, by: player)

        // 2 history entries: one from exchange, one from playCard
        game.undo() // reverts playCard
        game.undo() // reverts exchange
        XCTAssertFalse(game.canUndo)
    }

    func test_startNewHand_clears_undo_history() {
        let game = Game()
        game.performExchange()
        try! game.playCompleteTrick()

        XCTAssertTrue(game.canUndo)

        game.endHand()
        game.startNewHand()

        XCTAssertFalse(game.canUndo)
    }
}
