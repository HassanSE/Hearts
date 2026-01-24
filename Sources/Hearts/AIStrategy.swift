//
//  AIStrategy.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import Foundation

// MARK: - AI Strategy Protocol

protocol AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards
    func selectCardToPlay(from hand: Hand) -> Card
}

// MARK: - Bot Difficulty

enum BotDifficulty {
    case easy
    case medium
    case hard

    func makeStrategy() -> AIStrategy {
        switch self {
        case .easy:
            return RandomAIStrategy()
        case .medium:
            return BasicAIStrategy()
        case .hard:
            return AdvancedAIStrategy()
        }
    }
}

// MARK: - AI Strategy Implementations

struct RandomAIStrategy: AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards {
        // Random strategy: just pick first 3 cards
        return (hand[0], hand[1], hand[2])
    }

    func selectCardToPlay(from hand: Hand) -> Card {
        // Random strategy: pick first valid card
        return hand[0]
    }
}

struct BasicAIStrategy: AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards {
        // Basic strategy: pass high cards
        // TODO: Implement smarter logic
        return (hand[0], hand[1], hand[2])
    }

    func selectCardToPlay(from hand: Hand) -> Card {
        // Basic strategy: simple heuristics
        // TODO: Implement smarter logic
        return hand[0]
    }
}

struct AdvancedAIStrategy: AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards {
        // Advanced strategy: card counting, shooting the moon detection
        // TODO: Implement advanced logic
        return (hand[0], hand[1], hand[2])
    }

    func selectCardToPlay(from hand: Hand) -> Card {
        // Advanced strategy: strategic play
        // TODO: Implement advanced logic
        return hand[0]
    }
}
