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
        XCTAssertEqual(players[0].opponents?.count, 3)
        XCTAssertEqual(players[1].opponents?.count, 3)
        XCTAssertEqual(players[2].opponents?.count, 3)
        XCTAssertEqual(players[3].opponents?.count, 3)
        
        let allOpponents = Array(players[0].opponents! +
                                 players[1].opponents! +
                                 players[2].opponents! +
                                 players[3].opponents!)
        XCTAssertEqual(allOpponents.count, 12)
        
        var unique: [Opponent] = []
        for opponent in allOpponents {
            if unique.contains(opponent) { XCTFail("Opponents are not unique") }
            unique.append(opponent)
        }
    }
}
