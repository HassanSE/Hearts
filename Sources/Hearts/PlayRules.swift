//
//  PlayRules.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

/// The single authority on which cards may legally be played from a hand.
///
/// Captures the inputs the four Hearts play rules depend on and answers two questions about them:
/// `validate(_:)` explains why a specific card is illegal, and `legalMoves()` lists every card that
/// `validate(_:)` accepts. The second is defined in terms of the first, so they cannot disagree.
///
/// ```swift
/// let rules = PlayRules(hand: hand, currentTrick: trick, heartsBroken: false, isFirstTrick: true)
/// try rules.validate(card)          // throws GameError.cannotPlayPointsOnFirstTrick
/// let playable = rules.legalMoves() // every card in `hand` that validate() accepts
/// ```
///
/// The rules, in the order they are checked:
/// 1. The first trick of a hand must be led with 2♣.
/// 2. No point card (a heart or Q♠) may be played on the first trick unless the hand holds nothing else.
/// 3. Hearts may not be led until broken unless the hand holds only hearts.
/// 4. The lead suit must be followed if the hand holds it.
///
/// Turn order and hand completion are `Game`'s responsibility, not this type's.
public struct PlayRules: Sendable {
    /// The cards the deciding player currently holds.
    public let hand: [Card]
    /// The trick in progress; empty when the player is leading.
    public let currentTrick: Trick
    /// Whether a heart has already been played this hand.
    public let heartsBroken: Bool
    /// Whether no trick has yet been completed this hand.
    public let isFirstTrick: Bool

    /// Creates a rules oracle for one decision.
    /// - Parameters:
    ///   - hand: The cards the deciding player currently holds.
    ///   - currentTrick: The trick in progress; empty when the player is leading.
    ///   - heartsBroken: Whether a heart has already been played this hand.
    ///   - isFirstTrick: Whether no trick has yet been completed this hand.
    public init(hand: [Card], currentTrick: Trick, heartsBroken: Bool, isFirstTrick: Bool) {
        self.hand = hand
        self.currentTrick = currentTrick
        self.heartsBroken = heartsBroken
        self.isFirstTrick = isFirstTrick
    }

    /// Whether the deciding player is leading the trick.
    private var isLeading: Bool { currentTrick.leadSuit == nil }

    /// Checks whether `card` may be played from `hand` right now.
    /// - Parameter card: The card to check.
    /// - Throws: The first violated rule, as a `GameError`: `.cardNotInHand`, `.mustLeadWithTwoOfClubs`,
    ///   `.cannotPlayPointsOnFirstTrick`, `.heartsNotBroken` or `.mustFollowSuit(required:)`.
    public func validate(_ card: Card) throws {
        guard hand.contains(card) else {
            throw GameError.cardNotInHand
        }

        if isFirstTrick && isLeading {
            guard card.suit == .clubs && card.rank == .two else {
                throw GameError.mustLeadWithTwoOfClubs
            }
        }

        if isFirstTrick && card.points > 0 {
            let hasNonPointCard = hand.contains(where: { $0.points == 0 })
            guard !hasNonPointCard else {
                throw GameError.cannotPlayPointsOnFirstTrick
            }
        }

        if isLeading && card.suit == .hearts && !heartsBroken {
            let hasOnlyHearts = hand.allSatisfy { $0.suit == .hearts }
            guard hasOnlyHearts else {
                throw GameError.heartsNotBroken
            }
        }

        if let leadSuit = currentTrick.leadSuit {
            let hasLeadSuit = hand.contains(where: { $0.suit == leadSuit })
            if hasLeadSuit && card.suit != leadSuit {
                throw GameError.mustFollowSuit(required: leadSuit)
            }
        }
    }

    /// The cards in `hand` that `validate(_:)` accepts, in hand order.
    /// - Returns: Every legal card. In states reachable through `Game` this is empty only if the hand is
    ///   empty or the first trick's leader lacks 2♣.
    public func legalMoves() -> [Card] {
        hand.filter { (try? validate($0)) != nil }
    }
}
