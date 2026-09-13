//
//  AIStrategy.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

// MARK: - Trick Context

/// Everything a strategy may consult when choosing a card to play.
///
/// Built by `Game` for the deciding seat on every play. All state is a copy taken at decision time,
/// so a strategy cannot mutate the game through it.
public struct TrickContext: Sendable {
    /// The seat making this decision.
    public let seat: Seat
    /// The cards `seat` currently holds.
    public let hand: [Card]
    /// The trick in progress; empty when `seat` is leading.
    public let currentTrick: Trick
    /// Whether a heart has been played this hand.
    public let heartsBroken: Bool
    /// Whether this is the first trick of the hand.
    public let isFirstTrick: Bool
    /// Tricks already completed this hand, in play order.
    public let completedTricks: [Trick]
    /// Raw points each seat has taken in tricks so far this hand (before moon-shot settlement).
    public let roundScores: SeatMap<Int>
    /// Each seat's running total across settled hands.
    public let totalScores: SeatMap<Int>
    /// Zero-based index of the current hand.
    public let roundNumber: Int

    /// Creates a context. Defaults describe the first trick of a fresh game with no history.
    public init(
        seat: Seat = .south,
        hand: [Card],
        currentTrick: Trick,
        heartsBroken: Bool,
        isFirstTrick: Bool,
        completedTricks: [Trick] = [],
        roundScores: SeatMap<Int> = SeatMap(repeating: 0),
        totalScores: SeatMap<Int> = SeatMap(repeating: 0),
        roundNumber: Int = 0
    ) {
        self.seat = seat
        self.hand = hand
        self.currentTrick = currentTrick
        self.heartsBroken = heartsBroken
        self.isFirstTrick = isFirstTrick
        self.completedTricks = completedTricks
        self.roundScores = roundScores
        self.totalScores = totalScores
        self.roundNumber = roundNumber
    }

    /// The seat that led `currentTrick`, or `nil` when `seat` is about to lead.
    public var trickLeader: Seat? {
        currentTrick.plays.first?.seat
    }

    /// All cards played in previous completed tricks
    public var playedCards: [Card] {
        completedTricks.flatMap { $0.cards }
    }

    /// The cards in `hand` that `PlayRules` accepts for this decision.
    public var legalMoves: [Card] {
        PlayRules(hand: hand, currentTrick: currentTrick, heartsBroken: heartsBroken, isFirstTrick: isFirstTrick)
            .legalMoves()
    }
}

// MARK: - AI Strategy Protocol

/// Decision-making for a bot seat.
///
/// `Game` keeps one instance per bot seat for the life of the game, so a class conformer can
/// remember what it has seen across tricks and hands; a struct conformer is stateless.
/// Supply your own via `Game.init(…, strategies:)`; the built-in ones are chosen by `BotDifficulty`.
public protocol AIStrategy {
    /// Chooses three cards to pass before a hand.
    /// - Parameters:
    ///   - hand: The full 13-card hand.
    ///   - direction: Where the cards will go.
    /// - Returns: Three distinct cards from `hand`.
    func selectCardsToPass(from hand: [Card], direction: CardExchangeDirection) -> PassedCards

    /// Chooses a card to play.
    /// - Parameter context: The deciding seat's hand and the visible game state.
    /// - Returns: A card from `context.legalMoves`, which is never empty when `Game` calls this.
    func selectCardToPlay(context: TrickContext) -> Card
}

// MARK: - Bot Difficulty

/// Which built-in `AIStrategy` a bot seat uses.
public enum BotDifficulty: Hashable, Codable, Sendable {
    /// `RandomAIStrategy`: any legal card.
    case easy
    /// `BasicAIStrategy`: plays low, passes high.
    case medium
    /// `AdvancedAIStrategy`: card counting, void inference and moon-shot pursuit.
    case hard

    /// Builds the strategy for this difficulty.
    /// - Parameter randomSource: Generator the random (easy) strategy draws from; ignored by the
    ///   deterministic strategies.
    func makeStrategy(randomSource: RandomSource) -> AIStrategy {
        switch self {
        case .easy:
            return RandomAIStrategy(randomSource: randomSource)
        case .medium:
            return BasicAIStrategy()
        case .hard:
            return AdvancedAIStrategy()
        }
    }
}

// MARK: - AI Strategy Implementations

extension Card {
    /// Passing priority shared by the built-in strategies: Q♠ first, then hearts, then spades
    /// (they risk winning Q♠), then anything else by descending rank.
    static func isMoreDangerous(_ lhs: Card, than rhs: Card) -> Bool {
        let lhsIsQueen = lhs == Card(suit: .spades, rank: .queen)
        let rhsIsQueen = rhs == Card(suit: .spades, rank: .queen)
        if lhsIsQueen != rhsIsQueen { return lhsIsQueen }
        if (lhs.suit == .hearts) != (rhs.suit == .hearts) { return lhs.suit == .hearts }
        if (lhs.suit == .spades) != (rhs.suit == .spades) { return lhs.suit == .spades }
        return lhs.rank > rhs.rank
    }
}

/// Easy: passes three random cards and plays a random legal card.
public struct RandomAIStrategy: AIStrategy {
    /// Shared with the owning `Game` so a seeded game replays its random plays exactly.
    var randomSource: RandomSource

    /// Creates a strategy drawing from the system generator. `Game` substitutes its own seeded source.
    public init() {
        self.randomSource = RandomSource(SystemRandomNumberGenerator())
    }

    init(randomSource: RandomSource) {
        self.randomSource = randomSource
    }

    /// Passes three cards drawn at random from `hand`.
    /// - Parameters:
    ///   - hand: The full 13-card hand.
    ///   - direction: Ignored.
    /// - Returns: Three distinct cards from `hand`.
    public func selectCardsToPass(from hand: [Card], direction: CardExchangeDirection) -> PassedCards {
        // Random strategy: randomly select 3 cards from hand
        var generator = randomSource
        let shuffled = hand.shuffled(using: &generator)
        return (shuffled[0], shuffled[1], shuffled[2])
    }

    /// Plays a card drawn at random from `context.legalMoves`.
    /// - Parameter context: The deciding seat's hand and the visible game state.
    /// - Returns: A random legal card (or the first card in hand if, outside `Game`, none is legal).
    public func selectCardToPlay(context: TrickContext) -> Card {
        // Random strategy: randomly select from legal moves
        var generator = randomSource
        // `Game` only asks while a legal move exists; the hand fallback keeps this total.
        return context.legalMoves.randomElement(using: &generator) ?? context.hand[0]
    }
}

/// Medium: passes the most dangerous cards and plays low.
public struct BasicAIStrategy: AIStrategy {
    /// Creates the strategy; it holds no state.
    public init() {}

    /// Passes the three most dangerous cards: Q♠, then hearts, then spades, then highest rank.
    /// - Parameters:
    ///   - hand: The full 13-card hand.
    ///   - direction: Ignored.
    /// - Returns: Three distinct cards from `hand`.
    public func selectCardsToPass(from hand: [Card], direction: CardExchangeDirection) -> PassedCards {
        // Basic strategy: Pass high dangerous cards
        // Priority: Queen of Spades > High Hearts > High Spades > Other high cards

        let sorted = hand.sorted(by: Card.isMoreDangerous)

        return (sorted[0], sorted[1], sorted[2])
    }

    /// Plays the lowest legal card when following; when leading, the lowest non-point card if there is one.
    /// - Parameter context: The deciding seat's hand and the visible game state.
    /// - Returns: A card from `context.legalMoves`.
    public func selectCardToPlay(context: TrickContext) -> Card {
        // Basic strategy: Play low cards to avoid taking points
        let legalMoves = context.legalMoves

        // If we must follow suit, try to play low and avoid winning
        if context.currentTrick.leadSuit != nil {
            let sorted = legalMoves.sorted { $0.rank < $1.rank }
            return sorted[0]
        }

        // If we're leading, prefer non-point cards, then lowest card
        let nonPointCards = legalMoves.filter { $0.points == 0 }
        let cardsToConsider = nonPointCards.isEmpty ? legalMoves : nonPointCards

        let sorted = cardsToConsider.sorted { $0.rank < $1.rank }
        return sorted[0]
    }
}

/// Hard: voids suits when passing, counts spades, avoids known voids and pursues the moon.
public struct AdvancedAIStrategy: AIStrategy {
    /// Creates the strategy; it holds no state and infers everything from `TrickContext`.
    public init() {}

    /// Passes to void the shortest suit when it has three cards or fewer (topping up with the most
    /// dangerous other cards); otherwise Q♠, high hearts, high spades, then the highest remaining ranks.
    /// - Parameters:
    ///   - hand: The full 13-card hand.
    ///   - direction: Ignored.
    /// - Returns: Three distinct cards from `hand`.
    public func selectCardsToPass(from hand: [Card], direction: CardExchangeDirection) -> PassedCards {
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
            let cardsToPass = shortest.value.sorted { $0.rank > $1.rank }
            if cardsToPass.count == 3 {
                return (cardsToPass[0], cardsToPass[1], cardsToPass[2])
            } else if cardsToPass.count == 2 {
                // Void the 2-card suit + pass 1 high dangerous card
                let highDangerous = hand.filter { $0.suit != shortest.key }.sorted(by: Card.isMoreDangerous)
                return (cardsToPass[0], cardsToPass[1], highDangerous[0])
            } else if cardsToPass.count == 1 {
                // Void the 1-card suit + pass 2 high dangerous cards
                let highDangerous = hand.filter { $0.suit != shortest.key }.sorted(by: Card.isMoreDangerous)
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
            $0.suit == .hearts && $0.rank >= .jack
        }.sorted { $0.rank > $1.rank }

        for card in highHearts.prefix(3 - cardsToPass.count) {
            cardsToPass.append(card)
        }

        // Priority 3: Pass high spades (to avoid capturing Q♠)
        if cardsToPass.count < 3 {
            let highSpades = hand.filter {
                $0.suit == .spades && $0.rank >= .jack &&
                !($0.rank == .queen) // Already handled Q♠
            }.sorted { $0.rank > $1.rank }

            for card in highSpades.prefix(3 - cardsToPass.count) {
                cardsToPass.append(card)
            }
        }

        // Priority 4: Pass any other high cards
        if cardsToPass.count < 3 {
            let remaining = hand.filter { !cardsToPass.contains($0) }
                .sorted { $0.rank > $1.rank }

            for card in remaining.prefix(3 - cardsToPass.count) {
                cardsToPass.append(card)
            }
        }

        return (cardsToPass[0], cardsToPass[1], cardsToPass[2])
    }

    /// Chooses a card using the tricks seen so far. Pursues the moon while it holds Q♠ and seven or
    /// more hearts and no opponent has captured a point. Otherwise, when following, plays the highest
    /// card that will not win the trick, falling back to the lowest if the trick holds points; when
    /// leading, leads Q♠ once A♠ and K♠ are gone, avoids suits an opponent is known to be void in,
    /// and prefers its longest suit.
    /// - Parameter context: The deciding seat's hand and the visible game state.
    /// - Returns: A card from `context.legalMoves`.
    public func selectCardToPlay(context: TrickContext) -> Card {
        // Advanced strategy: Play smart based on current trick and game state
        let legalMoves = context.legalMoves

        // Moon-shot pursuit: if we hold a dominant heart hand + Q♠, try to capture everything
        if shouldAttemptMoonShot(context: context) {
            if context.currentTrick.leadSuit != nil {
                // Following: play highest card to win the trick and capture points
                if let highest = legalMoves.max(by: { $0.rank < $1.rank }) {
                    return highest
                }
            } else {
                // Leading: lead highest heart to force opponents to give up points
                let hearts = legalMoves.filter { $0.suit == .hearts }
                if let highestHeart = hearts.max(by: { $0.rank < $1.rank }) {
                    return highestHeart
                }
                if let queenOfSpades = legalMoves.first(where: { $0.suit == .spades && $0.rank == .queen }) {
                    return queenOfSpades
                }
            }
        }

        // If following suit, try to duck under (play high but not highest)
        if context.currentTrick.leadSuit != nil {
            return selectCardToFollow(legalMoves: legalMoves, currentTrick: context.currentTrick)
        }

        // If leading, be strategic
        return selectCardToLead(legalMoves: legalMoves, context: context)
    }

    /// A moon attempt needs a dominant heart hand with Q♠ and, crucially, no point already captured
    /// by another seat — once an opponent holds a heart or Q♠ the moon is impossible and chasing it
    /// would only pile up points.
    private func shouldAttemptMoonShot(context: TrickContext) -> Bool {
        let heartsInHand = context.hand.filter { $0.suit == .hearts }.count
        let hasQueenOfSpades = context.hand.contains { $0.suit == .spades && $0.rank == .queen }
        return heartsInHand >= 7 && hasQueenOfSpades && !opponentHasTakenPoints(context: context)
    }

    /// Whether any seat other than the deciding one has won a trick containing a heart or Q♠.
    private func opponentHasTakenPoints(context: TrickContext) -> Bool {
        context.completedTricks.contains { trick in
            trick.winner != context.seat && trick.cards.contains { $0.points > 0 }
        }
    }

    private func selectCardToFollow(legalMoves: [Card], currentTrick: Trick) -> Card {
        // Get the highest card played so far in the lead suit
        let cardsInLeadSuit = currentTrick.cards.filter { $0.suit == currentTrick.leadSuit }
        let highestSoFar = cardsInLeadSuit.max(by: { $0.rank < $1.rank })

        let sorted = legalMoves.sorted { $0.rank < $1.rank }

        // Try to duck under: play the highest card that won't win
        if let highest = highestSoFar {
            // Play highest safe card (duck under)
            if let highestSafe = sorted.last(where: { $0.rank < highest.rank }) {
                return highestSafe
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

    private func selectCardToLead(legalMoves: [Card], context: TrickContext) -> Card {
        let playedCards = context.playedCards

        // Card counting: if A♠ and K♠ have both been played, Q♠ is safe to lead
        if let queenOfSpades = legalMoves.first(where: { $0.suit == .spades && $0.rank == .queen }) {
            let aceOfSpadesPlayed = playedCards.contains { $0.suit == .spades && $0.rank == .ace }
            let kingOfSpadesPlayed = playedCards.contains { $0.suit == .spades && $0.rank == .king }
            if aceOfSpadesPlayed && kingOfSpadesPlayed {
                return queenOfSpades
            }
        }

        // Opponent void avoidance: avoid leading suits where an opponent is known void.
        // An opponent is inferred void in suit S if they played off-suit when S was the lead.
        // Leading into a void invites dangerous discards (high hearts, Q♠) onto our trick.
        let voidedSuits = opponentVoidedSuits(from: context.completedTricks, excluding: context.seat)
        let safeLeads = legalMoves.filter { !voidedSuits.contains($0.suit) }
        let movesToConsider = safeLeads.isEmpty ? legalMoves : safeLeads

        // Among safe leads, prefer cards from our longest suit for flexibility.
        // Iterate suits from longest to shortest so we respect the safe-lead constraint.
        let suitGroups = Dictionary(grouping: context.hand, by: { $0.suit })
        let suitsByLength = suitGroups.sorted { $0.value.count > $1.value.count }

        for (suit, _) in suitsByLength {
            let candidates = movesToConsider.filter { $0.suit == suit }
            if !candidates.isEmpty {
                let sorted = candidates.sorted { $0.rank < $1.rank }
                return sorted.count >= 3 ? sorted[sorted.count / 2] : sorted[0]
            }
        }

        // Fallback: lowest card among movesToConsider
        return movesToConsider.sorted { $0.rank < $1.rank }[0]
    }

    /// Returns the suits any opponent is known to be void in, inferred from completed tricks.
    /// The deciding seat's own off-suit plays reveal nothing about the opponents and are ignored.
    private func opponentVoidedSuits(from completedTricks: [Trick], excluding seat: Seat) -> Set<Card.Suit> {
        var voids: Set<Card.Suit> = []
        for trick in completedTricks {
            guard let leadSuit = trick.leadSuit else { continue }
            for play in trick.plays where play.seat != seat && play.card.suit != leadSuit {
                voids.insert(leadSuit)
            }
        }
        return voids
    }
}
