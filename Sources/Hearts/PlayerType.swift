//
//  PlayerType.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import Foundation

public enum PlayerType: Equatable, Codable {
    case human
    case bot(difficulty: BotDifficulty)

    public var isBot: Bool {
        if case .bot = self { return true }
        return false
    }

    public var isHuman: Bool {
        if case .human = self { return true }
        return false
    }

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
