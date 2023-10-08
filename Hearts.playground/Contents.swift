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

extension CardRank: CustomStringConvertible {
    var symbol: String {
        switch self {
        case .ace:
            return "A"
        case .king:
            return "K"
        case .queen:
            return "Q"
        case .jack:
            return "J"
        case .ten:
            return "10"
        case .nine:
            return "9"
        case .eight:
            return "8"
        case .seven:
            return "7"
        case .six:
            return "6"
        case .five:
            return "5"
        case .four:
            return "4"
        case .three:
            return "3"
        case .two:
            return "2"
            
        }
    }
    
    var description: String {
        symbol
    }
}

enum CardType: CaseIterable, Comparable {
    case hearts
    case spades
    case diamonds
    case clubs
}

extension CardType: CustomStringConvertible {
    var symbol: String {
        switch self {
        case .hearts:
            return "♥"
        case .spades:
            return "♠"
        case .diamonds:
            return "♦"
        case .clubs:
            return "♣"
        }
    }
    
    var description: String {
        symbol
    }
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

extension PlayingCard: CustomStringConvertible {
    var description: String {
        "\(self.rank) \(self.type)"
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

struct CardDistributor {
    let deck: Deck
    
    init(_ deck: Deck) {
        self.deck = deck
    }
    
    func distribute(_ slots: Int = 4) -> [[PlayingCard]] {
        let shufffled = deck.deck.shuffled()
        var chunks: [[PlayingCard]] = Array(repeating: [], count: slots)
        for (index, card) in shufffled.enumerated() {
            let chunkNumber = index % slots
            chunks[chunkNumber].append(card)
        }
        return chunks.map { arr in
            arr.sorted { $0.rank > $1.rank }
               .sorted { $0.type > $1.type }
        }
    }
}

let cardDistributor = CardDistributor(deck)
let chunks = cardDistributor.distribute(6)

for chunk in chunks {
    print("\(chunk) - \(chunk.count)")
}
