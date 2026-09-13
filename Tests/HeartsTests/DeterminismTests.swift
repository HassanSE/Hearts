//
//  DeterminismTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

/// Covers the randomness seam: seeded deals, fixed deals and the random strategy.
final class DeterminismTests: XCTestCase {

    // MARK: - Seeded deals

    func test_init_withSameSeed_dealsIdenticalHands() {
        let first = Game(using: SeededRandomNumberGenerator(seed: 42))
        let second = Game(using: SeededRandomNumberGenerator(seed: 42))

        XCTAssertEqual(first.hands, second.hands)
        XCTAssertEqual(first.currentSeat, second.currentSeat)
    }

    func test_init_withDifferentSeeds_dealsDifferentHands() {
        let first = Game(using: SeededRandomNumberGenerator(seed: 1))
        let second = Game(using: SeededRandomNumberGenerator(seed: 2))

        XCTAssertNotEqual(first.hands, second.hands)
    }

    // MARK: - Seeded full games

    /// Easy bots use `RandomAIStrategy`, so this only holds if the strategy draws from the game's generator.
    private func makeEasyBotGame(seed: UInt64) -> Game {
        let bots = Player.makeBotPlayers(difficulty: .easy)
        return Game(player1: bots[0], player2: bots[1], player3: bots[2], player4: bots[3],
                    configuration: GameConfiguration(jackOfDiamondsBonus: true, winningScore: 50),
                    using: SeededRandomNumberGenerator(seed: seed))
    }

    func test_playCompleteGame_withSameSeedAndRandomBots_producesIdenticalOutcome() throws {
        let first = makeEasyBotGame(seed: 7)
        let second = makeEasyBotGame(seed: 7)

        let firstWinner = try first.playCompleteGame()
        let secondWinner = try second.playCompleteGame()

        XCTAssertEqual(first.totalScores, second.totalScores)
        XCTAssertEqual(first.roundNumber, second.roundNumber)
        XCTAssertEqual(first.completedTricks, second.completedTricks)
        XCTAssertEqual(firstWinner, secondWinner)
    }

    // MARK: - Random strategy

    func test_randomAIStrategy_withSameSeed_makesIdenticalChoices() {
        let hand = Deck().cards.prefix(13).map { $0 }
        let context = TrickContext(hand: hand, currentTrick: Trick(), heartsBroken: true,
                                   isFirstTrick: false, completedTricks: [])

        let first = RandomAIStrategy(randomSource: RandomSource(SeededRandomNumberGenerator(seed: 9)))
        let second = RandomAIStrategy(randomSource: RandomSource(SeededRandomNumberGenerator(seed: 9)))

        let firstPlays = (0..<10).map { _ in first.selectCardToPlay(context: context) }
        let secondPlays = (0..<10).map { _ in second.selectCardToPlay(context: context) }
        XCTAssertEqual(firstPlays, secondPlays)

        let firstPass = first.selectCardsToPass(from: hand, direction: .left)
        let secondPass = second.selectCardsToPass(from: hand, direction: .left)
        XCTAssertEqual([firstPass.first, firstPass.second, firstPass.third],
                       [secondPass.first, secondPass.second, secondPass.third])
    }

    // MARK: - Fixed deals

    private let fourPlayers = [Player(name: "A"), Player(name: "B"), Player(name: "C"), Player(name: "D")]

    private func makeFixedDealGame(hands: [[Card]]) throws -> Game {
        try Game(player1: fourPlayers[0], player2: fourPlayers[1], player3: fourPlayers[2], player4: fourPlayers[3],
                 hands: hands)
    }

    func test_init_withFixedHands_dealsExactlyThoseHandsAndSeatsTwoOfClubsHolderAsLeader() throws {
        let hands: [[Card]] = [
            [Card(suit: .diamonds, rank: .four)],
            [Card(suit: .clubs, rank: .two), Card(suit: .hearts, rank: .six)],
            [Card(suit: .clubs, rank: .eight)],
            [Card(suit: .spades, rank: .queen)]
        ]

        let game = try makeFixedDealGame(hands: hands)

        XCTAssertEqual(game.hands.values, hands)
        XCTAssertEqual(game.currentSeat, .west)
        XCTAssertTrue(game.completedTricks.isEmpty)
        XCTAssertFalse(game.heartsBroken)
    }

    func test_init_withFixedHands_wrongHandCount_throwsInvalidDeal() {
        XCTAssertThrowsError(try makeFixedDealGame(hands: [[Card(suit: .clubs, rank: .two)]])) { error in
            XCTAssertEqual(error as? GameError, .invalidDeal)
        }
    }

    func test_init_withFixedHands_duplicateCard_throwsInvalidDeal() {
        let hands: [[Card]] = [
            [Card(suit: .clubs, rank: .two)],
            [Card(suit: .clubs, rank: .two)],
            [Card(suit: .clubs, rank: .three)],
            [Card(suit: .clubs, rank: .four)]
        ]
        XCTAssertThrowsError(try makeFixedDealGame(hands: hands)) { error in
            XCTAssertEqual(error as? GameError, .invalidDeal)
        }
    }

    func test_startNewHand_afterFixedDeal_dealsAFullShuffledHandFromTheGenerator() throws {
        let hands: [[Card]] = [[Card(suit: .clubs, rank: .two)], [], [], []]
        let game = try Game(player1: fourPlayers[0], player2: fourPlayers[1], player3: fourPlayers[2],
                            player4: fourPlayers[3], hands: hands, using: SeededRandomNumberGenerator(seed: 3))
        let reference = Game(using: SeededRandomNumberGenerator(seed: 3))

        // A one-card deal can never be played out; put the fixture straight into the settled state.
        game.phase = .handComplete(game.scoring.settleHand(capturedCards: SeatMap(repeating: []), totalScores: game.totalScores))
        try game.startNewHand()

        XCTAssertEqual(game.hands.mapValues(\.count), [13, 13, 13, 13])
        XCTAssertEqual(game.hands, reference.hands,
                       "the fixed deal consumes no randomness, so the next deal matches a fresh seeded game")
    }
}
