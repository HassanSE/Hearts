//
//  PlayRulesTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

/// Rules are exercised directly through `PlayRules`; no `Game` is constructed anywhere in this file.
final class PlayRulesTests: XCTestCase {

    private func rules(hand: [Card], trick: Trick = Trick(), heartsBroken: Bool = false, isFirstTrick: Bool = false) -> PlayRules {
        PlayRules(hand: hand, currentTrick: trick, heartsBroken: heartsBroken, isFirstTrick: isFirstTrick)
    }

    private func assertThrows(_ rules: PlayRules, _ card: Card, _ expected: GameError,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try rules.validate(card), file: file, line: line) { error in
            XCTAssertEqual(error as? GameError, expected, file: file, line: line)
        }
    }

    // MARK: - Rule 1: 2♣ leads the first trick

    func test_validate_firstTrickLeadingWithoutTwoOfClubs_throwsMustLeadWithTwoOfClubs() {
        let rules = rules(hand: [Card.twoOfClubs, Card.threeOfClubs], isFirstTrick: true)
        assertThrows(rules, Card.threeOfClubs, .mustLeadWithTwoOfClubs)
        XCTAssertNoThrow(try rules.validate(Card.twoOfClubs))
        XCTAssertEqual(rules.legalMoves(), [Card.twoOfClubs])
    }

    func test_validate_firstTrickLeadWithoutTwoOfClubs_throwsMustLeadWithTwoOfClubs() {
        // Unreachable through Game (the 2♣ holder always leads) but the rule is stated unconditionally.
        let rules = rules(hand: [Card.threeOfClubs], isFirstTrick: true)
        assertThrows(rules, Card.threeOfClubs, .mustLeadWithTwoOfClubs)
        XCTAssertTrue(rules.legalMoves().isEmpty)
    }

    func test_validate_laterTrickLeading_doesNotRequireTwoOfClubs() {
        let rules = rules(hand: [Card.twoOfClubs, Card.threeOfClubs], isFirstTrick: false)
        XCTAssertNoThrow(try rules.validate(Card.threeOfClubs))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    // MARK: - Rule 2: no points on the first trick

    func test_validate_firstTrickPointCardWithAlternative_throwsCannotPlayPointsOnFirstTrick() throws {
        let rules = rules(
            hand: [Card.sevenOfHearts, Card.queenOfSpades, Card.fiveOfDiamonds],
            trick: try Trick.mock([Card.twoOfClubs]),
            isFirstTrick: true
        )
        assertThrows(rules, Card.sevenOfHearts, .cannotPlayPointsOnFirstTrick)
        assertThrows(rules, Card.queenOfSpades, .cannotPlayPointsOnFirstTrick)
        XCTAssertEqual(rules.legalMoves(), [Card.fiveOfDiamonds])
    }

    func test_validate_firstTrickOnlyPointCards_allowsPoints() throws {
        let rules = rules(
            hand: [Card.sevenOfHearts, Card.queenOfSpades],
            trick: try Trick.mock([Card.twoOfClubs]),
            isFirstTrick: true
        )
        XCTAssertNoThrow(try rules.validate(Card.sevenOfHearts))
        XCTAssertNoThrow(try rules.validate(Card.queenOfSpades))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    func test_validate_firstTrickPointCard_checksPointsBeforeFollowSuit() throws {
        // A point card played while holding the lead suit violates two rules; the first-trick rule wins.
        let rules = rules(
            hand: [Card.nineOfClubs, Card.sevenOfHearts],
            trick: try Trick.mock([Card.twoOfClubs]),
            isFirstTrick: true
        )
        assertThrows(rules, Card.sevenOfHearts, .cannotPlayPointsOnFirstTrick)
    }

    // MARK: - Rule 3: hearts must be broken to lead

    func test_validate_leadingHeartBeforeBrokenWithOtherSuits_throwsHeartsNotBroken() {
        let rules = rules(hand: [Card.threeOfHearts, Card.fourOfDiamonds], heartsBroken: false)
        assertThrows(rules, Card.threeOfHearts, .heartsNotBroken)
        XCTAssertEqual(rules.legalMoves(), [Card.fourOfDiamonds])
    }

    func test_validate_leadingHeartAfterBroken_allowsHeart() {
        let rules = rules(hand: [Card.threeOfHearts, Card.fourOfDiamonds], heartsBroken: true)
        XCTAssertNoThrow(try rules.validate(Card.threeOfHearts))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    func test_validate_leadingHeartBeforeBrokenWithOnlyHearts_allowsHeart() {
        let rules = rules(hand: [Card.threeOfHearts, Card.fourOfHearts], heartsBroken: false)
        XCTAssertNoThrow(try rules.validate(Card.threeOfHearts))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    func test_validate_followingWithHeartBeforeBroken_isNotALeadViolation() throws {
        // Discarding a heart while void in the lead suit is legal even if hearts are unbroken.
        let rules = rules(hand: [Card.threeOfHearts], trick: try Trick.mock([Card.aceOfDiamonds]), heartsBroken: false)
        XCTAssertNoThrow(try rules.validate(Card.threeOfHearts))
    }

    // MARK: - Rule 4: must follow suit

    func test_validate_offSuitWhileHoldingLeadSuit_throwsMustFollowSuit() throws {
        let rules = rules(hand: [Card.twoOfDiamonds, Card.queenOfSpades], trick: try Trick.mock([Card.aceOfDiamonds]))
        assertThrows(rules, Card.queenOfSpades, .mustFollowSuit(required: .diamonds))
        XCTAssertEqual(rules.legalMoves(), [Card.twoOfDiamonds])
    }

    func test_validate_voidInLeadSuit_allowsAnyCard() throws {
        let rules = rules(hand: [Card.twoOfClubs, Card.queenOfSpades], trick: try Trick.mock([Card.aceOfDiamonds]))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    // MARK: - Card not in hand

    func test_validate_cardNotInHand_throwsCardNotInHand() {
        let rules = rules(hand: [Card.twoOfDiamonds])
        assertThrows(rules, Card.threeOfDiamonds, .cardNotInHand)
    }

    func test_legalMoves_emptyHand_isEmpty() {
        XCTAssertTrue(rules(hand: []).legalMoves().isEmpty)
    }

    // MARK: - Property: legalMoves() agrees with validate(_:) for any state

    func test_legalMoves_forRandomStates_equalsCardsThatValidateAccepts() {
        var generator = SeededRandomNumberGenerator(seed: 0x5EED)
        let deck = Deck().cards

        for _ in 0..<500 {
            var cards = deck.shuffled(using: &generator)
            let handSize = Int.random(in: 0...13, using: &generator)
            let hand = Array(cards.prefix(handSize))
            cards.removeFirst(handSize)
            let trickSize = Int.random(in: 0...3, using: &generator)
            var trick = Trick()
            for index in 0..<trickSize {
                try! trick.play(cards[index], by: Seat.allCases[index])
            }
            let rules = PlayRules(
                hand: hand,
                currentTrick: trick,
                heartsBroken: Bool.random(using: &generator),
                isFirstTrick: Bool.random(using: &generator)
            )

            let accepted = hand.filter { card in
                do { try rules.validate(card); return true } catch { return false }
            }
            XCTAssertEqual(rules.legalMoves(), accepted)
            // Every legal card is in the hand. In any state reachable through Game (the first trick is
            // always led with 2♣), a non-empty hand has no legal card only when the first trick's
            // leader lacks 2♣.
            XCTAssertTrue(rules.legalMoves().allSatisfy { hand.contains($0) })
            let reachable = !rules.isFirstTrick || trick.leadSuit == nil || trick.leadSuit == .clubs
            if reachable && !hand.isEmpty && rules.legalMoves().isEmpty {
                XCTAssertTrue(rules.isFirstTrick && trick.leadSuit == nil && !hand.contains(Card.twoOfClubs))
            }
        }
    }
}
