//
//  HistoryTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

/// Snapshot/undo as a history log: every mutation is undoable, `restore(from:)` validates, and
/// observers are told when state is rewound.
final class HistoryTests: XCTestCase {

    // MARK: - Fixtures

    /// A copy of `snapshot` with some fields replaced, standing in for a hand-edited or corrupt save file.
    private func edited(_ snapshot: GameSnapshot,
                        hands: SeatMap<[Card]>? = nil,
                        totalScores: SeatMap<Int>? = nil,
                        currentTrick: Trick? = nil,
                        completedTricks: [Trick]? = nil,
                        heartsBroken: Bool? = nil,
                        currentSeat: Seat? = nil,
                        phase: GamePhase? = nil) -> GameSnapshot {
        GameSnapshot(players: snapshot.players,
                     hands: hands ?? snapshot.hands,
                     roundScores: snapshot.roundScores,
                     totalScores: totalScores ?? snapshot.totalScores,
                     roundNumber: snapshot.roundNumber,
                     currentTrick: currentTrick ?? snapshot.currentTrick,
                     completedTricks: completedTricks ?? snapshot.completedTricks,
                     heartsBroken: heartsBroken ?? snapshot.heartsBroken,
                     currentSeat: currentSeat ?? snapshot.currentSeat,
                     configuration: snapshot.configuration,
                     phase: phase ?? snapshot.phase)
    }

    private func assertInconsistent(_ snapshot: GameSnapshot, on game: Game,
                                    _ message: String, file: StaticString = #filePath, line: UInt = #line) {
        let before = game.snapshot()
        XCTAssertThrowsError(try game.restore(from: snapshot), message, file: file, line: line) { error in
            XCTAssertEqual(error as? GameError, .inconsistentSnapshot, message, file: file, line: line)
        }
        XCTAssertEqual(game.snapshot(), before, "a rejected restore changes nothing", file: file, line: line)
    }

    private func settledGame(seed: UInt64 = 5) throws -> Game {
        let game = Game(using: SeededRandomNumberGenerator(seed: seed))
        try game.playCompleteHand()
        return game
    }

    // MARK: - Undo across a hand boundary

    func test_undo_afterStartNewHand_restoresTheSettledHand() throws {
        let game = try settledGame()
        guard case .handComplete(let result) = game.phase else { return XCTFail("expected handComplete") }
        let tricksBefore = game.completedTricks

        try game.startNewHand()
        XCTAssertEqual(game.phase, .awaitingExchange)
        XCTAssertTrue(game.canUndo, "startNewHand is a mutation and must be undoable")

        game.undo()

        XCTAssertEqual(game.phase, .handComplete(result))
        XCTAssertEqual(game.completedTricks, tricksBefore)
        XCTAssertEqual(game.totalScores, result.totalScores)
        XCTAssertTrue(game.hands.values.allSatisfy(\.isEmpty))
        XCTAssertEqual(game.roundNumber, 1)
    }

    func test_undo_repeatedly_walksBackThroughTheWholeGame() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        let dealt = game.snapshot()
        try game.playCompleteHand()
        try game.startNewHand()
        try game.performExchange()
        try game.playCompleteTrick()

        while game.canUndo { game.undo() }

        XCTAssertEqual(game.phase, .awaitingExchange)
        XCTAssertEqual(game.roundNumber, 0)
        XCTAssertEqual(game.totalScores, [0, 0, 0, 0])
        XCTAssertEqual(game.hands, dealt.hands, "back at the very first deal")
    }

    // MARK: - restore(from:) validation

    func test_restore_withSnapshotFromDifferentConfiguration_throwsAndLeavesStateUntouched() throws {
        let source = Game(configuration: .withJackBonus, using: SeededRandomNumberGenerator(seed: 5))
        let foreign = source.snapshot()
        let game = try settledGame()
        let before = game.snapshot()
        try game.startNewHand()
        let dealt = game.snapshot()

        XCTAssertThrowsError(try game.restore(from: foreign)) { error in
            XCTAssertEqual(error as? GameError, .snapshotFromDifferentGame)
        }

        XCTAssertEqual(game.snapshot(), dealt, "a rejected restore changes nothing")
        XCTAssertTrue(game.canUndo, "history survives a rejected restore")
        game.undo()
        XCTAssertEqual(game.snapshot(), before)
    }

    func test_restore_withDecodedSnapshotWhoseCardIsDuplicated_throwsInconsistentSnapshot() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(game.snapshot())) as? [String: Any])
        var hands = try XCTUnwrap(json["hands"] as? [[Any]])
        hands[1][0] = hands[0][0]   // west's first card is now the same as south's
        json["hands"] = hands
        let tampered = try JSONDecoder().decode(GameSnapshot.self, from: JSONSerialization.data(withJSONObject: json))

        assertInconsistent(tampered, on: game, "a card held twice is not a deck")
    }

    func test_restore_withMissingCard_throwsInconsistentSnapshot() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        var hands = game.hands
        hands[.north].removeLast()

        assertInconsistent(edited(game.snapshot(), hands: hands), on: game, "51 cards is not a deck")
    }

    func test_restore_withCardBothInHandAndInATrick_throwsInconsistentSnapshot() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        try game.performExchange()
        try game.playCompleteTrick()
        let played = game.completedTricks[0].plays[0]
        var hands = game.hands
        hands[played.seat].append(played.card)
        hands[played.seat].removeFirst()

        assertInconsistent(edited(game.snapshot(), hands: hands), on: game, "a played card cannot still be held")
    }

    // MARK: - Phase must agree with the cards and scores

    func test_restore_withAwaitingExchangeButTricksAlreadyPlayed_throwsInconsistentSnapshot() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        try game.performExchange()
        try game.playCompleteTrick()

        assertInconsistent(edited(game.snapshot(), phase: .awaitingExchange), on: game,
                           "cards have been played, so the exchange is over")
    }

    func test_restore_withAwaitingPlayForASeatOtherThanCurrentSeat_throwsInconsistentSnapshot() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        try game.performExchange()

        assertInconsistent(edited(game.snapshot(), phase: .awaitingPlay(game.currentSeat.next)), on: game,
                           "the seat to play is currentSeat")
    }

    func test_restore_withAwaitingPlayForASeatThatAlreadyPlayedThisTrick_throwsInconsistentSnapshot() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        try game.performExchange()
        let leader = game.currentSeat
        try game.playCard(try XCTUnwrap(game.selectCardForBotPlay(seat: leader)), by: leader)

        assertInconsistent(edited(game.snapshot(), currentSeat: leader, phase: .awaitingPlay(leader)), on: game,
                           "a seat plays once per trick")
    }

    func test_restore_withAwaitingSettlementButCardsStillHeld_throwsInconsistentSnapshot() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        try game.performExchange()

        assertInconsistent(edited(game.snapshot(), phase: .awaitingSettlement), on: game,
                           "settlement needs every card played")
    }

    func test_restore_withHandCompleteResultDisagreeingWithTotals_throwsInconsistentSnapshot() throws {
        let game = try settledGame()
        var totals = game.totalScores
        totals[.south] += 1

        assertInconsistent(edited(game.snapshot(), totalScores: totals), on: game,
                           "the settled result and the totals must match")
    }

    func test_restore_withGameOverButNobodyAtWinningScore_throwsInconsistentSnapshot() throws {
        let game = try settledGame()

        assertInconsistent(edited(game.snapshot(), phase: .gameOver(winner: .south)), on: game,
                           "the game is not over at these totals")
    }

    func test_restore_withHeartsBrokenDisagreeingWithPlays_throwsInconsistentSnapshot() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        try game.performExchange()
        try game.playCompleteTrick()   // first trick can hold no hearts

        assertInconsistent(edited(game.snapshot(), heartsBroken: true), on: game,
                           "hearts are broken exactly when a heart has been played")
    }

    func test_restore_withEverySnapshotOfARealGame_succeeds() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 9))
        var snapshots: [GameSnapshot] = []
        let spy = DelegateSpy()
        spy.onEvent = { game, event in
            if case .transition = event { snapshots.append(game.snapshot()) }
        }
        game.delegate = spy
        try game.playCompleteGame()

        let replay = Game(using: SeededRandomNumberGenerator(seed: 9))
        for snapshot in snapshots {
            XCTAssertNoThrow(try replay.restore(from: snapshot), "\(snapshot.phase)")
            XCTAssertEqual(replay.snapshot(), snapshot)
        }
    }

    // MARK: - Delegate

    func test_undo_withDelegate_firesRestoreBeforeTransition() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        let spy = DelegateSpy()
        game.delegate = spy
        try game.performExchange()
        spy.reset()

        game.undo()

        XCTAssertEqual(spy.events, [.restore(.awaitingExchange), .transition(.awaitingExchange)])
    }

    func test_restore_withDelegate_firesRestoreBeforeTransition() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        try game.performExchange()
        let snap = game.snapshot()
        try game.playCompleteTrick()
        let spy = DelegateSpy()
        game.delegate = spy

        try game.restore(from: snap)

        XCTAssertEqual(spy.events, [.restore(snap.phase), .transition(snap.phase)])
    }

    func test_restore_whenRejected_notifiesNobody() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        let spy = DelegateSpy()
        game.delegate = spy

        XCTAssertThrowsError(try game.restore(from: edited(game.snapshot(), phase: .awaitingSettlement)))

        XCTAssertEqual(spy.events, [])
    }
}
