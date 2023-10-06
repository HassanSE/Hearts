import UIKit

enum CardRank: CaseIterable, Comparable {
    case ace
    case king
    case queen
    case jack
    case ten
    case nine
    case eight
    case seven
    case six
    case five
    case four
    case three
    case two
}

enum CardType: CaseIterable {
    case hearts
    case spades
    case diamonds
    case clubs
}

struct PlayingCard {
    let rank: CardRank
    let type: CardType
}

extension PlayingCard: Comparable {
    static func < (lhs: PlayingCard, rhs: PlayingCard) -> Bool {
        lhs.rank > rhs.rank
    }
}

struct Deck {
    let deck: [PlayingCard]
    
    var count: Int { deck.count }
    
    init() {
        deck = CardRank.allCases.flatMap { rank in
            CardType.allCases.map { type in
                PlayingCard(rank: rank, type: type)
            }
        }
    }
}

let deck = Deck()
assert(deck.count == 52)

let ace = PlayingCard(rank: .ace, type: .hearts)
let king = PlayingCard(rank: .king, type: .hearts)

assert(ace > king)
assert(ace == ace)
