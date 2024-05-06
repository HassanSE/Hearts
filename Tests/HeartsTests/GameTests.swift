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
        XCTAssertEqual(players[0].opponents.count, 3)
        XCTAssertEqual(players[1].opponents.count, 3)
        XCTAssertEqual(players[2].opponents.count, 3)
        XCTAssertEqual(players[3].opponents.count, 3)
        
        let allOpponents = players.flatMap { $0.opponents }
        XCTAssertEqual(allOpponents.count, 12)
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
        XCTAssertEqual(player1.getOpponent(direction: .right), players[3], "Player 1's right opponent should be Player 4.")
        XCTAssertEqual(players[3].getOpponent(direction: .left), players[0], "Player 4's left opponent should be Player 1.")
        
        guard let left = player1.getOpponent(direction: .left),
              let leftOfLeft = game.getOpponent(left, direction: .left),
              let player1Across = player1.getOpponent(direction: .across) else {
            XCTFail("Failed to get left opponent of Player 1 or player across from Player 1.")
            return
        }
        XCTAssertEqual(leftOfLeft, player1Across, "The left of left opponent of Player 1 should be the player across from Player 1.")
        
        guard let right = player1.getOpponent(direction: .right),
              let rightOfRight = game.getOpponent(right, direction: .right),
              let player1Across = player1.getOpponent(direction: .across) else {
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

        game.hand = 1
        XCTAssertEqual(game.exchangeDirection, .right)

        game.hand = 2
        XCTAssertEqual(game.exchangeDirection, .across)

        game.hand = 3
        XCTAssertEqual(game.exchangeDirection, .none)

        game.hand = 4
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
}
