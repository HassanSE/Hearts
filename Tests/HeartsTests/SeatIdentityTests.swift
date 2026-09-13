//
//  SeatIdentityTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

/// Seats are the engine's identity: plays, delegate payloads, scores and snapshots are all keyed by `Seat`.
final class SeatIdentityTests: XCTestCase {

    private func makeMixedGame() -> Game {
        Game(player1: .bot("Bot"),
             player2: .human("You"),
             player3: .bot("Bot"),
             player4: .human("Also you"),
             using: SeededRandomNumberGenerator(seed: 5))
    }

    // MARK: - Player is an immutable profile

    func test_player_isJustNameAndType_andTwoEqualProfilesAreEqual() {
        XCTAssertEqual(Player.human("Bob"), .human("Bob"))
        XCTAssertNotEqual(Player.human("Bob"), .bot("Bob"))
    }

    // MARK: - Trick plays are recorded by seat

    func test_trick_recordsSeatPerPlay_andWinnerIsASeat() throws {
        var trick = Trick()
        try trick.play(Card.fiveOfClubs, by: .north)
        try trick.play(Card.aceOfClubs, by: .east)
        try trick.play(Card.kingOfHearts, by: .south)
        try trick.play(Card.tenOfClubs, by: .west)

        XCTAssertEqual(trick.plays.map(\.seat), [.north, .east, .south, .west])
        XCTAssertEqual(trick.winner, .east)
        XCTAssertTrue(trick.hasPlayed(.south))
    }

    func test_trick_sameSeatTwice_throwsNotPlayersTurn() throws {
        var trick = Trick()
        try trick.play(Card.fiveOfClubs, by: .north)
        XCTAssertThrowsError(try trick.play(Card.sixOfClubs, by: .north)) { error in
            XCTAssertEqual(error as? GameError, .notPlayersTurn)
        }
    }

    // MARK: - Game state is owned per seat

    func test_game_hands_areLiveAndKeyedBySeat() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))
        try game.performExchange()
        let leader = game.currentSeat
        let card = Card.twoOfClubs
        XCTAssertTrue(game.hands[leader].contains(card))

        try game.playCard(card, by: leader)

        XCTAssertFalse(game.hands[leader].contains(card))
        XCTAssertEqual(game.hands[leader].count, 12)
        XCTAssertEqual(game.currentSeat, leader.next)
    }

    func test_game_leader_isTheOneSeatHoldingTwoOfClubs() throws {
        let game = try Game(player1: Player(name: "A"), player2: Player(name: "B"),
                            player3: Player(name: "C"), player4: Player(name: "D"),
                            hands: [[], [], [Card.twoOfClubs], []])
        XCTAssertEqual(game.leader, .north)
        XCTAssertEqual(game.currentSeat, .north)
    }

    func test_humanSeats_mixedGame_partitionSeatsByType() {
        let game = makeMixedGame()
        XCTAssertEqual(game.humanSeats, [.west, .east])
        XCTAssertEqual(game.botSeats, [.south, .north])
        XCTAssertEqual(Game().humanSeats, [])
    }

    func test_playCard_byWrongSeat_throwsNotPlayersTurn() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 1))
        try game.performExchange()
        let wrongSeat = game.currentSeat.next
        XCTAssertThrowsError(try game.playCard(game.hands[wrongSeat][0], by: wrongSeat)) { error in
            XCTAssertEqual(error as? GameError, .notPlayersTurn)
        }
    }

    // MARK: - Delegate and scores are keyed by seat

    func test_didPlayCard_fullHand_seatsMatchRecordedTricks() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 2))
        let spy = DelegateSpy()
        game.delegate = spy

        try game.playCompleteHand()

        XCTAssertEqual(spy.plays.map(\.seat), game.completedTricks.flatMap { $0.plays.map(\.seat) })
        XCTAssertEqual(spy.completedTricks.map(\.winner), game.completedTricks.compactMap(\.winner))
        XCTAssertEqual(spy.handResults.first?.totalScores, game.totalScores)
        XCTAssertEqual(game.roundScores, SeatMap(repeating: 0))
    }

    func test_endHand_gameOver_reportsWinningSeat() throws {
        let game = Game(configuration: GameConfiguration(winningScore: 30), using: SeededRandomNumberGenerator(seed: 2))
        let spy = DelegateSpy()
        game.delegate = spy

        let winner = try game.playCompleteGame()

        let lowest = game.totalScores.min { $0.value < $1.value }?.seat
        XCTAssertEqual(winner, lowest)
        XCTAssertEqual(game.gameWinner, lowest)
        XCTAssertEqual(spy.gameWinners, [winner], "didEndGame fires once, for the seat with the unique lowest total")
    }

    func test_performExchange_selectionsKeyedBySeat_movesEachSeatsCards() throws {
        let game = makeMixedGame()
        let westPass = Array(game.hands[.west].prefix(3))
        let eastPass = Array(game.hands[.east].prefix(3))

        try game.performExchange(selections: [.west: westPass, .east: eastPass])

        // Round 0 passes left: west → north, east → south
        for card in westPass { XCTAssertTrue(game.hands[.north].contains(card)) }
        for card in eastPass { XCTAssertTrue(game.hands[.south].contains(card)) }
    }

    func test_performExchange_missingHumanSeat_namesTheSeat() {
        let game = makeMixedGame()
        XCTAssertThrowsError(try game.performExchange(selections: [.west: Array(game.hands[.west].prefix(3))])) { error in
            XCTAssertEqual(error as? GameError, .missingPassSelection(seat: .east))
        }
    }

    // MARK: - Snapshots no longer embed hands in plays

    func test_snapshot_encoded_playsCarryOnlySeatAndCard() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 3))
        try game.playCompleteHand()

        let data = try JSONEncoder().encode(game.snapshot())
        let json = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let tricks = try XCTUnwrap(json["completedTricks"] as? [[String: Any]])
        XCTAssertEqual(tricks.count, 13)
        for trick in tricks {
            let plays = try XCTUnwrap(trick["plays"] as? [[String: Any]])
            for play in plays {
                XCTAssertEqual(Set(play.keys), ["seat", "card"])
            }
        }
        // Hands appear exactly once, at the top level, one per seat.
        let hands = try XCTUnwrap(json["hands"] as? [[Any]])
        XCTAssertEqual(hands.count, 4)
        XCTAssertLessThan(data.count, 8_000, "a full-hand snapshot is a few KB once plays stop embedding hands")
    }

    func test_restore_midHand_restoresPerSeatStateAndCurrentSeat() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 4))
        try game.performExchange()
        let before = game.snapshot()
        try game.playCompleteTrick()

        try game.restore(from: before)

        XCTAssertEqual(game.hands, before.hands)
        XCTAssertEqual(game.roundScores, before.roundScores)
        XCTAssertEqual(game.totalScores, before.totalScores)
        XCTAssertEqual(game.currentSeat, before.currentSeat)
        XCTAssertEqual(game.currentSeat, game.leader)
    }
}
