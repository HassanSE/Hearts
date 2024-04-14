//
//  CardExchangeStrategy.swift
//
//
//  Created by Muhammad Hassan on 14/04/2024.
//

import Foundation

protocol CardExchangeStrategy {
    var hand: Hand { get }
    func pickCards() -> [Card]
}

extension CardExchangeStrategy {
    func pickCards() -> [Card] {
        Array(hand.prefix(3))
    }
}
