//
//  Scoring.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

/// The point rules of Hearts under a particular `GameConfiguration`.
///
/// `Scoring` is the single authority on how many points a card or trick is worth. It is a
/// pure value: it never inspects a `Game`, so consumers can score hand-built tricks and
/// UIs can explain a result without driving the engine.
public struct Scoring: Sendable {
    /// The rule variants this scorer applies.
    public let configuration: GameConfiguration

    /// Creates a scorer for `configuration`.
    /// - Parameter configuration: Rule variants (J♦ bonus, moon-shot variant, winning score).
    public init(configuration: GameConfiguration) {
        self.configuration = configuration
    }

    /// Points a single card is worth to whoever captures it.
    ///
    /// Hearts are 1, Q♠ is 13, and J♦ is −10 when `configuration.jackOfDiamondsBonus`
    /// is enabled; everything else is 0.
    /// - Parameter card: The card to value.
    /// - Returns: The card's point value under this configuration.
    public func points(for card: Card) -> Int {
        if configuration.jackOfDiamondsBonus && card == Card(suit: .diamonds, rank: .jack) {
            return -10
        }
        return card.points
    }

    /// Points a trick is worth to its winner, complete or partial.
    /// - Parameter trick: The trick to score.
    /// - Returns: The sum of `points(for:)` over the cards played so far.
    public func points(in trick: Trick) -> Int {
        trick.cards.reduce(0) { $0 + points(for: $1) }
    }
}

/// The outcome of settling one hand, keyed by seat.
public struct HandResult: Equatable, Codable, Sendable {
    /// Points each seat adds to its total for this hand, after any moon-shot adjustment.
    public let roundScores: SeatMap<Int>
    /// Each seat's total after this hand's `roundScores` were applied.
    public let totalScores: SeatMap<Int>
    /// The seat that shot the moon this hand, or `nil` if nobody did.
    public let moonShooter: Seat?
}

extension Scoring {
    /// Settles a hand: values every seat's captured cards and adds them to the running totals.
    ///
    /// - Parameters:
    ///   - capturedCards: The cards each seat won in tricks this hand.
    ///   - totalScores: Each seat's total before this hand.
    /// - Returns: The per-seat round scores, the new totals, and the moon shooter if any.
    public func settleHand(capturedCards: SeatMap<[Card]>, totalScores: SeatMap<Int>) -> HandResult {
        var roundScores = capturedCards.mapValues { cards in cards.reduce(0) { $0 + points(for: $1) } }
        let moonShooter = self.moonShooter(capturedCards: capturedCards)

        if let shooter = moonShooter {
            // The 26 points of hearts + Q♠ are forgiven; any J♦ bonus stays with whoever captured it.
            roundScores[shooter] -= Scoring.moonShotPoints
            switch configuration.moonShotVariant {
            case .addToOthers:
                for seat in Seat.allCases where seat != shooter {
                    roundScores[seat] += Scoring.moonShotPoints
                }
            case .subtractFromSelf:
                roundScores[shooter] -= Scoring.moonShotPoints
            }
        }

        return HandResult(
            roundScores: roundScores,
            totalScores: SeatMap { totalScores[$0] + roundScores[$0] },
            moonShooter: moonShooter
        )
    }

    /// The seat that captured every heart and Q♠ this hand, or `nil` if nobody did.
    /// - Parameter capturedCards: The cards each seat won in tricks this hand.
    /// - Returns: The moon shooter's seat.
    public func moonShooter(capturedCards: SeatMap<[Card]>) -> Seat? {
        capturedCards.first { _, cards in
            cards.filter { $0.suit == .hearts }.count == 13
                && cards.contains(Card(suit: .spades, rank: .queen))
        }?.seat
    }

    /// The combined value of all thirteen hearts and Q♠.
    static let moonShotPoints = 26
}

extension Scoring {
    /// Whether the game has ended: some seat has reached `configuration.winningScore`.
    /// - Parameter totalScores: Each seat's running total.
    public func isGameOver(totalScores: SeatMap<Int>) -> Bool {
        totalScores.values.contains { $0 >= configuration.winningScore }
    }

    /// Whether the game has ended with more than one seat sharing the lowest total,
    /// in which case there is no winner and another hand must be played.
    /// - Parameter totalScores: Each seat's running total.
    public func isTied(totalScores: SeatMap<Int>) -> Bool {
        guard isGameOver(totalScores: totalScores), let lowest = totalScores.values.min() else { return false }
        return totalScores.values.filter { $0 == lowest }.count > 1
    }

    /// The seat with the unique lowest total once the game is over.
    /// - Parameter totalScores: Each seat's running total.
    /// - Returns: The winning seat, or `nil` if the game is not over or is tied.
    public func winner(totalScores: SeatMap<Int>) -> Seat? {
        guard isGameOver(totalScores: totalScores), !isTied(totalScores: totalScores),
              let lowest = totalScores.values.min() else { return nil }
        return totalScores.first { $0.value == lowest }?.seat
    }
}
