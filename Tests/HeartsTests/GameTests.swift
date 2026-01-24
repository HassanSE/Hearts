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

        // Player 1 Assertions
        XCTAssertEqual(player1CardsAE.count, playerHandCount)
        let passedCards = player1CardsBE.filter { !player1CardsAE.contains($0) }
        XCTAssertEqual(passedCards.count, passedCardCount)
        
        // Player 2 Assertions
        XCTAssertTrue(player2CardsAE.contains(passedCards))
        XCTAssertEqual(player2CardsAE.count, playerHandCount)
        let passedCards2 = player2CardsBE.filter { !player2CardsAE.contains($0) }
        XCTAssertEqual(passedCards2.count, passedCardCount)
        
        // Player 3 Assertions
        XCTAssertTrue(player3CardsAE.contains(passedCards2))
        XCTAssertEqual(player3CardsAE.count, playerHandCount)
        let passedCards3 = player3CardsBE.filter { !player3CardsAE.contains($0) }
        XCTAssertEqual(passedCards3.count, passedCardCount)
        
        // Player 4 Assertions
        XCTAssertTrue(player4CardsAE.contains(passedCards3))
        XCTAssertEqual(player4CardsAE.count, playerHandCount)
        let passedCards4 = player4CardsBE.filter { !player4CardsAE.contains($0) }
        XCTAssertEqual(passedCards4.count, passedCardCount)
        XCTAssertTrue(player1CardsAE.contains(passedCards4))
    }

    func test_exchange_cards_full_flow_13_to_10_to_13() {
        // This integration test demonstrates the complete card exchange flow:
        // 1. Each player starts with 13 cards (after dealing)
        // 2. Each player picks 3 cards to pass (reducing to 10 cards)
        // 3. Each player accepts 3 cards from another player (back to 13 cards)

        let player1 = Player(name: "Alice")
        let player2 = Player(name: "Bob")
        let player3 = Player(name: "Charlie")
        let player4 = Player(name: "Diana")

        let game = Game(player1: player1, player2: player2, player3: player3, player4: player4)

        // Step 1: Verify all players start with 13 cards after dealing
        XCTAssertEqual(game.players[0].hand.count, 13, "Player 1 should start with 13 cards")
        XCTAssertEqual(game.players[1].hand.count, 13, "Player 2 should start with 13 cards")
        XCTAssertEqual(game.players[2].hand.count, 13, "Player 3 should start with 13 cards")
        XCTAssertEqual(game.players[3].hand.count, 13, "Player 4 should start with 13 cards")

        // Note: performExchange() is already called in Game.init(), which:
        // - Calls pickCards() on each player (13 → 10 cards)
        // - Then calls acceptExchange() on each player (10 → 13 cards)
        // So after init, players already have 13 cards again

        // To test the intermediate state, we need to manually test the flow
        var testPlayer = Player(name: "Test")
        testPlayer.hand = [
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

        XCTAssertEqual(testPlayer.hand.count, 13, "Test player starts with 13 cards")

        // Step 2: Player picks 3 cards to pass
        let passedCards = testPlayer.pickCards()
        XCTAssertEqual(testPlayer.hand.count, 10, "Test player should have 10 cards after picking 3 to pass")

        // Step 3: Player accepts 3 cards from another player
        let receivedCards: PassedCards = (
            Card(suit: .hearts, rank: .ace),
            Card(suit: .hearts, rank: .king),
            Card(suit: .hearts, rank: .queen)
        )
        testPlayer.acceptExchange(cards: receivedCards)
        XCTAssertEqual(testPlayer.hand.count, 13, "Test player should have 13 cards after accepting exchange")

        // Verify the flow completed correctly
        XCTAssertFalse(testPlayer.hand.contains(passedCards.first), "Player should not have the first passed card")
        XCTAssertFalse(testPlayer.hand.contains(passedCards.second), "Player should not have the second passed card")
        XCTAssertFalse(testPlayer.hand.contains(passedCards.third), "Player should not have the third passed card")
        XCTAssertTrue(testPlayer.hand.contains(receivedCards.first), "Player should have the first received card")
        XCTAssertTrue(testPlayer.hand.contains(receivedCards.second), "Player should have the second received card")
        XCTAssertTrue(testPlayer.hand.contains(receivedCards.third), "Player should have the third received card")
    }
}
