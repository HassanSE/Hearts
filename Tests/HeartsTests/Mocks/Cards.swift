//
//  Cards.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import Hearts

// MARK: - Named cards

/// Every card in the deck by name, so fixtures read `.queenOfSpades` instead of `Card(suit: .spades, rank: .queen)`.
extension Card {
    static let twoOfClubs = Card(suit: .clubs, rank: .two)
    static let threeOfClubs = Card(suit: .clubs, rank: .three)
    static let fourOfClubs = Card(suit: .clubs, rank: .four)
    static let fiveOfClubs = Card(suit: .clubs, rank: .five)
    static let sixOfClubs = Card(suit: .clubs, rank: .six)
    static let sevenOfClubs = Card(suit: .clubs, rank: .seven)
    static let eightOfClubs = Card(suit: .clubs, rank: .eight)
    static let nineOfClubs = Card(suit: .clubs, rank: .nine)
    static let tenOfClubs = Card(suit: .clubs, rank: .ten)
    static let jackOfClubs = Card(suit: .clubs, rank: .jack)
    static let queenOfClubs = Card(suit: .clubs, rank: .queen)
    static let kingOfClubs = Card(suit: .clubs, rank: .king)
    static let aceOfClubs = Card(suit: .clubs, rank: .ace)
    static let twoOfDiamonds = Card(suit: .diamonds, rank: .two)
    static let threeOfDiamonds = Card(suit: .diamonds, rank: .three)
    static let fourOfDiamonds = Card(suit: .diamonds, rank: .four)
    static let fiveOfDiamonds = Card(suit: .diamonds, rank: .five)
    static let sixOfDiamonds = Card(suit: .diamonds, rank: .six)
    static let sevenOfDiamonds = Card(suit: .diamonds, rank: .seven)
    static let eightOfDiamonds = Card(suit: .diamonds, rank: .eight)
    static let nineOfDiamonds = Card(suit: .diamonds, rank: .nine)
    static let tenOfDiamonds = Card(suit: .diamonds, rank: .ten)
    static let jackOfDiamonds = Card(suit: .diamonds, rank: .jack)
    static let queenOfDiamonds = Card(suit: .diamonds, rank: .queen)
    static let kingOfDiamonds = Card(suit: .diamonds, rank: .king)
    static let aceOfDiamonds = Card(suit: .diamonds, rank: .ace)
    static let twoOfSpades = Card(suit: .spades, rank: .two)
    static let threeOfSpades = Card(suit: .spades, rank: .three)
    static let fourOfSpades = Card(suit: .spades, rank: .four)
    static let fiveOfSpades = Card(suit: .spades, rank: .five)
    static let sixOfSpades = Card(suit: .spades, rank: .six)
    static let sevenOfSpades = Card(suit: .spades, rank: .seven)
    static let eightOfSpades = Card(suit: .spades, rank: .eight)
    static let nineOfSpades = Card(suit: .spades, rank: .nine)
    static let tenOfSpades = Card(suit: .spades, rank: .ten)
    static let jackOfSpades = Card(suit: .spades, rank: .jack)
    static let queenOfSpades = Card(suit: .spades, rank: .queen)
    static let kingOfSpades = Card(suit: .spades, rank: .king)
    static let aceOfSpades = Card(suit: .spades, rank: .ace)
    static let twoOfHearts = Card(suit: .hearts, rank: .two)
    static let threeOfHearts = Card(suit: .hearts, rank: .three)
    static let fourOfHearts = Card(suit: .hearts, rank: .four)
    static let fiveOfHearts = Card(suit: .hearts, rank: .five)
    static let sixOfHearts = Card(suit: .hearts, rank: .six)
    static let sevenOfHearts = Card(suit: .hearts, rank: .seven)
    static let eightOfHearts = Card(suit: .hearts, rank: .eight)
    static let nineOfHearts = Card(suit: .hearts, rank: .nine)
    static let tenOfHearts = Card(suit: .hearts, rank: .ten)
    static let jackOfHearts = Card(suit: .hearts, rank: .jack)
    static let queenOfHearts = Card(suit: .hearts, rank: .queen)
    static let kingOfHearts = Card(suit: .hearts, rank: .king)
    static let aceOfHearts = Card(suit: .hearts, rank: .ace)
}

// MARK: - Hand builders

extension Card {
    /// All thirteen cards of `suit`, two through ace.
    static func fullSuit(_ suit: Suit) -> [Card] {
        Rank.allCases.map { Card(suit: suit, rank: $0) }
    }

    /// The given ranks of one suit, in the order listed: `Card.suited(.clubs, .two, .three)`.
    static func suited(_ suit: Suit, _ ranks: Rank...) -> [Card] {
        ranks.map { Card(suit: suit, rank: $0) }
    }

    /// One full suit per seat — clubs, diamonds, hearts, spades — so every seat's cards are known
    /// and the deal is valid by construction.
    static let oneSuitPerSeat: [[Card]] = [.clubs, .diamonds, .hearts, .spades].map(fullSuit)
}
