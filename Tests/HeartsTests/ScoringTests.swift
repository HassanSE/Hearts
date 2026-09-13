//
//  ScoringTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

/// Exercises the scoring rules with hand-built tricks; no `Game` is constructed.
final class ScoringTests: XCTestCase {

    private let queenOfSpades = Card(suit: .spades, rank: .queen)
    private let jackOfDiamonds = Card(suit: .diamonds, rank: .jack)
    private let allHearts = Card.Rank.allCases.map { Card(suit: .hearts, rank: $0) }

    // MARK: - Trick points

    func test_pointsInTrick_withJackBonusOn_trickContainingJackOfDiamonds_returnsMinus10() throws {
        let scoring = Scoring(configuration: .withJackBonus)
        let trick = try makeTrick([jackOfDiamonds, Card(suit: .diamonds, rank: .two),
                                   Card(suit: .diamonds, rank: .five), Card(suit: .diamonds, rank: .nine)])

        XCTAssertEqual(scoring.points(in: trick), -10)
    }

    // MARK: - Hand settlement

    func test_settleHand_noMoonShot_addsCapturedPointsToTotals() {
        let scoring = Scoring(configuration: .standard)
        let captured: SeatMap<[Card]> = [
            [Card(suit: .hearts, rank: .two), Card(suit: .hearts, rank: .three), Card(suit: .clubs, rank: .ace)],
            [queenOfSpades],
            [],
            [Card(suit: .hearts, rank: .king)]
        ]

        let result = scoring.settleHand(capturedCards: captured, totalScores: [10, 20, 30, 40])

        XCTAssertEqual(result.roundScores, [2, 13, 0, 1])
        XCTAssertEqual(result.totalScores, [12, 33, 30, 41])
        XCTAssertNil(result.moonShooter)
    }

    func test_settleHand_moonShot_addToOthers_shooterGetsZeroOthersGet26() {
        let scoring = Scoring(configuration: .standard)
        let captured: SeatMap<[Card]> = [[], allHearts + [queenOfSpades], [], []]

        let result = scoring.settleHand(capturedCards: captured, totalScores: [10, 20, 30, 40])

        XCTAssertEqual(result.moonShooter, .west)
        XCTAssertEqual(result.roundScores, [26, 0, 26, 26])
        XCTAssertEqual(result.totalScores, [36, 20, 56, 66])
    }

    func test_settleHand_moonShot_subtractFromSelf_shooterLoses26OthersUnchanged() {
        let scoring = Scoring(configuration: .withSubtractMoonShot)
        let captured: SeatMap<[Card]> = [allHearts + [queenOfSpades], [], [], []]

        let result = scoring.settleHand(capturedCards: captured, totalScores: [50, 10, 20, 30])

        XCTAssertEqual(result.moonShooter, .south)
        XCTAssertEqual(result.roundScores, [-26, 0, 0, 0])
        XCTAssertEqual(result.totalScores, [24, 10, 20, 30])
    }

    func test_settleHand_moonShot_withJackBonus_shooterCapturedJack_shooterGetsMinus10() {
        let scoring = Scoring(configuration: .withJackBonus)
        let captured: SeatMap<[Card]> = [allHearts + [queenOfSpades, jackOfDiamonds], [], [], []]

        let result = scoring.settleHand(capturedCards: captured, totalScores: [0, 0, 0, 0])

        XCTAssertEqual(result.moonShooter, .south)
        XCTAssertEqual(result.roundScores, [-10, 26, 26, 26])
    }

    func test_settleHand_moonShot_withJackBonus_opponentCapturedJack_bonusStaysWithOpponent() {
        let scoring = Scoring(configuration: .withJackBonus)
        let captured: SeatMap<[Card]> = [allHearts + [queenOfSpades], [], [jackOfDiamonds], []]

        let result = scoring.settleHand(capturedCards: captured, totalScores: [0, 0, 0, 0])

        XCTAssertEqual(result.moonShooter, .south)
        XCTAssertEqual(result.roundScores, [0, 26, 16, 26])
    }

    func test_settleHand_moonShot_withJackBonus_subtractFromSelf_shooterCapturedJack_getsMinus36() {
        let scoring = Scoring(configuration: GameConfiguration(jackOfDiamondsBonus: true, moonShotVariant: .subtractFromSelf))
        let captured: SeatMap<[Card]> = [[], allHearts + [queenOfSpades, jackOfDiamonds], [], []]

        let result = scoring.settleHand(capturedCards: captured, totalScores: [0, 0, 0, 0])

        XCTAssertEqual(result.roundScores, [0, -36, 0, 0])
    }

    func test_settleHand_allHeartsWithoutQueen_isNotMoonShot() {
        let scoring = Scoring(configuration: .standard)
        let captured: SeatMap<[Card]> = [allHearts, [queenOfSpades], [], []]

        let result = scoring.settleHand(capturedCards: captured, totalScores: [0, 0, 0, 0])

        XCTAssertNil(result.moonShooter)
        XCTAssertEqual(result.roundScores, [13, 13, 0, 0])
    }

    func test_settleHand_queenWithoutAllHearts_isNotMoonShot() {
        let scoring = Scoring(configuration: .standard)
        let captured: SeatMap<[Card]> = [Array(allHearts.dropLast()) + [queenOfSpades], [allHearts[12]], [], []]

        let result = scoring.settleHand(capturedCards: captured, totalScores: [0, 0, 0, 0])

        XCTAssertNil(result.moonShooter)
        XCTAssertEqual(result.roundScores, [25, 1, 0, 0])
    }

    // MARK: - Game over

    func test_isGameOver_nobodyAtWinningScore_returnsFalse() {
        let scoring = Scoring(configuration: GameConfiguration(winningScore: 50))

        XCTAssertFalse(scoring.isGameOver(totalScores: [49, 10, 20, 30]))
    }

    func test_isGameOver_someoneReachesWinningScore_returnsTrue() {
        let scoring = Scoring(configuration: GameConfiguration(winningScore: 50))

        XCTAssertTrue(scoring.isGameOver(totalScores: [50, 10, 20, 30]))
    }

    func test_winner_gameOverWithUniqueLowest_returnsLowestSeat() {
        let scoring = Scoring(configuration: .standard)

        XCTAssertEqual(scoring.winner(totalScores: [100, 40, 20, 30]), .north)
        XCTAssertFalse(scoring.isTied(totalScores: [100, 40, 20, 30]))
    }

    func test_winner_gameOverWithTiedLowest_returnsNilAndIsTied() {
        let scoring = Scoring(configuration: .standard)

        XCTAssertNil(scoring.winner(totalScores: [100, 20, 20, 30]))
        XCTAssertTrue(scoring.isTied(totalScores: [100, 20, 20, 30]))
    }

    func test_winner_gameNotOver_returnsNilAndNotTied() {
        let scoring = Scoring(configuration: .standard)

        XCTAssertNil(scoring.winner(totalScores: [10, 20, 20, 30]))
        XCTAssertFalse(scoring.isTied(totalScores: [10, 20, 20, 30]))
    }

    // MARK: - Helpers

    private func makeTrick(_ cards: [Card]) throws -> Trick {
        var trick = Trick()
        for (index, card) in cards.enumerated() {
            try trick.play(card, by: Seat.allCases[index])
        }
        return trick
    }
}
