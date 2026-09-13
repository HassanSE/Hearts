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

        // Known deal (valid by construction): player 0 holds 2♣ and leads.
        let game = try! Game(player1: player1, player2: player2, player3: player3, player4: player4, hands: [
            [
                Card(suit: .clubs, rank: .two),
                Card(suit: .clubs, rank: .three),
                Card(suit: .diamonds, rank: .four)
            ],
            [
                Card(suit: .clubs, rank: .five),
                Card(suit: .hearts, rank: .six),
                Card(suit: .diamonds, rank: .seven)
            ],
            [
                Card(suit: .clubs, rank: .eight),
                Card(suit: .hearts, rank: .nine),
                Card(suit: .diamonds, rank: .ten)
            ],
            [
                Card(suit: .clubs, rank: .jack),
                Card(suit: .hearts, rank: .queen),
                Card(suit: .diamonds, rank: .king)
            ]
        ])

        return game
    }

    /// Helper to simulate a seat capturing all hearts + Q♠ (shooting the moon)
    /// Creates completed tricks where the specified seat won all point cards
    func simulateMoonShot(by moonShooter: Seat, in game: Game, includeJackOfDiamonds: Bool = false) {
        // Get other seats for trick construction
        let otherPlayers = Seat.allCases.filter { $0 != moonShooter }

        // Create 13 separate tricks, one for each heart rank
        let heartRanks = Card.Rank.allCases
        for rank in heartRanks {
            var trick = Trick()

            // Moon shooter leads and wins with the heart
            // Other players play non-hearts (lower rank cards)
            try! trick.play(Card(suit: .hearts, rank: rank), by: moonShooter)
            try! trick.play(Card(suit: .clubs, rank: .two), by: otherPlayers[0])
            try! trick.play(Card(suit: .clubs, rank: .three), by: otherPlayers[1])
            try! trick.play(Card(suit: .clubs, rank: .four), by: otherPlayers[2])

            game.completedTricks.append(trick)
        }

        // Create trick with Q♠ and optionally J♦ where moon shooter wins
        var queenTrick = Trick()
        try! queenTrick.play(Card(suit: .spades, rank: .two), by: otherPlayers[0])
        try! queenTrick.play(Card(suit: .spades, rank: .queen), by: otherPlayers[1])

        if includeJackOfDiamonds {
            try! queenTrick.play(Card(suit: .diamonds, rank: .jack), by: otherPlayers[2])
        } else {
            try! queenTrick.play(Card(suit: .spades, rank: .three), by: otherPlayers[2])
        }

        try! queenTrick.play(Card(suit: .spades, rank: .ace), by: moonShooter)
        game.completedTricks.append(queenTrick)

        // Calculate and set round scores (points were awarded during tricks in real game)
        game.roundScores[moonShooter] = includeJackOfDiamonds ? 16 : 26
    }

    /// Appends completed tricks so that each seat has captured exactly `points[seat]` hearts,
    /// mirroring what `completeTrick` records during play. Points must be 0...13 per seat and
    /// distinct hearts are used across seats, so the sum must not exceed 13.
    func simulateCapturedHearts(_ points: [Int], in game: Game) {
        var hearts = Card.Rank.allCases.map { Card(suit: .hearts, rank: $0) }
        for (seat, count) in zip(Seat.allCases, points) {
            let others = Seat.allCases.filter { $0 != seat }
            for _ in 0..<count {
                var trick = Trick()
                // The winner leads a heart; the others discard low clubs.
                try! trick.play(hearts.removeLast(), by: seat)
                try! trick.play(Card(suit: .clubs, rank: .two), by: others[0])
                try! trick.play(Card(suit: .clubs, rank: .three), by: others[1])
                try! trick.play(Card(suit: .clubs, rank: .four), by: others[2])
                game.completedTricks.append(trick)
                game.roundScores[seat] += 1
            }
        }
    }

    // MARK: - Turn Validation Tests

    func test_playCard_throws_when_not_players_turn() throws {
        let game = makeTestGame()

        let wrongPlayer: Seat = .west
        let card = game.hands[wrongPlayer][0]

        XCTAssertThrowsError(try game.playCard(card, by: wrongPlayer)) { error in
            XCTAssertEqual(error as? GameError, GameError.notPlayersTurn)
        }
    }

    func test_playCard_succeeds_when_players_turn() throws {
        let game = makeTestGame()

        let currentSeat = game.currentSeat
        let card = Card(suit: .clubs, rank: .two)

        XCTAssertNoThrow(try game.playCard(card, by: currentSeat))
    }

    func test_playCard_advances_turn_after_play() throws {
        let game = makeTestGame()

        let player1: Seat = .south
        let card = Card(suit: .clubs, rank: .two)

        try game.playCard(card, by: player1)

        XCTAssertEqual(game.currentSeat, .west, "Turn should advance to next player")
    }

    // MARK: - First Trick Rules Tests

    func test_playCard_throws_when_first_card_is_not_two_of_clubs() throws {
        let game = makeTestGame()
        game.hands[.south] = [
            Card(suit: .clubs, rank: .three),
            Card(suit: .clubs, rank: .two)
        ]

        let player: Seat = .south
        let wrongCard = Card(suit: .clubs, rank: .three)

        XCTAssertThrowsError(try game.playCard(wrongCard, by: player)) { error in
            XCTAssertEqual(error as? GameError, GameError.mustLeadWithTwoOfClubs)
        }
    }

    func test_playCard_allows_two_of_clubs_as_first_card() throws {
        let game = makeTestGame()

        let player: Seat = .south
        let card = Card(suit: .clubs, rank: .two)

        XCTAssertNoThrow(try game.playCard(card, by: player))
    }

    func test_playCard_throws_when_playing_points_on_first_trick() throws {
        let game = makeTestGame()

        // Play 2♣ first
        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)

        // Try to play a heart on first trick
        let player2: Seat = .west
        let heartCard = Card(suit: .hearts, rank: .six)

        XCTAssertThrowsError(try game.playCard(heartCard, by: player2)) { error in
            XCTAssertEqual(error as? GameError, GameError.cannotPlayPointsOnFirstTrick)
        }
    }

    func test_playCard_allows_points_on_first_trick_if_no_choice() throws {
        let game = makeTestGame()

        // Set up player with only hearts
        game.hands[.west] = [
            Card(suit: .hearts, rank: .six),
            Card(suit: .hearts, rank: .seven)
        ]

        // Play 2♣ first
        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)

        // Should allow heart since player has no other cards
        let player2: Seat = .west
        let heartCard = Card(suit: .hearts, rank: .six)

        XCTAssertNoThrow(try game.playCard(heartCard, by: player2))
    }

    // MARK: - Hearts Broken Tests

    func test_playCard_throws_when_leading_hearts_before_broken() throws {
        let game = makeTestGame()

        // Set up game state after first trick
        game.completedTricks = [Trick()]
        game.heartsBroken = false
        game.hands[.south] = [
            Card(suit: .hearts, rank: .three),
            Card(suit: .diamonds, rank: .four)
        ]

        let player: Seat = .south
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
        game.hands[.south] = [Card(suit: .hearts, rank: .three)]

        let player: Seat = .south
        let heartCard = Card(suit: .hearts, rank: .three)

        XCTAssertNoThrow(try game.playCard(heartCard, by: player))
    }

    func test_playCard_allows_leading_hearts_when_only_hearts_in_hand() throws {
        let game = makeTestGame()

        // Set up game state with only hearts
        game.completedTricks = [Trick()]
        game.heartsBroken = false
        game.hands[.south] = [
            Card(suit: .hearts, rank: .three),
            Card(suit: .hearts, rank: .four)
        ]

        let player: Seat = .south
        let heartCard = Card(suit: .hearts, rank: .three)

        XCTAssertNoThrow(try game.playCard(heartCard, by: player))
    }

    func test_playCard_sets_hearts_broken_when_heart_played() throws {
        let game = makeTestGame()

        // Complete first trick with no points (to avoid first trick restrictions)
        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        try game.playCard(Card(suit: .clubs, rank: .five), by: .west)
        try game.playCard(Card(suit: .clubs, rank: .eight), by: .north)
        try game.playCard(Card(suit: .clubs, rank: .jack), by: .east)

        XCTAssertFalse(game.heartsBroken, "Hearts should not be broken yet")
        XCTAssertEqual(game.completedTricks.count, 1)

        // Player 3 won, now leading second trick
        // Set up player 3 to lead diamonds, then player 0 has no diamonds so plays heart
        game.hands[.east] = [Card(suit: .diamonds, rank: .king)]
        game.hands[.south] = [
            Card(suit: .hearts, rank: .three),
            Card(suit: .clubs, rank: .three)
        ]

        try game.playCard(Card(suit: .diamonds, rank: .king), by: .east)
        try game.playCard(Card(suit: .hearts, rank: .three), by: .south)

        XCTAssertTrue(game.heartsBroken, "Hearts should be broken after playing a heart")
    }

    // MARK: - Trick Completion Tests

    func test_playCard_completes_trick_after_4_plays() throws {
        let game = makeTestGame()

        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertFalse(game.currentTrick.isComplete)

        // Play all 4 cards
        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        try game.playCard(Card(suit: .clubs, rank: .five), by: .west)
        try game.playCard(Card(suit: .clubs, rank: .eight), by: .north)
        try game.playCard(Card(suit: .clubs, rank: .jack), by: .east)

        XCTAssertEqual(game.completedTricks.count, 1, "Trick should be completed")
        XCTAssertEqual(game.currentTrick.plays.count, 0, "New trick should be started")
    }

    func test_playCard_awards_points_to_trick_winner() throws {
        let game = makeTestGame()

        // Set up a trick with points
        game.hands[.south] = [Card(suit: .clubs, rank: .two)]
        game.hands[.west] = [Card(suit: .hearts, rank: .six)] // 1 point
        game.hands[.north] = [Card(suit: .hearts, rank: .nine)] // 1 point
        game.hands[.east] = [Card(suit: .clubs, rank: .jack)] // Wins trick

        let initialScore = game.roundScores[.east]

        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        try game.playCard(Card(suit: .hearts, rank: .six), by: .west)
        try game.playCard(Card(suit: .hearts, rank: .nine), by: .north)
        try game.playCard(Card(suit: .clubs, rank: .jack), by: .east)

        XCTAssertEqual(game.roundScores[.east], initialScore + 2, "Winner should get 2 points")
    }

    func test_playCard_winner_leads_next_trick() throws {
        let game = makeTestGame()

        // Player 3 will win with jack of clubs
        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        try game.playCard(Card(suit: .clubs, rank: .five), by: .west)
        try game.playCard(Card(suit: .clubs, rank: .eight), by: .north)
        try game.playCard(Card(suit: .clubs, rank: .jack), by: .east)

        XCTAssertEqual(game.currentSeat, .east, "Winner should lead next trick")
    }

    // MARK: - Card Removal Tests

    func test_playCard_removes_card_from_hand() throws {
        let game = makeTestGame()

        let player: Seat = .south
        let card = Card(suit: .clubs, rank: .two)
        let initialHandSize = game.hands[player].count

        try game.playCard(card, by: player)

        XCTAssertEqual(game.hands[.south].count, initialHandSize - 1)
        XCTAssertFalse(game.hands[.south].contains(card))
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

        let player: Seat = .south
        let card = game.hands[.south][0]

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

        try game.playCard(twoOfClubs, by: .south)
        XCTAssertEqual(game.currentSeat, .west)
        XCTAssertEqual(game.currentTrick.plays.count, 1)

        try game.playCard(fiveOfClubs, by: .west)
        XCTAssertEqual(game.currentSeat, .north)
        XCTAssertEqual(game.currentTrick.plays.count, 2)

        try game.playCard(eightOfClubs, by: .north)
        XCTAssertEqual(game.currentSeat, .east)
        XCTAssertEqual(game.currentTrick.plays.count, 3)

        try game.playCard(jackOfClubs, by: .east)

        // After trick completes
        XCTAssertEqual(game.completedTricks.count, 1)
        XCTAssertEqual(game.currentTrick.plays.count, 0)
        XCTAssertEqual(game.currentSeat, .east, "Winner leads next")
    }

    // MARK: - Multi-Round Tests

    func test_endHand_transfers_round_scores_to_total_scores() {
        let game = makeTestGame()

        // Seats capture 4, 3, 0 and 6 hearts respectively
        simulateCapturedHearts([4, 3, 0, 6], in: game)

        let initialTotals = game.totalScores

        game.endHand()

        XCTAssertEqual(game.totalScores[.south], initialTotals[.south] + 4)
        XCTAssertEqual(game.totalScores[.west], initialTotals[.west] + 3)
        XCTAssertEqual(game.totalScores[.north], initialTotals[.north] + 0)
        XCTAssertEqual(game.totalScores[.east], initialTotals[.east] + 6)
    }

    func test_endHand_resets_round_scores_to_zero() {
        let game = makeTestGame()

        simulateCapturedHearts([4, 3, 0, 6], in: game)

        game.endHand()

        XCTAssertEqual(game.roundScores[.south], 0)
        XCTAssertEqual(game.roundScores[.west], 0)
        XCTAssertEqual(game.roundScores[.north], 0)
        XCTAssertEqual(game.roundScores[.east], 0)
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
        game.hands[.south] = []
        game.hands[.west] = []
        game.hands[.north] = []
        game.hands[.east] = []

        game.startNewHand()

        XCTAssertEqual(game.hands[.south].count, 13)
        XCTAssertEqual(game.hands[.west].count, 13)
        XCTAssertEqual(game.hands[.north].count, 13)
        XCTAssertEqual(game.hands[.east].count, 13)
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
        let currentSeat = game.currentSeat
        XCTAssertTrue(game.hands[currentSeat].contains(where: { $0.suit == .clubs && $0.rank == .two }))
    }

    func test_isGameOver_is_false_when_no_player_reaches_winning_score() {
        let game = makeTestGame()

        game.totalScores[.south] = 50
        game.totalScores[.west] = 60
        game.totalScores[.north] = 70
        game.totalScores[.east] = 80

        XCTAssertFalse(game.isGameOver)
    }

    func test_isGameOver_is_true_when_player_reaches_winning_score() {
        let game = makeTestGame()

        game.totalScores[.south] = 50
        game.totalScores[.west] = 100
        game.totalScores[.north] = 70
        game.totalScores[.east] = 80

        XCTAssertTrue(game.isGameOver)
    }

    func test_gameWinner_is_nil_when_game_not_over() {
        let game = makeTestGame()

        game.totalScores[.south] = 50
        game.totalScores[.west] = 60

        XCTAssertNil(game.gameWinner)
    }

    func test_gameWinner_returns_player_with_lowest_score() {
        let game = makeTestGame()

        game.totalScores[.south] = 105
        game.totalScores[.west] = 100
        game.totalScores[.north] = 110
        game.totalScores[.east] = 95  // Lowest score - winner!

        let winner = game.gameWinner

        XCTAssertEqual(winner, .east)
    }

    func test_isGameTied_is_false_when_game_not_over() {
        let game = makeTestGame()

        game.totalScores[.south] = 40
        game.totalScores[.west] = 40

        XCTAssertFalse(game.isGameTied)
    }

    func test_isGameTied_is_false_when_one_clear_winner() {
        let game = makeTestGame()

        game.totalScores[.south] = 105
        game.totalScores[.west] = 100
        game.totalScores[.north] = 110
        game.totalScores[.east] = 95  // Unique lowest — clear winner

        XCTAssertFalse(game.isGameTied)
    }

    func test_isGameTied_is_false_when_higher_scores_tied_but_winner_is_clear() {
        let game = makeTestGame()

        // Players 1 and 2 are tied at 100, but player 3 has a uniquely lower score
        game.totalScores[.south] = 100
        game.totalScores[.west] = 100
        game.totalScores[.north] = 110
        game.totalScores[.east] = 60  // Clear winner

        XCTAssertFalse(game.isGameTied)
        XCTAssertEqual(game.gameWinner, .east)
    }

    func test_isGameTied_is_true_when_two_players_share_minimum() {
        let game = makeTestGame()

        game.totalScores[.south] = 100  // Threshold crossed
        game.totalScores[.west] = 50   // Tied minimum
        game.totalScores[.north] = 80
        game.totalScores[.east] = 50   // Tied minimum

        XCTAssertTrue(game.isGameTied)
        XCTAssertNil(game.gameWinner)
    }

    func test_isGameTied_is_true_when_all_players_share_minimum() {
        let game = makeTestGame()

        game.totalScores[.south] = 100  // Threshold crossed
        game.totalScores[.west] = 100
        game.totalScores[.north] = 100
        game.totalScores[.east] = 100

        XCTAssertTrue(game.isGameTied)
        XCTAssertNil(game.gameWinner)
    }

    func test_multi_round_flow() {
        let game = makeTestGame()

        // Play first round and accumulate scores
        simulateCapturedHearts([4, 3, 0, 6], in: game)

        // End first hand
        game.endHand()

        XCTAssertEqual(game.roundNumber, 1)
        XCTAssertEqual(game.totalScores[.south], 4)
        XCTAssertEqual(game.totalScores[.east], 6)
        XCTAssertEqual(game.roundScores[.south], 0)

        // Start second hand
        game.startNewHand()

        XCTAssertEqual(game.hands[.south].count, 13)
        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertFalse(game.heartsBroken)

        // Verify game continues
        XCTAssertFalse(game.isGameOver)
    }

    // MARK: - Jack of Diamonds Bonus Tests

    func test_jackOfDiamonds_no_bonus_with_standard_config() throws {
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: .standard
        )

        // Set up first trick with Jack of Diamonds
        game.hands[.south] = [Card(suit: .clubs, rank: .two)]
        game.hands[.west] = [Card(suit: .clubs, rank: .three)]
        game.hands[.north] = [Card(suit: .clubs, rank: .four)]
        game.hands[.east] = [Card(suit: .diamonds, rank: .jack), Card(suit: .clubs, rank: .ace)]  // Will win

        game.currentSeat = .south

        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        try game.playCard(Card(suit: .clubs, rank: .three), by: .west)
        try game.playCard(Card(suit: .clubs, rank: .four), by: .north)
        try game.playCard(Card(suit: .clubs, rank: .ace), by: .east)

        // Player 3 won but no bonus applied
        XCTAssertEqual(game.roundScores[.east], 0, "Jack of Diamonds should not apply bonus in standard config")
    }

    func test_jackOfDiamonds_applies_bonus_with_jackBonus_config() throws {
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: .withJackBonus
        )

        // Set up trick where player wins Jack of Diamonds
        game.hands[.south] = [Card(suit: .diamonds, rank: .king)]
        game.hands[.west] = [Card(suit: .diamonds, rank: .jack)]  // J♦
        game.hands[.north] = [Card(suit: .diamonds, rank: .three)]
        game.hands[.east] = [Card(suit: .diamonds, rank: .ace)]  // Will win

        // Can't use 2♣ for first trick here, so manually set up state
        game.completedTricks = [Trick()]
        game.currentSeat = .south

        try game.playCard(Card(suit: .diamonds, rank: .king), by: .south)
        try game.playCard(Card(suit: .diamonds, rank: .jack), by: .west)
        try game.playCard(Card(suit: .diamonds, rank: .three), by: .north)
        try game.playCard(Card(suit: .diamonds, rank: .ace), by: .east)

        // Player 3 won and should get -10 points
        XCTAssertEqual(game.roundScores[.east], -10, "Jack of Diamonds should apply -10 bonus")
    }

    func test_jackOfDiamonds_bonus_with_hearts_in_same_trick() throws {
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: .withJackBonus
        )

        // Set up trick with hearts and J♦
        game.hands[.south] = [Card(suit: .diamonds, rank: .king)]
        game.hands[.west] = [Card(suit: .diamonds, rank: .jack)]  // J♦
        game.hands[.north] = [Card(suit: .hearts, rank: .three)]   // 1 point
        game.hands[.east] = [Card(suit: .diamonds, rank: .ace)]   // Will win

        game.completedTricks = [Trick()]
        game.currentSeat = .south
        game.heartsBroken = true  // Allow hearts to be played

        try game.playCard(Card(suit: .diamonds, rank: .king), by: .south)
        try game.playCard(Card(suit: .diamonds, rank: .jack), by: .west)
        try game.playCard(Card(suit: .hearts, rank: .three), by: .north)
        try game.playCard(Card(suit: .diamonds, rank: .ace), by: .east)

        // Player 3 should get 1 (heart) - 10 (J♦) = -9 points
        XCTAssertEqual(game.roundScores[.east], -9)
    }

    func test_gameConfiguration_custom_winning_score() {
        let customConfig = GameConfiguration(jackOfDiamondsBonus: false, winningScore: 50)
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: customConfig
        )

        XCTAssertEqual(game.winningScore, 50)

        game.totalScores[.south] = 50
        XCTAssertTrue(game.isGameOver)
    }

    func test_jackOfDiamonds_bonus_can_result_in_negative_round_score() throws {
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: .withJackBonus
        )

        // Player takes only J♦, no other point cards
        game.completedTricks = [Trick()]
        game.hands[.south] = [Card(suit: .diamonds, rank: .two)]
        game.hands[.west] = [Card(suit: .diamonds, rank: .jack)]
        game.hands[.north] = [Card(suit: .diamonds, rank: .three)]
        game.hands[.east] = [Card(suit: .diamonds, rank: .ace)]  // Wins

        game.currentSeat = .south

        try game.playCard(Card(suit: .diamonds, rank: .two), by: .south)
        try game.playCard(Card(suit: .diamonds, rank: .jack), by: .west)
        try game.playCard(Card(suit: .diamonds, rank: .three), by: .north)
        try game.playCard(Card(suit: .diamonds, rank: .ace), by: .east)

        XCTAssertEqual(game.roundScores[.east], -10)
    }

    func test_shootTheMoon_with_jackBonus_shooter_gets_negative_10() {
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: .withJackBonus
        )

        // Player 0 shoots the moon and also captures J♦
        simulateMoonShot(by: .south, in: game, includeJackOfDiamonds: true)

        game.endHand()

        // Moon shooter gets -10, others get 26
        XCTAssertEqual(game.totalScores[.south], -10, "Moon shooter with J♦ bonus gets -10")
        XCTAssertEqual(game.totalScores[.west], 26)
        XCTAssertEqual(game.totalScores[.north], 26)
        XCTAssertEqual(game.totalScores[.east], 26)
    }

    // MARK: - Shooting the Moon Tests

    func test_shootTheMoon_standard_config_shooter_gets_zero() {
        let game = makeTestGame()

        // Player 2 shoots the moon (no J♦ bonus in standard config)
        simulateMoonShot(by: .north, in: game, includeJackOfDiamonds: false)

        game.endHand()

        // Moon shooter gets 0 points
        XCTAssertEqual(game.totalScores[.north], 0)
    }

    func test_shootTheMoon_standard_config_others_get_26() {
        let game = makeTestGame()

        // Player 2 shoots the moon
        simulateMoonShot(by: .north, in: game, includeJackOfDiamonds: false)

        game.endHand()

        // All other players get 26 points
        XCTAssertEqual(game.totalScores[.south], 26)
        XCTAssertEqual(game.totalScores[.west], 26)
        XCTAssertEqual(game.totalScores[.east], 26)
    }

    func test_shootTheMoon_round_scores_reset_after_moon_shot() {
        let game = makeTestGame()

        // Player 1 shoots the moon
        simulateMoonShot(by: .west, in: game, includeJackOfDiamonds: false)

        game.endHand()

        // All round scores should be reset to 0
        XCTAssertEqual(game.roundScores[.south], 0)
        XCTAssertEqual(game.roundScores[.west], 0)
        XCTAssertEqual(game.roundScores[.north], 0)
        XCTAssertEqual(game.roundScores[.east], 0)
    }

    func test_shootTheMoon_adds_to_existing_total_scores() {
        let game = makeTestGame()

        // Set up existing total scores
        game.totalScores[.south] = 10
        game.totalScores[.west] = 5
        game.totalScores[.north] = 8
        game.totalScores[.east] = 12

        // Player 3 shoots the moon
        simulateMoonShot(by: .east, in: game, includeJackOfDiamonds: false)

        game.endHand()

        // Moon shooter's total unchanged, others get +26
        XCTAssertEqual(game.totalScores[.south], 36)  // 10 + 26
        XCTAssertEqual(game.totalScores[.west], 31)  // 5 + 26
        XCTAssertEqual(game.totalScores[.north], 34)  // 8 + 26
        XCTAssertEqual(game.totalScores[.east], 12)  // 12 + 0 (moon shooter)
    }

    func test_shootTheMoon_does_not_trigger_without_all_hearts() {
        let game = makeTestGame()

        // Player 0 has Q♠ and only 3 hearts (missing 10)
        var heartTrick = Trick()
        try! heartTrick.play(Card(suit: .hearts, rank: .two), by: .west)
        try! heartTrick.play(Card(suit: .hearts, rank: .three), by: .north)
        try! heartTrick.play(Card(suit: .clubs, rank: .two), by: .east)
        try! heartTrick.play(Card(suit: .hearts, rank: .ace), by: .south)  // Wins

        var queenTrick = Trick()
        try! queenTrick.play(Card(suit: .spades, rank: .two), by: .west)
        try! queenTrick.play(Card(suit: .spades, rank: .queen), by: .north)
        try! queenTrick.play(Card(suit: .clubs, rank: .four), by: .east)
        try! queenTrick.play(Card(suit: .spades, rank: .ace), by: .south)  // Wins

        game.completedTricks = [heartTrick, queenTrick]
        game.roundScores[.south] = 16  // 3 hearts + Q♠ = 16, but missing 10 hearts

        game.endHand()

        // Normal scoring applies (no moon shot)
        XCTAssertEqual(game.totalScores[.south], 16)
        XCTAssertEqual(game.totalScores[.west], 0)
        XCTAssertEqual(game.totalScores[.north], 0)
        XCTAssertEqual(game.totalScores[.east], 0)
    }

    // MARK: - Hearts Broken Tests

    func test_queenOfSpades_does_not_break_hearts() {
        let game = makeTestGame()

        // Hearts are not broken at start
        XCTAssertFalse(game.heartsBroken)

        // Set up a trick: player 0 leads clubs, player 1 is void in clubs and plays Q♠
        // player 1's hand: replace clubs card with Q♠ so they must play off-suit
        game.hands[.south] = [Card(suit: .clubs, rank: .two)]
        game.hands[.west] = [Card(suit: .spades, rank: .queen)]  // void in clubs, plays Q♠
        game.hands[.north] = [Card(suit: .clubs, rank: .three)]
        game.hands[.east] = [Card(suit: .clubs, rank: .four)]

        game.currentSeat = .south

        // Play the trick
        try! game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        try! game.playCard(Card(suit: .spades, rank: .queen), by: .west)
        try! game.playCard(Card(suit: .clubs, rank: .three), by: .north)
        try! game.playCard(Card(suit: .clubs, rank: .four), by: .east)

        // Q♠ must NOT break hearts
        XCTAssertFalse(game.heartsBroken, "Playing Q♠ should not break hearts")
    }

    func test_shootTheMoon_does_not_trigger_without_queen_of_spades() {
        let game = makeTestGame()

        // Player 1 has all 13 hearts but not Q♠
        // Create 13 heart tricks where player 1 leads a heart and wins it
        for rank in Card.Rank.allCases {
            var trick = Trick()
            try! trick.play(Card(suit: .hearts, rank: rank), by: .west)  // Wins
            try! trick.play(Card(suit: .clubs, rank: .two), by: .north)
            try! trick.play(Card(suit: .clubs, rank: .three), by: .east)
            try! trick.play(Card(suit: .clubs, rank: .four), by: .south)
            game.completedTricks.append(trick)
        }

        // Q♠ goes to someone else (player 2)
        var queenTrick = Trick()
        try! queenTrick.play(Card(suit: .spades, rank: .two), by: .south)
        try! queenTrick.play(Card(suit: .spades, rank: .three), by: .west)
        try! queenTrick.play(Card(suit: .spades, rank: .queen), by: .east)
        try! queenTrick.play(Card(suit: .spades, rank: .ace), by: .north)  // Wins Q♠
        game.completedTricks.append(queenTrick)

        game.roundScores[.west] = 13  // All hearts but no Q♠
        game.roundScores[.north] = 13  // Q♠

        game.endHand()

        // Normal scoring applies (no moon shot)
        XCTAssertEqual(game.totalScores[.south], 0)
        XCTAssertEqual(game.totalScores[.west], 13)  // Gets their 13 points
        XCTAssertEqual(game.totalScores[.north], 13)  // Gets Q♠
        XCTAssertEqual(game.totalScores[.east], 0)
    }

    // MARK: - Moon-Shot Variant: subtractFromSelf

    func test_shootTheMoon_subtractFromSelf_shooterScoreDecreasesByTwentySix() {
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: .withSubtractMoonShot
        )

        game.totalScores[.south] = 50  // Shooter's existing score

        simulateMoonShot(by: .south, in: game, includeJackOfDiamonds: false)
        game.endHand()

        XCTAssertEqual(game.totalScores[.south], 24, "Shooter's score should decrease by 26: 50 - 26 = 24")
    }

    func test_shootTheMoon_subtractFromSelf_opponentsScoresAreUnchanged() {
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: .withSubtractMoonShot
        )

        game.totalScores[.west] = 10
        game.totalScores[.north] = 20
        game.totalScores[.east] = 30

        simulateMoonShot(by: .south, in: game, includeJackOfDiamonds: false)
        game.endHand()

        // Opponents' scores are unchanged (no 26 added)
        XCTAssertEqual(game.totalScores[.west], 10, "Opponent scores should not change")
        XCTAssertEqual(game.totalScores[.north], 20)
        XCTAssertEqual(game.totalScores[.east], 30)
    }

    func test_shootTheMoon_subtractFromSelf_canGoNegative() {
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: .withSubtractMoonShot
        )

        game.totalScores[.south] = 10  // Will go to -16

        simulateMoonShot(by: .south, in: game, includeJackOfDiamonds: false)
        game.endHand()

        XCTAssertEqual(game.totalScores[.south], -16, "Score can go negative with subtractFromSelf variant")
    }

    func test_shootTheMoon_subtractFromSelf_roundScoresAreReset() {
        let game = Game(
            player1: Player(name: "Alice"),
            player2: Player(name: "Bob"),
            player3: Player(name: "Charlie"),
            player4: Player(name: "Diana"),
            configuration: .withSubtractMoonShot
        )

        simulateMoonShot(by: .west, in: game, includeJackOfDiamonds: false)
        game.endHand()

        XCTAssertEqual(game.roundScores, SeatMap(repeating: 0), "Round scores should be reset to 0 after endHand")
    }
}
