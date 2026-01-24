//
//  TrickTests.swift
//
//
//  Created by Muhammad Hassan on 24/01/2026.
//

import XCTest
@testable import Hearts

final class TrickTests: XCTestCase {
  
  // MARK: - Initialization Tests
  
  func test_init_trick_is_empty() {
    let trick = Trick()
    
    XCTAssertEqual(trick.plays.count, 0)
    XCTAssertEqual(trick.points, 0)
    XCTAssertFalse(trick.isComplete)
    XCTAssertNil(trick.leadSuit)
    XCTAssertNil(trick.winner)
  }
  
  // MARK: - Lead Suit Tests
  
  func test_leadSuit_is_nil_when_no_cards_played() {
    let trick = Trick()
    
    XCTAssertNil(trick.leadSuit)
  }
  
  func test_leadSuit_is_suit_of_first_card_played() throws {
    var trick = Trick()
    let player = Player(name: "Alice")
    let card = Card(suit: .clubs, rank: .five)
    
    try trick.play(card, by: player, from: [card])
    
    XCTAssertEqual(trick.leadSuit, .clubs)
  }
  
  // MARK: - Completion Tests
  
  func test_isComplete_is_false_with_less_than_4_cards() throws {
    var trick = Trick()
    let players = [Player(name: "A"), Player(name: "B"), Player(name: "C")]
    let cards = [
      Card(suit: .clubs, rank: .two),
      Card(suit: .clubs, rank: .three),
      Card(suit: .clubs, rank: .four)
    ]
    
    for (player, card) in zip(players, cards) {
      try trick.play(card, by: player, from: [card])
      if trick.plays.count < 4 {
        XCTAssertFalse(trick.isComplete)
      }
    }
  }
  
  func test_isComplete_is_true_with_4_cards() throws {
    var trick = Trick()
    let players = [Player(name: "A"), Player(name: "B"), Player(name: "C"), Player(name: "D")]
    let cards = [
      Card(suit: .clubs, rank: .two),
      Card(suit: .clubs, rank: .three),
      Card(suit: .clubs, rank: .four),
      Card(suit: .clubs, rank: .five)
    ]
    
    for (player, card) in zip(players, cards) {
      try trick.play(card, by: player, from: [card])
    }
    
    XCTAssertTrue(trick.isComplete)
  }
  
  // MARK: - Winner Tests
  
  func test_winner_is_nil_when_trick_incomplete() throws {
    var trick = Trick()
    let player = Player(name: "Alice")
    let card = Card(suit: .clubs, rank: .ace)
    
    try trick.play(card, by: player, from: [card])
    
    XCTAssertNil(trick.winner, "Winner should be nil until trick is complete")
  }
  
  func test_winner_is_player_with_highest_card_of_lead_suit() throws {
    var trick = Trick()
    let player1 = Player(name: "Alice")
    let player2 = Player(name: "Bob")
    let player3 = Player(name: "Charlie")
    let player4 = Player(name: "Diana")
    
    let card1 = Card(suit: .clubs, rank: .five)
    let card2 = Card(suit: .clubs, rank: .ace)  // Highest clubs - should win
    let card3 = Card(suit: .hearts, rank: .king) // Different suit
    let card4 = Card(suit: .clubs, rank: .ten)
    
    try trick.play(card1, by: player1, from: [card1])
    try trick.play(card2, by: player2, from: [card2])
    try trick.play(card3, by: player3, from: [card3])
    try trick.play(card4, by: player4, from: [card4])
    
    XCTAssertEqual(trick.winner, player2, "Player with highest card of lead suit should win")
  }
  
  func test_winner_ignores_higher_cards_of_non_lead_suit() throws {
    var trick = Trick()
    let player1 = Player(name: "Alice")
    let player2 = Player(name: "Bob")
    let player3 = Player(name: "Charlie")
    let player4 = Player(name: "Diana")
    
    let card1 = Card(suit: .diamonds, rank: .two)  // Lead with diamonds
    let card2 = Card(suit: .hearts, rank: .ace)    // Ace but wrong suit
    let card3 = Card(suit: .diamonds, rank: .five) // Should win (highest diamonds)
    let card4 = Card(suit: .spades, rank: .king)   // King but wrong suit
    
    try trick.play(card1, by: player1, from: [card1])
    try trick.play(card2, by: player2, from: [card2])
    try trick.play(card3, by: player3, from: [card3])
    try trick.play(card4, by: player4, from: [card4])
    
    XCTAssertEqual(trick.winner, player3, "Only cards of lead suit can win")
  }
  
  // MARK: - Points Tests
  
  func test_points_is_zero_for_no_point_cards() throws {
    var trick = Trick()
    let players = [Player(name: "A"), Player(name: "B"), Player(name: "C"), Player(name: "D")]
    let cards = [
      Card(suit: .clubs, rank: .two),
      Card(suit: .clubs, rank: .three),
      Card(suit: .clubs, rank: .four),
      Card(suit: .clubs, rank: .five)
    ]
    
    for (player, card) in zip(players, cards) {
      try trick.play(card, by: player, from: [card])
    }
    
    XCTAssertEqual(trick.points, 0)
  }
  
  func test_points_counts_hearts() throws {
    var trick = Trick()
    let players = [Player(name: "A"), Player(name: "B"), Player(name: "C"), Player(name: "D")]
    let cards = [
      Card(suit: .clubs, rank: .two),
      Card(suit: .hearts, rank: .three),  // 1 point
      Card(suit: .hearts, rank: .four),   // 1 point
      Card(suit: .clubs, rank: .five)
    ]
    
    for (player, card) in zip(players, cards) {
      try trick.play(card, by: player, from: [card])
    }
    
    XCTAssertEqual(trick.points, 2, "Should count 2 hearts as 2 points")
  }
  
  func test_points_counts_queen_of_spades() throws {
    var trick = Trick()
    let players = [Player(name: "A"), Player(name: "B"), Player(name: "C"), Player(name: "D")]
    let cards = [
      Card(suit: .spades, rank: .two),
      Card(suit: .spades, rank: .queen),  // 13 points
      Card(suit: .spades, rank: .four),
      Card(suit: .spades, rank: .five)
    ]
    
    for (player, card) in zip(players, cards) {
      try trick.play(card, by: player, from: [card])
    }
    
    XCTAssertEqual(trick.points, 13, "Queen of spades should be worth 13 points")
  }
  
  func test_points_counts_hearts_and_queen_of_spades() throws {
    var trick = Trick()
    let players = [Player(name: "A"), Player(name: "B"), Player(name: "C"), Player(name: "D")]
    let cards = [
      Card(suit: .hearts, rank: .two),    // 1 point
      Card(suit: .spades, rank: .queen),  // 13 points
      Card(suit: .hearts, rank: .four),   // 1 point
      Card(suit: .clubs, rank: .five)
    ]
    
    for (player, card) in zip(players, cards) {
      try trick.play(card, by: player, from: [card])
    }
    
    XCTAssertEqual(trick.points, 15, "Should count 2 hearts + Q♠ = 15 points")
  }
  
  // MARK: - Validation Tests
  
  func test_play_throws_when_trick_is_complete() throws {
    var trick = Trick()
    let players = [Player(name: "A"), Player(name: "B"), Player(name: "C"), Player(name: "D"), Player(name: "E")]
    let cards = [
      Card(suit: .clubs, rank: .two),
      Card(suit: .clubs, rank: .three),
      Card(suit: .clubs, rank: .four),
      Card(suit: .clubs, rank: .five),
      Card(suit: .clubs, rank: .six)
    ]
    
    // Play 4 cards
    for i in 0..<4 {
      try trick.play(cards[i], by: players[i], from: [cards[i]])
    }
    
    // Try to play 5th card
    XCTAssertThrowsError(try trick.play(cards[4], by: players[4], from: [cards[4]])) { error in
      XCTAssertEqual(error as? TrickError, TrickError.trickAlreadyComplete)
    }
  }
  
  func test_play_throws_when_player_already_played() throws {
    var trick = Trick()
    let player = Player(name: "Alice")
    let card1 = Card(suit: .clubs, rank: .two)
    let card2 = Card(suit: .clubs, rank: .three)
    
    try trick.play(card1, by: player, from: [card1, card2])
    
    // Same player tries to play again
    XCTAssertThrowsError(try trick.play(card2, by: player, from: [card1, card2])) { error in
      XCTAssertEqual(error as? TrickError, TrickError.playerAlreadyPlayed)
    }
  }
  
  func test_play_throws_when_card_not_in_hand() throws {
    var trick = Trick()
    let player = Player(name: "Alice")
    let card = Card(suit: .clubs, rank: .two)
    let otherCard = Card(suit: .hearts, rank: .ace)
    
    XCTAssertThrowsError(try trick.play(card, by: player, from: [otherCard])) { error in
      XCTAssertEqual(error as? TrickError, TrickError.cardNotInHand)
    }
  }
  
  func test_play_throws_when_not_following_suit() throws {
    var trick = Trick()
    let player1 = Player(name: "Alice")
    let player2 = Player(name: "Bob")
    
    let leadCard = Card(suit: .clubs, rank: .two)
    let clubCard = Card(suit: .clubs, rank: .three)
    let heartCard = Card(suit: .hearts, rank: .ace)
    
    // Player 1 leads with clubs
    try trick.play(leadCard, by: player1, from: [leadCard])
    
    // Player 2 has clubs but plays hearts
    XCTAssertThrowsError(try trick.play(heartCard, by: player2, from: [clubCard, heartCard])) { error in
      if case TrickError.mustFollowSuit(let required) = error {
        XCTAssertEqual(required, .clubs)
      } else {
        XCTFail("Expected mustFollowSuit error")
      }
    }
  }
  
  func test_play_allows_different_suit_when_player_has_no_lead_suit() throws {
    var trick = Trick()
    let player1 = Player(name: "Alice")
    let player2 = Player(name: "Bob")
    
    let leadCard = Card(suit: .clubs, rank: .two)
    let heartCard = Card(suit: .hearts, rank: .ace)
    
    try trick.play(leadCard, by: player1, from: [leadCard])
    
    // Player 2 has no clubs, should be allowed to play hearts
    XCTAssertNoThrow(try trick.play(heartCard, by: player2, from: [heartCard]))
  }
  
  // MARK: - Helper Property Tests
  
  func test_cards_returns_all_played_cards() throws {
    var trick = Trick()
    let players = [Player(name: "A"), Player(name: "B")]
    let cards = [
      Card(suit: .clubs, rank: .two),
      Card(suit: .clubs, rank: .three)
    ]
    
    for (player, card) in zip(players, cards) {
      try trick.play(card, by: player, from: [card])
    }
    
    XCTAssertEqual(trick.cards, cards)
  }
  
  func test_players_returns_all_players_who_played() throws {
    var trick = Trick()
    let players = [Player(name: "A"), Player(name: "B")]
    let cards = [
      Card(suit: .clubs, rank: .two),
      Card(suit: .clubs, rank: .three)
    ]
    
    for (player, card) in zip(players, cards) {
      try trick.play(card, by: player, from: [card])
    }
    
    XCTAssertEqual(trick.players, players)
  }
  
  func test_hasPlayed_returns_true_for_player_who_played() throws {
    var trick = Trick()
    let player = Player(name: "Alice")
    let card = Card(suit: .clubs, rank: .two)
    
    try trick.play(card, by: player, from: [card])
    
    XCTAssertTrue(trick.hasPlayed(player))
  }
  
  func test_hasPlayed_returns_false_for_player_who_has_not_played() {
    let trick = Trick()
    let player = Player(name: "Alice")
    
    XCTAssertFalse(trick.hasPlayed(player))
  }
  
  // MARK: - Debug Description Tests
  
  func test_debugDescription_shows_plays() throws {
    var trick = Trick()
    let player1 = Player(name: "Alice")
    let player2 = Player(name: "Bob")
    let card1 = Card(suit: .clubs, rank: .two)
    let card2 = Card(suit: .clubs, rank: .three)
    
    try trick.play(card1, by: player1, from: [card1])
    try trick.play(card2, by: player2, from: [card2])
    
    let description = trick.debugDescription
    
    XCTAssertTrue(description.contains("Alice"))
    XCTAssertTrue(description.contains("Bob"))
  }
}
