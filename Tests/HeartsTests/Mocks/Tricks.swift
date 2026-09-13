//
//  Tricks.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

@testable import Hearts

extension Trick {
    /// A trick with `cards` played in order, starting from `leader` and going clockwise.
    /// Fewer than four cards gives a partial trick.
    static func mock(_ cards: [Card], leadingFrom leader: Seat = .south) throws -> Trick {
        var trick = Trick()
        for (offset, card) in cards.enumerated() {
            try trick.play(card, by: leader.advanced(by: offset))
        }
        return trick
    }
}
