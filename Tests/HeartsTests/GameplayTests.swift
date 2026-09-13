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

    /// A three-card deal for four humans; south holds 2♣ and leads.
    func makeTestGame() -> Game {
        try! Game.fixedDeal([
            [Card.twoOfClubs, Card.threeOfClubs, Card.fourOfDiamonds],
            [Card.fiveOfClubs, Card.sixOfHearts, Card.sevenOfDiamonds],
            [Card.eightOfClubs, Card.nineOfHearts, Card.tenOfDiamonds],
            [Card.jackOfClubs, Card.queenOfHearts, Card.kingOfDiamonds]
        ])
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
            try! trick.play(Card.twoOfClubs, by: otherPlayers[0])
            try! trick.play(Card.threeOfClubs, by: otherPlayers[1])
            try! trick.play(Card.fourOfClubs, by: otherPlayers[2])

            game.completedTricks.append(trick)
        }

        // Create trick with Q♠ and optionally J♦ where moon shooter wins
        var queenTrick = Trick()
        try! queenTrick.play(Card.twoOfSpades, by: otherPlayers[0])
        try! queenTrick.play(Card.queenOfSpades, by: otherPlayers[1])

        if includeJackOfDiamonds {
            try! queenTrick.play(Card.jackOfDiamonds, by: otherPlayers[2])
        } else {
            try! queenTrick.play(Card.threeOfSpades, by: otherPlayers[2])
        }

        try! queenTrick.play(Card.aceOfSpades, by: moonShooter)
        game.completedTricks.append(queenTrick)

        // Calculate and set round scores (points were awarded during tricks in real game)
        game.roundScores[moonShooter] = includeJackOfDiamonds ? 16 : 26
        game.phase = .awaitingSettlement
    }

    /// Appends completed tricks so that each seat has captured exactly `points[seat]` hearts,
    /// mirroring what `completeTrick` records during play. Points must be 0...13 per seat and
    /// distinct hearts are used across seats, so the sum must not exceed 13.
    func simulateCapturedHearts(_ points: [Int], in game: Game) {
        var hearts = Card.fullSuit(.hearts)
        for (seat, count) in zip(Seat.allCases, points) {
            let others = Seat.allCases.filter { $0 != seat }
            for _ in 0..<count {
                var trick = Trick()
                // The winner leads a heart; the others discard low clubs.
                try! trick.play(hearts.removeLast(), by: seat)
                try! trick.play(Card.twoOfClubs, by: others[0])
                try! trick.play(Card.threeOfClubs, by: others[1])
                try! trick.play(Card.fourOfClubs, by: others[2])
                game.completedTricks.append(trick)
                game.roundScores[seat] += 1
            }
        }
        game.phase = .awaitingSettlement
    }

    // MARK: - Turn Validation Tests

    func test_playCard_outOfTurn_throws() throws {
        let game = makeTestGame()

        let wrongPlayer: Seat = .west
        let card = game.hands[wrongPlayer][0]

        XCTAssertThrowsError(try game.playCard(card, by: wrongPlayer)) { error in
            XCTAssertEqual(error as? GameError, GameError.notPlayersTurn)
        }
    }

    func test_playCard_onTurn_succeeds() throws {
        let game = makeTestGame()

        let currentSeat = game.currentSeat
        let card = Card.twoOfClubs

        XCTAssertNoThrow(try game.playCard(card, by: currentSeat))
    }

    func test_playCard_onTurn_advancesToNextSeat() throws {
        let game = makeTestGame()

        let player1: Seat = .south
        let card = Card.twoOfClubs

        try game.playCard(card, by: player1)

        XCTAssertEqual(game.currentSeat, .west, "Turn should advance to next player")
    }

    // MARK: - First Trick Rules Tests

    func test_playCard_firstCardNotTwoOfClubs_throws() throws {
        let game = makeTestGame()
        game.hands[.south] = [
            Card.threeOfClubs,
            Card.twoOfClubs
        ]

        let player: Seat = .south
        let wrongCard = Card.threeOfClubs

        XCTAssertThrowsError(try game.playCard(wrongCard, by: player)) { error in
            XCTAssertEqual(error as? GameError, GameError.mustLeadWithTwoOfClubs)
        }
    }

    func test_playCard_twoOfClubsFirst_succeeds() throws {
        let game = makeTestGame()

        let player: Seat = .south
        let card = Card.twoOfClubs

        XCTAssertNoThrow(try game.playCard(card, by: player))
    }

    func test_playCard_pointsOnFirstTrick_throws() throws {
        let game = makeTestGame()

        // Play 2♣ first
        try game.playCard(Card.twoOfClubs, by: .south)

        // Try to play a heart on first trick
        let player2: Seat = .west
        let heartCard = Card.sixOfHearts

        XCTAssertThrowsError(try game.playCard(heartCard, by: player2)) { error in
            XCTAssertEqual(error as? GameError, GameError.cannotPlayPointsOnFirstTrick)
        }
    }

    func test_playCard_onlyPointsOnFirstTrick_succeeds() throws {
        let game = makeTestGame()

        // Set up player with only hearts
        game.hands[.west] = [
            Card.sixOfHearts,
            Card.sevenOfHearts
        ]

        // Play 2♣ first
        try game.playCard(Card.twoOfClubs, by: .south)

        // Should allow heart since player has no other cards
        let player2: Seat = .west
        let heartCard = Card.sixOfHearts

        XCTAssertNoThrow(try game.playCard(heartCard, by: player2))
    }

    // MARK: - Hearts Broken Tests

    func test_playCard_leadingHeartsBeforeBroken_throws() throws {
        let game = makeTestGame()

        // Set up game state after first trick
        game.completedTricks = [Trick()]
        game.heartsBroken = false
        game.hands[.south] = [
            Card.threeOfHearts,
            Card.fourOfDiamonds
        ]

        let player: Seat = .south
        let heartCard = Card.threeOfHearts

        XCTAssertThrowsError(try game.playCard(heartCard, by: player)) { error in
            XCTAssertEqual(error as? GameError, GameError.heartsNotBroken)
        }
    }

    func test_playCard_leadingHeartsAfterBroken_succeeds() throws {
        let game = makeTestGame()

        // Set up game state with hearts broken
        game.completedTricks = [Trick()]
        game.heartsBroken = true
        game.hands[.south] = [Card.threeOfHearts]

        let player: Seat = .south
        let heartCard = Card.threeOfHearts

        XCTAssertNoThrow(try game.playCard(heartCard, by: player))
    }

    func test_playCard_leadingHeartsWithOnlyHearts_succeeds() throws {
        let game = makeTestGame()

        // Set up game state with only hearts
        game.completedTricks = [Trick()]
        game.heartsBroken = false
        game.hands[.south] = [
            Card.threeOfHearts,
            Card.fourOfHearts
        ]

        let player: Seat = .south
        let heartCard = Card.threeOfHearts

        XCTAssertNoThrow(try game.playCard(heartCard, by: player))
    }

    func test_playCard_heartPlayed_setsHeartsBroken() throws {
        let game = makeTestGame()

        // Complete first trick with no points (to avoid first trick restrictions)
        try game.playCard(Card.twoOfClubs, by: .south)
        try game.playCard(Card.fiveOfClubs, by: .west)
        try game.playCard(Card.eightOfClubs, by: .north)
        try game.playCard(Card.jackOfClubs, by: .east)

        XCTAssertFalse(game.heartsBroken, "Hearts should not be broken yet")
        XCTAssertEqual(game.completedTricks.count, 1)

        // Player 3 won, now leading second trick
        // Set up player 3 to lead diamonds, then player 0 has no diamonds so plays heart
        game.hands[.east] = [Card.kingOfDiamonds]
        game.hands[.south] = [
            Card.threeOfHearts,
            Card.threeOfClubs
        ]

        try game.playCard(Card.kingOfDiamonds, by: .east)
        try game.playCard(Card.threeOfHearts, by: .south)

        XCTAssertTrue(game.heartsBroken, "Hearts should be broken after playing a heart")
    }

    // MARK: - Trick Completion Tests

    func test_playCard_fourthPlay_completesTrick() throws {
        let game = makeTestGame()

        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertFalse(game.currentTrick.isComplete)

        // Play all 4 cards
        try game.playCard(Card.twoOfClubs, by: .south)
        try game.playCard(Card.fiveOfClubs, by: .west)
        try game.playCard(Card.eightOfClubs, by: .north)
        try game.playCard(Card.jackOfClubs, by: .east)

        XCTAssertEqual(game.completedTricks.count, 1, "Trick should be completed")
        XCTAssertEqual(game.currentTrick.plays.count, 0, "New trick should be started")
    }

    func test_playCard_trickWithPoints_awardsPointsToWinner() throws {
        let game = makeTestGame()

        // Set up a trick with points
        game.hands[.south] = [Card.twoOfClubs]
        game.hands[.west] = [Card.sixOfHearts] // 1 point
        game.hands[.north] = [Card.nineOfHearts] // 1 point
        game.hands[.east] = [Card.jackOfClubs] // Wins trick

        let initialScore = game.roundScores[.east]

        try game.playCard(Card.twoOfClubs, by: .south)
        try game.playCard(Card.sixOfHearts, by: .west)
        try game.playCard(Card.nineOfHearts, by: .north)
        try game.playCard(Card.jackOfClubs, by: .east)

        XCTAssertEqual(game.roundScores[.east], initialScore + 2, "Winner should get 2 points")
    }

    func test_playCard_trickComplete_winnerLeadsNext() throws {
        let game = makeTestGame()

        // Player 3 will win with jack of clubs
        try game.playCard(Card.twoOfClubs, by: .south)
        try game.playCard(Card.fiveOfClubs, by: .west)
        try game.playCard(Card.eightOfClubs, by: .north)
        try game.playCard(Card.jackOfClubs, by: .east)

        XCTAssertEqual(game.currentSeat, .east, "Winner should lead next trick")
    }

    // MARK: - Card Removal Tests

    func test_playCard_onTurn_removesCardFromHand() throws {
        let game = makeTestGame()

        let player: Seat = .south
        let card = Card.twoOfClubs
        let initialHandSize = game.hands[player].count

        try game.playCard(card, by: player)

        XCTAssertEqual(game.hands[.south].count, initialHandSize - 1)
        XCTAssertFalse(game.hands[.south].contains(card))
    }

    // MARK: - Hand Completion Tests

    func test_isHandComplete_initially_isFalse() {
        let game = makeTestGame()

        XCTAssertFalse(game.isHandComplete)
    }

    func test_isHandComplete_everyCardPlayed_isTrue() throws {
        let game = makeTestGame()

        // Play out the three-card fixture: 2♣ 5♣ 8♣ J♣, then east leads twice.
        try game.playCard(Card.twoOfClubs, by: .south)
        try game.playCard(Card.fiveOfClubs, by: .west)
        try game.playCard(Card.eightOfClubs, by: .north)
        try game.playCard(Card.jackOfClubs, by: .east)
        try game.playCard(Card.kingOfDiamonds, by: .east)
        try game.playCard(Card.fourOfDiamonds, by: .south)
        try game.playCard(Card.sevenOfDiamonds, by: .west)
        try game.playCard(Card.tenOfDiamonds, by: .north)
        XCTAssertFalse(game.isHandComplete)
        try game.playCard(Card.queenOfHearts, by: .east)
        try game.playCard(Card.threeOfClubs, by: .south)
        try game.playCard(Card.sixOfHearts, by: .west)
        try game.playCard(Card.nineOfHearts, by: .north)

        XCTAssertTrue(game.isHandComplete)
        XCTAssertEqual(game.phase, .awaitingSettlement)
    }

    func test_playCard_handComplete_throwsWrongPhase() throws {
        let game = makeTestGame()
        game.phase = .awaitingSettlement

        let player: Seat = .south
        let card = game.hands[.south][0]

        XCTAssertThrowsError(try game.playCard(card, by: player)) { error in
            XCTAssertEqual(error as? GameError, .wrongPhase(.awaitingSettlement))
        }
    }

    // MARK: - Integration Tests

    func test_complete_trick_flow() throws {
        let game = makeTestGame()

        // Play a complete trick
        let twoOfClubs = Card.twoOfClubs
        let fiveOfClubs = Card.fiveOfClubs
        let eightOfClubs = Card.eightOfClubs
        let jackOfClubs = Card.jackOfClubs

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

    func test_endHand_afterPlay_addsRoundScoresToTotals() throws {
        let game = makeTestGame()

        // Seats capture 4, 3, 0 and 6 hearts respectively
        simulateCapturedHearts([4, 3, 0, 6], in: game)

        let initialTotals = game.totalScores

        try game.endHand()

        XCTAssertEqual(game.totalScores[.south], initialTotals[.south] + 4)
        XCTAssertEqual(game.totalScores[.west], initialTotals[.west] + 3)
        XCTAssertEqual(game.totalScores[.north], initialTotals[.north] + 0)
        XCTAssertEqual(game.totalScores[.east], initialTotals[.east] + 6)
    }

    func test_endHand_afterPlay_resetsRoundScores() throws {
        let game = makeTestGame()

        simulateCapturedHearts([4, 3, 0, 6], in: game)

        try game.endHand()

        XCTAssertEqual(game.roundScores[.south], 0)
        XCTAssertEqual(game.roundScores[.west], 0)
        XCTAssertEqual(game.roundScores[.north], 0)
        XCTAssertEqual(game.roundScores[.east], 0)
    }

    func test_endHand_afterPlay_incrementsRoundNumber() throws {
        let game = makeTestGame()
        game.phase = .awaitingSettlement

        let initialRound = game.roundNumber

        try game.endHand()

        XCTAssertEqual(game.roundNumber, initialRound + 1)
    }

    func test_startNewHand_afterHandComplete_dealsThirteenCardsEach() throws {
        let game = makeTestGame()
        game.phase = .awaitingSettlement
        try game.endHand()

        try game.startNewHand()

        XCTAssertEqual(game.hands[.south].count, 13)
        XCTAssertEqual(game.hands[.west].count, 13)
        XCTAssertEqual(game.hands[.north].count, 13)
        XCTAssertEqual(game.hands[.east].count, 13)
    }

    func test_startNewHand_afterHandComplete_resetsTrickState() throws {
        let game = makeTestGame()

        // Create some completed tricks
        game.completedTricks = [Trick(), Trick(), Trick()]
        game.heartsBroken = true
        game.phase = .awaitingSettlement
        try game.endHand()

        try game.startNewHand()

        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertEqual(game.currentTrick.plays.count, 0)
        XCTAssertFalse(game.heartsBroken)
    }

    func test_startNewHand_afterHandComplete_setsCurrentSeatToLeader() throws {
        let game = makeTestGame()
        game.phase = .awaitingSettlement
        try game.endHand()

        try game.startNewHand()

        // Verify current player has 2 of clubs
        let currentSeat = game.currentSeat
        XCTAssertTrue(game.hands[currentSeat].contains(where: { $0.suit == .clubs && $0.rank == .two }))
    }

    func test_isGameOver_belowWinningScore_isFalse() {
        let game = makeTestGame()

        game.totalScores[.south] = 50
        game.totalScores[.west] = 60
        game.totalScores[.north] = 70
        game.totalScores[.east] = 80

        XCTAssertFalse(game.isGameOver)
    }

    func test_isGameOver_atWinningScore_isTrue() {
        let game = makeTestGame()

        game.totalScores[.south] = 50
        game.totalScores[.west] = 100
        game.totalScores[.north] = 70
        game.totalScores[.east] = 80

        XCTAssertTrue(game.isGameOver)
    }

    func test_gameWinner_gameNotOver_isNil() {
        let game = makeTestGame()

        game.totalScores[.south] = 50
        game.totalScores[.west] = 60

        XCTAssertNil(game.gameWinner)
    }

    func test_gameWinner_gameOver_isLowestScoringSeat() {
        let game = makeTestGame()

        game.totalScores[.south] = 105
        game.totalScores[.west] = 100
        game.totalScores[.north] = 110
        game.totalScores[.east] = 95  // Lowest score - winner!

        let winner = game.gameWinner

        XCTAssertEqual(winner, .east)
    }

    func test_isGameTied_gameNotOver_isFalse() {
        let game = makeTestGame()

        game.totalScores[.south] = 40
        game.totalScores[.west] = 40

        XCTAssertFalse(game.isGameTied)
    }

    func test_isGameTied_clearWinner_isFalse() {
        let game = makeTestGame()

        game.totalScores[.south] = 105
        game.totalScores[.west] = 100
        game.totalScores[.north] = 110
        game.totalScores[.east] = 95  // Unique lowest — clear winner

        XCTAssertFalse(game.isGameTied)
    }

    func test_isGameTied_higherScoresTiedWithClearWinner_isFalse() {
        let game = makeTestGame()

        // Players 1 and 2 are tied at 100, but player 3 has a uniquely lower score
        game.totalScores[.south] = 100
        game.totalScores[.west] = 100
        game.totalScores[.north] = 110
        game.totalScores[.east] = 60  // Clear winner

        XCTAssertFalse(game.isGameTied)
        XCTAssertEqual(game.gameWinner, .east)
    }

    func test_isGameTied_twoSeatsShareMinimum_isTrue() {
        let game = makeTestGame()

        game.totalScores[.south] = 100  // Threshold crossed
        game.totalScores[.west] = 50   // Tied minimum
        game.totalScores[.north] = 80
        game.totalScores[.east] = 50   // Tied minimum

        XCTAssertTrue(game.isGameTied)
        XCTAssertNil(game.gameWinner)
    }

    func test_isGameTied_allSeatsShareMinimum_isTrue() {
        let game = makeTestGame()

        game.totalScores[.south] = 100  // Threshold crossed
        game.totalScores[.west] = 100
        game.totalScores[.north] = 100
        game.totalScores[.east] = 100

        XCTAssertTrue(game.isGameTied)
        XCTAssertNil(game.gameWinner)
    }

    func test_multi_round_flow() throws {
        let game = makeTestGame()

        // Play first round and accumulate scores
        simulateCapturedHearts([4, 3, 0, 6], in: game)

        // End first hand
        try game.endHand()

        XCTAssertEqual(game.roundNumber, 1)
        XCTAssertEqual(game.totalScores[.south], 4)
        XCTAssertEqual(game.totalScores[.east], 6)
        XCTAssertEqual(game.roundScores[.south], 0)

        // Start second hand
        try game.startNewHand()

        XCTAssertEqual(game.hands[.south].count, 13)
        XCTAssertEqual(game.completedTricks.count, 0)
        XCTAssertFalse(game.heartsBroken)

        // Verify game continues
        XCTAssertFalse(game.isGameOver)
    }

    // MARK: - Jack of Diamonds Bonus Tests

    func test_jackOfDiamonds_standardConfig_appliesNoBonus() throws {
        let game = Game.fourHumans(configuration: .standard)

        // Set up first trick with Jack of Diamonds
        game.hands[.south] = [Card.twoOfClubs]
        game.hands[.west] = [Card.threeOfClubs]
        game.hands[.north] = [Card.fourOfClubs]
        game.hands[.east] = [Card.jackOfDiamonds, Card.aceOfClubs]  // Will win

        game.currentSeat = .south
        game.phase = .awaitingPlay(.south)

        try game.playCard(Card.twoOfClubs, by: .south)
        try game.playCard(Card.threeOfClubs, by: .west)
        try game.playCard(Card.fourOfClubs, by: .north)
        try game.playCard(Card.aceOfClubs, by: .east)

        // Player 3 won but no bonus applied
        XCTAssertEqual(game.roundScores[.east], 0, "Jack of Diamonds should not apply bonus in standard config")
    }

    func test_jackOfDiamonds_jackBonusConfig_subtractsTen() throws {
        let game = Game.fourHumans(configuration: .withJackBonus)

        // Set up trick where player wins Jack of Diamonds
        game.hands[.south] = [Card.kingOfDiamonds]
        game.hands[.west] = [Card.jackOfDiamonds]  // J♦
        game.hands[.north] = [Card.threeOfDiamonds]
        game.hands[.east] = [Card.aceOfDiamonds]  // Will win

        // Can't use 2♣ for first trick here, so manually set up state
        game.completedTricks = [Trick()]
        game.currentSeat = .south
        game.phase = .awaitingPlay(.south)

        try game.playCard(Card.kingOfDiamonds, by: .south)
        try game.playCard(Card.jackOfDiamonds, by: .west)
        try game.playCard(Card.threeOfDiamonds, by: .north)
        try game.playCard(Card.aceOfDiamonds, by: .east)

        // Player 3 won and should get -10 points
        XCTAssertEqual(game.roundScores[.east], -10, "Jack of Diamonds should apply -10 bonus")
    }

    func test_jackOfDiamonds_heartsInSameTrick_netsBonusAgainstPenalties() throws {
        let game = Game.fourHumans(configuration: .withJackBonus)

        // Set up trick with hearts and J♦
        game.hands[.south] = [Card.kingOfDiamonds]
        game.hands[.west] = [Card.jackOfDiamonds]  // J♦
        game.hands[.north] = [Card.threeOfHearts]   // 1 point
        game.hands[.east] = [Card.aceOfDiamonds]   // Will win

        game.completedTricks = [Trick()]
        game.currentSeat = .south
        game.phase = .awaitingPlay(.south)
        game.heartsBroken = true  // Allow hearts to be played

        try game.playCard(Card.kingOfDiamonds, by: .south)
        try game.playCard(Card.jackOfDiamonds, by: .west)
        try game.playCard(Card.threeOfHearts, by: .north)
        try game.playCard(Card.aceOfDiamonds, by: .east)

        // Player 3 should get 1 (heart) - 10 (J♦) = -9 points
        XCTAssertEqual(game.roundScores[.east], -9)
    }

    func test_isGameOver_customWinningScore_endsAtConfiguredScore() {
        let customConfig = GameConfiguration(jackOfDiamondsBonus: false, winningScore: 50)
        let game = Game.fourHumans(configuration: customConfig)

        XCTAssertEqual(game.winningScore, 50)

        game.totalScores[.south] = 50
        XCTAssertTrue(game.isGameOver)
    }

    func test_jackOfDiamonds_bonusWithoutPenalties_givesNegativeRoundScore() throws {
        let game = Game.fourHumans(configuration: .withJackBonus)

        // Player takes only J♦, no other point cards
        game.completedTricks = [Trick()]
        game.hands[.south] = [Card.twoOfDiamonds]
        game.hands[.west] = [Card.jackOfDiamonds]
        game.hands[.north] = [Card.threeOfDiamonds]
        game.hands[.east] = [Card.aceOfDiamonds]  // Wins

        game.currentSeat = .south
        game.phase = .awaitingPlay(.south)

        try game.playCard(Card.twoOfDiamonds, by: .south)
        try game.playCard(Card.jackOfDiamonds, by: .west)
        try game.playCard(Card.threeOfDiamonds, by: .north)
        try game.playCard(Card.aceOfDiamonds, by: .east)

        XCTAssertEqual(game.roundScores[.east], -10)
    }

    func test_shootTheMoon_jackBonusConfig_shooterGetsMinusTen() throws {
        let game = Game.fourHumans(configuration: .withJackBonus)

        // Player 0 shoots the moon and also captures J♦
        simulateMoonShot(by: .south, in: game, includeJackOfDiamonds: true)

        try game.endHand()

        // Moon shooter gets -10, others get 26
        XCTAssertEqual(game.totalScores[.south], -10, "Moon shooter with J♦ bonus gets -10")
        XCTAssertEqual(game.totalScores[.west], 26)
        XCTAssertEqual(game.totalScores[.north], 26)
        XCTAssertEqual(game.totalScores[.east], 26)
    }

    // MARK: - Shooting the Moon Tests

    func test_shootTheMoon_standardConfig_shooterGetsZero() throws {
        let game = makeTestGame()

        // Player 2 shoots the moon (no J♦ bonus in standard config)
        simulateMoonShot(by: .north, in: game, includeJackOfDiamonds: false)

        try game.endHand()

        // Moon shooter gets 0 points
        XCTAssertEqual(game.totalScores[.north], 0)
    }

    func test_shootTheMoon_standardConfig_othersGet26() throws {
        let game = makeTestGame()

        // Player 2 shoots the moon
        simulateMoonShot(by: .north, in: game, includeJackOfDiamonds: false)

        try game.endHand()

        // All other players get 26 points
        XCTAssertEqual(game.totalScores[.south], 26)
        XCTAssertEqual(game.totalScores[.west], 26)
        XCTAssertEqual(game.totalScores[.east], 26)
    }

    func test_shootTheMoon_afterEndHand_resetsRoundScores() throws {
        let game = makeTestGame()

        // Player 1 shoots the moon
        simulateMoonShot(by: .west, in: game, includeJackOfDiamonds: false)

        try game.endHand()

        // All round scores should be reset to 0
        XCTAssertEqual(game.roundScores[.south], 0)
        XCTAssertEqual(game.roundScores[.west], 0)
        XCTAssertEqual(game.roundScores[.north], 0)
        XCTAssertEqual(game.roundScores[.east], 0)
    }

    func test_shootTheMoon_existingTotals_addsToTotals() throws {
        let game = makeTestGame()

        // Set up existing total scores
        game.totalScores[.south] = 10
        game.totalScores[.west] = 5
        game.totalScores[.north] = 8
        game.totalScores[.east] = 12

        // Player 3 shoots the moon
        simulateMoonShot(by: .east, in: game, includeJackOfDiamonds: false)

        try game.endHand()

        // Moon shooter's total unchanged, others get +26
        XCTAssertEqual(game.totalScores[.south], 36)  // 10 + 26
        XCTAssertEqual(game.totalScores[.west], 31)  // 5 + 26
        XCTAssertEqual(game.totalScores[.north], 34)  // 8 + 26
        XCTAssertEqual(game.totalScores[.east], 12)  // 12 + 0 (moon shooter)
    }

    func test_shootTheMoon_missingAHeart_doesNotTrigger() throws {
        let game = makeTestGame()

        // Player 0 has Q♠ and only 3 hearts (missing 10)
        var heartTrick = Trick()
        try! heartTrick.play(Card.twoOfHearts, by: .west)
        try! heartTrick.play(Card.threeOfHearts, by: .north)
        try! heartTrick.play(Card.twoOfClubs, by: .east)
        try! heartTrick.play(Card.aceOfHearts, by: .south)  // Wins

        var queenTrick = Trick()
        try! queenTrick.play(Card.twoOfSpades, by: .west)
        try! queenTrick.play(Card.queenOfSpades, by: .north)
        try! queenTrick.play(Card.fourOfClubs, by: .east)
        try! queenTrick.play(Card.aceOfSpades, by: .south)  // Wins

        game.completedTricks = [heartTrick, queenTrick]
        game.roundScores[.south] = 16  // 3 hearts + Q♠ = 16, but missing 10 hearts

        game.phase = .awaitingSettlement
        try game.endHand()

        // Normal scoring applies (no moon shot)
        XCTAssertEqual(game.totalScores[.south], 16)
        XCTAssertEqual(game.totalScores[.west], 0)
        XCTAssertEqual(game.totalScores[.north], 0)
        XCTAssertEqual(game.totalScores[.east], 0)
    }

    // MARK: - Hearts Broken Tests

    func test_playCard_queenOfSpades_doesNotBreakHearts() {
        let game = makeTestGame()

        // Hearts are not broken at start
        XCTAssertFalse(game.heartsBroken)

        // Set up a trick: player 0 leads clubs, player 1 is void in clubs and plays Q♠
        // player 1's hand: replace clubs card with Q♠ so they must play off-suit
        game.hands[.south] = [Card.twoOfClubs]
        game.hands[.west] = [Card.queenOfSpades]  // void in clubs, plays Q♠
        game.hands[.north] = [Card.threeOfClubs]
        game.hands[.east] = [Card.fourOfClubs]

        game.currentSeat = .south
        game.phase = .awaitingPlay(.south)

        // Play the trick
        try! game.playCard(Card.twoOfClubs, by: .south)
        try! game.playCard(Card.queenOfSpades, by: .west)
        try! game.playCard(Card.threeOfClubs, by: .north)
        try! game.playCard(Card.fourOfClubs, by: .east)

        // Q♠ must NOT break hearts
        XCTAssertFalse(game.heartsBroken, "Playing Q♠ should not break hearts")
    }

    func test_shootTheMoon_missingQueenOfSpades_doesNotTrigger() throws {
        let game = makeTestGame()

        // Player 1 has all 13 hearts but not Q♠
        // Create 13 heart tricks where player 1 leads a heart and wins it
        for rank in Card.Rank.allCases {
            var trick = Trick()
            try! trick.play(Card(suit: .hearts, rank: rank), by: .west)  // Wins
            try! trick.play(Card.twoOfClubs, by: .north)
            try! trick.play(Card.threeOfClubs, by: .east)
            try! trick.play(Card.fourOfClubs, by: .south)
            game.completedTricks.append(trick)
        }

        // Q♠ goes to someone else (player 2)
        var queenTrick = Trick()
        try! queenTrick.play(Card.twoOfSpades, by: .south)
        try! queenTrick.play(Card.threeOfSpades, by: .west)
        try! queenTrick.play(Card.queenOfSpades, by: .east)
        try! queenTrick.play(Card.aceOfSpades, by: .north)  // Wins Q♠
        game.completedTricks.append(queenTrick)

        game.roundScores[.west] = 13  // All hearts but no Q♠
        game.roundScores[.north] = 13  // Q♠

        game.phase = .awaitingSettlement
        try game.endHand()

        // Normal scoring applies (no moon shot)
        XCTAssertEqual(game.totalScores[.south], 0)
        XCTAssertEqual(game.totalScores[.west], 13)  // Gets their 13 points
        XCTAssertEqual(game.totalScores[.north], 13)  // Gets Q♠
        XCTAssertEqual(game.totalScores[.east], 0)
    }

    // MARK: - Moon-Shot Variant: subtractFromSelf

    func test_shootTheMoon_subtractFromSelf_shooterScoreDecreasesByTwentySix() throws {
        let game = Game.fourHumans(configuration: .withSubtractMoonShot)

        game.totalScores[.south] = 50  // Shooter's existing score

        simulateMoonShot(by: .south, in: game, includeJackOfDiamonds: false)
        try game.endHand()

        XCTAssertEqual(game.totalScores[.south], 24, "Shooter's score should decrease by 26: 50 - 26 = 24")
    }

    func test_shootTheMoon_subtractFromSelf_opponentsScoresAreUnchanged() throws {
        let game = Game.fourHumans(configuration: .withSubtractMoonShot)

        game.totalScores[.west] = 10
        game.totalScores[.north] = 20
        game.totalScores[.east] = 30

        simulateMoonShot(by: .south, in: game, includeJackOfDiamonds: false)
        try game.endHand()

        // Opponents' scores are unchanged (no 26 added)
        XCTAssertEqual(game.totalScores[.west], 10, "Opponent scores should not change")
        XCTAssertEqual(game.totalScores[.north], 20)
        XCTAssertEqual(game.totalScores[.east], 30)
    }

    func test_shootTheMoon_subtractFromSelf_canGoNegative() throws {
        let game = Game.fourHumans(configuration: .withSubtractMoonShot)

        game.totalScores[.south] = 10  // Will go to -16

        simulateMoonShot(by: .south, in: game, includeJackOfDiamonds: false)
        try game.endHand()

        XCTAssertEqual(game.totalScores[.south], -16, "Score can go negative with subtractFromSelf variant")
    }

    func test_shootTheMoon_subtractFromSelf_roundScoresAreReset() throws {
        let game = Game.fourHumans(configuration: .withSubtractMoonShot)

        simulateMoonShot(by: .west, in: game, includeJackOfDiamonds: false)
        try game.endHand()

        XCTAssertEqual(game.roundScores, SeatMap(repeating: 0), "Round scores should be reset to 0 after endHand")
    }
}
