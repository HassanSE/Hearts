//
//  TrickTests.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import XCTest
@testable import Hearts

final class TrickTests: XCTestCase {

    // MARK: - Initialization Tests

    func test_init_fresh_isEmpty() {
        let trick = Trick()

        XCTAssertEqual(trick.plays.count, 0)
        XCTAssertEqual(trick.points, 0)
        XCTAssertFalse(trick.isComplete)
        XCTAssertNil(trick.leadSuit)
        XCTAssertNil(trick.winner)
    }

    // MARK: - Lead Suit Tests

    func test_leadSuit_noPlays_isNil() {
        let trick = Trick()

        XCTAssertNil(trick.leadSuit)
    }

    func test_leadSuit_afterFirstPlay_isFirstCardsSuit() throws {
        var trick = Trick()

        try trick.play(Card.fiveOfClubs, by: .south)

        XCTAssertEqual(trick.leadSuit, .clubs)
    }

    // MARK: - Completion Tests

    func test_isComplete_fewerThanFourPlays_isFalse() throws {
        var trick = Trick()
        let cards = [
            Card.twoOfClubs,
            Card.threeOfClubs,
            Card.fourOfClubs
        ]

        for (seat, card) in zip(Seat.allCases, cards) {
            try trick.play(card, by: seat)
            XCTAssertFalse(trick.isComplete)
        }
    }

    func test_isComplete_fourPlays_isTrue() throws {
        let trick = try Trick.mock([
            Card.twoOfClubs,
            Card.threeOfClubs,
            Card.fourOfClubs,
            Card.fiveOfClubs
        ])

        XCTAssertTrue(trick.isComplete)
    }

    // MARK: - Winner Tests

    func test_winner_incomplete_isNil() throws {
        var trick = Trick()

        try trick.play(Card.aceOfClubs, by: .south)

        XCTAssertNil(trick.winner, "Winner should be nil until trick is complete")
    }

    func test_winner_complete_isHighestCardOfLeadSuit() throws {
        let trick = try Trick.mock([
            Card.fiveOfClubs,
            Card.aceOfClubs,   // Highest club — should win
            Card.kingOfHearts, // Different suit
            Card.tenOfClubs
        ])

        XCTAssertEqual(trick.winner, .west, "Seat with highest card of lead suit should win")
    }

    func test_winner_higherOffSuitCard_ignoresIt() throws {
        let trick = try Trick.mock([
            Card.twoOfDiamonds,  // Lead with diamonds
            Card.aceOfHearts,    // Ace but wrong suit
            Card.fiveOfDiamonds, // Should win (highest diamond)
            Card.kingOfSpades    // King but wrong suit
        ])

        XCTAssertEqual(trick.winner, .north, "Only cards of lead suit can win")
    }

    // MARK: - Points Tests

    func test_points_noPointCards_isZero() throws {
        let trick = try Trick.mock([
            Card.twoOfClubs,
            Card.threeOfClubs,
            Card.fourOfClubs,
            Card.fiveOfClubs
        ])

        XCTAssertEqual(trick.points, 0)
    }

    func test_points_counts_hearts() throws {
        let trick = try Trick.mock([
            Card.twoOfClubs,
            Card.threeOfHearts,  // 1 point
            Card.fourOfHearts,   // 1 point
            Card.fiveOfClubs
        ])

        XCTAssertEqual(trick.points, 2, "Should count 2 hearts as 2 points")
    }

    func test_points_queenOfSpades_isThirteen() throws {
        let trick = try Trick.mock([
            Card.twoOfSpades,
            Card.queenOfSpades,  // 13 points
            Card.fourOfSpades,
            Card.fiveOfSpades
        ])

        XCTAssertEqual(trick.points, 13, "Queen of spades should be worth 13 points")
    }

    func test_points_heartsAndQueenOfSpades_sumsBoth() throws {
        let trick = try Trick.mock([
            Card.twoOfHearts,    // 1 point
            Card.queenOfSpades,  // 13 points
            Card.fourOfHearts,   // 1 point
            Card.fiveOfClubs
        ])

        XCTAssertEqual(trick.points, 15, "Should count 2 hearts + Q♠ = 15 points")
    }

    // MARK: - Validation Tests

    func test_play_completeTrick_throws() throws {
        var trick = try Trick.mock([
            Card.twoOfClubs,
            Card.threeOfClubs,
            Card.fourOfClubs,
            Card.fiveOfClubs
        ])

        // A fifth card cannot be played, even by a seat that has not played (impossible in practice)
        XCTAssertThrowsError(try trick.play(Card.sixOfClubs, by: .south)) { error in
            XCTAssertEqual(error as? GameError, GameError.trickAlreadyComplete)
        }
    }

    func test_play_seatAlreadyPlayed_throws() throws {
        var trick = Trick()

        try trick.play(Card.twoOfClubs, by: .south)

        // Same seat tries to play again
        XCTAssertThrowsError(try trick.play(Card.threeOfClubs, by: .south)) { error in
            XCTAssertEqual(error as? GameError, GameError.notPlayersTurn)
        }
    }

    // Trick no longer validates card-in-hand; Game does before calling Trick.
    func test_play_anyCard_doesNotCheckHand() throws {
        var trick = Trick()

        // Trick accepts the play regardless — caller (Game) is responsible for the hand check
        XCTAssertNoThrow(try trick.play(Card.twoOfClubs, by: .south))
    }

    // Trick no longer validates follow-suit; Game does before calling Trick.
    func test_play_offSuit_doesNotEnforceFollowSuit() throws {
        var trick = Trick()

        try trick.play(Card.twoOfClubs, by: .south)

        // Even though west "has clubs", Trick does not enforce follow-suit — Game does.
        XCTAssertNoThrow(try trick.play(Card.aceOfHearts, by: .west))
    }

    // MARK: - Helper Property Tests

    func test_cards_afterPlays_returnsAllInOrder() throws {
        let cards = [
            Card.twoOfClubs,
            Card.threeOfClubs
        ]

        let trick = try Trick.mock(cards)

        XCTAssertEqual(trick.cards, cards)
    }

    func test_seats_afterPlays_returnsAllInOrder() throws {
        var trick = Trick()

        try trick.play(Card.twoOfClubs, by: .east)
        try trick.play(Card.threeOfClubs, by: .south)

        XCTAssertEqual(trick.seats, [.east, .south])
    }

    func test_hasPlayed_seatThatPlayed_isTrue() throws {
        var trick = Trick()

        try trick.play(Card.twoOfClubs, by: .south)

        XCTAssertTrue(trick.hasPlayed(.south))
    }

    func test_hasPlayed_seatThatHasNotPlayed_isFalse() {
        let trick = Trick()

        XCTAssertFalse(trick.hasPlayed(.south))
    }

    // MARK: - Debug Description Tests

    func test_debugDescription_shows_plays() throws {
        var trick = Trick()

        try trick.play(Card.twoOfClubs, by: .south)
        try trick.play(Card.threeOfClubs, by: .west)

        let description = trick.debugDescription

        XCTAssertTrue(description.contains("south"))
        XCTAssertTrue(description.contains("west"))
    }
}
