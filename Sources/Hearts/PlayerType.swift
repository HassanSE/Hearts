//
//  PlayerType.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import Foundation

enum PlayerType: Equatable {
    case human
    case bot(difficulty: BotDifficulty)

    var isBot: Bool {
        if case .bot = self { return true }
        return false
    }

    var isHuman: Bool {
        if case .human = self { return true }
        return false
    }

    var botDifficulty: BotDifficulty? {
        if case .bot(let difficulty) = self { return difficulty }
        return nil
    }
}
