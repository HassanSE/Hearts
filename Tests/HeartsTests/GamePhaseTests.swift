//
//  GamePhaseTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

final class GamePhaseTests: XCTestCase {

    // MARK: - Fixtures

    private final class PhaseSpy: GameEngineDelegate {
        var phases: [GamePhase] = []
        var handResults: [HandResult] = []
        var trickCount = 0
        var phaseAtLastTrick: GamePhase?
        func game(_ game: Game, didTransitionTo phase: GamePhase) { phases.append(phase) }
        func game(_ game: Game, didEndHand result: HandResult) { handResults.append(result) }
        func game(_ game: Game, didCompleteTrick trick: Trick, winner: Seat, points: Int) {
            trickCount += 1
            phaseAtLastTrick = game.phase
        }
    }

    private func botGame(seed: UInt64 = 1, winningScore: Int = 100) -> Game {
        Game(configuration: GameConfiguration(winningScore: winningScore),
             using: SeededRandomNumberGenerator(seed: seed))
    }

    private func mixedGame(seed: UInt64 = 1, winningScore: Int = 100) -> Game {
        let human = Player(name: "You", type: .human)
        let bots = (1...3).map { Player(name: "Bot\($0)", type: .bot(difficulty: .easy)) }
        return Game(player1: human, player2: bots[0], player3: bots[1], player4: bots[2],
                    configuration: GameConfiguration(winningScore: winningScore),
                    using: SeededRandomNumberGenerator(seed: seed))
    }

    private enum PhaseCase: CaseIterable {
        case awaitingExchange, awaitingPlay, awaitingSettlement, handComplete, gameOver
    }

    /// An all-bot game driven by real play into the requested phase.
    private func botGame(in phaseCase: PhaseCase) throws -> Game {
        let game = botGame(seed: 7, winningScore: phaseCase == .gameOver ? 1 : 100)
        switch phaseCase {
        case .awaitingExchange:
            break
        case .awaitingPlay:
            try game.performExchange()
        case .awaitingSettlement:
            try game.performExchange()
            for _ in 0..<13 { try game.playCompleteTrick() }
        case .handComplete:
            try game.performExchange()
            for _ in 0..<13 { try game.playCompleteTrick() }
            try game.endHand()
        case .gameOver:
            try game.playCompleteGame()
        }
        return game
    }

    // MARK: - Transitions

    func test_phase_afterInit_isAwaitingExchange() {
        XCTAssertEqual(botGame().phase, .awaitingExchange)
        XCTAssertEqual(mixedGame().phase, .awaitingExchange)
        XCTAssertFalse(botGame().isHandComplete)
    }

    func test_performExchange_movesToAwaitingPlayForTheTwoOfClubsHolder() throws {
        let game = botGame()
        try game.performExchange()
        XCTAssertEqual(game.phase, .awaitingPlay(game.currentSeat))
        XCTAssertEqual(game.currentSeat, game.leader)
    }

    func test_playCard_advancesAwaitingPlayToTheNextSeat() throws {
        let game = botGame()
        try game.performExchange()
        let seat = game.currentSeat
        let card = try XCTUnwrap(game.legalMoves(for: seat).first)
        try game.playCard(card, by: seat)
        XCTAssertEqual(game.phase, .awaitingPlay(seat.next))
    }

    func test_playCard_lastCardOfHand_movesToAwaitingSettlement() throws {
        let game = try botGame(in: .awaitingSettlement)
        XCTAssertEqual(game.phase, .awaitingSettlement)
        XCTAssertTrue(game.isHandComplete)
        XCTAssertEqual(game.completedTricks.count, 13)
        XCTAssertEqual(game.roundNumber, 0, "settlement has not happened yet")
    }

    func test_playCard_onPartialDeal_movesToAwaitingSettlementWhenHandsAreEmpty() throws {
        let players = (0..<4).map { Player(name: "P\($0)") }
        let game = try Game(player1: players[0], player2: players[1], player3: players[2], player4: players[3], hands: [
            [Card(suit: .clubs, rank: .two)], [Card(suit: .clubs, rank: .three)],
            [Card(suit: .clubs, rank: .four)], [Card(suit: .clubs, rank: .five)]
        ])
        game.phase = .awaitingPlay(.south)

        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        try game.playCard(Card(suit: .clubs, rank: .three), by: .west)
        try game.playCard(Card(suit: .clubs, rank: .four), by: .north)
        XCTAssertEqual(game.phase, .awaitingPlay(.east))
        try game.playCard(Card(suit: .clubs, rank: .five), by: .east)

        XCTAssertEqual(game.phase, .awaitingSettlement)
        XCTAssertTrue(game.isHandComplete)
    }

    func test_endHand_movesToHandCompleteCarryingTheResult() throws {
        let game = try botGame(in: .awaitingSettlement)
        let result = try game.endHand()
        XCTAssertEqual(game.phase, .handComplete(result))
        XCTAssertEqual(game.roundNumber, 1)
    }

    func test_endHand_whenWinnerEmerges_movesToGameOver() throws {
        let game = try botGame(in: .gameOver)
        XCTAssertEqual(game.phase, .gameOver(winner: try XCTUnwrap(game.gameWinner)))
        XCTAssertTrue(game.isHandComplete)
    }

    func test_endHand_whenTied_movesToHandCompleteSoAnotherHandIsPlayed() throws {
        let game = try botGame(in: .awaitingSettlement)
        // Arrange totals so every seat lands on exactly the winning score: over, but tied.
        let captured = SeatMap<[Card]> { seat in game.completedTricks.filter { $0.winner == seat }.flatMap(\.cards) }
        let rounds = game.scoring.settleHand(capturedCards: captured, totalScores: SeatMap(repeating: 0)).roundScores
        game.totalScores = SeatMap { 100 - rounds[$0] }

        let result = try game.endHand()

        XCTAssertEqual(game.totalScores, SeatMap(repeating: 100))
        XCTAssertTrue(game.isGameTied)
        XCTAssertEqual(game.phase, .handComplete(result))
    }

    func test_startNewHand_movesToAwaitingExchangeWithAFreshDeal() throws {
        let game = try botGame(in: .handComplete)
        try game.startNewHand()
        XCTAssertEqual(game.phase, .awaitingExchange)
        XCTAssertEqual(game.hands.mapValues(\.count), [13, 13, 13, 13])
        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertFalse(game.isHandComplete)
    }

    // MARK: - Wrong-phase rejection (phase × mutator)

    func test_everyMutator_inEveryOtherPhase_throwsWrongPhase() throws {
        typealias Mutator = (name: String, run: (Game) throws -> Void, accepted: PhaseCase)
        let mutators: [Mutator] = [
            ("performExchange", { try $0.performExchange() }, .awaitingExchange),
            ("playCard", { game in
                let card = game.hands[game.currentSeat].first ?? Card(suit: .clubs, rank: .two)
                try game.playCard(card, by: game.currentSeat)
            }, .awaitingPlay),
            ("endHand", { try $0.endHand() }, .awaitingSettlement),
            ("startNewHand", { try $0.startNewHand() }, .handComplete),
            ("playCompleteTrick", { try $0.playCompleteTrick() }, .awaitingPlay),
        ]

        for phaseCase in PhaseCase.allCases {
            for mutator in mutators where mutator.accepted != phaseCase {
                let game = try botGame(in: phaseCase)
                let before = game.snapshot()
                XCTAssertThrowsError(try mutator.run(game), "\(mutator.name) in \(phaseCase)") { error in
                    XCTAssertEqual(error as? GameError, .wrongPhase(before.phase), "\(mutator.name) in \(phaseCase)")
                }
                XCTAssertEqual(game.phase, before.phase, "\(mutator.name) must not change the phase")
                XCTAssertEqual(game.hands, before.hands, "\(mutator.name) must not touch hands")
                XCTAssertEqual(game.totalScores, before.totalScores, "\(mutator.name) must not touch totals")
            }
        }
    }

    func test_playCard_checksPhaseBeforeTurnAndCard() throws {
        let game = botGame()
        let wrongSeat = game.currentSeat.next
        XCTAssertThrowsError(try game.playCard(Card(suit: .diamonds, rank: .ace), by: wrongSeat)) { error in
            XCTAssertEqual(error as? GameError, .wrongPhase(.awaitingExchange))
        }
    }

    func test_playCompleteHand_afterSettlement_throwsWrongPhase() throws {
        let game = try botGame(in: .handComplete)
        XCTAssertThrowsError(try game.playCompleteHand()) { error in
            XCTAssertEqual(error as? GameError, .wrongPhase(game.phase))
        }
    }

    // MARK: - advance()

    func test_advance_allBotGame_runsToGameOver() throws {
        let game = botGame(winningScore: 50)
        try game.advance()
        guard case .gameOver(let winner) = game.phase else {
            return XCTFail("expected gameOver, got \(game.phase)")
        }
        XCTAssertEqual(winner, game.gameWinner)
        XCTAssertGreaterThan(game.roundNumber, 1, "a 50-point game takes several hands")
    }

    func test_advance_whenGameOver_isANoop() throws {
        let game = try botGame(in: .gameOver)
        let before = game.snapshot()
        try game.advance()
        XCTAssertEqual(game.phase, before.phase)
        XCTAssertEqual(game.roundNumber, before.roundNumber)
    }

    func test_advance_mixedGame_stopsAtTheHumanExchange() throws {
        let game = mixedGame()
        try game.advance()
        XCTAssertEqual(game.phase, .awaitingExchange)
        XCTAssertEqual(game.hands.mapValues(\.count), [13, 13, 13, 13], "nothing moved without the human's choice")
    }

    func test_advance_mixedGame_performsANoPassExchangeItself() throws {
        let game = mixedGame()
        game.roundNumber = 3  // pass direction .none
        XCTAssertEqual(game.exchangeDirection, .none)

        try game.advance()

        guard case .awaitingPlay(let seat) = game.phase else {
            return XCTFail("expected awaitingPlay, got \(game.phase)")
        }
        XCTAssertEqual(seat, .south, "stopped at the human's turn")
        XCTAssertTrue(game.players[seat].type.isHuman)
    }

    func test_advance_mixedGame_playsBotsUntilTheHumanMustPlay() throws {
        let game = mixedGame()
        try game.performExchange(selections: [.south: Array(game.hands[.south].prefix(3))])

        try game.advance()

        XCTAssertEqual(game.phase, .awaitingPlay(.south))
        // Every bot before the human in this trick has played; the human has not.
        XCTAssertEqual(game.hands[.south].count, 13)
        XCTAssertTrue(game.currentTrick.plays.allSatisfy { $0.seat != .south })
    }

    func test_advance_mixedGame_afterHumanPlays_finishesTrickAndSettlesHandsWithoutHelp() throws {
        let game = mixedGame(winningScore: 1)
        let spy = PhaseSpy()
        game.delegate = spy

        while true {
            try game.advance()
            switch game.phase {
            case .awaitingExchange:
                try game.performExchange(selections: [.south: Array(game.hands[.south].prefix(3))])
            case .awaitingPlay(let seat):
                XCTAssertEqual(seat, .south)
                try game.playCard(try XCTUnwrap(game.legalMoves(for: seat).first), by: seat)
            case .gameOver:
                XCTAssertEqual(spy.handResults.count, game.roundNumber)
                XCTAssertEqual(spy.trickCount, 13 * game.roundNumber)
                return
            case .awaitingSettlement, .handComplete:
                XCTFail("advance() must not stop at \(game.phase)")
                return
            }
        }
    }

    // MARK: - Scripted human, full game

    func test_mixedGame_scriptedHuman_playsToGameOverThroughThePhaseLoop() throws {
        let game = mixedGame(seed: 11, winningScore: 40)
        var humanPlays = 0
        var humanPasses = 0

        while true {
            try game.advance()
            switch game.phase {
            case .awaitingExchange:
                XCTAssertNotEqual(game.exchangeDirection, .none)
                // Script: pass the three highest cards.
                let pass = Array(game.hands[.south].sorted().suffix(3))
                try game.performExchange(selections: [.south: pass])
                humanPasses += 1
            case .awaitingPlay(let seat):
                XCTAssertEqual(seat, .south)
                // Script: play the lowest legal card.
                let card = try XCTUnwrap(game.legalMoves(for: .south).min())
                try game.playCard(card, by: .south)
                humanPlays += 1
            case .gameOver(let winner):
                XCTAssertEqual(winner, game.gameWinner)
                XCTAssertTrue(game.isGameOver)
                XCTAssertFalse(game.isGameTied)
                XCTAssertEqual(humanPlays, 13 * game.roundNumber, "the human plays every trick of every hand")
                XCTAssertEqual(humanPasses, (0..<game.roundNumber).filter { $0 % 4 != 3 }.count,
                               "one selection per hand that has a pass direction")
                return
            case .awaitingSettlement, .handComplete:
                XCTFail("advance() must not stop at \(game.phase)")
                return
            }
        }
    }

    func test_playCompleteHand_mixedGame_throwsHumanInputRequired() throws {
        let game = mixedGame()
        XCTAssertThrowsError(try game.playCompleteHand()) { error in
            XCTAssertEqual(error as? GameError, .humanInputRequired(seat: .south))
        }
        XCTAssertEqual(game.phase, .awaitingExchange)

        try game.performExchange(selections: [.south: Array(game.hands[.south].prefix(3))])
        XCTAssertThrowsError(try game.playCompleteGame()) { error in
            XCTAssertEqual(error as? GameError, .humanInputRequired(seat: .south))
        }
        XCTAssertEqual(game.phase, .awaitingPlay(.south))
    }

    // MARK: - Delegate

    func test_delegate_receivesEveryTransitionOfAHand() throws {
        let game = botGame()
        let spy = PhaseSpy()
        game.delegate = spy

        try game.playCompleteHand()

        XCTAssertEqual(spy.phases.count, 1 + 52 + 1)
        XCTAssertEqual(spy.phases.first, .awaitingPlay(game.completedTricks[0].plays[0].seat))
        XCTAssertEqual(spy.phases[52], .awaitingSettlement)
        XCTAssertEqual(spy.phases.last, .handComplete(try XCTUnwrap(spy.handResults.first)))
        XCTAssertEqual(spy.phases.last, game.phase)
    }

    func test_delegate_didTransitionTo_firesAfterTheEventThatCausedIt() throws {
        let game = botGame()
        let spy = PhaseSpy()
        game.delegate = spy
        try game.performExchange()

        try game.playCompleteTrick()

        let closingSeat = game.completedTricks[0].plays[3].seat
        XCTAssertEqual(spy.phaseAtLastTrick, .awaitingPlay(closingSeat),
                       "didCompleteTrick still sees the phase of the play that closed the trick")
        XCTAssertEqual(spy.phases.last, .awaitingPlay(game.currentSeat))
    }

    func test_delegate_receivesTransitionOnUndoAndRestore() throws {
        let game = botGame()
        try game.performExchange()
        let snap = game.snapshot()
        try game.playCompleteTrick()
        let spy = PhaseSpy()
        game.delegate = spy

        game.undo()
        XCTAssertEqual(spy.phases, [.awaitingPlay(game.currentSeat)])

        try game.restore(from: snap)
        XCTAssertEqual(spy.phases.last, snap.phase)
        XCTAssertEqual(game.phase, snap.phase)
    }

    // MARK: - Snapshot / undo

    func test_snapshot_carriesThePhaseAndRestoreReappliesIt() throws {
        let game = try botGame(in: .handComplete)
        let snap = game.snapshot()
        XCTAssertEqual(snap.phase, game.phase)

        try game.startNewHand()
        XCTAssertEqual(game.phase, .awaitingExchange)

        try game.restore(from: snap)
        XCTAssertEqual(game.phase, snap.phase)
        XCTAssertTrue(game.isHandComplete)
    }

    func test_undo_afterEndHand_restoresThePreSettlementState() throws {
        let game = try botGame(in: .awaitingSettlement)
        let totalsBefore = game.totalScores
        let roundScoresBefore = game.roundScores
        try game.endHand()
        XCTAssertNotEqual(game.totalScores, totalsBefore)

        game.undo()

        XCTAssertEqual(game.phase, .awaitingSettlement)
        XCTAssertEqual(game.roundNumber, 0)
        XCTAssertEqual(game.totalScores, totalsBefore)
        XCTAssertEqual(game.roundScores, roundScoresBefore)
        XCTAssertEqual(try game.endHand().totalScores, game.totalScores, "settlement can be redone")
    }

    func test_legalMoves_isEmptyOutsideAwaitingPlay() throws {
        let game = botGame()
        XCTAssertEqual(game.legalMoves(for: game.currentSeat), [])
        try game.performExchange()
        XCTAssertFalse(game.legalMoves(for: game.currentSeat).isEmpty)
        for _ in 0..<13 { try game.playCompleteTrick() }
        XCTAssertEqual(game.legalMoves(for: game.currentSeat), [])
    }
}
