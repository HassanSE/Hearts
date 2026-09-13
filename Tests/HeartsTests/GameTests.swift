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
        XCTAssertEqual(game.players.count, 4)
    }
    
    func test_init_game_pass_4_players() {
        let game = Game(player1: Player(name: "Joe"),
                        player2: Player(name: "Dan"),
                        player3: Player(name: "Ali"),
                        player4: Player(name: "Tim"))
        XCTAssertEqual(game.players.count, 4)
    }
    
    func test_init_deal_cards() {
        let game = Game()
        XCTAssertEqual(game.players[0].hand.count, 13)
        XCTAssertEqual(game.players[1].hand.count, 13)
        XCTAssertEqual(game.players[2].hand.count, 13)
        XCTAssertEqual(game.players[3].hand.count, 13)
    }
    
    func test_init_each_player_has_3_opponents() {
        let game = Game()
        let players = game.players

        // Each player should have 3 opponents (left, right, across)
        for player in players {
            XCTAssertNotNil(game.getOpponent(player, direction: .left))
            XCTAssertNotNil(game.getOpponent(player, direction: .right))
            XCTAssertNotNil(game.getOpponent(player, direction: .across))
        }
    }
    
    func test_leader_after_first_hand_is_dealt() {
        let game = Game()
        let leader = game.players.filter { $0.hand.contains(where: { $0.suit == .clubs && $0.rank == .two }) }.first
        XCTAssertEqual(leader, game.leader)
    }
    
    func test_players_direction() {
        let game = Game()
        let players = game.players

        let player1 = players[0]
        XCTAssertEqual(game.getOpponent(player1, direction: .right), players[3], "Player 1's right opponent should be Player 4.")
        XCTAssertEqual(game.getOpponent(players[3], direction: .left), players[0], "Player 4's left opponent should be Player 1.")

        guard let left = game.getOpponent(player1, direction: .left),
              let leftOfLeft = game.getOpponent(left, direction: .left),
              let player1Across = game.getOpponent(player1, direction: .across) else {
            XCTFail("Failed to get left opponent of Player 1 or player across from Player 1.")
            return
        }
        XCTAssertEqual(leftOfLeft, player1Across, "The left of left opponent of Player 1 should be the player across from Player 1.")

        guard let right = game.getOpponent(player1, direction: .right),
              let rightOfRight = game.getOpponent(right, direction: .right),
              let player1Across = game.getOpponent(player1, direction: .across) else {
            XCTFail("Failed to get right opponent of Player 1 or player across from Player 1.")
            return
        }

        XCTAssertEqual(rightOfRight, player1Across, "The right of right opponent of Player 1 should be the player across from Player 1.")

        let acrossOfRight = game.getOpponent(right, direction: .across)
        XCTAssertEqual(acrossOfRight, left, "The across opponent of right opponent of Player 1 should be the left opponent of Player 1.")
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
    
    func test_exchange_cards() {
        let game = Game()
        
        // Cards before exchange
        let player1CardsBE = game.players[0].hand
        let player2CardsBE = game.players[1].hand
        let player3CardsBE = game.players[2].hand
        let player4CardsBE = game.players[3].hand

        game.performExchange()
        
        // Cards after exchange
        let player1CardsAE = game.players[0].hand
        let player2CardsAE = game.players[1].hand
        let player3CardsAE = game.players[2].hand
        let player4CardsAE = game.players[3].hand
        
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

    func test_selectCardsForBotExchange_returns_3_cards_from_hand() {
        let game = Game()
        let botPlayer = game.players[0]  // All players are bots in default init

        let selectedCards = game.selectCardsForBotExchange(player: botPlayer)

        // Should return 3 cards from the bot's hand
        XCTAssertTrue(botPlayer.hand.contains(selectedCards.0))
        XCTAssertTrue(botPlayer.hand.contains(selectedCards.1))
        XCTAssertTrue(botPlayer.hand.contains(selectedCards.2))

        // Should be unique cards
        XCTAssertNotEqual(selectedCards.0, selectedCards.1)
        XCTAssertNotEqual(selectedCards.0, selectedCards.2)
        XCTAssertNotEqual(selectedCards.1, selectedCards.2)
    }

    func test_selectCardForBotPlay_returns_legal_card() {
        let game = Game()
        let botPlayer = game.players[game.currentPlayerIndex]

        let selectedCard = game.selectCardForBotPlay(player: botPlayer)

        // Should return a card from the bot's hand
        XCTAssertTrue(botPlayer.hand.contains(selectedCard))

        // Should be a legal move (2 of clubs on first play)
        if game.completedTricks.isEmpty && game.currentTrick.cards.isEmpty {
            XCTAssertEqual(selectedCard.suit, .clubs)
            XCTAssertEqual(selectedCard.rank, .two)
        }
    }

    func test_selectCardForBotPlay_respects_follow_suit_rule() {
        let botPlayer1 = Player(name: "Bot1", type: .bot(difficulty: .medium))
        let botPlayer2 = Player(name: "Bot2", type: .bot(difficulty: .medium))
        let botPlayer3 = Player(name: "Bot3", type: .bot(difficulty: .medium))
        let botPlayer4 = Player(name: "Bot4", type: .bot(difficulty: .medium))

        let game = Game(player1: botPlayer1, player2: botPlayer2, player3: botPlayer3, player4: botPlayer4)

        // Play first card (2 of clubs)
        let firstCard = game.selectCardForBotPlay(player: game.currentPlayer)
        try! game.playCard(firstCard, by: game.currentPlayer)

        // Next player must follow suit if possible
        let secondPlayer = game.currentPlayer
        let secondCard = game.selectCardForBotPlay(player: secondPlayer)

        // If player has clubs, they must play a club
        let hasClubs = secondPlayer.hand.contains(where: { $0.suit == .clubs })
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

    /// Builds a complete trick from four cards played by the game's four players in order.
    private func makeTrick(_ cards: [Card], in game: Game) throws -> Trick {
        var trick = Trick()
        for (player, card) in zip(game.players, cards) {
            try trick.play(card, by: player)
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
        try trick.play(Card(suit: .diamonds, rank: .jack), by: game.players[0])

        XCTAssertEqual(game.points(in: trick), -10)
    }

    func test_points_matchesPointsDeliveredToDelegate() throws {
        final class Spy: GameEngineDelegate {
            var delivered: [Int] = []
            func game(_ game: Game, didCompleteTrick trick: Trick, winner: Player, points: Int) {
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
        game.performExchange()

        var invalidAttempts = 0
        while !game.isHandComplete {
            for player in game.players {
                for card in game.hand(for: player) {
                    let legal = game.legalMoves(for: player).contains(card)
                    if legal { continue }
                    do {
                        try game.playCard(card, by: player)
                        XCTFail("Illegal play \(card) by \(player.name) was accepted")
                    } catch let error as GameError {
                        invalidAttempts += 1
                        _ = error
                    } catch {
                        XCTFail("Non-GameError escaped playCard: \(error)")
                    }
                }
            }
            let current = game.currentPlayer
            guard let move = game.legalMoves(for: current).first else {
                return XCTFail("No legal move for \(current.name)")
            }
            try game.playCard(move, by: current)
        }

        XCTAssertGreaterThan(invalidAttempts, 0)
        XCTAssertThrowsError(try game.playCard(Card(suit: .clubs, rank: .two), by: game.currentPlayer)) { error in
            XCTAssertEqual(error as? GameError, .handComplete)
        }
    }
}
