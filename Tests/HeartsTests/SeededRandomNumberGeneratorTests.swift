//
//  SeededRandomNumberGeneratorTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
@testable import Hearts

final class SeededRandomNumberGeneratorTests: XCTestCase {

    private func sequence(seed: UInt64, count: Int = 8) -> [UInt64] {
        var generator = SeededRandomNumberGenerator(seed: seed)
        return (0..<count).map { _ in generator.next() }
    }

    // MARK: - SeededRandomNumberGenerator

    func test_next_sameSeed_producesSameSequence() {
        XCTAssertEqual(sequence(seed: 42), sequence(seed: 42))
    }

    func test_next_differentSeeds_produceDifferentSequences() {
        XCTAssertNotEqual(sequence(seed: 1), sequence(seed: 2))
    }

    func test_next_repeatedCalls_doNotRepeatImmediately() {
        let values = sequence(seed: 7, count: 64)
        XCTAssertEqual(Set(values).count, values.count, "SplitMix64 should not cycle within 64 draws")
    }

    // MARK: - RandomSource

    func test_randomSource_wrappingSeededGenerator_yieldsTheSameStream() {
        let source = RandomSource(SeededRandomNumberGenerator(seed: 42))
        let drawn = (0..<8).map { _ in source.next() }

        XCTAssertEqual(drawn, sequence(seed: 42))
    }

    func test_randomSource_sharedByTwoConsumers_advancesOneStream() {
        let source = RandomSource(SeededRandomNumberGenerator(seed: 42))
        let expected = sequence(seed: 42, count: 4)

        // Two consumers holding the same reference take turns drawing.
        let consumerA = source
        let consumerB = source
        let interleaved = [consumerA.next(), consumerB.next(), consumerA.next(), consumerB.next()]

        XCTAssertEqual(interleaved, expected, "every draw comes from one stream, in order")
    }
}
