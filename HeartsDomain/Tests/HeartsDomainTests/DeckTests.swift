//
//  DeckTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
import HeartsDomain

final class DeckTests: XCTestCase {
    func test_init_deck_has_52_cards() {
        let deck = Deck()
        XCTAssertEqual(deck.count, 52)
    }
}
