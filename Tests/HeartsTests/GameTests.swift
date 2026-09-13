//
//  GameTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
@testable import Hearts

final class GameTests: XCTestCase {
    func test_init_game_has_4_players() {
        let game = Game()
        XCTAssertEqual(game.players.values.count, 4)
    }
    
    func test_init_game_seats_players_in_order() {
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
    
    func test_init_each_seat_has_3_opponents() {
        // Each seat should have 3 opponents (left, right, across)
        for seat in Seat.allCases {
            XCTAssertNotNil(CardExchangeDirection.left.recipient(of: seat))
            XCTAssertNotNil(CardExchangeDirection.right.recipient(of: seat))
            XCTAssertNotNil(CardExchangeDirection.across.recipient(of: seat))
        }
    }
    
    func test_leader_after_first_hand_is_dealt() {
        let game = Game()
        let leader = game.hands.first { $0.value.contains(Card(suit: .clubs, rank: .two)) }?.seat
        XCTAssertNotNil(leader)
        XCTAssertEqual(leader, game.leader)
        XCTAssertEqual(leader, game.currentSeat)
    }
    
    func test_seats_direction() {
        XCTAssertEqual(CardExchangeDirection.right.recipient(of: .south), .east, "South's right opponent should be east.")
        XCTAssertEqual(CardExchangeDirection.left.recipient(of: .east), .south, "East's left opponent should be south.")

        guard let left = CardExchangeDirection.left.recipient(of: .south),
              let leftOfLeft = CardExchangeDirection.left.recipient(of: left),
              let across = CardExchangeDirection.across.recipient(of: .south) else {
            XCTFail("Failed to get left opponent of south or seat across from south.")
            return
        }
        XCTAssertEqual(leftOfLeft, across, "The left of left of south should be the seat across from south.")

        guard let right = CardExchangeDirection.right.recipient(of: .south),
              let rightOfRight = CardExchangeDirection.right.recipient(of: right) else {
            XCTFail("Failed to get right opponent of south.")
            return
        }

        XCTAssertEqual(rightOfRight, across, "The right of right of south should be the seat across from south.")

        let acrossOfRight = CardExchangeDirection.across.recipient(of: right)
        XCTAssertEqual(acrossOfRight, left, "The seat across from south's right opponent should be south's left opponent.")
    }

    func test_exchange_cards_direction() {
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
    
    func test_exchange_cards() throws {
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

    func test_selectCardsForBotExchange_returns_3_cards_from_hand() throws {
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

    func test_selectCardForBotPlay_returns_legal_card() throws {
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

    func test_selectCardForBotPlay_respects_follow_suit_rule() throws {
        let botPlayer1 = Player(name: "Bot1", type: .bot(difficulty: .medium))
        let botPlayer2 = Player(name: "Bot2", type: .bot(difficulty: .medium))
        let botPlayer3 = Player(name: "Bot3", type: .bot(difficulty: .medium))
        let botPlayer4 = Player(name: "Bot4", type: .bot(difficulty: .medium))

        let game = Game(player1: botPlayer1, player2: botPlayer2, player3: botPlayer3, player4: botPlayer4)

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

    /// Builds a complete trick from four cards played from south clockwise.
    private func makeTrick(_ cards: [Card], in game: Game) throws -> Trick {
        var trick = Trick()
        for (seat, card) in zip(Seat.allCases, cards) {
            try trick.play(card, by: seat)
        }
        return trick
    }

    func test_points_withJackBonusOn_trickContainingJackOfDiamonds_returnsMinus10() throws {
        let game = makeGame(jackBonus: true)
        let trick = try makeTrick([
            Card(suit: .diamonds, rank: .two),
            Card(suit: .diamonds, rank: .jack),
            Card(suit: .diamonds, rank: .five),
            Card(suit: .diamonds, rank: .nine)
        ], in: game)

        XCTAssertEqual(game.points(in: trick), -10)
    }

    func test_points_withJackBonusOn_jackAndHearts_sumsBonusAndPenalties() throws {
        let game = makeGame(jackBonus: true)
        let trick = try makeTrick([
            Card(suit: .diamonds, rank: .jack),
            Card(suit: .hearts, rank: .three),
            Card(suit: .hearts, rank: .king),
            Card(suit: .spades, rank: .queen)
        ], in: game)

        XCTAssertEqual(game.points(in: trick), 5)
    }

    func test_points_withJackBonusOff_trickContainingJackOfDiamonds_returnsRawPoints() throws {
        let game = makeGame(jackBonus: false)
        let trick = try makeTrick([
            Card(suit: .diamonds, rank: .jack),
            Card(suit: .hearts, rank: .three),
            Card(suit: .diamonds, rank: .five),
            Card(suit: .diamonds, rank: .nine)
        ], in: game)

        XCTAssertEqual(game.points(in: trick), 1)
        XCTAssertEqual(game.points(in: trick), trick.points)
    }

    func test_points_partialTrick_countsCardsPlayedSoFar() throws {
        let game = makeGame(jackBonus: true)
        var trick = Trick()
        try trick.play(Card(suit: .diamonds, rank: .jack), by: .south)

        XCTAssertEqual(game.points(in: trick), -10)
    }

    func test_points_matchesPointsDeliveredToDelegate() throws {
        final class Spy: GameEngineDelegate {
            var delivered: [Int] = []
            func game(_ game: Game, didCompleteTrick trick: Trick, winner: Seat, points: Int) {
                delivered.append(points)
            }
        }
        let bots = (1...4).map { Player(name: "Bot\($0)", type: .bot(difficulty: .easy)) }
        let game = Game(player1: bots[0], player2: bots[1], player3: bots[2], player4: bots[3],
                        configuration: GameConfiguration(jackOfDiamondsBonus: true))
        let spy = Spy()
        game.delegate = spy
        try game.performExchange()
        try game.playCompleteHand()

        XCTAssertEqual(spy.delivered.count, 13)
        XCTAssertEqual(spy.delivered, game.completedTricks.map { game.points(in: $0) })
        XCTAssertTrue(game.completedTricks.contains { $0.cards.contains(Card(suit: .diamonds, rank: .jack)) })
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
        game.startNewHand()
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
        XCTAssertThrowsError(try game.playCard(Card(suit: .clubs, rank: .two), by: game.currentSeat)) { error in
            XCTAssertEqual(error as? GameError, .handComplete)
        }
    }
}

// MARK: - Hand settlement

final class GameEndHandTests: XCTestCase {
    private final class Spy: GameEngineDelegate {
        var results: [HandResult] = []
        func game(_ game: Game, didEndHand result: HandResult) {
            results.append(result)
        }
    }

    /// Two tricks: seat 2 wins the first (2♣ 3♣ 5♣ 7♥), then seat 0 wins the second (6♣ 8♥ A♣ 4♣).
    /// Seats 0 and 2 each capture one heart.
    private func makeTwoTrickGame(configuration: GameConfiguration = .standard) throws -> Game {
        let players = (0..<4).map { Player(name: "P\($0)") }
        let game = try Game(player1: players[0], player2: players[1], player3: players[2], player4: players[3], hands: [
            [Card(suit: .clubs, rank: .two), Card(suit: .clubs, rank: .ace)],
            [Card(suit: .clubs, rank: .three), Card(suit: .clubs, rank: .four)],
            [Card(suit: .clubs, rank: .five), Card(suit: .clubs, rank: .six)],
            [Card(suit: .hearts, rank: .seven), Card(suit: .hearts, rank: .eight)]
        ], configuration: configuration)
        try game.playCard(Card(suit: .clubs, rank: .two), by: .south)
        try game.playCard(Card(suit: .clubs, rank: .three), by: .west)
        try game.playCard(Card(suit: .clubs, rank: .five), by: .north)
        try game.playCard(Card(suit: .hearts, rank: .seven), by: .east)
        try game.playCard(Card(suit: .clubs, rank: .six), by: .north)
        try game.playCard(Card(suit: .hearts, rank: .eight), by: .east)
        try game.playCard(Card(suit: .clubs, rank: .ace), by: .south)
        try game.playCard(Card(suit: .clubs, rank: .four), by: .west)
        return game
    }

    func test_endHand_returnsRoundScoresDerivedFromTricksAndNewTotals() throws {
        let game = try makeTwoTrickGame()
        game.totalScores[.north] = 40

        let result = game.endHand()

        XCTAssertEqual(result.roundScores, [1, 0, 1, 0])
        XCTAssertEqual(result.totalScores, [1, 0, 41, 0])
        XCTAssertNil(result.moonShooter)
        XCTAssertEqual(game.totalScores, [1, 0, 41, 0])
        XCTAssertEqual(game.roundScores, [0, 0, 0, 0])
    }

    func test_endHand_deliversSameResultToDelegate() throws {
        let game = try makeTwoTrickGame()
        let spy = Spy()
        game.delegate = spy

        let result = game.endHand()

        XCTAssertEqual(spy.results, [result])
    }

    func test_endHand_usesConfiguredScoring() throws {
        let game = try makeTwoTrickGame(configuration: .withJackBonus)

        XCTAssertEqual(game.endHand(), game.scoring.settleHand(
            capturedCards: [
                [Card(suit: .clubs, rank: .six), Card(suit: .hearts, rank: .eight),
                 Card(suit: .clubs, rank: .ace), Card(suit: .clubs, rank: .four)],
                [],
                [Card(suit: .clubs, rank: .two), Card(suit: .clubs, rank: .three),
                 Card(suit: .clubs, rank: .five), Card(suit: .hearts, rank: .seven)],
                []
            ],
            totalScores: [0, 0, 0, 0]))
    }
}
