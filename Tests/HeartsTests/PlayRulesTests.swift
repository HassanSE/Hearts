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

    private let twoOfClubs = Card(suit: .clubs, rank: .two)

    private func trick(_ cards: Card...) -> Trick {
        var trick = Trick()
        for (index, card) in cards.enumerated() {
            try! trick.play(card, by: Player(name: "P\(index)", type: .bot(difficulty: .easy)))
        }
        return trick
    }

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
        let rules = rules(hand: [twoOfClubs, Card(suit: .clubs, rank: .three)], isFirstTrick: true)
        assertThrows(rules, Card(suit: .clubs, rank: .three), .mustLeadWithTwoOfClubs)
        XCTAssertNoThrow(try rules.validate(twoOfClubs))
        XCTAssertEqual(rules.legalMoves(), [twoOfClubs])
    }

    func test_validate_firstTrickLeading_hasNoTwoOfClubs_throwsMustLeadWithTwoOfClubs() {
        // Unreachable through Game (the 2♣ holder always leads) but the rule is stated unconditionally.
        let rules = rules(hand: [Card(suit: .clubs, rank: .three)], isFirstTrick: true)
        assertThrows(rules, Card(suit: .clubs, rank: .three), .mustLeadWithTwoOfClubs)
        XCTAssertTrue(rules.legalMoves().isEmpty)
    }

    func test_validate_laterTrickLeading_doesNotRequireTwoOfClubs() {
        let rules = rules(hand: [twoOfClubs, Card(suit: .clubs, rank: .three)], isFirstTrick: false)
        XCTAssertNoThrow(try rules.validate(Card(suit: .clubs, rank: .three)))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    // MARK: - Rule 2: no points on the first trick

    func test_validate_firstTrickFollowing_pointCardWithAlternative_throwsCannotPlayPointsOnFirstTrick() {
        let rules = rules(
            hand: [Card(suit: .hearts, rank: .seven), Card(suit: .spades, rank: .queen), Card(suit: .diamonds, rank: .five)],
            trick: trick(twoOfClubs),
            isFirstTrick: true
        )
        assertThrows(rules, Card(suit: .hearts, rank: .seven), .cannotPlayPointsOnFirstTrick)
        assertThrows(rules, Card(suit: .spades, rank: .queen), .cannotPlayPointsOnFirstTrick)
        XCTAssertEqual(rules.legalMoves(), [Card(suit: .diamonds, rank: .five)])
    }

    func test_validate_firstTrickFollowing_onlyPointCards_allowsPoints() {
        let rules = rules(
            hand: [Card(suit: .hearts, rank: .seven), Card(suit: .spades, rank: .queen)],
            trick: trick(twoOfClubs),
            isFirstTrick: true
        )
        XCTAssertNoThrow(try rules.validate(Card(suit: .hearts, rank: .seven)))
        XCTAssertNoThrow(try rules.validate(Card(suit: .spades, rank: .queen)))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    func test_validate_firstTrickFollowing_pointsChecked_beforeFollowSuit() {
        // A point card played while holding the lead suit violates two rules; the first-trick rule wins.
        let rules = rules(
            hand: [Card(suit: .clubs, rank: .nine), Card(suit: .hearts, rank: .seven)],
            trick: trick(twoOfClubs),
            isFirstTrick: true
        )
        assertThrows(rules, Card(suit: .hearts, rank: .seven), .cannotPlayPointsOnFirstTrick)
    }

    // MARK: - Rule 3: hearts must be broken to lead

    func test_validate_leadingHeartBeforeBroken_withOtherSuits_throwsHeartsNotBroken() {
        let rules = rules(hand: [Card(suit: .hearts, rank: .three), Card(suit: .diamonds, rank: .four)], heartsBroken: false)
        assertThrows(rules, Card(suit: .hearts, rank: .three), .heartsNotBroken)
        XCTAssertEqual(rules.legalMoves(), [Card(suit: .diamonds, rank: .four)])
    }

    func test_validate_leadingHeartAfterBroken_allowsHeart() {
        let rules = rules(hand: [Card(suit: .hearts, rank: .three), Card(suit: .diamonds, rank: .four)], heartsBroken: true)
        XCTAssertNoThrow(try rules.validate(Card(suit: .hearts, rank: .three)))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    func test_validate_leadingHeartBeforeBroken_onlyHearts_allowsHeart() {
        let rules = rules(hand: [Card(suit: .hearts, rank: .three), Card(suit: .hearts, rank: .four)], heartsBroken: false)
        XCTAssertNoThrow(try rules.validate(Card(suit: .hearts, rank: .three)))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    func test_validate_followingWithHeartBeforeBroken_isNotALeadViolation() {
        // Discarding a heart while void in the lead suit is legal even if hearts are unbroken.
        let rules = rules(hand: [Card(suit: .hearts, rank: .three)], trick: trick(Card(suit: .diamonds, rank: .ace)), heartsBroken: false)
        XCTAssertNoThrow(try rules.validate(Card(suit: .hearts, rank: .three)))
    }

    // MARK: - Rule 4: must follow suit

    func test_validate_holdingLeadSuit_playingOffSuit_throwsMustFollowSuit() {
        let rules = rules(hand: [Card(suit: .diamonds, rank: .two), Card(suit: .spades, rank: .queen)], trick: trick(Card(suit: .diamonds, rank: .ace)))
        assertThrows(rules, Card(suit: .spades, rank: .queen), .mustFollowSuit(required: .diamonds))
        XCTAssertEqual(rules.legalMoves(), [Card(suit: .diamonds, rank: .two)])
    }

    func test_validate_voidInLeadSuit_allowsAnyCard() {
        let rules = rules(hand: [Card(suit: .clubs, rank: .two), Card(suit: .spades, rank: .queen)], trick: trick(Card(suit: .diamonds, rank: .ace)))
        XCTAssertEqual(rules.legalMoves().count, 2)
    }

    // MARK: - Card not in hand

    func test_validate_cardNotInHand_throwsCardNotInHand() {
        let rules = rules(hand: [Card(suit: .diamonds, rank: .two)])
        assertThrows(rules, Card(suit: .diamonds, rank: .three), .cardNotInHand)
    }

    func test_legalMoves_emptyHand_isEmpty() {
        XCTAssertTrue(rules(hand: []).legalMoves().isEmpty)
    }

    // MARK: - Property: legalMoves() agrees with validate(_:) for any state

    func test_legalMoves_forRandomStates_equalsCardsThatValidateAccepts() {
        var generator = SeededRandomNumberGenerator(seed: 0x5EED)
        let deck = Card.Suit.allCases.flatMap { suit in Card.Rank.allCases.map { Card(suit: suit, rank: $0) } }

        for _ in 0..<500 {
            var cards = deck.shuffled(using: &generator)
            let handSize = Int.random(in: 0...13, using: &generator)
            let hand = Array(cards.prefix(handSize))
            cards.removeFirst(handSize)
            let trickSize = Int.random(in: 0...3, using: &generator)
            var trick = Trick()
            for index in 0..<trickSize {
                try! trick.play(cards[index], by: Player(name: "P\(index)", type: .bot(difficulty: .easy)))
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
                XCTAssertTrue(rules.isFirstTrick && trick.leadSuit == nil && !hand.contains(twoOfClubs))
            }
        }
    }
}
