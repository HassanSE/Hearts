import UIKit

enum CardRank: CaseIterable {
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

var deck: [PlayingCard] = {
    var arr = [PlayingCard]()
    for rank in CardRank.allCases {
        for type in CardType.allCases {
            arr.append(PlayingCard(rank: rank, type: type))
        }
    }
    return arr
}()

assert(deck.count == 52)
