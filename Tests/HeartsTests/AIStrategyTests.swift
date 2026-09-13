//
//  AIStrategyTests.swift
//
//
//  Created by Muhammad Hassan on 01/02/2026.
//

import XCTest
@testable import Hearts

final class AIStrategyTests: XCTestCase {

    // MARK: - RandomAIStrategy Tests

    func test_selectCardsToPass_random_returnsThreeCardsFromHand() {
        let strategy = RandomAIStrategy()
        let hand: Hand = [
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.queenOfHearts,
            Card.aceOfSpades,
            Card.kingOfSpades,
            Card.twoOfClubs,
            Card.threeOfClubs,
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

        // Should return 3 cards
        XCTAssertNotNil(passedCards.0)
        XCTAssertNotNil(passedCards.1)
        XCTAssertNotNil(passedCards.2)

        // All cards should be from the hand
        XCTAssertTrue(hand.contains(passedCards.0))
        XCTAssertTrue(hand.contains(passedCards.1))
        XCTAssertTrue(hand.contains(passedCards.2))

        // Should be unique cards
        XCTAssertNotEqual(passedCards.0, passedCards.1)
        XCTAssertNotEqual(passedCards.0, passedCards.2)
        XCTAssertNotEqual(passedCards.1, passedCards.2)
    }

    func test_selectCardToPlay_random_returnsCardFromHand() {
        let strategy = RandomAIStrategy()
        let hand: Hand = [
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.twoOfClubs,
        ]

        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false
        )

        let selectedCard = strategy.selectCardToPlay(context: context)

        // Should return a legal card from the hand
        XCTAssertTrue(context.legalMoves.contains(selectedCard))
    }

    // MARK: - BasicAIStrategy Tests

    func test_selectCardsToPass_basicHoldingQueenOfSpades_passesQueen() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card.queenOfSpades,  // Most dangerous
            Card.twoOfHearts,
            Card.aceOfClubs,
            Card.aceOfDiamonds,
            Card.twoOfClubs,
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

        // Queen of spades should be first card passed
        XCTAssertEqual(passedCards.0, Card.queenOfSpades)
    }

    func test_selectCardsToPass_basicHoldingHighHearts_passesHighHearts() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card.aceOfHearts,  // High heart
            Card.kingOfHearts,  // High heart
            Card.queenOfHearts,  // High heart
            Card.twoOfClubs,
            Card.threeOfClubs,
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

        // All three passed cards should be hearts
        XCTAssertEqual(passedCards.0.suit, .hearts)
        XCTAssertEqual(passedCards.1.suit, .hearts)
        XCTAssertEqual(passedCards.2.suit, .hearts)
    }

    func test_selectCardsToPass_basicHoldingHighSpades_passesHighSpades() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card.aceOfSpades,  // High spade
            Card.kingOfSpades,  // High spade
            Card.twoOfClubs,
            Card.threeOfClubs,
            Card.twoOfDiamonds,
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

        // High spades should be passed
        XCTAssertEqual(passedCards.0.suit, .spades)
        XCTAssertEqual(passedCards.1.suit, .spades)
    }

    func test_selectCardToPlay_basic_returnsLowestCard() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.twoOfClubs,  // Lowest
            Card.queenOfSpades,
        ]

        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,  // Hearts broken so we can lead hearts
            isFirstTrick: false
        )

        let selectedCard = strategy.selectCardToPlay(context: context)

        // Should select the lowest non-point card when leading
        XCTAssertEqual(selectedCard, Card.twoOfClubs)
    }

    // MARK: - AdvancedAIStrategy Tests

    func test_selectCardsToPass_advancedWithThreeCardSuit_voidsThatSuit() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.aceOfDiamonds,  // 3 diamonds - shortest suit
            Card.kingOfDiamonds,
            Card.queenOfDiamonds,
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.queenOfHearts,
            Card.jackOfHearts,
            Card.aceOfSpades,
            Card.kingOfSpades,
            Card.queenOfSpades,
            Card.jackOfSpades,
            Card.aceOfClubs,
            Card.kingOfClubs,
            Card.queenOfClubs,
            Card.jackOfClubs,
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

        // Should pass all 3 diamonds to void the suit (diamonds is the shortest suit with 3 cards)
        let passedSuits = [passedCards.0.suit, passedCards.1.suit, passedCards.2.suit]
        let diamondCount = passedSuits.filter { $0 == .diamonds }.count
        XCTAssertEqual(diamondCount, 3, "Should void the 3-card diamonds suit")
    }

    func test_selectCardsToPass_advancedWithTwoCardSuit_voidsThatSuit() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.aceOfDiamonds,  // 2 diamonds - should void this suit
            Card.kingOfDiamonds,
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.queenOfHearts,
            Card.jackOfHearts,
            Card.aceOfSpades,
            Card.kingOfSpades,
            Card.queenOfSpades,
            Card.aceOfClubs,
            Card.kingOfClubs,
            Card.queenOfClubs,
            Card.jackOfClubs,
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

        // Should pass both diamonds plus one high dangerous card
        let passedSuits = [passedCards.0.suit, passedCards.1.suit, passedCards.2.suit]
        let diamondCount = passedSuits.filter { $0 == .diamonds }.count
        XCTAssertEqual(diamondCount, 2, "Should void the 2-card diamonds suit")
    }

    func test_selectCardsToPass_advancedWithSingleton_voidsThatSuit() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.aceOfDiamonds,  // 1 diamond - should void this suit
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.queenOfHearts,
            Card.jackOfHearts,
            Card.aceOfSpades,
            Card.kingOfSpades,
            Card.queenOfSpades,
            Card.jackOfSpades,
            Card.aceOfClubs,
            Card.kingOfClubs,
            Card.queenOfClubs,
            Card.jackOfClubs,
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

        // Should pass the single diamond plus two high dangerous cards
        let passedSuits = [passedCards.0.suit, passedCards.1.suit, passedCards.2.suit]
        let diamondCount = passedSuits.filter { $0 == .diamonds }.count
        XCTAssertEqual(diamondCount, 1, "Should void the 1-card diamonds suit")
    }

    func test_selectCardsToPass_advancedWithNoShortSuit_passesQueenOfSpades() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.queenOfSpades,  // Most dangerous
            Card.kingOfSpades,
            Card.aceOfSpades,
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.queenOfHearts,
            Card.aceOfClubs,
            Card.kingOfClubs,
            Card.queenOfClubs,
            Card.aceOfDiamonds,
            Card.kingOfDiamonds,
            Card.queenOfDiamonds,
            Card.jackOfDiamonds,
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

        // Queen of spades should be passed
        XCTAssertTrue(
            passedCards.0 == Card.queenOfSpades ||
            passedCards.1 == Card.queenOfSpades ||
            passedCards.2 == Card.queenOfSpades,
            "Should pass Queen of Spades"
        )
    }

    func test_selectCardToPlay_advancedLeading_prefersMiddleCards() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.twoOfHearts,    // Lowest
            Card.sevenOfHearts,  // Middle
            Card.aceOfHearts,    // Highest
        ]

        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,  // Hearts broken so we can lead hearts
            isFirstTrick: false
        )

        let selectedCard = strategy.selectCardToPlay(context: context)

        // Should prefer middle card when leading from longest suit
        XCTAssertEqual(selectedCard, Card.sevenOfHearts)
    }

    func test_selectCardToPlay_advancedLeading_playsFromLongestSuit() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.twoOfHearts,
            Card.threeOfHearts,
            Card.fourOfHearts,
            Card.fiveOfHearts,  // Longest suit (4 cards)
            Card.twoOfClubs,
            Card.threeOfClubs,  // 2 cards
            Card.aceOfSpades,   // 1 card
        ]

        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,  // Hearts broken so we can lead hearts
            isFirstTrick: false
        )

        let selectedCard = strategy.selectCardToPlay(context: context)

        // Should play from hearts (longest suit)
        XCTAssertEqual(selectedCard.suit, Card.Suit.hearts)
    }

    // MARK: - TrickContext Tests

    func test_legalMoves_anyContext_matchesPlayRules() {
        // Rule coverage lives in PlayRulesTests; the context only forwards its inputs to the oracle.
        var trick = Trick()
        try! trick.play(Card.aceOfClubs, by: .south)
        let hand: Hand = [
            Card.sevenOfHearts,
            Card.queenOfSpades,
            Card.fiveOfDiamonds,
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: true)
        let rules = PlayRules(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: true)

        XCTAssertEqual(context.legalMoves, rules.legalMoves())
        XCTAssertEqual(context.legalMoves, [Card.fiveOfDiamonds])
    }

    // MARK: - BasicAIStrategy Additional Tests

    func test_selectCardToPlay_basicFollowingSuit_playsLowest() {
        let strategy = BasicAIStrategy()
        var trick = Trick()
        try! trick.play(Card.aceOfSpades, by: .south)

        let hand: Hand = [
            Card.kingOfSpades,
            Card.twoOfSpades,
            Card.aceOfHearts,
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card.twoOfSpades)
    }

    func test_selectCardToPlay_basicHoldingOnlyPointCards_playsLowest() {
        let strategy = BasicAIStrategy()
        // All legal moves are point cards (only hearts in hand, hearts broken)
        let hand: Hand = [
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.twoOfHearts,
        ]
        let context = TrickContext(hand: hand, currentTrick: Trick(), heartsBroken: true, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card.twoOfHearts)
    }

    // MARK: - AdvancedAIStrategy Play Tests (following suit)

    func test_selectCardToPlay_advancedFollowingSuit_ducksUnder() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        try! trick.play(Card.kingOfClubs, by: .south)

        let hand: Hand = [
            Card.aceOfClubs,    // Would win
            Card.queenOfClubs,  // Highest card that ducks under king
            Card.twoOfClubs,    // Lowest
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card.queenOfClubs)
    }

    func test_selectCardToPlay_advancedCannotDuckWithPointsInTrick_playsLowest() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        // Lead with Q♠ (13 pts) - any spade follower must win it
        try! trick.play(Card.queenOfSpades, by: .south)

        let hand: Hand = [
            Card.aceOfSpades,   // Both beat Q♠ — can't duck
            Card.kingOfSpades,
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        // Can't duck under Q♠, trick has 13 points → play lowest (K♠)
        XCTAssertEqual(selected, Card.kingOfSpades)
    }

    func test_selectCardToPlay_advancedCannotDuckWithoutPoints_playsMiddle() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        try! trick.play(Card.twoOfClubs, by: .south)

        // All three cards beat the 2♣ lead — can't duck, no points in trick
        let hand: Hand = [
            Card.aceOfClubs,
            Card.kingOfClubs,
            Card.queenOfClubs,
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        // sorted ascending: [Q♣, K♣, A♣], middle index = 1 → K♣
        XCTAssertEqual(selected, Card.kingOfClubs)
    }

    func test_selectCardToPlay_advancedCannotDuckWithFewCards_playsLowest() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        try! trick.play(Card.twoOfClubs, by: .south)

        // Only 2 clubs — can't duck, no points, < 3 legal cards → play lowest
        let hand: Hand = [
            Card.aceOfClubs,
            Card.kingOfClubs,
            Card.aceOfHearts,  // Not clubs — excluded by follow-suit
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card.kingOfClubs)
    }

    func test_selectCardToPlay_advancedLongestSuitIllegal_fallsBackToLowest() {
        let strategy = AdvancedAIStrategy()
        // Hearts is the longest suit but hearts are not broken — can't lead hearts
        let hand: Hand = [
            Card.twoOfHearts,
            Card.threeOfHearts,
            Card.fourOfHearts,
            Card.fiveOfHearts,  // 4 hearts (longest suit)
            Card.aceOfClubs,    // Only non-heart
        ]
        let context = TrickContext(hand: hand, currentTrick: Trick(), heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        // Hearts not legal to lead → fallback to lowest of remaining legal cards: A♣
        XCTAssertEqual(selected, Card.aceOfClubs)
    }

    func test_selectCardToPlay_advancedTwoCardLongestSuit_playsLowest() {
        let strategy = AdvancedAIStrategy()
        // Longest suit has exactly 2 cards — should play lowest, not middle
        let hand: Hand = [
            Card.kingOfSpades,
            Card.twoOfSpades,   // 2 spades (longest)
            Card.aceOfClubs,    // 1 club
        ]
        let context = TrickContext(hand: hand, currentTrick: Trick(), heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card.twoOfSpades)
    }

    // MARK: - AdvancedAIStrategy Passing Fallback Tests
    // Uses two-suit hands (6+7 cards) so no suit has ≤3 cards, forcing the priority-based fallback

    func test_selectCardsToPass_advancedFallback_passesQueenOfSpadesFirst() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.queenOfSpades,  // Priority 1
            Card.kingOfSpades,
            Card.aceOfSpades,
            Card.jackOfSpades,
            Card.tenOfSpades,
            Card.nineOfSpades,   // 6 spades
            Card.aceOfHearts,    // Priority 2 — high heart
            Card.kingOfHearts,   // Priority 2 — high heart
            Card.queenOfHearts,
            Card.jackOfHearts,
            Card.tenOfHearts,
            Card.nineOfHearts,
            Card.eightOfHearts,  // 7 hearts
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)
        let allPassed = [passedCards.0, passedCards.1, passedCards.2]

        XCTAssertTrue(allPassed.contains(Card.queenOfSpades), "Should pass Q♠ (priority 1)")
        XCTAssertTrue(allPassed.contains(Card.aceOfHearts), "Should pass A♥ (priority 2)")
        XCTAssertTrue(allPassed.contains(Card.kingOfHearts), "Should pass K♥ (priority 2)")
    }

    func test_selectCardsToPass_advancedFallbackWithoutQueenOrHearts_passesHighSpades() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.aceOfSpades,    // Priority 3 — high spade
            Card.kingOfSpades,   // Priority 3 — high spade
            Card.jackOfSpades,   // Priority 3 — high spade
            Card.tenOfSpades,
            Card.nineOfSpades,
            Card.eightOfSpades,  // 6 spades, no Q♠
            Card.aceOfClubs,
            Card.kingOfClubs,
            Card.queenOfClubs,
            Card.jackOfClubs,
            Card.tenOfClubs,
            Card.nineOfClubs,
            Card.eightOfClubs,   // 7 clubs, no hearts
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)
        let allPassed = [passedCards.0, passedCards.1, passedCards.2]

        XCTAssertTrue(allPassed.contains(Card.aceOfSpades))
        XCTAssertTrue(allPassed.contains(Card.kingOfSpades))
        XCTAssertTrue(allPassed.contains(Card.jackOfSpades))
    }

    func test_selectCardsToPass_advancedFallbackWithoutPriorityCards_passesHighestCards() {
        let strategy = AdvancedAIStrategy()
        // No Q♠, no hearts, no high spades — priority 4: pass the 3 highest cards
        let hand: Hand = [
            Card.aceOfClubs,    // Rank 14 — should be passed
            Card.kingOfClubs,   // Rank 13 — should be passed
            Card.queenOfClubs,  // Rank 12 — should be passed
            Card.jackOfClubs,
            Card.tenOfClubs,
            Card.nineOfClubs,   // 6 clubs
            Card.twoOfDiamonds,
            Card.threeOfDiamonds,
            Card.fourOfDiamonds,
            Card.fiveOfDiamonds,
            Card.sixOfDiamonds,
            Card.sevenOfDiamonds,
            Card.eightOfDiamonds,  // 7 low diamonds
        ]

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)
        let allPassed = [passedCards.0, passedCards.1, passedCards.2]

        XCTAssertTrue(allPassed.contains(Card.aceOfClubs))
        XCTAssertTrue(allPassed.contains(Card.kingOfClubs))
        XCTAssertTrue(allPassed.contains(Card.queenOfClubs))
    }

    // MARK: - Direction Parameter Tests

    func test_selectCardsForBotExchange_anyRound_passesExchangeDirection() throws {
        let game = Game()  // roundNumber=0 → .left
        let hand = game.hands[.south]

        // We can verify the direction is forwarded by checking the game's exchangeDirection
        // and confirming selectCardsForBotExchange does not crash and returns 3 valid cards.
        let cards = try XCTUnwrap(game.selectCardsForBotExchange(seat: .south))
        XCTAssertTrue(hand.contains(cards.first))
        XCTAssertTrue(hand.contains(cards.second))
        XCTAssertTrue(hand.contains(cards.third))
        XCTAssertEqual(game.exchangeDirection, .left)
    }

    func test_selectCardsToPass_everyDirection_acceptedByAllStrategies() {
        let hand: Hand = [
            Card.twoOfClubs,
            Card.threeOfClubs,
            Card.fourOfClubs,
            Card.fiveOfClubs,
            Card.sixOfClubs,
        ]

        for direction in [CardExchangeDirection.left, .right, .across, .none] {
            let r = RandomAIStrategy().selectCardsToPass(from: hand, direction: direction)
            let b = BasicAIStrategy().selectCardsToPass(from: hand, direction: direction)
            let a = AdvancedAIStrategy().selectCardsToPass(from: hand, direction: direction)
            // All should return 3 cards from the hand without crashing
            XCTAssertTrue(hand.contains(r.first))
            XCTAssertTrue(hand.contains(b.first))
            XCTAssertTrue(hand.contains(a.first))
        }
    }

    // MARK: - TrickContext completedTricks / playedCards Tests

    func test_trickContext_playedCards_flattensCompletedTricks() {
        var trick1 = Trick()
        var trick2 = Trick()

        try! trick1.play(Card.twoOfClubs, by: .south)
        try! trick1.play(Card.threeOfClubs, by: .west)
        try! trick1.play(Card.fourOfClubs, by: .north)
        try! trick1.play(Card.fiveOfClubs, by: .east)

        try! trick2.play(Card.aceOfDiamonds, by: .south)
        try! trick2.play(Card.kingOfDiamonds, by: .west)
        try! trick2.play(Card.queenOfDiamonds, by: .north)
        try! trick2.play(Card.jackOfDiamonds, by: .east)

        let context = TrickContext(
            hand: [],
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false,
            completedTricks: [trick1, trick2]
        )

        XCTAssertEqual(context.playedCards.count, 8)
        XCTAssertTrue(context.playedCards.contains(Card.twoOfClubs))
        XCTAssertTrue(context.playedCards.contains(Card.aceOfDiamonds))
    }

    func test_trickContext_playedCards_emptyWhenNoCompletedTricks() {
        let context = TrickContext(
            hand: [],
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: true
        )
        XCTAssertTrue(context.playedCards.isEmpty)
    }

    // MARK: - Card Counting Tests

    func test_advancedAIStrategy_leadsQueenOfSpades_whenAceAndKingAlreadyPlayed() {
        let strategy = AdvancedAIStrategy()

        // Build a completed trick containing A♠ and K♠
        var trick = Trick()
        try! trick.play(Card.aceOfSpades, by: .south)
        try! trick.play(Card.kingOfSpades, by: .west)
        try! trick.play(Card.twoOfClubs, by: .north)
        try! trick.play(Card.threeOfClubs, by: .east)

        let hand: Hand = [
            Card.queenOfSpades,  // Only card — should be led
            Card.fourOfClubs,
            Card.fiveOfClubs,
            Card.sixOfClubs,
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false,
            completedTricks: [trick]
        )

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card.queenOfSpades, "Should lead Q♠ when A♠ and K♠ have been played")
    }

    func test_advancedAIStrategy_avoidsQueenOfSpades_whenHighSpadesNotYetPlayed() {
        let strategy = AdvancedAIStrategy()

        // No completed tricks — A♠ and K♠ haven't been played yet
        let hand: Hand = [
            Card.queenOfSpades,
            Card.fourOfClubs,
            Card.fiveOfClubs,
            Card.sixOfClubs,
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false,
            completedTricks: []
        )

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertNotEqual(selected, Card.queenOfSpades, "Should avoid leading Q♠ when higher spades remain")
    }

    // MARK: - Moon-Shot Pursuit Tests

    func test_advancedAIStrategy_leadsHighHearts_inMoonShotMode() {
        let strategy = AdvancedAIStrategy()
        // Hand: all 12 hearts + Q♠ (clear moon-shot candidate)
        let hand: Hand = [
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.queenOfHearts,
            Card.jackOfHearts,
            Card.tenOfHearts,
            Card.nineOfHearts,
            Card.eightOfHearts,
            Card.sevenOfHearts,
            Card.sixOfHearts,
            Card.fiveOfHearts,
            Card.fourOfHearts,
            Card.threeOfHearts,
            Card.queenOfSpades,
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,
            isFirstTrick: false
        )

        let selected = strategy.selectCardToPlay(context: context)

        // Moon-shot mode: should lead A♥ (highest heart)
        XCTAssertEqual(selected, Card.aceOfHearts, "Should lead A♥ aggressively in moon-shot mode")
    }

    func test_advancedAIStrategy_playsHighestFollowing_inMoonShotMode() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        try! trick.play(Card.threeOfHearts, by: .south)

        // Hand: 7+ hearts + Q♠ → moon-shot mode; following hearts → play highest
        let hand: Hand = [
            Card.kingOfHearts,
            Card.sevenOfHearts,
            Card.twoOfHearts,
            Card.fourOfHearts,
            Card.fiveOfHearts,
            Card.sixOfHearts,
            Card.eightOfHearts,
            Card.queenOfSpades,
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: true, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card.kingOfHearts, "Should play highest heart in moon-shot following mode")
    }

    func test_advancedAIStrategy_abandonsMoonShot_onceAnotherSeatHasTakenAPoint() throws {
        let strategy = AdvancedAIStrategy()
        // Earlier this hand, west won a trick containing a heart: the moon is now impossible for south.
        var spoiled = Trick()
        try spoiled.play(Card.fourOfClubs, by: .south)
        try spoiled.play(Card.aceOfClubs, by: .west)
        try spoiled.play(Card.twoOfHearts, by: .north)
        try spoiled.play(Card.fiveOfClubs, by: .east)
        XCTAssertEqual(spoiled.winner, .west)

        // South still holds a textbook moon hand: 8 hearts + Q♠, plus a low club to lead safely.
        let hand: [Card] = [
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.queenOfHearts,
            Card.jackOfHearts,
            Card.tenOfHearts,
            Card.nineOfHearts,
            Card.eightOfHearts,
            Card.sevenOfHearts,
            Card.queenOfSpades,
            Card.threeOfClubs,
        ]
        let context = TrickContext(
            seat: .south,
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,
            isFirstTrick: false,
            completedTricks: [spoiled]
        )

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertNotEqual(selected, Card.aceOfHearts,
            "Once another seat holds a point the moon is off; stop leading high hearts")
        XCTAssertLessThan(selected.rank, .ace, "Normal-mode lead never opens with the top heart")
    }

    func test_advancedAIStrategy_keepsMoonShot_whenOnlyItHasTakenPoints() throws {
        let strategy = AdvancedAIStrategy()
        // South itself captured the only points so far: the moon is still on.
        var mine = Trick()
        try mine.play(Card.aceOfClubs, by: .south)
        try mine.play(Card.fourOfClubs, by: .west)
        try mine.play(Card.twoOfHearts, by: .north)
        try mine.play(Card.fiveOfClubs, by: .east)
        XCTAssertEqual(mine.winner, .south)

        let hand: [Card] = [
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.queenOfHearts,
            Card.jackOfHearts,
            Card.tenOfHearts,
            Card.nineOfHearts,
            Card.eightOfHearts,
            Card.sevenOfHearts,
            Card.queenOfSpades,
            Card.threeOfClubs,
        ]
        let context = TrickContext(
            seat: .south,
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,
            isFirstTrick: false,
            completedTricks: [mine]
        )

        XCTAssertEqual(strategy.selectCardToPlay(context: context), Card.aceOfHearts)
    }

    func test_advancedAIStrategy_doesNotAttemptMoonShot_withTooFewHearts() {
        let strategy = AdvancedAIStrategy()
        // Only 3 hearts + Q♠ — NOT moon-shot territory
        let hand: Hand = [
            Card.aceOfHearts,
            Card.kingOfHearts,
            Card.queenOfHearts,
            Card.queenOfSpades,
            Card.twoOfClubs,
            Card.threeOfClubs,
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,
            isFirstTrick: false
        )

        let selected = strategy.selectCardToPlay(context: context)

        // Normal mode: should NOT lead A♥ (would play lowest non-point or longest-suit card)
        XCTAssertNotEqual(selected, Card.aceOfHearts, "Should not aggressively lead hearts without moon-shot hand")
    }

    // MARK: - Determinism Tests

    func test_basicAIStrategy_selectCardToPlay_isDeterministic() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card.kingOfSpades,
            Card.fiveOfClubs,
            Card.sevenOfDiamonds,
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false
        )

        let first = strategy.selectCardToPlay(context: context)
        let second = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(first, second, "BasicAIStrategy must be deterministic")
    }

    func test_basicAIStrategy_selectCardsToPass_isDeterministic() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card.aceOfHearts,
            Card.queenOfSpades,
            Card.twoOfClubs,
            Card.threeOfClubs,
            Card.fourOfDiamonds,
        ]

        let first = strategy.selectCardsToPass(from: hand, direction: .left)
        let second = strategy.selectCardsToPass(from: hand, direction: .left)

        XCTAssertEqual(first.0, second.0, "BasicAIStrategy pass selection must be deterministic")
        XCTAssertEqual(first.1, second.1)
        XCTAssertEqual(first.2, second.2)
    }

    func test_advancedAIStrategy_selectCardToPlay_isDeterministic() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.kingOfSpades,
            Card.fiveOfClubs,
            Card.sevenOfDiamonds,
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false
        )

        let first = strategy.selectCardToPlay(context: context)
        let second = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(first, second, "AdvancedAIStrategy must be deterministic")
    }

    func test_advancedAIStrategy_selectCardsToPass_isDeterministic() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card.aceOfHearts,
            Card.queenOfSpades,
            Card.twoOfClubs,
            Card.threeOfClubs,
            Card.fourOfDiamonds,
        ]

        let first = strategy.selectCardsToPass(from: hand, direction: .left)
        let second = strategy.selectCardsToPass(from: hand, direction: .left)

        XCTAssertEqual(first.0, second.0, "AdvancedAIStrategy pass selection must be deterministic")
        XCTAssertEqual(first.1, second.1)
        XCTAssertEqual(first.2, second.2)
    }

    // MARK: - BotDifficulty Tests

    func test_makeStrategy_everyDifficulty_createsMatchingStrategy() {
        let easyStrategy = BotDifficulty.easy.makeStrategy(randomSource: RandomSource(SystemRandomNumberGenerator()))
        let mediumStrategy = BotDifficulty.medium.makeStrategy(randomSource: RandomSource(SystemRandomNumberGenerator()))
        let hardStrategy = BotDifficulty.hard.makeStrategy(randomSource: RandomSource(SystemRandomNumberGenerator()))

        XCTAssertTrue(easyStrategy is RandomAIStrategy)
        XCTAssertTrue(mediumStrategy is BasicAIStrategy)
        XCTAssertTrue(hardStrategy is AdvancedAIStrategy)
    }

    func test_makeStrategy_easy_createsRandomStrategy() {
        let strategy = BotDifficulty.easy.makeStrategy(randomSource: RandomSource(SystemRandomNumberGenerator()))
        XCTAssertTrue(strategy is RandomAIStrategy)
    }

    func test_makeStrategy_medium_createsBasicStrategy() {
        let strategy = BotDifficulty.medium.makeStrategy(randomSource: RandomSource(SystemRandomNumberGenerator()))
        XCTAssertTrue(strategy is BasicAIStrategy)
    }

    func test_makeStrategy_hard_createsAdvancedStrategy() {
        let strategy = BotDifficulty.hard.makeStrategy(randomSource: RandomSource(SystemRandomNumberGenerator()))
        XCTAssertTrue(strategy is AdvancedAIStrategy)
    }

    // MARK: - AdvancedAIStrategy Opponent Modeling

    func test_selectCardToPlay_advancedOpponentVoidInSuit_avoidsLeadingThatSuit() throws {
        // Build a completed trick where clubs was led and one opponent played off-suit,
        // revealing they are void in clubs.

        var pastTrick = Trick()
        try pastTrick.play(Card.fiveOfClubs, by: .south)
        try pastTrick.play(Card.kingOfHearts, by: .west)  // B is void in clubs
        try pastTrick.play(Card.threeOfClubs, by: .north)
        try pastTrick.play(Card.aceOfClubs, by: .east)

        // AI hand: clubs is the longest suit (3 cards), diamonds and spades are alternatives.
        // Without void avoidance the AI would lead the middle club.
        // With void avoidance it should skip clubs (voided) and choose diamonds or spades.
        let aiHand: Hand = [
            Card.sixOfClubs,
            Card.eightOfClubs,
            Card.tenOfClubs,
            Card.fourOfDiamonds,
            Card.twoOfSpades,
        ]

        let context = TrickContext(
            hand: aiHand,
            currentTrick: Trick(),
            heartsBroken: false,   // hearts not legal to lead
            isFirstTrick: false,
            completedTricks: [pastTrick]
        )

        let card = AdvancedAIStrategy().selectCardToPlay(context: context)
        XCTAssertNotEqual(card.suit, .clubs,
            "AdvancedAI should avoid leading clubs when an opponent is known void in it")
    }

    func test_selectCardToPlay_advancedAllSuitsVoided_leadsAnyLegalCard() throws {
        // Make clubs and spades both voided so the only legal non-heart leads are constrained.

        // Trick where clubs was led but p2 played off-suit → p2 void in clubs
        var trick1 = Trick()
        try trick1.play(Card.threeOfClubs, by: .south)
        try trick1.play(Card.twoOfSpades, by: .west)   // p2 void in clubs
        try trick1.play(Card.fourOfClubs, by: .north)
        try trick1.play(Card.fiveOfClubs, by: .east)

        // Trick where diamonds was led but p3 played off-suit → p3 void in diamonds
        var trick2 = Trick()
        try trick2.play(Card.threeOfDiamonds, by: .south)
        try trick2.play(Card.fourOfDiamonds, by: .west)
        try trick2.play(Card.sixOfClubs, by: .north)    // p3 void in diamonds
        try trick2.play(Card.fiveOfDiamonds, by: .east)

        // AI hand: only spades remain to lead (hearts not broken)
        let aiHand: Hand = [
            Card.sevenOfSpades,
            Card.nineOfSpades,
        ]

        let context = TrickContext(
            hand: aiHand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false,
            completedTricks: [trick1, trick2]
        )

        // Must not crash and must return a card from the hand
        let card = AdvancedAIStrategy().selectCardToPlay(context: context)
        XCTAssertTrue(aiHand.contains(card),
            "AI must return a card from hand even when all suits have known voids")
    }

    func test_advancedAI_ignoresOwnOffSuitPlay_whenInferringVoids() throws {
        // Only the deciding seat (west) played off-suit when clubs was led. That says nothing about
        // the opponents, so clubs must still be considered a safe lead.
        var pastTrick = Trick()
        try pastTrick.play(Card.fiveOfClubs, by: .south)
        try pastTrick.play(Card.kingOfDiamonds, by: .west)  // we discarded, not an opponent
        try pastTrick.play(Card.threeOfClubs, by: .north)
        try pastTrick.play(Card.aceOfClubs, by: .east)

        // Clubs is our longest suit; the normal lead is its middle card (8♣).
        let aiHand: [Card] = [
            Card.sixOfClubs,
            Card.eightOfClubs,
            Card.tenOfClubs,
            Card.fourOfDiamonds,
            Card.twoOfSpades,
        ]

        let context = TrickContext(
            seat: .west,
            hand: aiHand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false,
            completedTricks: [pastTrick]
        )

        let card = AdvancedAIStrategy().selectCardToPlay(context: context)
        XCTAssertEqual(card, Card.eightOfClubs,
            "Our own off-suit play must not mark clubs as an opponent void")
    }

    func test_selectCardToPlay_advancedNoVoidHistory_doesNotAvoidSuit() throws {
        // No completed tricks → no void info → AI should use normal longest-suit logic.
        let aiHand: Hand = [
            Card.sixOfClubs,
            Card.eightOfClubs,
            Card.tenOfClubs,
            Card.fourOfDiamonds,
        ]

        let context = TrickContext(
            hand: aiHand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false,
            completedTricks: []   // no history
        )

        let card = AdvancedAIStrategy().selectCardToPlay(context: context)
        // With no void info, longest suit (clubs, 3 cards) is preferred — middle card = 8♣
        XCTAssertEqual(card.suit, .clubs,
            "With no void history AI should lead from its longest suit")
        XCTAssertEqual(card.rank, .eight,
            "AI should lead the middle card of its longest suit")
    }

    // MARK: - TrickContext trickLeader

    func test_trickLeader_whenLeading_isNil() {
        let context = TrickContext(hand: [.twoOfClubs], currentTrick: Trick(), heartsBroken: false, isFirstTrick: true)
        XCTAssertNil(context.trickLeader)
    }

    func test_trickLeader_whenFollowing_isSeatThatLed() throws {
        let trick = try Trick.mock([.twoOfClubs, .threeOfClubs], leadingFrom: .west)
        let context = TrickContext(seat: .south, hand: [.aceOfClubs], currentTrick: trick, heartsBroken: false, isFirstTrick: true)
        XCTAssertEqual(context.trickLeader, .west)
    }

    // MARK: - Fallbacks outside Game

    func test_selectCardToPlay_randomWithNoLegalMoves_fallsBackToFirstCard() {
        // Leading the first trick without 2♣: no card is legal. Game never asks in this state.
        let strategy = RandomAIStrategy(randomSource: RandomSource(SeededRandomNumberGenerator(seed: 1)))
        let context = TrickContext(hand: [.aceOfClubs, .kingOfClubs], currentTrick: Trick(), heartsBroken: false, isFirstTrick: true)
        XCTAssertTrue(context.legalMoves.isEmpty)
        XCTAssertEqual(strategy.selectCardToPlay(context: context), .aceOfClubs)
    }

    func test_advancedAIStrategy_leadingInMoonShotModeWithHeartsUnbroken_leadsQueenOfSpades() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            .aceOfHearts, .kingOfHearts, .queenOfHearts, .jackOfHearts,
            .tenOfHearts, .nineOfHearts, .eightOfHearts,
            .queenOfSpades, .twoOfClubs,
        ]
        let context = TrickContext(hand: hand, currentTrick: Trick(), heartsBroken: false, isFirstTrick: false)

        // Hearts cannot be led, so the moon shooter forces the issue with Q♠ instead.
        XCTAssertEqual(strategy.selectCardToPlay(context: context), .queenOfSpades)
    }

    func test_selectCardToPlay_advancedFollowingTwoCardsInLeadSuit_ducksUnderTheHigher() throws {
        let strategy = AdvancedAIStrategy()
        let trick = try Trick.mock([.fiveOfDiamonds, .tenOfDiamonds], leadingFrom: .west)
        let context = TrickContext(
            seat: .east,
            hand: [.sevenOfDiamonds, .jackOfDiamonds, .twoOfClubs],
            currentTrick: trick,
            heartsBroken: false,
            isFirstTrick: false
        )

        XCTAssertEqual(strategy.selectCardToPlay(context: context), .sevenOfDiamonds)
    }

}
