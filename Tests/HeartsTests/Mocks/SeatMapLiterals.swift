//
//  SeatMapLiterals.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import Hearts

/// Lets tests spell a `SeatMap` as a four-element array literal in seat order (south, west, north, east).
/// Test-only: the library deliberately has no literal initialiser because a wrong count is a programmer error.
extension SeatMap: @retroactive ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Value...) {
        precondition(elements.count == Seat.allCases.count, "A SeatMap literal needs exactly one value per seat")
        self.init { elements[$0.rawValue] }
    }
}
