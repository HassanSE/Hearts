import UIKit

struct Card {
    let suit: Suit
    let rank: Rank
    
    enum Rank: Int, CaseIterable, Comparable {
        static func < (lhs: Rank, rhs: Rank) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
        
        case two = 2, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
    }
    
    enum Suit: CaseIterable, Comparable {
        case hearts
        case spades
        case diamonds
        case clubs
    }
}

extension Card.Rank: CustomStringConvertible {
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
        default:
            return String(rawValue)
        }
    }
    
    var description: String {
        symbol
    }
}

extension Card.Suit: CustomStringConvertible {
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

extension Card: Comparable {
    static func < (lhs: Card, rhs: Card) -> Bool {
        lhs.rank < rhs.rank
    }
}

extension Card: CustomStringConvertible {
    var description: String {
        "\(self.rank) \(self.suit)"
    }
}

class Deck {
    private var cards: [Card] = []
    
    var count: Int { cards.count }
    
    init() {
        for suit in Card.Suit.allCases {
            for rank in Card.Rank.allCases {
                cards.append(Card(suit: suit, rank: rank))
            }
        }
    }
    
    func shuffle() {
        cards.shuffle()
    }
    
    func deal() -> Card? {
        return cards.popLast()
    }
}

let deck = Deck()
assert(deck.count == 52)

let ace = Card(suit: .hearts, rank: .ace)
let king = Card(suit: .hearts, rank: .king)

assert(ace > king)
assert(ace == ace)

typealias Hand = [Card]

struct CardDistributor {
    let deck: Deck
    
    init(_ deck: Deck) {
        self.deck = deck
    }
    
    func distribute(_ slots: Int = 4) -> [Hand] {
        deck.shuffle()
        var hands: [Hand] = Array(repeating: [], count: slots)
        for index in 0...deck.count - 1 {
            let chunkNumber = index % slots
            if let card = deck.deal() {
                hands[chunkNumber].append(card)
            }
        }
        return hands.map { hand in
            hand.sorted { $0.rank > $1.rank }
               .sorted { $0.suit > $1.suit }
        }
    }
}

struct HandSortor {
    static func sort(_ hands: [Hand]) -> [Hand] {
        return hands.map { arr in
            arr.sorted { $0.rank < $1.rank }
               .sorted { $0.suit > $1.suit }
        }
    }
}

let cardDistributor = CardDistributor(deck)
let hands = cardDistributor.distribute()
let sortedHands = HandSortor.sort(hands)

for hand in sortedHands {
    print("\(hand) - \(hand.count)")
}
