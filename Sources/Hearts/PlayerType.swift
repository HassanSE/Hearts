//
//  PlayerType.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

/// Who makes the decisions for a seat: a human supplying input, or a bot driven by an `AIStrategy`.
///
/// `Game.advance()` stops at every decision a `.human` seat must make and plays through the
/// `.bot` seats itself. Encodes as `{"type": "human"}` or `{"type": "bot", "difficulty": …}`.
public enum PlayerType: Hashable, Codable, Sendable {
    /// Decisions come from outside the engine via `Game.performExchange(selections:)` and `Game.playCard(_:by:)`.
    case human
    /// Decisions come from the built-in strategy for `difficulty` (or an override passed to `Game.init`).
    case bot(difficulty: BotDifficulty)

    /// Whether this is a `.bot` seat.
    public var isBot: Bool {
        if case .bot = self { return true }
        return false
    }

    /// Whether this is the `.human` seat type.
    public var isHuman: Bool {
        if case .human = self { return true }
        return false
    }

    /// The bot's difficulty, or `nil` for a human.
    public var botDifficulty: BotDifficulty? {
        if case .bot(let difficulty) = self { return difficulty }
        return nil
    }
}

extension PlayerType {
    private enum CodingKeys: String, CodingKey {
        case type, difficulty
    }

    private enum TypeValue: String, Codable {
        case human, bot
    }

    /// Decodes `{"type": "human"}` or `{"type": "bot", "difficulty": …}`.
    /// - Throws: `DecodingError` if `type` is missing or unknown, or a bot has no `difficulty`.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(TypeValue.self, forKey: .type)
        switch type {
        case .human:
            self = .human
        case .bot:
            let difficulty = try container.decode(BotDifficulty.self, forKey: .difficulty)
            self = .bot(difficulty: difficulty)
        }
    }

    /// Encodes as `{"type": "human"}` or `{"type": "bot", "difficulty": …}`.
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .human:
            try container.encode(TypeValue.human, forKey: .type)
        case .bot(let difficulty):
            try container.encode(TypeValue.bot, forKey: .type)
            try container.encode(difficulty, forKey: .difficulty)
        }
    }
}
