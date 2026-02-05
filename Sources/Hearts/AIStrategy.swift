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
        // Random strategy: randomly select 3 cards from hand
        let shuffled = hand.shuffled()
        return (shuffled[0], shuffled[1], shuffled[2])
    }

    func selectCardToPlay(from hand: Hand) -> Card {
        // Random strategy: randomly select any card from hand
        return hand.randomElement()!
    }
}

struct BasicAIStrategy: AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards {
        // Basic strategy: Pass high dangerous cards
        // Priority: Queen of Spades > High Hearts > High Spades > Other high cards

        let sorted = hand.sorted { lhs, rhs in
            // Queen of Spades is most dangerous
            if lhs.suit == .spades && lhs.rank == .queen { return true }
            if rhs.suit == .spades && rhs.rank == .queen { return false }

            // High hearts are very dangerous
            if lhs.suit == .hearts && rhs.suit != .hearts { return true }
            if rhs.suit == .hearts && lhs.suit != .hearts { return false }

            // High spades are dangerous (might take Q♠)
            if lhs.suit == .spades && rhs.suit != .spades { return true }
            if rhs.suit == .spades && lhs.suit != .spades { return false }

            // Otherwise, prefer passing higher cards
            return lhs.rank.rawValue > rhs.rank.rawValue
        }

        return (sorted[0], sorted[1], sorted[2])
    }

    func selectCardToPlay(from hand: Hand) -> Card {
        // Basic strategy: Play low cards to avoid taking points
        // If all cards are bad, dump the highest card

        // Prefer playing low cards
        let sorted = hand.sorted { lhs, rhs in
            lhs.rank.rawValue < rhs.rank.rawValue
        }

        return sorted[0]
    }
}

struct AdvancedAIStrategy: AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards {
        // Advanced strategy: Try to void a suit or minimize dangerous cards
        // 1. Check if we can void a suit (pass all cards of shortest suit)
        // 2. Otherwise, pass high dangerous cards strategically

        let suitGroups = Dictionary(grouping: hand, by: { $0.suit })

        // Find the shortest suit (candidate for voiding)
        // When there are ties, prefer to void the suit containing Q♠ (most dangerous)
        let shortestSuit = suitGroups.min(by: { lhs, rhs in
            if lhs.value.count != rhs.value.count {
                return lhs.value.count < rhs.value.count
            }
            // Tie: prefer suit with Q♠
            let lhsHasQueen = lhs.value.contains { $0.suit == .spades && $0.rank == .queen }
            let rhsHasQueen = rhs.value.contains { $0.suit == .spades && $0.rank == .queen }
            return lhsHasQueen && !rhsHasQueen
        })

        if let shortest = shortestSuit, shortest.value.count <= 3 {
            // We can void this suit completely! Pass all cards of this suit
            let cardsToPass = shortest.value.sorted { $0.rank.rawValue > $1.rank.rawValue }
            if cardsToPass.count == 3 {
                return (cardsToPass[0], cardsToPass[1], cardsToPass[2])
            } else if cardsToPass.count == 2 {
                // Void the 2-card suit + pass 1 high dangerous card
                let remaining = hand.filter { $0.suit != shortest.key }
                let highDangerous = remaining.sorted { lhs, rhs in
                    // Q♠ is most dangerous
                    if lhs.suit == .spades && lhs.rank == .queen { return true }
                    if rhs.suit == .spades && rhs.rank == .queen { return false }
                    // High hearts next
                    if lhs.suit == .hearts && rhs.suit != .hearts { return true }
                    if rhs.suit == .hearts && lhs.suit != .hearts { return false }
                    return lhs.rank.rawValue > rhs.rank.rawValue
                }
                return (cardsToPass[0], cardsToPass[1], highDangerous[0])
            } else if cardsToPass.count == 1 {
                // Void the 1-card suit + pass 2 high dangerous cards
                let remaining = hand.filter { $0.suit != shortest.key }
                let highDangerous = remaining.sorted { lhs, rhs in
                    if lhs.suit == .spades && lhs.rank == .queen { return true }
                    if rhs.suit == .spades && rhs.rank == .queen { return false }
                    if lhs.suit == .hearts && rhs.suit != .hearts { return true }
                    if rhs.suit == .hearts && lhs.suit != .hearts { return false }
                    return lhs.rank.rawValue > rhs.rank.rawValue
                }
                return (cardsToPass[0], highDangerous[0], highDangerous[1])
            }
        }

        // Can't void a suit, use sophisticated passing logic
        var cardsToPass: [Card] = []

        // Priority 1: Pass Queen of Spades if we have it
        if let queenOfSpades = hand.first(where: { $0.suit == .spades && $0.rank == .queen }) {
            cardsToPass.append(queenOfSpades)
        }

        // Priority 2: Pass high hearts (Ace, King, Queen)
        let highHearts = hand.filter {
            $0.suit == .hearts && $0.rank.rawValue >= Card.Rank.jack.rawValue
        }.sorted { $0.rank.rawValue > $1.rank.rawValue }

        for card in highHearts.prefix(3 - cardsToPass.count) {
            cardsToPass.append(card)
        }

        // Priority 3: Pass high spades (to avoid capturing Q♠)
        if cardsToPass.count < 3 {
            let highSpades = hand.filter {
                $0.suit == .spades && $0.rank.rawValue >= Card.Rank.jack.rawValue &&
                !($0.rank == .queen) // Already handled Q♠
            }.sorted { $0.rank.rawValue > $1.rank.rawValue }

            for card in highSpades.prefix(3 - cardsToPass.count) {
                cardsToPass.append(card)
            }
        }

        // Priority 4: Pass any other high cards
        if cardsToPass.count < 3 {
            let remaining = hand.filter { !cardsToPass.contains($0) }
                .sorted { $0.rank.rawValue > $1.rank.rawValue }

            for card in remaining.prefix(3 - cardsToPass.count) {
                cardsToPass.append(card)
            }
        }

        return (cardsToPass[0], cardsToPass[1], cardsToPass[2])
    }

    func selectCardToPlay(from hand: Hand) -> Card {
        // Advanced strategy: Play smart based on hand composition
        // Without game state, we focus on:
        // 1. Prefer playing middle-value cards (not too high, not wasting low cards)
        // 2. Avoid playing point cards if we have safe alternatives
        // 3. Try to play from longest suit to maintain flexibility

        let suitGroups = Dictionary(grouping: hand, by: { $0.suit })

        // Find the longest suit (gives us most flexibility)
        let longestSuit = suitGroups.max(by: { $0.value.count < $1.value.count })

        if let longest = longestSuit {
            // Play a middle card from longest suit
            let sortedCards = longest.value.sorted { $0.rank.rawValue < $1.rank.rawValue }

            // Prefer middle cards (not lowest, not highest)
            if sortedCards.count >= 3 {
                return sortedCards[sortedCards.count / 2]
            } else if sortedCards.count == 2 {
                return sortedCards[0] // Play lower card
            } else {
                return sortedCards[0]
            }
        }

        // Fallback: play lowest card
        return hand.min(by: { $0.rank.rawValue < $1.rank.rawValue })!
    }
}
