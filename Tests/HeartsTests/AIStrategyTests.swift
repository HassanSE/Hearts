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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)

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
        try! trick.play(Card(suit: .clubs, rank: .ace), by: leader)

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
        try! trick.play(Card(suit: .spades, rank: .ace), by: leader)

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
        try! trick.play(Card(suit: .clubs, rank: .king), by: leader)

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
        try! trick.play(Card(suit: .spades, rank: .queen), by: leader)

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
        try! trick.play(Card(suit: .clubs, rank: .two), by: leader)

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
        try! trick.play(Card(suit: .clubs, rank: .two), by: leader)

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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)
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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)
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

        let passedCards = strategy.selectCardsToPass(from: hand, direction: .left)
        let allPassed = [passedCards.0, passedCards.1, passedCards.2]

        XCTAssertTrue(allPassed.contains(Card(suit: .clubs, rank: .ace)))
        XCTAssertTrue(allPassed.contains(Card(suit: .clubs, rank: .king)))
        XCTAssertTrue(allPassed.contains(Card(suit: .clubs, rank: .queen)))
    }

    // MARK: - 2.1 Direction Parameter Tests

    func test_selectCardsForBotExchange_passesExchangeDirection() {
        let game = Game()  // roundNumber=0 → .left
        let botPlayer = game.players[0]

        // We can verify the direction is forwarded by checking the game's exchangeDirection
        // and confirming selectCardsForBotExchange does not crash and returns 3 valid cards.
        let cards = game.selectCardsForBotExchange(player: botPlayer)
        XCTAssertTrue(botPlayer.hand.contains(cards.first))
        XCTAssertTrue(botPlayer.hand.contains(cards.second))
        XCTAssertTrue(botPlayer.hand.contains(cards.third))
        XCTAssertEqual(game.exchangeDirection, .left)
    }

    func test_selectCardsToPass_direction_parameter_accepted_byAllStrategies() {
        let hand: Hand = [
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .four),
            Card(suit: .clubs, rank: .five),
            Card(suit: .clubs, rank: .six),
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

    // MARK: - 2.2 TrickContext completedTricks / playedCards Tests

    func test_trickContext_playedCards_flattensCompletedTricks() {
        var trick1 = Trick()
        var trick2 = Trick()
        let p1 = Player(name: "P1", type: .bot(difficulty: .easy))
        let p2 = Player(name: "P2", type: .bot(difficulty: .easy))
        let p3 = Player(name: "P3", type: .bot(difficulty: .easy))
        let p4 = Player(name: "P4", type: .bot(difficulty: .easy))

        try! trick1.play(Card(suit: .clubs, rank: .two), by: p1)
        try! trick1.play(Card(suit: .clubs, rank: .three), by: p2)
        try! trick1.play(Card(suit: .clubs, rank: .four), by: p3)
        try! trick1.play(Card(suit: .clubs, rank: .five), by: p4)

        try! trick2.play(Card(suit: .diamonds, rank: .ace), by: p1)
        try! trick2.play(Card(suit: .diamonds, rank: .king), by: p2)
        try! trick2.play(Card(suit: .diamonds, rank: .queen), by: p3)
        try! trick2.play(Card(suit: .diamonds, rank: .jack), by: p4)

        let context = TrickContext(
            hand: [],
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false,
            completedTricks: [trick1, trick2]
        )

        XCTAssertEqual(context.playedCards.count, 8)
        XCTAssertTrue(context.playedCards.contains(Card(suit: .clubs, rank: .two)))
        XCTAssertTrue(context.playedCards.contains(Card(suit: .diamonds, rank: .ace)))
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

    // MARK: - 2.3 Card Counting Tests

    func test_advancedAIStrategy_leadsQueenOfSpades_whenAceAndKingAlreadyPlayed() {
        let strategy = AdvancedAIStrategy()
        let p1 = Player(name: "P1", type: .bot(difficulty: .hard))
        let p2 = Player(name: "P2", type: .bot(difficulty: .hard))
        let p3 = Player(name: "P3", type: .bot(difficulty: .hard))
        let p4 = Player(name: "P4", type: .bot(difficulty: .hard))

        // Build a completed trick containing A♠ and K♠
        var trick = Trick()
        try! trick.play(Card(suit: .spades, rank: .ace), by: p1)
        try! trick.play(Card(suit: .spades, rank: .king), by: p2)
        try! trick.play(Card(suit: .clubs, rank: .two), by: p3)
        try! trick.play(Card(suit: .clubs, rank: .three), by: p4)

        let hand: Hand = [
            Card(suit: .spades, rank: .queen),  // Only card — should be led
            Card(suit: .clubs, rank: .four),
            Card(suit: .clubs, rank: .five),
            Card(suit: .clubs, rank: .six),
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false,
            completedTricks: [trick]
        )

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card(suit: .spades, rank: .queen), "Should lead Q♠ when A♠ and K♠ have been played")
    }

    func test_advancedAIStrategy_avoidsQueenOfSpades_whenHighSpadesNotYetPlayed() {
        let strategy = AdvancedAIStrategy()

        // No completed tricks — A♠ and K♠ haven't been played yet
        let hand: Hand = [
            Card(suit: .spades, rank: .queen),
            Card(suit: .clubs, rank: .four),
            Card(suit: .clubs, rank: .five),
            Card(suit: .clubs, rank: .six),
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: false,
            isFirstTrick: false,
            completedTricks: []
        )

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertNotEqual(selected, Card(suit: .spades, rank: .queen), "Should avoid leading Q♠ when higher spades remain")
    }

    // MARK: - 2.4 Moon-Shot Pursuit Tests

    func test_advancedAIStrategy_leadsHighHearts_inMoonShotMode() {
        let strategy = AdvancedAIStrategy()
        // Hand: all 12 hearts + Q♠ (clear moon-shot candidate)
        let hand: Hand = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .hearts, rank: .jack),
            Card(suit: .hearts, rank: .ten),
            Card(suit: .hearts, rank: .nine),
            Card(suit: .hearts, rank: .eight),
            Card(suit: .hearts, rank: .seven),
            Card(suit: .hearts, rank: .six),
            Card(suit: .hearts, rank: .five),
            Card(suit: .hearts, rank: .four),
            Card(suit: .hearts, rank: .three),
            Card(suit: .spades, rank: .queen),
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,
            isFirstTrick: false
        )

        let selected = strategy.selectCardToPlay(context: context)

        // Moon-shot mode: should lead A♥ (highest heart)
        XCTAssertEqual(selected, Card(suit: .hearts, rank: .ace), "Should lead A♥ aggressively in moon-shot mode")
    }

    func test_advancedAIStrategy_playsHighestFollowing_inMoonShotMode() {
        let strategy = AdvancedAIStrategy()
        var trick = Trick()
        let leader = Player(name: "Leader", type: .bot(difficulty: .easy))
        try! trick.play(Card(suit: .hearts, rank: .three), by: leader)

        // Hand: 7+ hearts + Q♠ → moon-shot mode; following hearts → play highest
        let hand: Hand = [
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .seven),
            Card(suit: .hearts, rank: .two),
            Card(suit: .hearts, rank: .four),
            Card(suit: .hearts, rank: .five),
            Card(suit: .hearts, rank: .six),
            Card(suit: .hearts, rank: .eight),
            Card(suit: .spades, rank: .queen),
        ]
        let context = TrickContext(hand: hand, currentTrick: trick, heartsBroken: true, isFirstTrick: false)

        let selected = strategy.selectCardToPlay(context: context)

        XCTAssertEqual(selected, Card(suit: .hearts, rank: .king), "Should play highest heart in moon-shot following mode")
    }

    func test_advancedAIStrategy_doesNotAttemptMoonShot_withTooFewHearts() {
        let strategy = AdvancedAIStrategy()
        // Only 3 hearts + Q♠ — NOT moon-shot territory
        let hand: Hand = [
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .spades, rank: .queen),
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
        ]
        let context = TrickContext(
            hand: hand,
            currentTrick: Trick(),
            heartsBroken: true,
            isFirstTrick: false
        )

        let selected = strategy.selectCardToPlay(context: context)

        // Normal mode: should NOT lead A♥ (would play lowest non-point or longest-suit card)
        XCTAssertNotEqual(selected, Card(suit: .hearts, rank: .ace), "Should not aggressively lead hearts without moon-shot hand")
    }

    // MARK: - 2.6 Determinism Tests

    func test_basicAIStrategy_selectCardToPlay_isDeterministic() {
        let strategy = BasicAIStrategy()
        let hand: Hand = [
            Card(suit: .spades, rank: .king),
            Card(suit: .clubs, rank: .five),
            Card(suit: .diamonds, rank: .seven),
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
            Card(suit: .hearts, rank: .ace),
            Card(suit: .spades, rank: .queen),
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .diamonds, rank: .four),
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
            Card(suit: .spades, rank: .king),
            Card(suit: .clubs, rank: .five),
            Card(suit: .diamonds, rank: .seven),
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
            Card(suit: .hearts, rank: .ace),
            Card(suit: .spades, rank: .queen),
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .diamonds, rank: .four),
        ]

        let first = strategy.selectCardsToPass(from: hand, direction: .left)
        let second = strategy.selectCardsToPass(from: hand, direction: .left)

        XCTAssertEqual(first.0, second.0, "AdvancedAIStrategy pass selection must be deterministic")
        XCTAssertEqual(first.1, second.1)
        XCTAssertEqual(first.2, second.2)
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

    // MARK: - AdvancedAIStrategy Opponent Modeling

    func test_advancedAI_avoids_leading_suit_opponent_is_void_in() throws {
        // Build a completed trick where clubs was led and one opponent played off-suit,
        // revealing they are void in clubs.
        let playerA = Player(name: "A")
        let playerB = Player(name: "B")  // void in clubs — played hearts when clubs was led
        let playerC = Player(name: "C")
        let playerD = Player(name: "D")  // AI's positional stand-in

        var pastTrick = Trick()
        try pastTrick.play(Card(suit: .clubs, rank: .five), by: playerA)
        try pastTrick.play(Card(suit: .hearts, rank: .king), by: playerB)  // B is void in clubs
        try pastTrick.play(Card(suit: .clubs, rank: .three), by: playerC)
        try pastTrick.play(Card(suit: .clubs, rank: .ace), by: playerD)

        // AI hand: clubs is the longest suit (3 cards), diamonds and spades are alternatives.
        // Without void avoidance the AI would lead the middle club.
        // With void avoidance it should skip clubs (voided) and choose diamonds or spades.
        let aiHand: Hand = [
            Card(suit: .clubs, rank: .six),
            Card(suit: .clubs, rank: .eight),
            Card(suit: .clubs, rank: .ten),
            Card(suit: .diamonds, rank: .four),
            Card(suit: .spades, rank: .two),
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

    func test_advancedAI_leads_any_valid_card_when_all_suits_are_voided() throws {
        // Make clubs and spades both voided so the only legal non-heart leads are constrained.
        let p1 = Player(name: "P1")
        let p2 = Player(name: "P2")
        let p3 = Player(name: "P3")
        let p4 = Player(name: "P4")

        // Trick where clubs was led but p2 played off-suit → p2 void in clubs
        var trick1 = Trick()
        try trick1.play(Card(suit: .clubs, rank: .three), by: p1)
        try trick1.play(Card(suit: .spades, rank: .two), by: p2)   // p2 void in clubs
        try trick1.play(Card(suit: .clubs, rank: .four), by: p3)
        try trick1.play(Card(suit: .clubs, rank: .five), by: p4)

        // Trick where diamonds was led but p3 played off-suit → p3 void in diamonds
        var trick2 = Trick()
        try trick2.play(Card(suit: .diamonds, rank: .three), by: p1)
        try trick2.play(Card(suit: .diamonds, rank: .four), by: p2)
        try trick2.play(Card(suit: .clubs, rank: .six), by: p3)    // p3 void in diamonds
        try trick2.play(Card(suit: .diamonds, rank: .five), by: p4)

        // AI hand: only spades remain to lead (hearts not broken)
        let aiHand: Hand = [
            Card(suit: .spades, rank: .seven),
            Card(suit: .spades, rank: .nine),
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

    func test_advancedAI_does_not_avoid_suit_with_no_void_history() throws {
        // No completed tricks → no void info → AI should use normal longest-suit logic.
        let aiHand: Hand = [
            Card(suit: .clubs, rank: .six),
            Card(suit: .clubs, rank: .eight),
            Card(suit: .clubs, rank: .ten),
            Card(suit: .diamonds, rank: .four),
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
}
