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

    func test_randomAIStrategy_selectCardsToPass_returns_3_cards() {
        let strategy = RandomAIStrategy()
        let hand: Hand = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .spades, rank: .ace),
            Card(suit: .spades, rank: .king),
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)

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

    func test_randomAIStrategy_selectCardToPlay_returns_card_from_hand() {
        let strategy = RandomAIStrategy()
        let hand: Hand = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .clubs, rank: .two),
        ]

        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false
        )

        let selectedCard = strategy.selectCardToPlay(context: context)

        // Should return a legal card from the hand
        XCTAssertTrue(context.getLegalMoves().contains(selectedCard))
    }

    // MARK: - BasicAIStrategy Tests

    func test_basicAIStrategy_selectCardsToPass_prioritizes_queen_of_spades() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card(suit: .spades, rank: .queen),  // Most dangerous
            Card(suit: .hearts, rank: .two),
            Card(suit: .clubs, rank: .ace),
            Card(suit: .diamonds, rank: .ace),
            Card(suit: .clubs, rank: .two),
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)

        // Queen of spades should be first card passed
        XCTAssertEqual(passedCards.0, Card(suit: .spades, rank: .queen))
    }

    func test_basicAIStrategy_selectCardsToPass_prioritizes_high_hearts() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card(suit: .hearts, rank: .ace),  // High heart
            Card(suit: .hearts, rank: .king),  // High heart
            Card(suit: .hearts, rank: .queen),  // High heart
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)

        // All three passed cards should be hearts
        XCTAssertEqual(passedCards.0.suit, .hearts)
        XCTAssertEqual(passedCards.1.suit, .hearts)
        XCTAssertEqual(passedCards.2.suit, .hearts)
    }

    func test_basicAIStrategy_selectCardsToPass_prioritizes_high_spades() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card(suit: .spades, rank: .ace),  // High spade
            Card(suit: .spades, rank: .king),  // High spade
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .diamonds, rank: .two),
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)

        // High spades should be passed
        XCTAssertEqual(passedCards.0.suit, .spades)
        XCTAssertEqual(passedCards.1.suit, .spades)
    }

    func test_basicAIStrategy_selectCardToPlay_returns_lowest_card() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .clubs, rank: .two),  // Lowest
            Card(suit: .spades, rank: .queen),
        ]

        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,  // Hearts broken so we can lead hearts
            isFirstTrick: false
        )

        let selectedCard = strategy.selectCardToPlay(context: context)

        // Should select the lowest non-point card when leading
        XCTAssertEqual(selectedCard, Card(suit: .clubs, rank: .two))
    }

    // MARK: - AdvancedAIStrategy Tests

    func test_advancedAIStrategy_selectCardsToPass_voids_suit_with_3_cards() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card(suit: .diamonds, rank: .ace),  // 3 diamonds - shortest suit
            Card(suit: .diamonds, rank: .king),
            Card(suit: .diamonds, rank: .queen),
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .hearts, rank: .jack),
            Card(suit: .spades, rank: .ace),
            Card(suit: .spades, rank: .king),
            Card(suit: .spades, rank: .queen),
            Card(suit: .spades, rank: .jack),
            Card(suit: .clubs, rank: .ace),
            Card(suit: .clubs, rank: .king),
            Card(suit: .clubs, rank: .queen),
            Card(suit: .clubs, rank: .jack),
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)

        // Should pass all 3 diamonds to void the suit (diamonds is the shortest suit with 3 cards)
        let passedSuits = [passedCards.0.suit, passedCards.1.suit, passedCards.2.suit]
        let diamondCount = passedSuits.filter { $0 == .diamonds }.count
        XCTAssertEqual(diamondCount, 3, "Should void the 3-card diamonds suit")
    }

    func test_advancedAIStrategy_selectCardsToPass_voids_suit_with_2_cards() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card(suit: .diamonds, rank: .ace),  // 2 diamonds - should void this suit
            Card(suit: .diamonds, rank: .king),
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .hearts, rank: .jack),
            Card(suit: .spades, rank: .ace),
            Card(suit: .spades, rank: .king),
            Card(suit: .spades, rank: .queen),
            Card(suit: .clubs, rank: .ace),
            Card(suit: .clubs, rank: .king),
            Card(suit: .clubs, rank: .queen),
            Card(suit: .clubs, rank: .jack),
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)

        // Should pass both diamonds plus one high dangerous card
        let passedSuits = [passedCards.0.suit, passedCards.1.suit, passedCards.2.suit]
        let diamondCount = passedSuits.filter { $0 == .diamonds }.count
        XCTAssertEqual(diamondCount, 2, "Should void the 2-card diamonds suit")
    }

    func test_advancedAIStrategy_selectCardsToPass_voids_suit_with_1_card() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card(suit: .diamonds, rank: .ace),  // 1 diamond - should void this suit
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .hearts, rank: .jack),
            Card(suit: .spades, rank: .ace),
            Card(suit: .spades, rank: .king),
            Card(suit: .spades, rank: .queen),
            Card(suit: .spades, rank: .jack),
            Card(suit: .clubs, rank: .ace),
            Card(suit: .clubs, rank: .king),
            Card(suit: .clubs, rank: .queen),
            Card(suit: .clubs, rank: .jack),
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)

        // Should pass the single diamond plus two high dangerous cards
        let passedSuits = [passedCards.0.suit, passedCards.1.suit, passedCards.2.suit]
        let diamondCount = passedSuits.filter { $0 == .diamonds }.count
        XCTAssertEqual(diamondCount, 1, "Should void the 1-card diamonds suit")
    }

    func test_advancedAIStrategy_selectCardsToPass_prioritizes_queen_of_spades_when_no_short_suit() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card(suit: .spades, rank: .queen),  // Most dangerous
            Card(suit: .spades, rank: .king),
            Card(suit: .spades, rank: .ace),
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .clubs, rank: .ace),
            Card(suit: .clubs, rank: .king),
            Card(suit: .clubs, rank: .queen),
            Card(suit: .diamonds, rank: .ace),
            Card(suit: .diamonds, rank: .king),
            Card(suit: .diamonds, rank: .queen),
            Card(suit: .diamonds, rank: .jack),
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)

        // Queen of spades should be passed
        XCTAssertTrue(
            passedCards.0 == Card(suit: .spades, rank: .queen) ||
            passedCards.1 == Card(suit: .spades, rank: .queen) ||
            passedCards.2 == Card(suit: .spades, rank: .queen),
            "Should pass Queen of Spades"
        )
    }

    func test_advancedAIStrategy_selectCardToPlay_prefers_middle_cards() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card(suit: .hearts, rank: .two),    // Lowest
            Card(suit: .hearts, rank: .seven),  // Middle
            Card(suit: .hearts, rank: .ace),    // Highest
        ]

        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,  // Hearts broken so we can lead hearts
            isFirstTrick: false
        )

        let selectedCard = strategy.selectCardToPlay(context: context)

        // Should prefer middle card when leading from longest suit
        XCTAssertEqual(selectedCard, Card(suit: .hearts, rank: .seven))
    }

    func test_advancedAIStrategy_selectCardToPlay_plays_from_longest_suit() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card(suit: .hearts, rank: .two),
            Card(suit: .hearts, rank: .three),
            Card(suit: .hearts, rank: .four),
            Card(suit: .hearts, rank: .five),  // Longest suit (4 cards)
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),  // 2 cards
            Card(suit: .spades, rank: .ace),   // 1 card
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

    func test_getLegalMoves_onlyHeartsInHand_canLeadDespiteHeartsNotBroken() {
        let hand: Hand = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false
        )

        let legal = context.getLegalMoves()

        XCTAssertEqual(legal.count, 2)
        XCTAssertTrue(legal.allSatisfy { $0.suit == .hearts })
    }

    func test_getLegalMoves_firstTrickFollowing_cannotPlayPointCards() {
        // On the first trick, a player following suit cannot dump point cards if non-point cards are available
        var trick = Trick()
        let leader = Player(name: "Leader", type: .bot(difficulty: .easy))
        try! trick.play(Card(suit: .clubs, rank: .ace), by: leader, from: [Card(suit: .clubs, rank: .ace)])

        // No clubs in hand - all cards are initially legal after the follow-suit check
        let hand: Hand = [
            Card(suit: .hearts, rank: .seven),   // 1 point - must be excluded
            Card(suit: .spades, rank: .queen),   // 13 points - must be excluded
            Card(suit: .diamonds, rank: .five),  // 0 points - only legal option
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: trick,
            heartsBroken: false,
            isFirstTrick: true
        )

        let legal = context.getLegalMoves()

        XCTAssertEqual(legal, [Card(suit: .diamonds, rank: .five)])
    }

    // MARK: - BasicAIStrategy Additional Tests

    func test_basicAIStrategy_selectCardToPlay_followsSuit_playsLowest() {
        let strategy = BasicAIStrategy()
        var trick = Trick()
        let leader = Player(name: "Leader", type: .bot(difficulty: .easy))
        try! trick.play(Card(suit: .spades, rank: .ace), by: leader, from: [Card(suit: .spades, rank: .ace)])

        let hand: Hand = [
            Card(suit: .spades, rank: .king),
            Card(suit: .spades, rank: .two),
            Card(suit: .hearts, rank: .ace),
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card(suit: .spades, rank: .two))
    }

    func test_basicAIStrategy_selectCardToPlay_allPointCards_playsLowest() {
        let strategy = BasicAIStrategy()
        // All legal moves are point cards (only hearts in hand, hearts broken)
        let hand: Hand = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .two),
        ]
        let context = TrickContext(hand: hand, currentTrick: Trick(), heartsBroken: true, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card(suit: .hearts, rank: .two))
    }

    // MARK: - AdvancedAIStrategy Play Tests (following suit)

    func test_advancedAIStrategy_selectCardToPlay_followsSuit_ducksUnder() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        let leader = Player(name: "Leader", type: .bot(difficulty: .hard))
        try! trick.play(Card(suit: .clubs, rank: .king), by: leader, from: [Card(suit: .clubs, rank: .king)])

        let hand: Hand = [
            Card(suit: .clubs, rank: .ace),    // Would win
            Card(suit: .clubs, rank: .queen),  // Highest card that ducks under king
            Card(suit: .clubs, rank: .two),    // Lowest
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card(suit: .clubs, rank: .queen))
    }

    func test_advancedAIStrategy_selectCardToPlay_cantDuck_trickHasPoints_playsLowest() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        let leader = Player(name: "Leader", type: .bot(difficulty: .hard))
        // Lead with Q♠ (13 pts) - any spade follower must win it
        try! trick.play(Card(suit: .spades, rank: .queen), by: leader, from: [Card(suit: .spades, rank: .queen)])

        let hand: Hand = [
            Card(suit: .spades, rank: .ace),   // Both beat Q♠ — can't duck
            Card(suit: .spades, rank: .king),
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        // Can't duck under Q♠, trick has 13 points → play lowest (K♠)
        XCTAssertEqual(selected, Card(suit: .spades, rank: .king))
    }

    func test_advancedAIStrategy_selectCardToPlay_cantDuck_noPoints_playsMiddle() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        let leader = Player(name: "Leader", type: .bot(difficulty: .hard))
        try! trick.play(Card(suit: .clubs, rank: .two), by: leader, from: [Card(suit: .clubs, rank: .two)])

        // All three cards beat the 2♣ lead — can't duck, no points in trick
        let hand: Hand = [
            Card(suit: .clubs, rank: .ace),
            Card(suit: .clubs, rank: .king),
            Card(suit: .clubs, rank: .queen),
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        // sorted ascending: [Q♣, K♣, A♣], middle index = 1 → K♣
        XCTAssertEqual(selected, Card(suit: .clubs, rank: .king))
    }

    func test_advancedAIStrategy_selectCardToPlay_cantDuck_noPoints_fewCards_playsLowest() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        let leader = Player(name: "Leader", type: .bot(difficulty: .hard))
        try! trick.play(Card(suit: .clubs, rank: .two), by: leader, from: [Card(suit: .clubs, rank: .two)])

        // Only 2 clubs — can't duck, no points, < 3 legal cards → play lowest
        let hand: Hand = [
            Card(suit: .clubs, rank: .ace),
            Card(suit: .clubs, rank: .king),
            Card(suit: .hearts, rank: .ace),  // Not clubs — excluded by follow-suit
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card(suit: .clubs, rank: .king))
    }

    func test_advancedAIStrategy_selectCardToPlay_longestSuitNotLegal_fallsBackToLowest() {
        let strategy = AdvancedAIStrategy()
        // Hearts is the longest suit but hearts are not broken — can't lead hearts
        let hand: Hand = [
            Card(suit: .hearts, rank: .two),
            Card(suit: .hearts, rank: .three),
            Card(suit: .hearts, rank: .four),
            Card(suit: .hearts, rank: .five),  // 4 hearts (longest suit)
            Card(suit: .clubs, rank: .ace),    // Only non-heart
        ]
        let context = TrickContext(hand: hand, currentTrick: Trick(), heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        // Hearts not legal to lead → fallback to lowest of remaining legal cards: A♣
        XCTAssertEqual(selected, Card(suit: .clubs, rank: .ace))
    }

    func test_advancedAIStrategy_selectCardToPlay_twoCardLongestSuit_playsLowest() {
        let strategy = AdvancedAIStrategy()
        // Longest suit has exactly 2 cards — should play lowest, not middle
        let hand: Hand = [
            Card(suit: .spades, rank: .king),
            Card(suit: .spades, rank: .two),   // 2 spades (longest)
            Card(suit: .clubs, rank: .ace),    // 1 club
        ]
        let context = TrickContext(hand: hand, currentTrick: Trick(), heartsBroken: false, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card(suit: .spades, rank: .two))
    }

    // MARK: - AdvancedAIStrategy Passing Fallback Tests
    // Uses two-suit hands (6+7 cards) so no suit has ≤3 cards, forcing the priority-based fallback

    func test_advancedAIStrategy_selectCardsToPass_fallback_prioritizesQueenOfSpades() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card(suit: .spades, rank: .queen),  // Priority 1
            Card(suit: .spades, rank: .king),
            Card(suit: .spades, rank: .ace),
            Card(suit: .spades, rank: .jack),
            Card(suit: .spades, rank: .ten),
            Card(suit: .spades, rank: .nine),   // 6 spades
            Card(suit: .hearts, rank: .ace),    // Priority 2 — high heart
            Card(suit: .hearts, rank: .king),   // Priority 2 — high heart
            Card(suit: .hearts, rank: .queen),
            Card(suit: .hearts, rank: .jack),
            Card(suit: .hearts, rank: .ten),
            Card(suit: .hearts, rank: .nine),
            Card(suit: .hearts, rank: .eight),  // 7 hearts
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)
        let allPassed = [passedCards.0, passedCards.1, passedCards.2]

        XCTAssertTrue(allPassed.contains(Card(suit: .spades, rank: .queen)), "Should pass Q♠ (priority 1)")
        XCTAssertTrue(allPassed.contains(Card(suit: .hearts, rank: .ace)), "Should pass A♥ (priority 2)")
        XCTAssertTrue(allPassed.contains(Card(suit: .hearts, rank: .king)), "Should pass K♥ (priority 2)")
    }

    func test_advancedAIStrategy_selectCardsToPass_fallback_passesHighSpades_whenNoQueenOrHearts() {
        let strategy = AdvancedAIStrategy()
        let hand: Hand = [
            Card(suit: .spades, rank: .ace),    // Priority 3 — high spade
            Card(suit: .spades, rank: .king),   // Priority 3 — high spade
            Card(suit: .spades, rank: .jack),   // Priority 3 — high spade
            Card(suit: .spades, rank: .ten),
            Card(suit: .spades, rank: .nine),
            Card(suit: .spades, rank: .eight),  // 6 spades, no Q♠
            Card(suit: .clubs, rank: .ace),
            Card(suit: .clubs, rank: .king),
            Card(suit: .clubs, rank: .queen),
            Card(suit: .clubs, rank: .jack),
            Card(suit: .clubs, rank: .ten),
            Card(suit: .clubs, rank: .nine),
            Card(suit: .clubs, rank: .eight),   // 7 clubs, no hearts
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)
        let allPassed = [passedCards.0, passedCards.1, passedCards.2]

        XCTAssertTrue(allPassed.contains(Card(suit: .spades, rank: .ace)))
        XCTAssertTrue(allPassed.contains(Card(suit: .spades, rank: .king)))
        XCTAssertTrue(allPassed.contains(Card(suit: .spades, rank: .jack)))
    }

    func test_advancedAIStrategy_selectCardsToPass_fallback_passesHighestCards_whenNoPriority() {
        let strategy = AdvancedAIStrategy()
        // No Q♠, no hearts, no high spades — priority 4: pass the 3 highest cards
        let hand: Hand = [
            Card(suit: .clubs, rank: .ace),    // Rank 14 — should be passed
            Card(suit: .clubs, rank: .king),   // Rank 13 — should be passed
            Card(suit: .clubs, rank: .queen),  // Rank 12 — should be passed
            Card(suit: .clubs, rank: .jack),
            Card(suit: .clubs, rank: .ten),
            Card(suit: .clubs, rank: .nine),   // 6 clubs
            Card(suit: .diamonds, rank: .two),
            Card(suit: .diamonds, rank: .three),
            Card(suit: .diamonds, rank: .four),
            Card(suit: .diamonds, rank: .five),
            Card(suit: .diamonds, rank: .six),
            Card(suit: .diamonds, rank: .seven),
            Card(suit: .diamonds, rank: .eight),  // 7 low diamonds
        ]

        let passedCards = strategy.selectCardsToPass(from: hand)
        let allPassed = [passedCards.0, passedCards.1, passedCards.2]

        XCTAssertTrue(allPassed.contains(Card(suit: .clubs, rank: .ace)))
        XCTAssertTrue(allPassed.contains(Card(suit: .clubs, rank: .king)))
        XCTAssertTrue(allPassed.contains(Card(suit: .clubs, rank: .queen)))
    }

    // MARK: - BotDifficulty Tests

    func test_botDifficulty_easy_creates_random_strategy() {
        let strategy = BotDifficulty.easy.makeStrategy()
        XCTAssertTrue(strategy is RandomAIStrategy)
    }

    func test_botDifficulty_medium_creates_basic_strategy() {
        let strategy = BotDifficulty.medium.makeStrategy()
        XCTAssertTrue(strategy is BasicAIStrategy)
    }

    func test_botDifficulty_hard_creates_advanced_strategy() {
        let strategy = BotDifficulty.hard.makeStrategy()
        XCTAssertTrue(strategy is AdvancedAIStrategy)
    }
}
