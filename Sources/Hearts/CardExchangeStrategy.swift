//
//  CardExchangeStrategy.swift
//
//
//  Created by Muhammad Hassan on 14/04/2024.
//

import Foundation

typealias PassedCards = (first: Card, second: Card, third: Card)

protocol CardExchangeStrategy {
    var hand: Hand { get set }
    mutating func pickCards() -> PassedCards
}

extension CardExchangeStrategy {
  mutating func pickCards() -> PassedCards {
        let passedCards = PassedCards(first: hand[0], second: hand[1], third: hand[2])
        hand.removeFirst(3)
        return passedCards
    }
}
