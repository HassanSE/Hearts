import UIKit

enum Rank: Int, CaseIterable, Comparable {
    static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case two = 2, three, four, five, six, seven, eight, nine, ten, jack, queen, king, ace
}

extension Rank: CustomStringConvertible {
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

enum Suit: CaseIterable, Comparable {
    case hearts
    case spades
    case diamonds
    case clubs
}

extension Suit: CustomStringConvertible {
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

struct Card {
    let rank: Rank
    let suit: Suit
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

struct Deck {
    let deck: [Card]
    
    var count: Int { deck.count }
    
    init() {
        deck = Rank.allCases.flatMap { rank in
            Suit.allCases.map { suit in
                Card(rank: rank, suit: suit)
            }
        }
    }
}

let deck = Deck()
assert(deck.count == 52)

let ace = Card(rank: .ace, suit: .hearts)
let king = Card(rank: .king, suit: .hearts)

assert(ace > king)
assert(ace == ace)

typealias Hand = [Card]

struct CardDistributor {
    let deck: Deck
    
    init(_ deck: Deck) {
        self.deck = deck
    }
    
    func distribute(_ slots: Int = 4) -> [Hand] {
        let shufffled = deck.deck.shuffled()
        var hands: [Hand] = Array(repeating: [], count: slots)
        for (index, card) in shufffled.enumerated() {
            let chunkNumber = index % slots
            hands[chunkNumber].append(card)
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
