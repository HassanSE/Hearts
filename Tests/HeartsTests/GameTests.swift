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
    
    func test_exchange_cards() {
        let game = Game()
    }
}
