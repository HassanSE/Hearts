//
//  CodableTests.swift
//
//
//  Created by Muhammad Hassan on 12/04/2026.
//

import XCTest
@testable import Hearts

final class CodableTests: XCTestCase {

    // MARK: - Helpers

    private func roundTrip<T: Codable>(_ value: T) throws -> T {
        let encoder = JSONEncoder()
        let data = try encoder.encode(value)
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Card.Rank

    func test_rank_round_trips() throws {
        for rank in Card.Rank.allCases {
            XCTAssertEqual(try roundTrip(rank), rank, "Rank.\(rank) should survive JSON round-trip")
        }
    }

    // MARK: - Card.Suit

    func test_suit_round_trips() throws {
        for suit in Card.Suit.allCases {
            XCTAssertEqual(try roundTrip(suit), suit, "Suit.\(suit) should survive JSON round-trip")
        }
    }

    // MARK: - Card

    func test_card_round_trips() throws {
        let card = Card(suit: .spades, rank: .queen)
        XCTAssertEqual(try roundTrip(card), card)
    }

    func test_card_all_suits_and_ranks_round_trip() throws {
        for suit in Card.Suit.allCases {
            for rank in Card.Rank.allCases {
                let card = Card(suit: suit, rank: rank)
                XCTAssertEqual(try roundTrip(card), card, "\(card) should survive JSON round-trip")
            }
        }
    }

    // MARK: - BotDifficulty

    func test_botDifficulty_round_trips() throws {
        XCTAssertEqual(try roundTrip(BotDifficulty.easy), .easy)
        XCTAssertEqual(try roundTrip(BotDifficulty.medium), .medium)
        XCTAssertEqual(try roundTrip(BotDifficulty.hard), .hard)
    }

    // MARK: - PlayerType

    func test_playerType_human_round_trips() throws {
        let type = PlayerType.human
        XCTAssertEqual(try roundTrip(type), .human)
    }

    func test_playerType_bot_round_trips() throws {
        XCTAssertEqual(try roundTrip(PlayerType.bot(difficulty: .easy)), .bot(difficulty: .easy))
        XCTAssertEqual(try roundTrip(PlayerType.bot(difficulty: .medium)), .bot(difficulty: .medium))
        XCTAssertEqual(try roundTrip(PlayerType.bot(difficulty: .hard)), .bot(difficulty: .hard))
    }

    // MARK: - Player

    func test_player_round_trips() throws {
        let player = Player(name: "Alice", type: .human, hand: [Card(suit: .hearts, rank: .ace)], roundScore: 3, totalScore: 42)
        let decoded = try roundTrip(player)
        XCTAssertEqual(decoded.id, player.id)
        XCTAssertEqual(decoded.name, player.name)
        XCTAssertEqual(decoded.type, player.type)
        XCTAssertEqual(decoded.hand, player.hand)
        XCTAssertEqual(decoded.roundScore, player.roundScore)
        XCTAssertEqual(decoded.totalScore, player.totalScore)
    }

    func test_player_bot_round_trips() throws {
        let player = Player(name: "Watson", type: .bot(difficulty: .hard))
        let decoded = try roundTrip(player)
        XCTAssertEqual(decoded.type, .bot(difficulty: .hard))
    }

    // MARK: - MoonShotVariant

    func test_moonShotVariant_round_trips() throws {
        XCTAssertEqual(try roundTrip(MoonShotVariant.addToOthers), .addToOthers)
        XCTAssertEqual(try roundTrip(MoonShotVariant.subtractFromSelf), .subtractFromSelf)
    }

    // MARK: - GameConfiguration

    func test_gameConfiguration_standard_round_trips() throws {
        let config = GameConfiguration.standard
        let decoded = try roundTrip(config)
        XCTAssertEqual(decoded.jackOfDiamondsBonus, config.jackOfDiamondsBonus)
        XCTAssertEqual(decoded.winningScore, config.winningScore)
        XCTAssertEqual(decoded.moonShotVariant, config.moonShotVariant)
    }

    func test_gameConfiguration_custom_round_trips() throws {
        let config = GameConfiguration(jackOfDiamondsBonus: true, winningScore: 50, moonShotVariant: .subtractFromSelf)
        let decoded = try roundTrip(config)
        XCTAssertEqual(decoded.jackOfDiamondsBonus, true)
        XCTAssertEqual(decoded.winningScore, 50)
        XCTAssertEqual(decoded.moonShotVariant, .subtractFromSelf)
    }

    // MARK: - CardExchangeDirection

    func test_cardExchangeDirection_round_trips() throws {
        XCTAssertEqual(try roundTrip(CardExchangeDirection.left), .left)
        XCTAssertEqual(try roundTrip(CardExchangeDirection.right), .right)
        XCTAssertEqual(try roundTrip(CardExchangeDirection.across), .across)
        XCTAssertEqual(try roundTrip(CardExchangeDirection.none), .none)
    }

    // MARK: - Trick

    func test_empty_trick_round_trips() throws {
        let trick = Trick()
        let encoder = JSONEncoder()
        let data = try encoder.encode(trick)
        let decoded = try JSONDecoder().decode(Trick.self, from: data)
        XCTAssertEqual(decoded.plays.count, 0)
        XCTAssertNil(decoded.leadSuit)
        XCTAssertFalse(decoded.isComplete)
    }

    func test_trick_with_plays_round_trips() throws {
        var trick = Trick()
        let player1 = Player(name: "A")
        let player2 = Player(name: "B")
        try trick.play(Card(suit: .clubs, rank: .two), by: player1)
        try trick.play(Card(suit: .clubs, rank: .ace), by: player2)

        let data = try JSONEncoder().encode(trick)
        let decoded = try JSONDecoder().decode(Trick.self, from: data)

        XCTAssertEqual(decoded.plays.count, 2)
        XCTAssertEqual(decoded.leadSuit, .clubs)
        XCTAssertEqual(decoded.cards, trick.cards)
        XCTAssertEqual(decoded.plays[0].player, player1)
        XCTAssertEqual(decoded.plays[0].card, Card(suit: .clubs, rank: .two))
        XCTAssertEqual(decoded.plays[1].player, player2)
        XCTAssertEqual(decoded.plays[1].card, Card(suit: .clubs, rank: .ace))
    }

    // MARK: - GameSnapshot

    func test_gameSnapshot_round_trips() throws {
        let players = Player.makeBotPlayers()
        let snapshot = GameSnapshot(
            players: players,
            roundNumber: 2,
            currentTrick: Trick(),
            completedTricks: [],
            heartsBroken: true,
            currentPlayerIndex: 1,
            configuration: .withJackBonus,
            hasExchanged: true
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: data)

        XCTAssertEqual(decoded.players.map(\.name), players.map(\.name))
        XCTAssertEqual(decoded.roundNumber, 2)
        XCTAssertEqual(decoded.completedTricks.count, 0)
        XCTAssertEqual(decoded.heartsBroken, true)
        XCTAssertEqual(decoded.currentPlayerIndex, 1)
        XCTAssertEqual(decoded.configuration.jackOfDiamondsBonus, true)
        XCTAssertEqual(decoded.hasExchanged, true)
    }

    func test_gameSnapshot_with_completed_tricks_round_trips() throws {
        let player1 = Player(name: "A")
        let player2 = Player(name: "B")
        let player3 = Player(name: "C")
        let player4 = Player(name: "D")

        var completedTrick = Trick()
        try completedTrick.play(Card(suit: .clubs, rank: .two), by: player1)
        try completedTrick.play(Card(suit: .clubs, rank: .five), by: player2)
        try completedTrick.play(Card(suit: .clubs, rank: .king), by: player3)
        try completedTrick.play(Card(suit: .clubs, rank: .three), by: player4)

        let snapshot = GameSnapshot(
            players: [player1, player2, player3, player4],
            roundNumber: 0,
            currentTrick: Trick(),
            completedTricks: [completedTrick],
            heartsBroken: false,
            currentPlayerIndex: 2,
            configuration: .standard,
            hasExchanged: false
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: data)

        XCTAssertEqual(decoded.completedTricks.count, 1)
        XCTAssertEqual(decoded.completedTricks[0].cards, completedTrick.cards)
        XCTAssertEqual(decoded.completedTricks[0].winner, player3)
    }
}
