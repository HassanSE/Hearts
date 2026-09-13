//
//  SeededRandomNumberGenerator.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

/// A deterministic pseudo-random generator (SplitMix64) for reproducible deals and bot play.
///
/// Two generators created with the same seed produce the same sequence, so a `Game` built
/// with one replays identically:
///
/// ```swift
/// let game = Game(using: SeededRandomNumberGenerator(seed: 42))
/// ```
///
/// Not cryptographically secure; use `SystemRandomNumberGenerator` (the default) for real play.
public struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    /// Creates a generator whose output is fully determined by `seed`.
    /// - Parameter seed: Any 64-bit value; equal seeds yield equal sequences.
    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

/// A reference-typed, type-erased generator shared by everything in one `Game` that needs randomness
/// (the deck shuffle and any `RandomAIStrategy`), so a single seed determines the whole game.
final class RandomSource: RandomNumberGenerator {
    private var base: any RandomNumberGenerator

    init(_ base: some RandomNumberGenerator) {
        self.base = base
    }

    func next() -> UInt64 {
        base.next()
    }
}
