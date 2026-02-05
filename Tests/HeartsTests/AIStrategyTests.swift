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

        let selectedCard = strategy.selectCardToPlay(from: hand)

        // Should return a card from the hand
        XCTAssertTrue(hand.contains(selectedCard))
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

        let selectedCard = strategy.selectCardToPlay(from: hand)

        // Should select the lowest card (2 of clubs)
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

        let selectedCard = strategy.selectCardToPlay(from: hand)

        // Should prefer middle card over lowest or highest
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

        let selectedCard = strategy.selectCardToPlay(from: hand)

        // Should play from hearts (longest suit)
        XCTAssertEqual(selectedCard.suit, .hearts)
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
