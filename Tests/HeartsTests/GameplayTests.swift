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

    // MARK: - Multi-Round Tests

    func test_endHand_transfers_round_scores_to_total_scores() {
        let game = makeTestGame()

        // Set up some round scores
        game.players[0].roundScore = 10
        game.players[1].roundScore = 5
        game.players[2].roundScore = 0
        game.players[3].roundScore = 26

        let initialTotals = game.players.map { $0.totalScore }

        game.endHand()

        XCTAssertEqual(game.players[0].totalScore, initialTotals[0] + 10)
        XCTAssertEqual(game.players[1].totalScore, initialTotals[1] + 5)
        XCTAssertEqual(game.players[2].totalScore, initialTotals[2] + 0)
        XCTAssertEqual(game.players[3].totalScore, initialTotals[3] + 26)
    }

    func test_endHand_resets_round_scores_to_zero() {
        let game = makeTestGame()

        game.players[0].roundScore = 10
        game.players[1].roundScore = 5
        game.players[2].roundScore = 0
        game.players[3].roundScore = 26

        game.endHand()

        XCTAssertEqual(game.players[0].roundScore, 0)
        XCTAssertEqual(game.players[1].roundScore, 0)
        XCTAssertEqual(game.players[2].roundScore, 0)
        XCTAssertEqual(game.players[3].roundScore, 0)
    }

    func test_endHand_increments_round_number() {
        let game = makeTestGame()

        let initialRound = game.roundNumber

        game.endHand()

        XCTAssertEqual(game.roundNumber, initialRound + 1)
    }

    func test_startNewHand_deals_13_cards_to_each_player() {
        let game = makeTestGame()

        // Clear hands
        game.players[0].hand = []
        game.players[1].hand = []
        game.players[2].hand = []
        game.players[3].hand = []

        game.startNewHand()

        XCTAssertEqual(game.players[0].hand.count, 13)
        XCTAssertEqual(game.players[1].hand.count, 13)
        XCTAssertEqual(game.players[2].hand.count, 13)
        XCTAssertEqual(game.players[3].hand.count, 13)
    }

    func test_startNewHand_resets_trick_state() {
        let game = makeTestGame()

        // Create some completed tricks
        game.completedTricks = [Trick(), Trick(), Trick()]
        game.heartsBroken = true

        game.startNewHand()

        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertEqual(game.currentTrick.plays.count, 0)
        XCTAssertFalse(game.heartsBroken)
    }

    func test_startNewHand_sets_current_player_to_leader() {
        let game = makeTestGame()

        game.startNewHand()

        // Verify current player has 2 of clubs
        let currentPlayer = game.currentPlayer
        XCTAssertTrue(currentPlayer.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }))
    }

    func test_isGameOver_is_false_when_no_player_reaches_winning_score() {
        let game = makeTestGame()

        game.players[0].totalScore = 50
        game.players[1].totalScore = 60
        game.players[2].totalScore = 70
        game.players[3].totalScore = 80

        XCTAssertFalse(game.isGameOver)
    }

    func test_isGameOver_is_true_when_player_reaches_winning_score() {
        let game = makeTestGame()

        game.players[0].totalScore = 50
        game.players[1].totalScore = 100
        game.players[2].totalScore = 70
        game.players[3].totalScore = 80

        XCTAssertTrue(game.isGameOver)
    }

    func test_gameWinner_is_nil_when_game_not_over() {
        let game = makeTestGame()

        game.players[0].totalScore = 50
        game.players[1].totalScore = 60

        XCTAssertNil(game.gameWinner)
    }

    func test_gameWinner_returns_player_with_lowest_score() {
        let game = makeTestGame()

        game.players[0].totalScore = 105
        game.players[1].totalScore = 100
        game.players[2].totalScore = 110
        game.players[3].totalScore = 95  // Lowest score - winner!

        let winner = game.gameWinner

        XCTAssertEqual(winner, game.players[3])
    }

    func test_multi_round_flow() {
        let game = makeTestGame()

        // Play first round and accumulate scores
        game.players[0].roundScore = 10
        game.players[1].roundScore = 5
        game.players[2].roundScore = 0
        game.players[3].roundScore = 26

        // End first hand
        game.endHand()

        XCTAssertEqual(game.roundNumber, 1)
        XCTAssertEqual(game.players[0].totalScore, 10)
        XCTAssertEqual(game.players[3].totalScore, 26)
        XCTAssertEqual(game.players[0].roundScore, 0)

        // Start second hand
        game.startNewHand()

        XCTAssertEqual(game.players[0].hand.count, 13)
        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertFalse(game.heartsBroken)

        // Verify game continues
        XCTAssertFalse(game.isGameOver)
    }
}
