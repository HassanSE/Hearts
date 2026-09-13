//
//  TrickTests.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import XCTest
@testable import Hearts

final class TrickTests: XCTestCase {

    /// Plays `cards` into a fresh trick from south clockwise.
    private func makeTrick(_ cards: [Card]) throws -> Trick {
        var trick = Trick()
        for (seat, card) in zip(Seat.allCases, cards) {
            try trick.play(card, by: seat)
        }
        return trick
    }

    // MARK: - Initialization Tests

    func test_init_trick_is_empty() {
        let trick = Trick()

        XCTAssertEqual(trick.plays.count, 0)
        XCTAssertEqual(trick.points, 0)
        XCTAssertFalse(trick.isComplete)
        XCTAssertNil(trick.leadSuit)
        XCTAssertNil(trick.winner)
    }

    // MARK: - Lead Suit Tests

    func test_leadSuit_is_nil_when_no_cards_played() {
        let trick = Trick()

        XCTAssertNil(trick.leadSuit)
    }

    func test_leadSuit_is_suit_of_first_card_played() throws {
        var trick = Trick()

        try trick.play(Card(suit: .clubs, rank: .five), by: .south)

        XCTAssertEqual(trick.leadSuit, .clubs)
    }

    // MARK: - Completion Tests

    func test_isComplete_is_false_with_less_than_4_cards() throws {
        var trick = Trick()
        let cards = [
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .four)
        ]

        for (seat, card) in zip(Seat.allCases, cards) {
            try trick.play(card, by: seat)
            XCTAssertFalse(trick.isComplete)
        }
    }

    func test_isComplete_is_true_with_4_cards() throws {
        let trick = try makeTrick([
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .four),
            Card(suit: .clubs, rank: .five)
        ])

        XCTAssertTrue(trick.isComplete)
    }

    // MARK: - Winner Tests

    func test_winner_is_nil_when_trick_incomplete() throws {
        var trick = Trick()

        try trick.play(Card(suit: .clubs, rank: .ace), by: .south)

        XCTAssertNil(trick.winner, "Winner should be nil until trick is complete")
    }

    func test_winner_is_seat_with_highest_card_of_lead_suit() throws {
        let trick = try makeTrick([
            Card(suit: .clubs, rank: .five),
            Card(suit: .clubs, rank: .ace),   // Highest club — should win
            Card(suit: .hearts, rank: .king), // Different suit
            Card(suit: .clubs, rank: .ten)
        ])

        XCTAssertEqual(trick.winner, .west, "Seat with highest card of lead suit should win")
    }

    func test_winner_ignores_higher_cards_of_non_lead_suit() throws {
        let trick = try makeTrick([
            Card(suit: .diamonds, rank: .two),  // Lead with diamonds
            Card(suit: .hearts, rank: .ace),    // Ace but wrong suit
            Card(suit: .diamonds, rank: .five), // Should win (highest diamond)
            Card(suit: .spades, rank: .king)    // King but wrong suit
        ])

        XCTAssertEqual(trick.winner, .north, "Only cards of lead suit can win")
    }

    // MARK: - Points Tests

    func test_points_is_zero_for_no_point_cards() throws {
        let trick = try makeTrick([
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .four),
            Card(suit: .clubs, rank: .five)
        ])

        XCTAssertEqual(trick.points, 0)
    }

    func test_points_counts_hearts() throws {
        let trick = try makeTrick([
            Card(suit: .clubs, rank: .two),
            Card(suit: .hearts, rank: .three),  // 1 point
            Card(suit: .hearts, rank: .four),   // 1 point
            Card(suit: .clubs, rank: .five)
        ])

        XCTAssertEqual(trick.points, 2, "Should count 2 hearts as 2 points")
    }

    func test_points_counts_queen_of_spades() throws {
        let trick = try makeTrick([
            Card(suit: .spades, rank: .two),
            Card(suit: .spades, rank: .queen),  // 13 points
            Card(suit: .spades, rank: .four),
            Card(suit: .spades, rank: .five)
        ])

        XCTAssertEqual(trick.points, 13, "Queen of spades should be worth 13 points")
    }

    func test_points_counts_hearts_and_queen_of_spades() throws {
        let trick = try makeTrick([
            Card(suit: .hearts, rank: .two),    // 1 point
            Card(suit: .spades, rank: .queen),  // 13 points
            Card(suit: .hearts, rank: .four),   // 1 point
            Card(suit: .clubs, rank: .five)
        ])

        XCTAssertEqual(trick.points, 15, "Should count 2 hearts + Q♠ = 15 points")
    }

    // MARK: - Validation Tests

    func test_play_throws_when_trick_is_complete() throws {
        var trick = try makeTrick([
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .four),
            Card(suit: .clubs, rank: .five)
        ])

        // A fifth card cannot be played, even by a seat that has not played (impossible in practice)
        XCTAssertThrowsError(try trick.play(Card(suit: .clubs, rank: .six), by: .south)) { error in
            XCTAssertEqual(error as? GameError, GameError.trickAlreadyComplete)
        }
    }

    func test_play_throws_when_seat_already_played() throws {
        var trick = Trick()

        try trick.play(Card(suit: .clubs, rank: .two), by: .south)

        // Same seat tries to play again
        XCTAssertThrowsError(try trick.play(Card(suit: .clubs, rank: .three), by: .south)) { error in
            XCTAssertEqual(error as? GameError, GameError.notPlayersTurn)
        }
    }

    // Trick no longer validates card-in-hand; Game does before calling Trick.
    func test_play_does_not_enforce_card_in_hand() throws {
        var trick = Trick()

        // Trick accepts the play regardless — caller (Game) is responsible for the hand check
        XCTAssertNoThrow(try trick.play(Card(suit: .clubs, rank: .two), by: .south))
    }

    // Trick no longer validates follow-suit; Game does before calling Trick.
    func test_play_does_not_enforce_follow_suit() throws {
        var trick = Trick()

        try trick.play(Card(suit: .clubs, rank: .two), by: .south)

        // Even though west "has clubs", Trick does not enforce follow-suit — Game does.
        XCTAssertNoThrow(try trick.play(Card(suit: .hearts, rank: .ace), by: .west))
    }

    // MARK: - Helper Property Tests

    func test_cards_returns_all_played_cards() throws {
        let cards = [
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three)
        ]

        let trick = try makeTrick(cards)

        XCTAssertEqual(trick.cards, cards)
    }

    func test_seats_returns_all_seats_that_played_in_order() throws {
        var trick = Trick()

        try trick.play(Card(suit: .clubs, rank: .two), by: .east)
        try trick.play(Card(suit: .clubs, rank: .three), by: .south)

        XCTAssertEqual(trick.seats, [.east, .south])
    }

    func test_hasPlayed_returns_true_for_seat_that_played() throws {
        var trick = Trick()

        try trick.play(Card(suit: .clubs, rank: .two), by: .south)

        XCTAssertTrue(trick.hasPlayed(.south))
    }

    func test_hasPlayed_returns_false_for_seat_that_has_not_played() {
        let trick = Trick()

        XCTAssertFalse(trick.hasPlayed(.south))
    }

    // MARK: - Debug Description Tests

    func test_debugDescription_shows_plays() throws {
        var trick = Trick()

        try trick.play(Card(suit: .clubs, rank: .two), by: .south)
        try trick.play(Card(suit: .clubs, rank: .three), by: .west)

        let description = trick.debugDescription

        XCTAssertTrue(description.contains("south"))
        XCTAssertTrue(description.contains("west"))
    }
}
