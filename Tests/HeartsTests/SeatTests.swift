//
//  SeatTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

final class SeatTests: XCTestCase {

    // MARK: - Seat

    func test_allCases_seat_isFourSeatsClockwise() {
        XCTAssertEqual(Seat.allCases, [.south, .west, .north, .east])
        XCTAssertEqual(Seat.allCases.map(\.rawValue), [0, 1, 2, 3])
    }

    func test_next_anySeat_isSeatToLeftWrappingAround() {
        XCTAssertEqual(Seat.south.next, .west)
        XCTAssertEqual(Seat.west.next, .north)
        XCTAssertEqual(Seat.north.next, .east)
        XCTAssertEqual(Seat.east.next, .south)
    }

    func test_advancedBy_anyCount_wrapsModuloFour() {
        XCTAssertEqual(Seat.east.advanced(by: 1), .south)
        XCTAssertEqual(Seat.south.advanced(by: 2), .north)
        XCTAssertEqual(Seat.west.advanced(by: 7), .south)
        XCTAssertEqual(Seat.west.advanced(by: 0), .west)
    }

    func test_recipient_forEachDirection_matchesTableGeometry() {
        XCTAssertEqual(CardExchangeDirection.left.recipient(of: .south), .west)
        XCTAssertEqual(CardExchangeDirection.right.recipient(of: .south), .east)
        XCTAssertEqual(CardExchangeDirection.across.recipient(of: .west), .east)
        XCTAssertNil(CardExchangeDirection.none.recipient(of: .south))
    }

    func test_codable_seat_roundTripsThroughJSON() throws {
        for seat in Seat.allCases {
            let data = try JSONEncoder().encode(seat)
            XCTAssertEqual(try JSONDecoder().decode(Seat.self, from: data), seat)
        }
    }

    // MARK: - SeatMap

    func test_seatMap_initRepeating_givesEverySeatTheValue() {
        let map = SeatMap(repeating: 7)
        for seat in Seat.allCases {
            XCTAssertEqual(map[seat], 7)
        }
    }

    func test_seatMap_initWithBuilder_callsBuilderOncePerSeatInOrder() {
        var seen: [Seat] = []
        let map = SeatMap { seat -> Int in
            seen.append(seat)
            return seat.rawValue * 10
        }
        XCTAssertEqual(seen, Seat.allCases)
        XCTAssertEqual(map[.east], 30)
    }

    func test_seatMap_subscriptSet_changesOnlyThatSeat() {
        var map = SeatMap(repeating: 0)
        map[.north] = 5
        XCTAssertEqual(map.values, [0, 0, 5, 0])
    }

    func test_iteration_seatMap_yieldsPairsInSeatOrder() {
        let map: SeatMap<String> = ["a", "b", "c", "d"]
        let pairs = map.map { "\($0.seat.rawValue)\($0.value)" }
        XCTAssertEqual(pairs, ["0a", "1b", "2c", "3d"])
    }

    func test_seatMap_mapValues_transformsEachValue() {
        let map: SeatMap<Int> = [1, 2, 3, 4]
        XCTAssertEqual(map.mapValues { $0 * 2 }, [2, 4, 6, 8])
    }

    func test_codable_seatMap_roundTripsAsFourElementArray() throws {
        let map: SeatMap<Int> = [1, 2, 3, 4]
        let data = try JSONEncoder().encode(map)
        XCTAssertEqual(String(data: data, encoding: .utf8), "[1,2,3,4]")
        XCTAssertEqual(try JSONDecoder().decode(SeatMap<Int>.self, from: data), map)
    }

    func test_seatMap_decodingWrongElementCount_throws() {
        let data = Data("[1,2,3]".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(SeatMap<Int>.self, from: data))
    }
}
