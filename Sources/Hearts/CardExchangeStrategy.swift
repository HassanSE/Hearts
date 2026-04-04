//
//  CardExchangeStrategy.swift
//
//
//  Created by Muhammad Hassan on 14/04/2024.
//

import Foundation

public typealias PassedCards = (first: Card, second: Card, third: Card)

protocol CardExchangeStrategy {
    var hand: Hand { get }
    func selectCardsToPass() -> PassedCards
}

extension CardExchangeStrategy {
    func selectCardsToPass() -> PassedCards {
        return PassedCards(first: hand[0], second: hand[1], third: hand[2])
    }
}
