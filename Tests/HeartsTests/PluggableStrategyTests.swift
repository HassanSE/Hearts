//
//  PluggableStrategyTests.swift
//
//
//  Created by Muhammad Hassan on 13/09/2026.
//

import XCTest
import Hearts   // deliberately not @testable: exercises the public surface only

/// A consumer-side strategy: always plays the lowest legal card and passes its three highest.
/// A class so it can remember how often it was consulted.
private final class LowestCardStrategy: AIStrategy {
    private(set) var playCalls = 0
    private(set) var passCalls = 0
    private(set) var seatsSeen: Set<Seat> = []

    func selectCardsToPass(from hand: [Card], direction: CardExchangeDirection) -> PassedCards {
        passCalls += 1
        let highest = hand.sorted { $0.rank > $1.rank }
        return (highest[0], highest[1], highest[2])
    }

    func selectCardToPlay(context: TrickContext) -> Card {
        playCalls += 1
        seatsSeen.insert(context.seat)
        return context.legalMoves.sorted()[0]
    }
}

final class PluggableStrategyTests: XCTestCase {

    private func makeBots() -> [Player] {
        (1...4).map { Player(name: "Bot\($0)", type: .bot(difficulty: .easy)) }
    }

    func test_customStrategy_suppliedForSeat_playsFullGame() throws {
        let bots = makeBots()
        let custom = LowestCardStrategy()
        let game = Game(player1: bots[0], player2: bots[1], player3: bots[2], player4: bots[3],
                        strategies: [.west: custom],
                        using: SeededRandomNumberGenerator(seed: 13))

        let winner = try game.playCompleteGame()

        XCTAssertNotNil(game.gameWinner)
        XCTAssertEqual(winner, game.gameWinner)
        XCTAssertGreaterThan(custom.playCalls, 0, "custom strategy must have been consulted")
        XCTAssertEqual(custom.seatsSeen, [.west], "context.seat identifies the deciding seat")
        XCTAssertEqual(custom.playCalls, 13 * game.roundNumber, "one decision per trick per hand")
    }

    func test_strategyInstance_persistsForSeat_acrossTricksAndHands() throws {
        let bots = makeBots()
        let north = LowestCardStrategy()
        let game = Game(player1: bots[0], player2: bots[1], player3: bots[2], player4: bots[3],
                        strategies: [.north: north],
                        using: SeededRandomNumberGenerator(seed: 21))

        try game.playCompleteHand()
        XCTAssertEqual(north.passCalls, 1, "one exchange decision for the hand")
        XCTAssertEqual(north.playCalls, 13, "the same instance answered every trick of the hand")

        try game.startNewHand()
        try game.playCompleteHand()
        XCTAssertEqual(north.passCalls, 2, "the instance survives into the next hand")
        XCTAssertEqual(north.playCalls, 26)
    }

    func test_init_strategyForHumanSeat_isIgnored() throws {
        let human = Player.human("You")
        let bots = makeBots()
        let stray = LowestCardStrategy()
        let game = Game(player1: human, player2: bots[1], player3: bots[2], player4: bots[3],
                        strategies: [.south: stray],
                        using: SeededRandomNumberGenerator(seed: 3))

        try game.performExchange(selections: [.south: Array(game.hands[.south].prefix(3))])
        try game.advance()

        XCTAssertEqual(game.phase, .awaitingPlay(.south), "engine still waits for the human")
        XCTAssertEqual(stray.playCalls + stray.passCalls, 0, "a human seat never consults a strategy")
    }

    func test_playCompleteHand_whenHandAlreadyComplete_throwsWrongPhase() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 5))
        try game.playCompleteHand()

        XCTAssertThrowsError(try game.playCompleteHand()) { error in
            XCTAssertEqual(error as? GameError, .wrongPhase(game.phase))
        }
    }

    func test_playCompleteGame_whenAlreadyWon_returnsWinnerWithoutPlaying() throws {
        let game = Game(using: SeededRandomNumberGenerator(seed: 8))
        let winner = try game.playCompleteGame()
        let rounds = game.roundNumber

        XCTAssertEqual(try game.playCompleteGame(), winner)
        XCTAssertEqual(game.roundNumber, rounds, "no extra hand is dealt once the game is decided")
    }
}
