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
        let card = Card.queenOfSpades
        XCTAssertEqual(try roundTrip(card), card)
    }

    func test_card_everySuitAndRank_roundTrips() throws {
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

    func test_playerType_human_roundTrips() throws {
        let type = PlayerType.human
        XCTAssertEqual(try roundTrip(type), .human)
    }

    func test_playerType_bot_roundTrips() throws {
        XCTAssertEqual(try roundTrip(PlayerType.bot(difficulty: .easy)), .bot(difficulty: .easy))
        XCTAssertEqual(try roundTrip(PlayerType.bot(difficulty: .medium)), .bot(difficulty: .medium))
        XCTAssertEqual(try roundTrip(PlayerType.bot(difficulty: .hard)), .bot(difficulty: .hard))
    }

    // MARK: - Player

    func test_player_round_trips() throws {
        let player = Player(name: "Alice", type: .human)
        XCTAssertEqual(try roundTrip(player), player)
    }

    func test_player_bot_roundTrips() throws {
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

    func test_gameConfiguration_standard_roundTrips() throws {
        let config = GameConfiguration.standard
        let decoded = try roundTrip(config)
        XCTAssertEqual(decoded.jackOfDiamondsBonus, config.jackOfDiamondsBonus)
        XCTAssertEqual(decoded.winningScore, config.winningScore)
        XCTAssertEqual(decoded.moonShotVariant, config.moonShotVariant)
    }

    func test_gameConfiguration_custom_roundTrips() throws {
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

    func test_trick_empty_roundTrips() throws {
        let trick = Trick()
        let encoder = JSONEncoder()
        let data = try encoder.encode(trick)
        let decoded = try JSONDecoder().decode(Trick.self, from: data)
        XCTAssertEqual(decoded.plays.count, 0)
        XCTAssertNil(decoded.leadSuit)
        XCTAssertFalse(decoded.isComplete)
    }

    func test_trick_withPlays_roundTrips() throws {
        var trick = Trick()
        try trick.play(Card.twoOfClubs, by: .east)
        try trick.play(Card.aceOfClubs, by: .south)

        let data = try JSONEncoder().encode(trick)
        let decoded = try JSONDecoder().decode(Trick.self, from: data)

        XCTAssertEqual(decoded, trick)
        XCTAssertEqual(decoded.leadSuit, .clubs)
        XCTAssertEqual(decoded.plays[0].seat, .east)
        XCTAssertEqual(decoded.plays[0].card, Card.twoOfClubs)
        XCTAssertEqual(decoded.plays[1].seat, .south)
        XCTAssertEqual(decoded.plays[1].card, Card.aceOfClubs)
    }

    // MARK: - HandResult

    func test_handResult_round_trips() throws {
        let result = HandResult(roundScores: [26, 0, 26, 26], totalScores: [30, 5, 40, 50], moonShooter: .west)
        XCTAssertEqual(try roundTrip(result), result)
    }

    // MARK: - GameSnapshot

    func test_gameSnapshot_round_trips() throws {
        let players = Player.makeBotPlayers()
        let snapshot = GameSnapshot(
            players: SeatMap { players[$0.rawValue] },
            hands: [[Card.aceOfHearts], [], [Card.twoOfClubs], []],
            roundScores: [1, 0, 0, 0],
            totalScores: [10, 20, 30, 40],
            roundNumber: 2,
            currentTrick: Trick(),
            completedTricks: [],
            heartsBroken: true,
            currentSeat: .west,
            configuration: .withJackBonus,
            phase: .awaitingPlay(.west)
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: data)

        XCTAssertEqual(decoded.players, snapshot.players)
        XCTAssertEqual(decoded.hands, snapshot.hands)
        XCTAssertEqual(decoded.roundScores, snapshot.roundScores)
        XCTAssertEqual(decoded.totalScores, snapshot.totalScores)
        XCTAssertEqual(decoded.roundNumber, 2)
        XCTAssertEqual(decoded.completedTricks.count, 0)
        XCTAssertEqual(decoded.heartsBroken, true)
        XCTAssertEqual(decoded.currentSeat, .west)
        XCTAssertEqual(decoded.configuration.jackOfDiamondsBonus, true)
        XCTAssertEqual(decoded.phase, .awaitingPlay(.west))
    }

    func test_gameSnapshot_withCompletedTricks_roundTrips() throws {
        var completedTrick = Trick()
        try completedTrick.play(Card.twoOfClubs, by: .south)
        try completedTrick.play(Card.fiveOfClubs, by: .west)
        try completedTrick.play(Card.kingOfClubs, by: .north)
        try completedTrick.play(Card.threeOfClubs, by: .east)

        let snapshot = GameSnapshot(
            players: SeatMap { Player(name: "\($0)") },
            hands: SeatMap(repeating: []),
            roundScores: SeatMap(repeating: 0),
            totalScores: SeatMap(repeating: 0),
            roundNumber: 0,
            currentTrick: Trick(),
            completedTricks: [completedTrick],
            heartsBroken: false,
            currentSeat: .north,
            configuration: .standard,
            phase: .awaitingExchange
        )

        let data = try JSONEncoder().encode(snapshot)
        let decoded = try JSONDecoder().decode(GameSnapshot.self, from: data)

        XCTAssertEqual(decoded.completedTricks, [completedTrick])
        XCTAssertEqual(decoded.completedTricks[0].winner, .north)
    }
}
