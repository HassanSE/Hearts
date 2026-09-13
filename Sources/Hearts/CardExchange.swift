//
//  CardExchange.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import Foundation

/// Direction in which each seat passes three cards before a hand.
///
/// The direction rotates each round: left, right, across, then no pass.
public enum CardExchangeDirection: Codable {
    /// Each seat passes to the next seat clockwise.
    case left
    /// Each seat passes to the previous seat.
    case right
    /// Each seat passes to the seat opposite.
    case across
    /// No cards are passed this hand.
    case none

    /// Seat offset (mod 4) from a passer to its recipient, or `nil` when no cards are passed.
    var seatOffset: Int? {
        switch self {
        case .left: return 1
        case .right: return 3
        case .across: return 2
        case .none: return nil
        }
    }

    /// The seat that receives cards passed from `seat`, or `nil` when no cards are passed.
    func recipient(of seat: Int, seatCount: Int = 4) -> Int? {
        seatOffset.map { (seat + $0) % seatCount }
    }
}

/// Three cards chosen to pass, as returned by an AI strategy.
typealias PassedCards = (first: Card, second: Card, third: Card)

/// Number of cards each seat passes during an exchange.
let cardsPerExchange = 3

/// The pure card-exchange operation: validates every seat's selection and computes the resulting hands.
///
/// Holds no game state, so it can be exercised with hand-built hands. `Game.performExchange(selections:)`
/// wraps it with phase checks and bot selections.
enum CardExchange {
    /// Validates `selections` against `hands` and returns the hands after passing in `direction`.
    ///
    /// - Parameters:
    ///   - hands: Current hand for each seat, indexed by seat.
    ///   - selections: Exactly three distinct cards for every seat, keyed by seat.
    ///   - direction: Where each seat's cards go. Must not be `.none`.
    /// - Returns: New hands, indexed by seat, with passed cards removed and received cards appended.
    /// - Throws: `GameError.invalidSeat`, `.missingPassSelection`, `.wrongPassCount`,
    ///   `.duplicatePassCards`, or `.passedCardNotInHand`. Nothing is modified on failure.
    static func apply(hands: [[Card]], selections: [Int: [Card]], direction: CardExchangeDirection) throws -> [[Card]] {
        let seatCount = hands.count
        for seat in selections.keys where !(0..<seatCount).contains(seat) {
            throw GameError.invalidSeat(seat)
        }
        for seat in 0..<seatCount {
            guard let selection = selections[seat] else { throw GameError.missingPassSelection(seat: seat) }
            guard selection.count == cardsPerExchange else {
                throw GameError.wrongPassCount(seat: seat, count: selection.count)
            }
            let hasDuplicate = selection.indices.contains { i in selection[..<i].contains(selection[i]) }
            guard !hasDuplicate else { throw GameError.duplicatePassCards(seat: seat) }
            for card in selection where !hands[seat].contains(card) {
                throw GameError.passedCardNotInHand(seat: seat, card: card)
            }
        }

        var result = hands
        for seat in 0..<seatCount {
            guard let selection = selections[seat], let recipient = direction.recipient(of: seat, seatCount: seatCount) else {
                continue
            }
            result[seat].removeAll { selection.contains($0) }
            result[recipient].append(contentsOf: selection)
        }
        return result
    }
}
