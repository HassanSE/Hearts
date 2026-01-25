//
//  GameplayTests.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import XCTest
@testable import Hearts

final class GameplayTests: XCTestCase {

    // MARK: - Setup Helper

    /// Creates a game with known card distribution for testing
    func makeTestGame() -> Game {
        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let player3 = Player(name: "Charlie")
        let player4 = Player(name: "Diana")

        let game = Game(player1: player1, player2: player2, player3: player3, player4: player4)

        // Manually set up hands for predictable testing
        // Give player 0 the 2 of clubs so they lead
        game.players[0].hand = [
            Card(suit: .clubs, rank: .two),
            Card(suit: .clubs, rank: .three),
            Card(suit: .diamonds, rank: .four)
        ]
        game.players[1].hand = [
            Card(suit: .clubs, rank: .five),
            Card(suit: .hearts, rank: .six),
            Card(suit: .diamonds, rank: .seven)
        ]
        game.players[2].hand = [
            Card(suit: .clubs, rank: .eight),
            Card(suit: .hearts, rank: .nine),
            Card(suit: .diamonds, rank: .ten)
        ]
        game.players[3].hand = [
            Card(suit: .clubs, rank: .jack),
            Card(suit: .hearts, rank: .queen),
            Card(suit: .diamonds, rank: .king)
        ]

        // Reset game state
        game.currentPlayerIndex = 0
        game.currentTrick = Trick()
        game.completedTricks = []
        game.heartsBroken = false

        return game
    }

    // MARK: - Turn Validation Tests

    func test_playCard_throws_when_not_players_turn() throws {
        let game = makeTestGame()

        let wrongPlayer = game.players[1]
        let card = wrongPlayer.hand[0]

        XCTAssertThrowsError(try game.playCard(card, by: wrongPlayer)) { error in
            XCTAssertEqual(error as? GameError, GameError.notPlayersTurn)
        }
    }

    func test_playCard_succeeds_when_players_turn() throws {
        let game = makeTestGame()

        let currentPlayer = game.currentPlayer
        let card = Card(suit: .clubs, rank: .two)

        XCTAssertNoThrow(try game.playCard(card, by: currentPlayer))
    }

    func test_playCard_advances_turn_after_play() throws {
        let game = makeTestGame()

        let player1 = game.players[0]
        let card = Card(suit: .clubs, rank: .two)

        try game.playCard(card, by: player1)

        XCTAssertEqual(game.currentPlayerIndex, 1, "Turn should advance to next player")
    }

    // MARK: - First Trick Rules Tests

    func test_playCard_throws_when_first_card_is_not_two_of_clubs() throws {
        let game = makeTestGame()
        game.players[0].hand = [
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .two)
        ]

        let player = game.players[0]
        let wrongCard = Card(suit: .clubs, rank: .three)

        XCTAssertThrowsError(try game.playCard(wrongCard, by: player)) { error in
            XCTAssertEqual(error as? GameError, GameError.mustLeadWithTwoOfClubs)
        }
    }

    func test_playCard_allows_two_of_clubs_as_first_card() throws {
        let game = makeTestGame()

        let player = game.players[0]
        let card = Card(suit: .clubs, rank: .two)

        XCTAssertNoThrow(try game.playCard(card, by: player))
    }

    func test_playCard_throws_when_playing_points_on_first_trick() throws {
        let game = makeTestGame()

        // Play 2♣ first
        try game.playCard(Card(suit: .clubs, rank: .two), by: game.players[0])

        // Try to play a heart on first trick
        let player2 = game.players[1]
        let heartCard = Card(suit: .hearts, rank: .six)

        XCTAssertThrowsError(try game.playCard(heartCard, by: player2)) { error in
            XCTAssertEqual(error as? GameError, GameError.cannotPlayPointsOnFirstTrick)
        }
    }

    func test_playCard_allows_points_on_first_trick_if_no_choice() throws {
        let game = makeTestGame()

        // Set up player with only hearts
        game.players[1].hand = [
            Card(suit: .hearts, rank: .six),
            Card(suit: .hearts, rank: .seven)
        ]

        // Play 2♣ first
        try game.playCard(Card(suit: .clubs, rank: .two), by: game.players[0])

        // Should allow heart since player has no other cards
        let player2 = game.players[1]
        let heartCard = Card(suit: .hearts, rank: .six)

        XCTAssertNoThrow(try game.playCard(heartCard, by: player2))
    }

    // MARK: - Hearts Broken Tests

    func test_playCard_throws_when_leading_hearts_before_broken() throws {
        let game = makeTestGame()

        // Set up game state after first trick
        game.completedTricks = [Trick()]
        game.heartsBroken = false
        game.players[0].hand = [
            Card(suit: .hearts, rank: .three),
            Card(suit: .diamonds, rank: .four)
        ]

        let player = game.players[0]
        let heartCard = Card(suit: .hearts, rank: .three)

        XCTAssertThrowsError(try game.playCard(heartCard, by: player)) { error in
            XCTAssertEqual(error as? GameError, GameError.heartsNotBroken)
        }
    }

    func test_playCard_allows_leading_hearts_after_broken() throws {
        let game = makeTestGame()

        // Set up game state with hearts broken
        game.completedTricks = [Trick()]
        game.heartsBroken = true
        game.players[0].hand = [Card(suit: .hearts, rank: .three)]

        let player = game.players[0]
        let heartCard = Card(suit: .hearts, rank: .three)

        XCTAssertNoThrow(try game.playCard(heartCard, by: player))
    }

    func test_playCard_allows_leading_hearts_when_only_hearts_in_hand() throws {
        let game = makeTestGame()

        // Set up game state with only hearts
        game.completedTricks = [Trick()]
        game.heartsBroken = false
        game.players[0].hand = [
            Card(suit: .hearts, rank: .three),
            Card(suit: .hearts, rank: .four)
        ]

        let player = game.players[0]
        let heartCard = Card(suit: .hearts, rank: .three)

        XCTAssertNoThrow(try game.playCard(heartCard, by: player))
    }

    func test_playCard_sets_hearts_broken_when_heart_played() throws {
        let game = makeTestGame()

        // Complete first trick with no points (to avoid first trick restrictions)
        try game.playCard(Card(suit: .clubs, rank: .two), by: game.players[0])
        try game.playCard(Card(suit: .clubs, rank: .five), by: game.players[1])
        try game.playCard(Card(suit: .clubs, rank: .eight), by: game.players[2])
        try game.playCard(Card(suit: .clubs, rank: .jack), by: game.players[3])

        XCTAssertFalse(game.heartsBroken, "Hearts should not be broken yet")
        XCTAssertEqual(game.completedTricks.count, 1)

        // Player 3 won, now leading second trick
        // Set up player 3 to lead diamonds, then player 0 has no diamonds so plays heart
        game.players[3].hand = [Card(suit: .diamonds, rank: .king)]
        game.players[0].hand = [
            Card(suit: .hearts, rank: .three),
            Card(suit: .clubs, rank: .three)
        ]

        try game.playCard(Card(suit: .diamonds, rank: .king), by: game.players[3])
        try game.playCard(Card(suit: .hearts, rank: .three), by: game.players[0])

        XCTAssertTrue(game.heartsBroken, "Hearts should be broken after playing a heart")
    }

    // MARK: - Trick Completion Tests

    func test_playCard_completes_trick_after_4_plays() throws {
        let game = makeTestGame()

        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertFalse(game.currentTrick.isComplete)

        // Play all 4 cards
        try game.playCard(Card(suit: .clubs, rank: .two), by: game.players[0])
        try game.playCard(Card(suit: .clubs, rank: .five), by: game.players[1])
        try game.playCard(Card(suit: .clubs, rank: .eight), by: game.players[2])
        try game.playCard(Card(suit: .clubs, rank: .jack), by: game.players[3])

        XCTAssertEqual(game.completedTricks.count, 1, "Trick should be completed")
        XCTAssertEqual(game.currentTrick.plays.count, 0, "New trick should be started")
    }

    func test_playCard_awards_points_to_trick_winner() throws {
        let game = makeTestGame()

        // Set up a trick with points
        game.players[0].hand = [Card(suit: .clubs, rank: .two)]
        game.players[1].hand = [Card(suit: .hearts, rank: .six)] // 1 point
        game.players[2].hand = [Card(suit: .hearts, rank: .nine)] // 1 point
        game.players[3].hand = [Card(suit: .clubs, rank: .jack)] // Wins trick

        let initialScore = game.players[3].roundScore

        try game.playCard(Card(suit: .clubs, rank: .two), by: game.players[0])
        try game.playCard(Card(suit: .hearts, rank: .six), by: game.players[1])
        try game.playCard(Card(suit: .hearts, rank: .nine), by: game.players[2])
        try game.playCard(Card(suit: .clubs, rank: .jack), by: game.players[3])

        XCTAssertEqual(game.players[3].roundScore, initialScore + 2, "Winner should get 2 points")
    }

    func test_playCard_winner_leads_next_trick() throws {
        let game = makeTestGame()

        // Player 3 will win with jack of clubs
        try game.playCard(Card(suit: .clubs, rank: .two), by: game.players[0])
        try game.playCard(Card(suit: .clubs, rank: .five), by: game.players[1])
        try game.playCard(Card(suit: .clubs, rank: .eight), by: game.players[2])
        try game.playCard(Card(suit: .clubs, rank: .jack), by: game.players[3])

        XCTAssertEqual(game.currentPlayerIndex, 3, "Winner should lead next trick")
    }

    // MARK: - Card Removal Tests

    func test_playCard_removes_card_from_hand() throws {
        let game = makeTestGame()

        let player = game.players[0]
        let card = Card(suit: .clubs, rank: .two)
        let initialHandSize = player.hand.count

        try game.playCard(card, by: player)

        XCTAssertEqual(game.players[0].hand.count, initialHandSize - 1)
        XCTAssertFalse(game.players[0].hand.contains(card))
    }

    // MARK: - Hand Completion Tests

    func test_isHandComplete_is_false_initially() {
        let game = makeTestGame()

        XCTAssertFalse(game.isHandComplete)
    }

    func test_isHandComplete_is_true_after_13_tricks() throws {
        let game = makeTestGame()

        // Simulate 13 completed tricks
        for _ in 0..<13 {
            game.completedTricks.append(Trick())
        }

        XCTAssertTrue(game.isHandComplete)
    }

    func test_playCard_throws_when_hand_is_complete() throws {
        let game = makeTestGame()

        // Simulate hand completion
        for _ in 0..<13 {
            game.completedTricks.append(Trick())
        }

        let player = game.players[0]
        let card = game.players[0].hand[0]

        XCTAssertThrowsError(try game.playCard(card, by: player)) { error in
            XCTAssertEqual(error as? GameError, GameError.handComplete)
        }
    }

    // MARK: - Integration Tests

    func test_complete_trick_flow() throws {
        let game = makeTestGame()

        // Play a complete trick
        let twoOfClubs = Card(suit: .clubs, rank: .two)
        let fiveOfClubs = Card(suit: .clubs, rank: .five)
        let eightOfClubs = Card(suit: .clubs, rank: .eight)
        let jackOfClubs = Card(suit: .clubs, rank: .jack)

        try game.playCard(twoOfClubs, by: game.players[0])
        XCTAssertEqual(game.currentPlayerIndex, 1)
        XCTAssertEqual(game.currentTrick.plays.count, 1)

        try game.playCard(fiveOfClubs, by: game.players[1])
        XCTAssertEqual(game.currentPlayerIndex, 2)
        XCTAssertEqual(game.currentTrick.plays.count, 2)

        try game.playCard(eightOfClubs, by: game.players[2])
        XCTAssertEqual(game.currentPlayerIndex, 3)
        XCTAssertEqual(game.currentTrick.plays.count, 3)

        try game.playCard(jackOfClubs, by: game.players[3])

        // After trick completes
        XCTAssertEqual(game.completedTricks.count, 1)
        XCTAssertEqual(game.currentTrick.plays.count, 0)
        XCTAssertEqual(game.currentPlayerIndex, 3, "Winner leads next")
    }
}
