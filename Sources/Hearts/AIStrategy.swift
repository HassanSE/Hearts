//
//  AIStrategy.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import Foundation

// MARK: - Trick Context

/// Context information needed for AI to make informed card-playing decisions
struct TrickContext {
    let hand: Hand
    let currentTrick: Trick
    let heartsBroken: Bool
    let isFirstTrick: Bool

    /// Returns only the cards from hand that are legal to play given the current game state
    func getLegalMoves() -> [Card] {
        var legalMoves = hand

        // Rule 1: Must follow suit if possible
        if let leadSuit = currentTrick.leadSuit {
            let cardsOfLeadSuit = hand.filter { $0.suit == leadSuit }
            if !cardsOfLeadSuit.isEmpty {
                legalMoves = cardsOfLeadSuit
            }
        }

        // Rule 2: Cannot lead hearts until broken (unless only hearts remain)
        if currentTrick.leadSuit == nil && !heartsBroken {
            let nonHearts = legalMoves.filter { $0.suit != .hearts }
            if !nonHearts.isEmpty {
                legalMoves = nonHearts
            }
        }

        // Rule 3: Cannot play points on first trick (unless no choice)
        if isFirstTrick && currentTrick.leadSuit != nil {
            let nonPointCards = legalMoves.filter { $0.points == 0 }
            if !nonPointCards.isEmpty {
                legalMoves = nonPointCards
            }
        }

        return legalMoves
    }
}

// MARK: - AI Strategy Protocol

protocol AIStrategy {
    func selectCardsToPass(from hand: Hand) -> PassedCards
    func selectCardToPlay(context: TrickContext) -> Card
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

    func selectCardToPlay(context: TrickContext) -> Card {
        // Random strategy: randomly select from legal moves
        let legalMoves = context.getLegalMoves()
        return legalMoves.randomElement()!
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

    func selectCardToPlay(context: TrickContext) -> Card {
        // Basic strategy: Play low cards to avoid taking points
        let legalMoves = context.getLegalMoves()

        // If we must follow suit, try to play low and avoid winning
        if context.currentTrick.leadSuit != nil {
            let sorted = legalMoves.sorted { $0.rank.rawValue < $1.rank.rawValue }
            return sorted[0]
        }

        // If we're leading, prefer non-point cards, then lowest card
        let nonPointCards = legalMoves.filter { $0.points == 0 }
        let cardsToConsider = nonPointCards.isEmpty ? legalMoves : nonPointCards

        let sorted = cardsToConsider.sorted { $0.rank.rawValue < $1.rank.rawValue }
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

    func selectCardToPlay(context: TrickContext) -> Card {
        // Advanced strategy: Play smart based on current trick and game state
        let legalMoves = context.getLegalMoves()

        // If following suit, try to duck under (play high but not highest)
        if context.currentTrick.leadSuit != nil {
            return selectCardToFollow(legalMoves: legalMoves, currentTrick: context.currentTrick)
        }

        // If leading, be strategic
        return selectCardToLead(legalMoves: legalMoves, hand: context.hand, heartsBroken: context.heartsBroken)
    }

    private func selectCardToFollow(legalMoves: [Card], currentTrick: Trick) -> Card {
        // Get the highest card played so far in the lead suit
        let cardsInLeadSuit = currentTrick.cards.filter { $0.suit == currentTrick.leadSuit }
        let highestSoFar = cardsInLeadSuit.max(by: { $0.rank.rawValue < $1.rank.rawValue })

        let sorted = legalMoves.sorted { $0.rank.rawValue < $1.rank.rawValue }

        // Try to duck under: play the highest card that won't win
        if let highest = highestSoFar {
            let safeCards = sorted.filter { $0.rank.rawValue < highest.rank.rawValue }
            if !safeCards.isEmpty {
                // Play highest safe card (duck under)
                return safeCards.last!
            }
        }

        // If we can't avoid winning or trick has points, play lowest
        if currentTrick.points > 0 {
            return sorted[0]
        }

        // No points in trick, play middle card
        if sorted.count >= 3 {
            return sorted[sorted.count / 2]
        }
        return sorted[0]
    }

    private func selectCardToLead(legalMoves: [Card], hand: Hand, heartsBroken: Bool) -> Card {
        // When leading, prefer cards from our longest suit for flexibility
        let suitGroups = Dictionary(grouping: hand, by: { $0.suit })
        let longestSuit = suitGroups.max(by: { $0.value.count < $1.value.count })

        if let longest = longestSuit {
            let legalFromLongest = legalMoves.filter { $0.suit == longest.key }
            if !legalFromLongest.isEmpty {
                let sorted = legalFromLongest.sorted { $0.rank.rawValue < $1.rank.rawValue }
                // Lead middle card from longest suit
                if sorted.count >= 3 {
                    return sorted[sorted.count / 2]
                }
                return sorted[0]
            }
        }

        // Fallback: play lowest card
        let sorted = legalMoves.sorted { $0.rank.rawValue < $1.rank.rawValue }
        return sorted[0]
    }
}
