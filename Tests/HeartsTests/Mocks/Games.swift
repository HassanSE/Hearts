//
//  Games.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

@testable import Hearts

// MARK: - Players

extension Player {
    /// A human profile.
    static func human(_ name: String = "You") -> Player {
        Player(name: name, type: .human)
    }

    /// A bot profile; `.easy` by default so fixtures stay fast and deterministic under a seeded generator.
    static func bot(_ name: String = "Bot", difficulty: BotDifficulty = .easy) -> Player {
        Player(name: name, type: .bot(difficulty: difficulty))
    }
}

// MARK: - Games

extension Game {
    /// Four bots and a seeded shuffle: the same `seed` always yields the same deal and the same play.
    static func seededBots(seed: UInt64 = 1,
                           difficulty: BotDifficulty = .easy,
                           configuration: GameConfiguration = .standard) -> Game {
        Game(player1: .bot("Bot1", difficulty: difficulty),
             player2: .bot("Bot2", difficulty: difficulty),
             player3: .bot("Bot3", difficulty: difficulty),
             player4: .bot("Bot4", difficulty: difficulty),
             configuration: configuration,
             using: SeededRandomNumberGenerator(seed: seed))
    }

    /// A human at south with three easy bots, dealt from a seeded shuffle.
    static func seededHumanSouth(seed: UInt64 = 1, configuration: GameConfiguration = .standard) -> Game {
        Game(player1: .human(),
             player2: .bot("Bot1"),
             player3: .bot("Bot2"),
             player4: .bot("Bot3"),
             configuration: configuration,
             using: SeededRandomNumberGenerator(seed: seed))
    }

    /// Four human profiles (Alice, Bob, Charlie, Diana) dealt from a seeded shuffle.
    static func fourHumans(configuration: GameConfiguration = .standard, seed: UInt64 = 1) -> Game {
        Game(player1: .human("Alice"), player2: .human("Bob"), player3: .human("Charlie"), player4: .human("Diana"),
             configuration: configuration, using: SeededRandomNumberGenerator(seed: seed))
    }

    /// A game whose first hand is exactly `hands` (one per seat, south first), started directly in play.
    ///
    /// Fixed deals are usually partial, so no exchange is possible; the phase is set to
    /// `.awaitingPlay` for the seat holding 2♣ (south if nobody does). Pass `types` to seat bots.
    static func fixedDeal(_ hands: [[Card]],
                          types: [PlayerType] = Array(repeating: .human, count: 4),
                          configuration: GameConfiguration = .standard,
                          seed: UInt64 = 1) throws -> Game {
        let players = zip(["Alice", "Bob", "Charlie", "Diana"], types).map { Player(name: $0, type: $1) }
        let game = try Game(player1: players[0], player2: players[1], player3: players[2], player4: players[3],
                            hands: hands, configuration: configuration,
                            using: SeededRandomNumberGenerator(seed: seed))
        game.phase = .awaitingPlay(game.leader ?? .south)
        return game
    }

    /// A two-card deal with a human at south (holding 2♣, so leading) and three easy bots.
    static func humanSouthTwoCardDeal() -> Game {
        try! fixedDeal([
            [Card.twoOfClubs, Card.threeOfClubs],
            [Card.fiveOfClubs, Card.sixOfClubs],
            [Card.eightOfClubs, Card.nineOfClubs],
            [Card.jackOfClubs, Card.queenOfClubs]
        ], types: [.human, .bot(difficulty: .easy), .bot(difficulty: .easy), .bot(difficulty: .easy)])
    }

    /// Plays `cards` in order, each by whichever seat is on turn, so a trick's winner leads the next one.
    func play(_ cards: [Card]) throws {
        for card in cards {
            try playCard(card, by: currentSeat)
        }
    }
}
