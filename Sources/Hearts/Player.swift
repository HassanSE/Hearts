//
//  Player.swift
//
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import Foundation

/// Who occupies a seat: a display name and whether a human or a bot makes the decisions.
///
/// `Player` is an immutable profile. Everything that changes during play — the hand, round and
/// total scores, whose turn it is — belongs to `Game` and is keyed by `Seat`, so a `Player` value
/// can be held indefinitely without going stale. Two players with the same name and type are equal;
/// identity at the table is the `Seat`, not the profile.
public struct Player: Codable, Hashable {
    /// Display name.
    public let name: String
    /// Whether this seat is played by a human (needs input) or a bot (chooses via its strategy).
    public let type: PlayerType

    /// Creates a profile.
    /// - Parameters:
    ///   - name: Display name.
    ///   - type: Human by default.
    public init(name: String, type: PlayerType = .human) {
        self.name = name
        self.type = type
    }
}

extension Player {
    static func makeBotPlayers(difficulty: BotDifficulty = .medium) -> [Player] {
        return [Player(name: "Watson", type: .bot(difficulty: difficulty)),
                Player(name: "Beth", type: .bot(difficulty: difficulty)),
                Player(name: "Cindy", type: .bot(difficulty: difficulty)),
                Player(name: "Max", type: .bot(difficulty: difficulty))]
    }
}

extension Player: CustomDebugStringConvertible {
    public var debugDescription: String {
        let typeDescription: String
        switch type {
        case .human:
            typeDescription = "human"
        case .bot(let difficulty):
            typeDescription = "bot(\(difficulty))"
        }
        return "Player(name: \(name), type: \(typeDescription))"
    }
}
