//
//  GameTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
@testable import Hearts

final class GameTests: XCTestCase {
    func test_init_default_seatsFourPlayers() {
        let game = Game()
        XCTAssertEqual(game.players.values.count, 4)
    }
    
    func test_init_namedPlayers_seatsThemInOrder() {
        let game = Game(player1: Player(name: "Joe"),
                        player2: Player(name: "Dan"),
                        player3: Player(name: "Ali"),
                        player4: Player(name: "Tim"))
        XCTAssertEqual(game.players.mapValues(\.name), ["Joe", "Dan", "Ali", "Tim"])
        XCTAssertEqual(game.players[.north].name, "Ali")
    }
    
    func test_init_deal_cards() {
        let game = Game()
        XCTAssertEqual(game.hands.mapValues(\.count), [13, 13, 13, 13])
    }
    

    func test_leader_afterDeal_isTwoOfClubsHolderAndCurrentSeat() {
        let game = Game()
        let leader = game.hands.first { $0.value.contains(Card.twoOfClubs) }?.seat
        XCTAssertNotNil(leader)
        XCTAssertEqual(leader, game.leader)
        XCTAssertEqual(leader, game.currentSeat)
    }
    

    func test_exchangeDirection_byRoundNumber_rotatesLeftRightAcrossNone() {
        let game = Game()
        XCTAssertEqual(game.exchangeDirection, .left)

        game.roundNumber = 1
        XCTAssertEqual(game.exchangeDirection, .right)

        game.roundNumber = 2
        XCTAssertEqual(game.exchangeDirection, .across)

        game.roundNumber = 3
        XCTAssertEqual(game.exchangeDirection, .none)

        game.roundNumber = 4
        XCTAssertEqual(game.exchangeDirection, .left)

        // Full wraparound: round 4 should behave identically to round 0
        game.roundNumber = 8
        XCTAssertEqual(game.exchangeDirection, .left, "Round 8 should wrap back to .left")
        game.roundNumber = 5
        XCTAssertEqual(game.exchangeDirection, .right, "Round 5 should wrap to .right")
        game.roundNumber = 6
        XCTAssertEqual(game.exchangeDirection, .across, "Round 6 should wrap to .across")
        game.roundNumber = 7
        XCTAssertEqual(game.exchangeDirection, .none, "Round 7 should wrap to .none")
    }
    
    func test_performExchange_allBots_movesThreeCardsToRecipient() throws {
        let game = Game()
        
        // Cards before exchange
        let player1CardsBE = game.hands[.south]
        let player2CardsBE = game.hands[.west]
        let player3CardsBE = game.hands[.north]
        let player4CardsBE = game.hands[.east]

        try game.performExchange()
        
        // Cards after exchange
        let player1CardsAE = game.hands[.south]
        let player2CardsAE = game.hands[.west]
        let player3CardsAE = game.hands[.north]
        let player4CardsAE = game.hands[.east]
        
        let playerHandCount = 13
        let passedCardCount = 3

        // Player 1 (index 0): passed cards should be gone from hand, received by Player 2 (index 1)
        XCTAssertEqual(player1CardsAE.count, playerHandCount)
        let passedCards = player1CardsBE.filter { !player1CardsAE.contains($0) }
        XCTAssertEqual(passedCards.count, passedCardCount, "Player 0 should have passed exactly 3 cards")
        XCTAssertTrue(passedCards.allSatisfy { !player1CardsAE.contains($0) }, "Player 0's passed cards should no longer be in Player 0's hand")
        XCTAssertTrue(passedCards.allSatisfy { player2CardsAE.contains($0) }, "Player 0's passed cards should appear in Player 1's hand (pass-left)")

        // Player 2 (index 1): passed cards should be gone from hand, received by Player 3 (index 2)
        XCTAssertEqual(player2CardsAE.count, playerHandCount)
        let passedCards2 = player2CardsBE.filter { !player2CardsAE.contains($0) }
        XCTAssertEqual(passedCards2.count, passedCardCount, "Player 1 should have passed exactly 3 cards")
        XCTAssertTrue(passedCards2.allSatisfy { !player2CardsAE.contains($0) }, "Player 1's passed cards should no longer be in Player 1's hand")
        XCTAssertTrue(passedCards2.allSatisfy { player3CardsAE.contains($0) }, "Player 1's passed cards should appear in Player 2's hand (pass-left)")

        // Player 3 (index 2): passed cards should be gone from hand, received by Player 4 (index 3)
        XCTAssertEqual(player3CardsAE.count, playerHandCount)
        let passedCards3 = player3CardsBE.filter { !player3CardsAE.contains($0) }
        XCTAssertEqual(passedCards3.count, passedCardCount, "Player 2 should have passed exactly 3 cards")
        XCTAssertTrue(passedCards3.allSatisfy { !player3CardsAE.contains($0) }, "Player 2's passed cards should no longer be in Player 2's hand")
        XCTAssertTrue(passedCards3.allSatisfy { player4CardsAE.contains($0) }, "Player 2's passed cards should appear in Player 3's hand (pass-left)")

        // Player 4 (index 3): passed cards should be gone from hand, received by Player 1 (index 0)
        XCTAssertEqual(player4CardsAE.count, playerHandCount)
        let passedCards4 = player4CardsBE.filter { !player4CardsAE.contains($0) }
        XCTAssertEqual(passedCards4.count, passedCardCount, "Player 3 should have passed exactly 3 cards")
        XCTAssertTrue(passedCards4.allSatisfy { !player4CardsAE.contains($0) }, "Player 3's passed cards should no longer be in Player 3's hand")
        XCTAssertTrue(passedCards4.allSatisfy { player1CardsAE.contains($0) }, "Player 3's passed cards should appear in Player 0's hand (pass-left)")
    }

    // MARK: - AI Integration Tests

    func test_selectCardsForBotExchange_botSeat_returnsThreeCardsFromHand() throws {
        let game = Game()  // All seats are bots in default init
        let hand = game.hands[.south]

        let selectedCards = try XCTUnwrap(game.selectCardsForBotExchange(seat: .south))

        // Should return 3 cards from the bot's hand
        XCTAssertTrue(hand.contains(selectedCards.0))
        XCTAssertTrue(hand.contains(selectedCards.1))
        XCTAssertTrue(hand.contains(selectedCards.2))

        // Should be unique cards
        XCTAssertNotEqual(selectedCards.0, selectedCards.1)
        XCTAssertNotEqual(selectedCards.0, selectedCards.2)
        XCTAssertNotEqual(selectedCards.1, selectedCards.2)
    }

    func test_selectCardForBotPlay_botSeat_returnsLegalCard() throws {
        let game = Game()
        let seat = game.currentSeat

        let selectedCard = try XCTUnwrap(game.selectCardForBotPlay(seat: seat))

        // Should return a card from the bot's hand
        XCTAssertTrue(game.hands[seat].contains(selectedCard))

        // Should be a legal move (2 of clubs on first play)
        if game.completedTricks.isEmpty && game.currentTrick.cards.isEmpty {
            XCTAssertEqual(selectedCard.suit, .clubs)
            XCTAssertEqual(selectedCard.rank, .two)
        }
    }

    func test_selectCardForBotPlay_holdingLeadSuit_followsSuit() throws {
        let botPlayer1 = Player.bot("Bot1", difficulty: .medium)
        let botPlayer2 = Player.bot("Bot2", difficulty: .medium)
        let botPlayer3 = Player.bot("Bot3", difficulty: .medium)
        let botPlayer4 = Player.bot("Bot4", difficulty: .medium)

        let game = Game(player1: botPlayer1, player2: botPlayer2, player3: botPlayer3, player4: botPlayer4)
        try game.performExchange()

        // Play first card (2 of clubs)
        let firstCard = try XCTUnwrap(game.selectCardForBotPlay(seat: game.currentSeat))
        try! game.playCard(firstCard, by: game.currentSeat)

        // Next seat must follow suit if possible
        let secondSeat = game.currentSeat
        let secondCard = try XCTUnwrap(game.selectCardForBotPlay(seat: secondSeat))

        // If the seat has clubs, it must play a club
        let hasClubs = game.hands[secondSeat].contains(where: { $0.suit == .clubs })
        if hasClubs {
            XCTAssertEqual(secondCard.suit, .clubs, "Bot should follow suit when possible")
        }
    }
}

// MARK: - Configured Trick Points

final class GameTrickPointsTests: XCTestCase {
    private func makeGame(jackBonus: Bool) -> Game {
        Game(player1: Player(name: "A"),
             player2: Player(name: "B"),
             player3: Player(name: "C"),
             player4: Player(name: "D"),
             configuration: GameConfiguration(jackOfDiamondsBonus: jackBonus))
    }

    func test_points_jackBonusOnWithJackOfDiamonds_returnsMinus10() throws {
        let game = makeGame(jackBonus: true)
        let trick = try Trick.mock([
            Card.twoOfDiamonds,
            Card.jackOfDiamonds,
            Card.fiveOfDiamonds,
            Card.nineOfDiamonds
        ])

        XCTAssertEqual(game.points(in: trick), -10)
    }

    func test_points_jackBonusOnWithJackAndHearts_sumsBonusAndPenalties() throws {
        let game = makeGame(jackBonus: true)
        let trick = try Trick.mock([
            Card.jackOfDiamonds,
            Card.threeOfHearts,
            Card.kingOfHearts,
            Card.queenOfSpades
        ])

        XCTAssertEqual(game.points(in: trick), 5)
    }

    func test_points_jackBonusOffWithJackOfDiamonds_returnsRawPoints() throws {
        let game = makeGame(jackBonus: false)
        let trick = try Trick.mock([
            Card.jackOfDiamonds,
            Card.threeOfHearts,
            Card.fiveOfDiamonds,
            Card.nineOfDiamonds
        ])

        XCTAssertEqual(game.points(in: trick), 1)
        XCTAssertEqual(game.points(in: trick), trick.points)
    }

    func test_points_partialTrick_countsCardsPlayedSoFar() throws {
        let game = makeGame(jackBonus: true)
        var trick = Trick()
        try trick.play(Card.jackOfDiamonds, by: .south)

        XCTAssertEqual(game.points(in: trick), -10)
    }

    func test_points_fullHand_matchesPointsDeliveredToDelegate() throws {
        let bots = (1...4).map { Player(name: "Bot\($0)", type: .bot(difficulty: .easy)) }
        let game = Game(player1: bots[0], player2: bots[1], player3: bots[2], player4: bots[3],
                        configuration: GameConfiguration(jackOfDiamondsBonus: true))
        let spy = DelegateSpy()
        game.delegate = spy
        try game.performExchange()
        try game.playCompleteHand()

        XCTAssertEqual(spy.completedTricks.map(\.points).count, 13)
        XCTAssertEqual(spy.completedTricks.map(\.points), game.completedTricks.map { game.points(in: $0) })
        XCTAssertTrue(game.completedTricks.contains { $0.cards.contains(Card.jackOfDiamonds) })
    }
}

// MARK: - Public error surface

final class GamePlayCardErrorSurfaceTests: XCTestCase {
    /// Every error that leaves `Game.playCard` must be a `GameError`, so library
    /// consumers can catch it by name. Before each legal play in a full bot hand,
    /// this attempts every card held by every player (including cards not in the
    /// current player's hand, out-of-turn plays, and rule violations) and fails
    /// if any throw is not a `GameError`.
    func test_playCard_anyInvalidAttempt_throwsOnlyGameError() throws {
        let game = Game()
        try game.performExchange()

        var invalidAttempts = 0
        while !game.isHandComplete {
            for (seat, hand) in game.hands {
                for card in hand {
                    let legal = game.legalMoves(for: seat).contains(card)
                    if legal { continue }
                    do {
                        try game.playCard(card, by: seat)
                        XCTFail("Illegal play \(card) by \(seat) was accepted")
                    } catch let error as GameError {
                        invalidAttempts += 1
                        _ = error
                    } catch {
                        XCTFail("Non-GameError escaped playCard: \(error)")
                    }
                }
            }
            let current = game.currentSeat
            guard let move = game.legalMoves(for: current).first else {
                return XCTFail("No legal move for \(current)")
            }
            try game.playCard(move, by: current)
        }

        XCTAssertGreaterThan(invalidAttempts, 0)
        XCTAssertThrowsError(try game.playCard(Card.twoOfClubs, by: game.currentSeat)) { error in
            XCTAssertEqual(error as? GameError, .wrongPhase(.awaitingSettlement))
        }
    }
}

// MARK: - Hand settlement

final class GameEndHandTests: XCTestCase {
    /// Two tricks: seat 2 wins the first (2♣ 3♣ 5♣ 7♥), then seat 0 wins the second (6♣ 8♥ A♣ 4♣).
    /// Seats 0 and 2 each capture one heart.
    private func makeTwoTrickGame(configuration: GameConfiguration = .standard) throws -> Game {
        let players = (0..<4).map { Player(name: "P\($0)") }
        let game = try Game(player1: players[0], player2: players[1], player3: players[2], player4: players[3], hands: [
            [Card.twoOfClubs, Card.aceOfClubs],
            [Card.threeOfClubs, Card.fourOfClubs],
            [Card.fiveOfClubs, Card.sixOfClubs],
            [Card.sevenOfHearts, Card.eightOfHearts]
        ], configuration: configuration)
        game.phase = .awaitingPlay(.south)
        try game.play([.twoOfClubs, .threeOfClubs, .fiveOfClubs, .sevenOfHearts,
                       .sixOfClubs, .eightOfHearts, .aceOfClubs, .fourOfClubs])
        return game
    }

    func test_endHand_twoTricks_returnsRoundScoresFromTricksAndNewTotals() throws {
        let game = try makeTwoTrickGame()
        game.totalScores[.north] = 40

        let result = try game.endHand()

        XCTAssertEqual(result.roundScores, [1, 0, 1, 0])
        XCTAssertEqual(result.totalScores, [1, 0, 41, 0])
        XCTAssertNil(result.moonShooter)
        XCTAssertEqual(game.totalScores, [1, 0, 41, 0])
        XCTAssertEqual(game.roundScores, [0, 0, 0, 0])
    }

    func test_endHand_withDelegate_deliversSameResult() throws {
        let game = try makeTwoTrickGame()
        let spy = DelegateSpy()
        game.delegate = spy

        let result = try game.endHand()

        XCTAssertEqual(spy.handResults, [result])
    }

    func test_endHand_jackBonusConfiguration_usesConfiguredScoring() throws {
        let game = try makeTwoTrickGame(configuration: .withJackBonus)

        XCTAssertEqual(try game.endHand(), game.scoring.settleHand(
            capturedCards: [
                [Card.sixOfClubs, Card.eightOfHearts,
                 Card.aceOfClubs, Card.fourOfClubs],
                [],
                [Card.twoOfClubs, Card.threeOfClubs,
                 Card.fiveOfClubs, Card.sevenOfHearts],
                []
            ],
            totalScores: [0, 0, 0, 0]))
    }
}
