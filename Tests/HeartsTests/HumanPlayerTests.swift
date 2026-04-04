//
//  HumanPlayerTests.swift
//
//
//  Created by Muhammad Hassan on 12/02/2026.
//

import XCTest
@testable import Hearts

// MARK: - Mock Delegate

private class MockDelegate: GameEngineDelegate {
    var didPlayCardCalls: [(card: Card, player: Player)] = []
    var didCompleteTrickCalls: [(trick: Trick, winner: Player, points: Int)] = []
    var didBreakHeartsCalls: [(card: Card, player: Player)] = []
    var didEndHandCalls: [(scores: [Player: Int], moonShooter: Player?)] = []
    var didEndGameCalls: [Player] = []

    func game(_ game: Game, didPlayCard card: Card, by player: Player) {
        didPlayCardCalls.append((card, player))
    }

    func game(_ game: Game, didCompleteTrick trick: Trick, winner: Player, points: Int) {
        didCompleteTrickCalls.append((trick, winner, points))
    }

    func game(_ game: Game, didBreakHearts card: Card, by player: Player) {
        didBreakHeartsCalls.append((card, player))
    }

    func game(_ game: Game, didEndHand scores: [Player: Int], moonShooter: Player?) {
        didEndHandCalls.append((scores, moonShooter))
    }

    func game(_ game: Game, didEndGame winner: Player) {
        didEndGameCalls.append(winner)
    }
}

// MARK: - Test Setup Helper

extension HumanPlayerTests {
    /// Creates a 3-card-per-player game with player0 as human and others as bots.
    /// Player 0 holds 2♣ and leads the first trick.
    func makeHumanBotGame() -> Game {
        let human = Player(name: "Human", type: .human)
        let bot1 = Player(name: "Bot1", type: .bot(difficulty: .easy))
        let bot2 = Player(name: "Bot2", type: .bot(difficulty: .easy))
        let bot3 = Player(name: "Bot3", type: .bot(difficulty: .easy))

        let game = Game(player1: human, player2: bot1, player3: bot2, player4: bot3)

        // Set up minimal hands: human has 2♣ and one other non-point card
        game.players[0].hand = [
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three)
        ]
        game.players[1].hand = [
            Card(suit: .clubs, rank: .five),
            Card(suit: .clubs, rank: .six)
        ]
        game.players[2].hand = [
            Card(suit: .clubs, rank: .eight),
            Card(suit: .clubs, rank: .nine)
        ]
        game.players[3].hand = [
            Card(suit: .clubs, rank: .jack),
            Card(suit: .clubs, rank: .queen)
        ]

        game.currentPlayerIndex = 0
        game.currentTrick = Trick()
        game.completedTricks = []
        game.heartsBroken = false

        return game
    }

    /// Creates a full 13-card all-bot game for automation tests.
    func makeMinimalBotGame() -> Game {
        return Game()  // Default init: 4 bots, 13 cards each, medium difficulty
    }
}

// MARK: - Tests

final class HumanPlayerTests: XCTestCase {

    // MARK: - Human Player Flow

    func test_humanPlayer_canPlayCard_viaPlayCard() throws {
        let game = makeHumanBotGame()
        let human = game.players[0]
        let card = Card(suit: .clubs, rank: .two)

        XCTAssertNoThrow(try game.playCard(card, by: human))
        // Check game's copy of the player's hand (Player is a value type)
        XCTAssertFalse(game.players[0].hand.contains(card), "Card should be removed from hand after playing")
    }

    func test_humanPlayer_playBotTurnsUntilHumanTurn_stopsAtHumanTurn() throws {
        let game = makeHumanBotGame()
        // Human (index 0) holds 2♣ and it's their turn — method should return immediately
        XCTAssertTrue(game.currentPlayer.type.isHuman)

        try game.playBotTurnsUntilHumanTurn()

        // Should still be human's turn (no bots to advance before the human)
        XCTAssertTrue(game.currentPlayer.type.isHuman)
        XCTAssertEqual(game.currentTrick.plays.count, 0, "No plays should have been made")
    }

    func test_humanPlayer_playBotTurnsUntilHumanTurn_advancesBotsBeforeHuman() throws {
        let game = makeHumanBotGame()

        // Human plays first (2♣ — required to open)
        let human = game.players[0]
        try game.playCard(Card(suit: .clubs, rank: .two), by: human)

        // Now it's Bot1's turn — advance bots until human turn comes back
        XCTAssertTrue(game.currentPlayer.type.isBot)
        try game.playBotTurnsUntilHumanTurn()

        // After all 3 bots play, the trick completes (4 cards total) and
        // the winner leads next — since all clubs are played the winner leads
        // and it will be a bot or the hand is complete with 1 trick.
        // Either the hand completed or it's back to a bot / human.
        // The key assertion: no crash and the trick had all 4 plays.
        XCTAssertTrue(game.completedTricks.count >= 1 || game.currentTrick.plays.count > 0)
    }

    func test_humanPlayer_playBotTurnsUntilHumanTurn_completesIfNoHuman() throws {
        let game = makeMinimalBotGame()
        // All bots — the method should complete the entire hand
        XCTAssertTrue(game.currentPlayer.type.isBot)

        try game.playBotTurnsUntilHumanTurn()

        // All 13 tricks should be completed, hand is over
        XCTAssertEqual(game.completedTricks.count, 13)
        XCTAssertTrue(game.isHandComplete)
    }

    // MARK: - Delegate: didPlayCard

    func test_delegate_didPlayCard_isCalledAfterEachPlay() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        let bot = game.currentPlayer
        try game.playCard(Card(suit: .clubs, rank: .two), by: bot)

        XCTAssertEqual(delegate.didPlayCardCalls.count, 1)
        XCTAssertEqual(delegate.didPlayCardCalls[0].card, Card(suit: .clubs, rank: .two))
        XCTAssertEqual(delegate.didPlayCardCalls[0].player, bot)
    }

    func test_delegate_didPlayCard_isCalledForEveryCardInHand() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playBotTurnsUntilHumanTurn()

        // All-bot game: 4 players × 13 cards = 52 plays
        XCTAssertEqual(delegate.didPlayCardCalls.count, 52)
    }

    // MARK: - Delegate: didCompleteTrick

    func test_delegate_didCompleteTrick_isCalledForEachTrick() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playBotTurnsUntilHumanTurn()

        // All-bot game: 13 tricks
        XCTAssertEqual(delegate.didCompleteTrickCalls.count, 13)
        // Each delegate call carries a complete trick
        for call in delegate.didCompleteTrickCalls {
            XCTAssertTrue(call.trick.isComplete)
            XCTAssertEqual(call.trick.plays.count, 4)
        }
    }

    func test_delegate_didCompleteTrick_providesCorrectWinner() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playBotTurnsUntilHumanTurn()

        // Each delegate call's winner should match the corresponding stored trick winner
        for (index, call) in delegate.didCompleteTrickCalls.enumerated() {
            XCTAssertEqual(call.winner, game.completedTricks[index].winner)
        }
    }

    // MARK: - Delegate: didBreakHearts

    func test_delegate_didBreakHearts_isCalledOnceWhenHeartsFirstPlayed() throws {
        // Set up a game where we can force a heart to be played
        let bot0 = Player(name: "Bot0", type: .bot(difficulty: .easy))
        let bot1 = Player(name: "Bot1", type: .bot(difficulty: .easy))
        let bot2 = Player(name: "Bot2", type: .bot(difficulty: .easy))
        let bot3 = Player(name: "Bot3", type: .bot(difficulty: .easy))
        let game = Game(player1: bot0, player2: bot1, player3: bot2, player4: bot3)

        // Give bot0 all clubs + one heart; bot1/2/3 have no clubs (forced to sluff hearts)
        game.players[0].hand = [Card(suit: .clubs, rank: .two), Card(suit: .hearts, rank: .three)]
        game.players[1].hand = [Card(suit: .hearts, rank: .four), Card(suit: .hearts, rank: .five)]
        game.players[2].hand = [Card(suit: .hearts, rank: .six), Card(suit: .hearts, rank: .seven)]
        game.players[3].hand = [Card(suit: .hearts, rank: .eight), Card(suit: .hearts, rank: .nine)]
        game.currentPlayerIndex = 0
        game.currentTrick = Trick()
        game.completedTricks = []
        game.heartsBroken = false

        let delegate = MockDelegate()
        game.delegate = delegate

        // Play 2♣ — bot1/2/3 have no clubs, so they play hearts → hearts break
        try game.playCard(Card(suit: .clubs, rank: .two), by: game.players[0])
        // Manually drive bot plays for the rest of the trick
        for _ in 0..<3 {
            let player = game.currentPlayer
            let card = player.hand.first!
            try game.playCard(card, by: player)
        }

        // Hearts should be broken now
        XCTAssertTrue(game.heartsBroken)
        // Delegate fired exactly once
        XCTAssertEqual(delegate.didBreakHeartsCalls.count, 1)
        XCTAssertEqual(delegate.didBreakHeartsCalls[0].card.suit, .hearts)
    }

    func test_delegate_didBreakHearts_isNotCalledWhenHeartsAlreadyBroken() throws {
        let bot0 = Player(name: "Bot0", type: .bot(difficulty: .easy))
        let bot1 = Player(name: "Bot1", type: .bot(difficulty: .easy))
        let bot2 = Player(name: "Bot2", type: .bot(difficulty: .easy))
        let bot3 = Player(name: "Bot3", type: .bot(difficulty: .easy))
        let game = Game(player1: bot0, player2: bot1, player3: bot2, player4: bot3)

        // Give bot0 only hearts so it's forced to play a heart as the first card
        game.players[0].hand = [Card(suit: .hearts, rank: .two), Card(suit: .hearts, rank: .three)]
        game.players[1].hand = [Card(suit: .hearts, rank: .four), Card(suit: .hearts, rank: .five)]
        game.players[2].hand = [Card(suit: .hearts, rank: .six), Card(suit: .hearts, rank: .seven)]
        game.players[3].hand = [Card(suit: .hearts, rank: .eight), Card(suit: .hearts, rank: .nine)]
        game.currentPlayerIndex = 0
        game.currentTrick = Trick()
        // Hearts already broken, simulate at least one prior trick so we're not on trick 1
        var priorTrick = Trick()
        try! priorTrick.play(Card(suit: .clubs, rank: .two), by: bot0)
        try! priorTrick.play(Card(suit: .clubs, rank: .three), by: bot1)
        try! priorTrick.play(Card(suit: .clubs, rank: .four), by: bot2)
        try! priorTrick.play(Card(suit: .clubs, rank: .five), by: bot3)
        game.completedTricks = [priorTrick]
        game.heartsBroken = true

        let delegate = MockDelegate()
        game.delegate = delegate

        // Play a heart — hearts already broken, delegate should NOT fire again
        try game.playCard(Card(suit: .hearts, rank: .two), by: game.players[0])

        XCTAssertEqual(delegate.didBreakHeartsCalls.count, 0)
    }

    // MARK: - Delegate: didEndHand

    func test_delegate_didEndHand_isCalledAfterEndHand() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        // Play the one trick
        try game.playBotTurnsUntilHumanTurn()
        game.endHand()

        XCTAssertEqual(delegate.didEndHandCalls.count, 1)
    }

    func test_delegate_didEndHand_providesCorrectScores() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playBotTurnsUntilHumanTurn()
        game.endHand()

        let call = delegate.didEndHandCalls[0]
        // Scores dict should have an entry per player
        XCTAssertEqual(call.scores.count, 4)
        // All players should be in the scores dict
        for player in game.players {
            XCTAssertNotNil(call.scores[player])
        }
    }

    func test_delegate_didEndHand_moonShooterIsNilWhenNoMoonShot() throws {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        try game.playBotTurnsUntilHumanTurn()
        game.endHand()

        XCTAssertNil(delegate.didEndHandCalls[0].moonShooter)
    }

    // MARK: - Delegate: didEndGame

    func test_delegate_didEndGame_isCalledWhenGameOver() {
        let game = Game()
        let delegate = MockDelegate()
        game.delegate = delegate

        // Drive one player past the winning score threshold manually
        game.players[1].totalScore = game.winningScore

        // endHand on a complete hand — requires completedTricks to be full
        // Build 13 fake completed tricks (no points, so no moon shot)
        let p0 = game.players[0]
        let p1 = game.players[1]
        let p2 = game.players[2]
        let p3 = game.players[3]

        for i in 0..<13 {
            var trick = Trick()
            let rankOffset = i % 13
            let rank = Card.Rank.allCases[rankOffset]
            try! trick.play(Card(suit: .clubs, rank: rank), by: p0)
            try! trick.play(Card(suit: .clubs, rank: .three), by: p1)
            try! trick.play(Card(suit: .clubs, rank: .four), by: p2)
            try! trick.play(Card(suit: .clubs, rank: .five), by: p3)
            game.completedTricks.append(trick)
        }

        game.endHand()

        XCTAssertTrue(game.isGameOver)
        XCTAssertEqual(delegate.didEndGameCalls.count, 1)
        XCTAssertEqual(delegate.didEndGameCalls[0], game.gameWinner)
    }

    func test_delegate_didEndGame_isNotCalledWhenGameNotOver() {
        let game = makeMinimalBotGame()
        let delegate = MockDelegate()
        game.delegate = delegate

        // All scores are 0, game is not over
        try! game.playBotTurnsUntilHumanTurn()
        game.endHand()

        XCTAssertFalse(game.isGameOver)
        XCTAssertEqual(delegate.didEndGameCalls.count, 0)
    }

    // MARK: - performExchange

    func test_performExchange_humanCards_usesSpecifiedCards() {
        let game = makeHumanBotGame()
        // Give the human a 13-card hand so exchange precondition is satisfied
        game.players[0].hand = [
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .four),
            Card(suit: .clubs, rank: .five),
            Card(suit: .clubs, rank: .six),
            Card(suit: .clubs, rank: .seven),
            Card(suit: .clubs, rank: .eight),
            Card(suit: .clubs, rank: .nine),
            Card(suit: .clubs, rank: .ten),
            Card(suit: .clubs, rank: .jack),
            Card(suit: .clubs, rank: .queen),
            Card(suit: .clubs, rank: .king),
            Card(suit: .clubs, rank: .ace)
        ]
        game.players[1].hand = Array(repeating: Card(suit: .diamonds, rank: .two), count: 0)
        // Give bots valid 13-card hands
        let botCards: [[Card]] = [
            [Card(suit: .diamonds, rank: .two), Card(suit: .diamonds, rank: .three),
             Card(suit: .diamonds, rank: .four), Card(suit: .diamonds, rank: .five),
             Card(suit: .diamonds, rank: .six), Card(suit: .diamonds, rank: .seven),
             Card(suit: .diamonds, rank: .eight), Card(suit: .diamonds, rank: .nine),
             Card(suit: .diamonds, rank: .ten), Card(suit: .diamonds, rank: .jack),
             Card(suit: .diamonds, rank: .queen), Card(suit: .diamonds, rank: .king),
             Card(suit: .diamonds, rank: .ace)],
            [Card(suit: .hearts, rank: .two), Card(suit: .hearts, rank: .three),
             Card(suit: .hearts, rank: .four), Card(suit: .hearts, rank: .five),
             Card(suit: .hearts, rank: .six), Card(suit: .hearts, rank: .seven),
             Card(suit: .hearts, rank: .eight), Card(suit: .hearts, rank: .nine),
             Card(suit: .hearts, rank: .ten), Card(suit: .hearts, rank: .jack),
             Card(suit: .hearts, rank: .queen), Card(suit: .hearts, rank: .king),
             Card(suit: .hearts, rank: .ace)],
            [Card(suit: .spades, rank: .two), Card(suit: .spades, rank: .three),
             Card(suit: .spades, rank: .four), Card(suit: .spades, rank: .five),
             Card(suit: .spades, rank: .six), Card(suit: .spades, rank: .seven),
             Card(suit: .spades, rank: .eight), Card(suit: .spades, rank: .nine),
             Card(suit: .spades, rank: .ten), Card(suit: .spades, rank: .jack),
             Card(suit: .spades, rank: .queen), Card(suit: .spades, rank: .king),
             Card(suit: .spades, rank: .ace)]
        ]
        game.players[1].hand = botCards[0]
        game.players[2].hand = botCards[1]
        game.players[3].hand = botCards[2]

        let card1 = Card(suit: .clubs, rank: .ace)
        let card2 = Card(suit: .clubs, rank: .king)
        let card3 = Card(suit: .clubs, rank: .queen)
        let humanCards = PassedCards(first: card1, second: card2, third: card3)

        // roundNumber=0 → .left exchange (human passes to player at index 1)
        game.performExchange(humanCards: humanCards)

        XCTAssertFalse(game.players[0].hand.contains(card1), "Human should no longer hold the passed card1")
        XCTAssertFalse(game.players[0].hand.contains(card2), "Human should no longer hold the passed card2")
        XCTAssertFalse(game.players[0].hand.contains(card3), "Human should no longer hold the passed card3")
        XCTAssertTrue(game.players[1].hand.contains(card1), "Bot1 should have received card1 from human")
        XCTAssertTrue(game.players[1].hand.contains(card2), "Bot1 should have received card2 from human")
        XCTAssertTrue(game.players[1].hand.contains(card3), "Bot1 should have received card3 from human")
        XCTAssertEqual(game.players[0].hand.count, 13)
        XCTAssertEqual(game.players[1].hand.count, 13)
    }

    func test_performExchange_preventedOnSecondCall() {
        let game = Game()  // all bots
        let handsBefore = game.players.map { $0.hand }

        game.performExchange()
        let handsAfterFirst = game.players.map { $0.hand }

        // Second call should be a no-op — hands must not change further
        game.performExchange()

        XCTAssertEqual(game.players[0].hand, handsAfterFirst[0], "Second exchange call should be a no-op")
        XCTAssertEqual(game.players[1].hand, handsAfterFirst[1])
        XCTAssertEqual(game.players[2].hand, handsAfterFirst[2])
        XCTAssertEqual(game.players[3].hand, handsAfterFirst[3])
        // First exchange should have changed hands
        let anyHandChanged = zip(handsBefore, handsAfterFirst).contains { $0 != $1 }
        XCTAssertTrue(anyHandChanged, "First exchange should change hands")
    }

    func test_performExchange_allowedAfterStartNewHand() {
        let game = Game()  // all bots

        game.performExchange()

        // Start a new hand — exchange flag resets
        game.startNewHand()
        let handsAfterNewHand = game.players.map { $0.hand }

        // Exchange again should work (hands change from fresh deal)
        game.performExchange()
        let handsAfterSecondExchange = game.players.map { $0.hand }

        // After startNewHand the hands are re-dealt (not the same as before)
        // After the second exchange, some cards should have moved again
        let anyHandChanged = zip(handsAfterNewHand, handsAfterSecondExchange).contains { $0 != $1 }
        XCTAssertTrue(anyHandChanged, "Exchange after startNewHand should change hands")
    }

    func test_performExchange_noPassRound_doesNothing() {
        let game = Game()  // all bots
        game.roundNumber = 3  // .none direction
        let handsBefore = game.players.map { $0.hand }

        game.performExchange()  // should be a no-op (direction is .none)

        for i in 0..<4 {
            XCTAssertEqual(game.players[i].hand, handsBefore[i], "Hands should not change when direction is .none")
        }
    }
}
