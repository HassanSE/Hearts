//
//  Seat.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

/// One of the four positions at the table, in clockwise order.
///
/// A `Seat` is the identity the engine uses for everything that happens during play: who played a
/// card, who won a trick, whose turn it is and who owes points. It never goes stale, unlike a copy
/// of a `Player` or a hand. `rawValue` is the seat's index (`0...3`), which is also the order the
/// four players were passed to `Game.init`.
public enum Seat: Int, CaseIterable, Codable, Hashable, Comparable, Sendable {
    /// Seat 0 — the first player given to `Game.init`.
    case south = 0
    /// Seat 1 — to the left of south.
    case west
    /// Seat 2 — across from south.
    case north
    /// Seat 3 — to the right of south.
    case east

    /// The seat to this seat's left, i.e. the next to play in a trick.
    public var next: Seat {
        advanced(by: 1)
    }

    /// The seat `offset` places clockwise from this one; wraps around the table.
    /// - Parameter offset: Number of seats to move clockwise (non-negative).
    public func advanced(by offset: Int) -> Seat {
        let count = Seat.allCases.count
        let index = ((rawValue + offset) % count + count) % count
        return Seat.allCases[index]
    }

    /// Orders seats clockwise from south: south < west < north < east.
    public static func < (lhs: Seat, rhs: Seat) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// Exactly one `Value` per `Seat`.
///
/// A fixed-size, total map: subscripting by a `Seat` always yields a value, so per-seat state
/// (hands, scores, captured cards) needs no optional handling. Iterating yields
/// `(seat, value)` pairs in seat order. Encodes as a four-element array in seat order.
public struct SeatMap<Value> {
    private var storage: [Value]

    /// Creates a map that holds `value` for every seat.
    /// - Parameter value: The value to store at all four seats.
    public init(repeating value: Value) {
        storage = Array(repeating: value, count: Seat.allCases.count)
    }

    /// Creates a map by calling `make` once per seat, in seat order.
    /// - Parameter make: Produces the value for the given seat.
    public init(_ make: (Seat) throws -> Value) rethrows {
        storage = try Seat.allCases.map(make)
    }

    /// The value at `seat`.
    public subscript(seat: Seat) -> Value {
        get { storage[seat.rawValue] }
        set { storage[seat.rawValue] = newValue }
    }

    /// All values in seat order (south, west, north, east).
    public var values: [Value] {
        storage
    }

    /// A map with `transform` applied to every value.
    /// - Parameter transform: Maps a value to its replacement.
    public func mapValues<T>(_ transform: (Value) throws -> T) rethrows -> SeatMap<T> {
        try SeatMap<T> { try transform(self[$0]) }
    }
}

extension SeatMap: Sequence {
    /// Yields `(seat, value)` pairs in seat order.
    public func makeIterator() -> IndexingIterator<[(seat: Seat, value: Value)]> {
        zip(Seat.allCases, storage).map { (seat: $0, value: $1) }.makeIterator()
    }
}

extension SeatMap: Equatable where Value: Equatable {}
extension SeatMap: Hashable where Value: Hashable {}
extension SeatMap: Sendable where Value: Sendable {}

extension SeatMap: Codable where Value: Codable {
    /// Decodes a four-element array in seat order.
    /// - Throws: `DecodingError.dataCorrupted` if the array does not hold exactly four values.
    public init(from decoder: Decoder) throws {
        let values = try decoder.singleValueContainer().decode([Value].self)
        guard values.count == Seat.allCases.count else {
            throw DecodingError.dataCorrupted(DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "A SeatMap needs exactly \(Seat.allCases.count) values, found \(values.count)"
            ))
        }
        storage = values
    }

    /// Encodes the values as a four-element array in seat order.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(storage)
    }
}
