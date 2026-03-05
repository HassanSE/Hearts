//
//  PlayerType.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import Foundation

public enum PlayerType: Equatable {
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
