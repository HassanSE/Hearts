//
//  GameTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
@testable import HeartsDomain

final class GameTests: XCTestCase {
    func test_init_game_has_4_players() {
        let game = Game()
        XCTAssertEqual(game.players.count, 4)
    }
    
    func test_init_game_pass_4_players() {
        let player1 = Player(name: "Joe")
        let player2 = Player(name: "Dan")
        let player3 = Player(name: "Ali")
        let player4 = Player(name: "Tim")
        
        let game = Game(players: [player1, player2, player3, player4])
        XCTAssertEqual(game.players.count, 4)
    }
}
