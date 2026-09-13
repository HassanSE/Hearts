//
//  CardExchangeTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

final class CardExchangeTests: XCTestCase {

    // MARK: - Fixtures

    /// One full suit per seat: clubs, diamonds, hearts, spades.
    private func suitHands() -> [[Card]] {
        [Card.Suit.clubs, .diamonds, .hearts, .spades].map { suit in
            Card.Rank.allCases.map { Card(suit: suit, rank: $0) }
        }
    }

    /// Builds a game with the given seat types, dealing each seat a full suit so the cards it holds are known.
    private func makeGame(types: [PlayerType]) -> Game {
        let players = types.enumerated().map { Player(name: "P\($0.offset)", type: $0.element) }
        // Four distinct full suits are a valid deal by construction.
        return try! Game(player1: players[0], player2: players[1], player3: players[2], player4: players[3],
                         hands: suitHands())
    }

    private func cards(_ suit: Card.Suit, _ ranks: Card.Rank...) -> [Card] {
        ranks.map { Card(suit: suit, rank: $0) }
    }

    /// The full suit dealt to `seat` by `suitHands()`.
    private func dealtSuit(of seat: Seat) -> Card.Suit {
        [Card.Suit.clubs, .diamonds, .hearts, .spades][seat.rawValue]
    }

    // MARK: - performExchange(selections:)

    func test_performExchange_withTwoHumans_deliversEachSelectionToTheLeftNeighbour() throws {
        let game = makeGame(types: [.human, .human, .bot(difficulty: .easy), .bot(difficulty: .easy)])
        let seat0Pass = cards(.clubs, .ace, .king, .queen)
        let seat1Pass = cards(.diamonds, .two, .three, .four)

        // roundNumber 0 → pass left (seat i → seat i+1)
        try game.performExchange(selections: [.south: seat0Pass, .west: seat1Pass])

        for card in seat0Pass {
            XCTAssertFalse(game.hands[.south].contains(card))
            XCTAssertTrue(game.hands[.west].contains(card))
        }
        for card in seat1Pass {
            XCTAssertFalse(game.hands[.west].contains(card))
            XCTAssertTrue(game.hands[.north].contains(card))
        }
        XCTAssertEqual(game.hands.mapValues(\.count), [13, 13, 13, 13])
        // Bots passed too: seat 3 received three spades-holder cards from seat 2 (hearts), seat 0 from seat 3 (spades)
        XCTAssertEqual(game.hands[.east].filter { $0.suit == .hearts }.count, 3)
        XCTAssertEqual(game.hands[.south].filter { $0.suit == .spades }.count, 3)
    }

    // MARK: - Validation

    private func assertExchangeThrows(
        _ expected: GameError,
        types: [PlayerType] = [.human, .bot(difficulty: .easy), .bot(difficulty: .easy), .bot(difficulty: .easy)],
        selections: [Seat: [Card]],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let game = makeGame(types: types)
        let handsBefore = game.hands

        XCTAssertThrowsError(try game.performExchange(selections: selections), file: file, line: line) { error in
            XCTAssertEqual(error as? GameError, expected, file: file, line: line)
        }
        XCTAssertEqual(game.hands, handsBefore, "Failed exchange must not touch any hand", file: file, line: line)
        XCTAssertFalse(game.canUndo, "Failed exchange must not push undo history", file: file, line: line)
    }

    func test_performExchange_withTwoCards_throwsWrongPassCount() {
        assertExchangeThrows(.wrongPassCount(seat: .south, count: 2), selections: [.south: cards(.clubs, .ace, .king)])
    }

    func test_performExchange_withFourCards_throwsWrongPassCount() {
        assertExchangeThrows(.wrongPassCount(seat: .south, count: 4), selections: [.south: cards(.clubs, .ace, .king, .queen, .jack)])
    }

    func test_performExchange_withDuplicateCard_throwsDuplicatePassCards() {
        assertExchangeThrows(.duplicatePassCards(seat: .south), selections: [.south: cards(.clubs, .ace, .king, .ace)])
    }

    func test_performExchange_withCardNotHeld_throwsPassedCardNotInHand() {
        let stranger = Card(suit: .hearts, rank: .ace)
        assertExchangeThrows(
            .passedCardNotInHand(seat: .south, card: stranger),
            selections: [.south: [Card(suit: .clubs, rank: .ace), stranger, Card(suit: .clubs, rank: .king)]]
        )
    }

    func test_performExchange_withHumanSeatMissing_throwsMissingPassSelection() {
        assertExchangeThrows(
            .missingPassSelection(seat: .west),
            types: [.human, .human, .bot(difficulty: .easy), .bot(difficulty: .easy)],
            selections: [.south: cards(.clubs, .ace, .king, .queen)]
        )
    }

    func test_performExchange_withBadBotSelection_throwsForThatSeat() {
        // A caller may override a bot's choice, but it is validated like any other seat.
        assertExchangeThrows(
            .passedCardNotInHand(seat: .west, card: Card(suit: .clubs, rank: .two)),
            selections: [.south: cards(.clubs, .ace, .king, .queen), .west: cards(.clubs, .two, .three, .four)]
        )
    }

    // MARK: - Phase guards

    func test_performExchange_calledTwice_throwsExchangeAlreadyPerformed() throws {
        let game = makeGame(types: [.human, .bot(difficulty: .easy), .bot(difficulty: .easy), .bot(difficulty: .easy)])
        try game.performExchange(selections: [.south: cards(.clubs, .ace, .king, .queen)])
        let handsAfterFirst = game.hands

        XCTAssertThrowsError(try game.performExchange(selections: [.south: cards(.clubs, .two, .three, .four)])) { error in
            XCTAssertEqual(error as? GameError, .exchangeAlreadyPerformed)
        }
        XCTAssertEqual(game.hands, handsAfterFirst)
    }

    func test_performExchange_afterCardPlayed_throwsExchangeNotAllowedAfterPlay() throws {
        let game = makeGame(types: [.human, .bot(difficulty: .easy), .bot(difficulty: .easy), .bot(difficulty: .easy)])
        game.currentSeat = .south
        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)

        XCTAssertThrowsError(try game.performExchange(selections: [.south: cards(.clubs, .ace, .king, .queen)])) { error in
            XCTAssertEqual(error as? GameError, .exchangeNotAllowedAfterPlay)
        }
    }

    // MARK: - No-pass round

    func test_performExchange_onNoPassRound_ignoresSelectionsAndMarksExchangeDone() throws {
        let game = makeGame(types: [.human, .bot(difficulty: .easy), .bot(difficulty: .easy), .bot(difficulty: .easy)])
        game.roundNumber = 3
        XCTAssertEqual(game.exchangeDirection, .none)
        let handsBefore = game.hands

        // Bad selections are irrelevant when nothing is passed.
        try game.performExchange(selections: [.south: []])

        XCTAssertEqual(game.hands, handsBefore)
        XCTAssertThrowsError(try game.performExchange()) { error in
            XCTAssertEqual(error as? GameError, .exchangeAlreadyPerformed)
        }
    }

    // MARK: - Mixed seat types

    func test_performExchange_withFourHumans_passesAcross() throws {
        let game = makeGame(types: [.human, .human, .human, .human])
        game.roundNumber = 2  // across: seat i → seat i+2
        let selections: [Seat: [Card]] = [
            .south: cards(.clubs, .ace, .king, .queen),
            .west: cards(.diamonds, .ace, .king, .queen),
            .north: cards(.hearts, .ace, .king, .queen),
            .east: cards(.spades, .ace, .king, .queen)
        ]

        try game.performExchange(selections: selections)

        for (seat, passed) in selections {
            let recipient = seat.advanced(by: 2)
            for card in passed {
                XCTAssertFalse(game.hands[seat].contains(card))
                XCTAssertTrue(game.hands[recipient].contains(card))
            }
            XCTAssertEqual(game.hands[seat].count, 13)
        }
    }

    func test_performExchange_withAllBots_needsNoSelections() throws {
        let game = makeGame(types: Array(repeating: .bot(difficulty: .easy), count: 4))
        game.roundNumber = 1  // right: seat i → seat i+3

        try game.performExchange()

        for seat in Seat.allCases {
            XCTAssertEqual(game.hands[seat].count, 13)
            let received = game.hands[seat.advanced(by: 3)].filter { $0.suit == dealtSuit(of: seat) }
            XCTAssertEqual(received.count, 3, "seat \(seat) should have passed 3 cards to its right")
        }
    }

    func test_performExchange_movesTwoOfClubs_updatesCurrentPlayer() throws {
        let game = makeGame(types: [.human, .bot(difficulty: .easy), .bot(difficulty: .easy), .bot(difficulty: .easy)])

        try game.performExchange(selections: [.south: cards(.clubs, .two, .three, .four)])

        XCTAssertEqual(game.currentSeat, .west)
    }

    // MARK: - CardExchangeDirection

    func test_recipient_forEachDirection_matchesSeatOffsets() {
        XCTAssertEqual(CardExchangeDirection.left.recipient(of: .east), .south)
        XCTAssertEqual(CardExchangeDirection.right.recipient(of: .south), .east)
        XCTAssertEqual(CardExchangeDirection.across.recipient(of: .west), .east)
        XCTAssertNil(CardExchangeDirection.none.recipient(of: .south))
    }
}
