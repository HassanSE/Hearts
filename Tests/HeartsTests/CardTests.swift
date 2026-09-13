//
//  CardTests.swift
//  
//
//  Created by Muhammad Hassan on 14/10/2023.
//

import XCTest
@testable import Hearts

final class CardTests: XCTestCase {
    
    func test_init_withSuitAndRank_storesBoth() {
        let card = Card.aceOfClubs
        XCTAssertEqual(card.suit, Card.Suit.clubs)
        XCTAssertEqual(card.rank, Card.Rank.ace)
    }
    
    func test_comparable_sameSuit_ordersByRank() {
        let aceOfClubs = Card.aceOfClubs
        let jackOfClubs = Card.jackOfClubs
        let twoOfClubs = Card.twoOfClubs
        XCTAssertGreaterThan(aceOfClubs, jackOfClubs)
        XCTAssertGreaterThan(jackOfClubs, twoOfClubs)
        XCTAssertLessThan(twoOfClubs, aceOfClubs)
    }
    
    // MARK: - Comparable

    func test_comparable_forAllCardPairs_incomparableImpliesEqual() {
        let cards = Deck().cards
        for a in cards {
            for b in cards {
                if !(a < b) && !(b < a) {
                    XCTAssertEqual(a, b, "\(a) and \(b) are neither < nor > but not ==")
                }
            }
        }
    }

    func test_sorted_mixedHand_groupsBySuitThenAscendingRank() {
        let hand: [Card] = [
            Card.twoOfHearts,
            Card.aceOfClubs,
            Card.queenOfSpades,
            Card.twoOfDiamonds,
            Card.threeOfClubs,
            Card.aceOfHearts,
        ]
        XCTAssertEqual(hand.sorted(), [
            Card.threeOfClubs,
            Card.aceOfClubs,
            Card.twoOfDiamonds,
            Card.queenOfSpades,
            Card.twoOfHearts,
            Card.aceOfHearts,
        ])
    }

    func test_points_everyCardInDeck_matchesStandardValues() {
        let deck = Deck()
        for card in deck.cards {
            if card.suit == .hearts {
                XCTAssertEqual(card.points, 1)
            } else if card.suit == .spades && card.rank == .queen {
                XCTAssertEqual(card.points, 13)
            } else {
                XCTAssertEqual(card.points, 0)
            }
        }
    }

    func test_points_namedCards_matchStandardValues() {
        XCTAssertEqual(Card.queenOfSpades.points, 13)
        XCTAssertEqual(Card.aceOfHearts.points, 1)
        XCTAssertEqual(Card.twoOfHearts.points, 1)
        XCTAssertEqual(Card.jackOfDiamonds.points, 0)
        XCTAssertEqual(Card.aceOfClubs.points, 0)
        XCTAssertEqual(Card.aceOfSpades.points, 0)
        XCTAssertEqual(Card.kingOfSpades.points, 0)
    }

    // MARK: - Rank

    
    func test_allCases_rank_hasThirteen() {
        let ranks = Card.Rank.allCases
        XCTAssertEqual(ranks.count, 13)
    }
    
    func test_comparable_rank_ordersTwoLowToAceHigh() {
        let ranks = Card.Rank.allCases.sorted(by: >)
        XCTAssertEqual(ranks.first, Card.Rank.ace)
        XCTAssertEqual(ranks.last, Card.Rank.two)
        XCTAssertEqual(ranks, [.ace, .king, .queen, .jack, .ten, .nine, .eight, .seven, .six, .five, .four, .three, .two])
    }

    // MARK: - Suit

    
    func test_allCases_suit_hasFour() {
        let suits = Card.Suit.allCases
        XCTAssertEqual(suits.count, 4)
    }
    
    func test_sorted_allSuits_followsDisplayOrderClubsDiamondsSpadesHearts() {
        let suits = Card.Suit.allCases.sorted()
        XCTAssertEqual(suits, [.clubs, .diamonds, .spades, .hearts])
    }

    // MARK: - Hashable

    func test_hashable_equalCards_shareHash() {
        XCTAssertEqual(Card(suit: .spades, rank: .queen).hashValue, Card.queenOfSpades.hashValue)
    }

    func test_set_ofFullDeck_holdsFiftyTwoDistinctCards() {
        let cards = Card.Suit.allCases.flatMap { suit in Card.Rank.allCases.map { Card(suit: suit, rank: $0) } }
        XCTAssertEqual(Set(cards).count, 52)
        XCTAssertEqual(Set(cards + cards).count, 52)
    }

    func test_dictionary_keyedByCard_looksUpByValue() {
        let points: [Card: Int] = [.queenOfSpades: 13, .aceOfHearts: 1]
        XCTAssertEqual(points[Card(suit: .spades, rank: .queen)], 13)
        XCTAssertNil(points[.twoOfClubs])
    }

    // MARK: - Sendable

    func test_sendable_engineValueTypes_crossIsolationBoundaries() async throws {
        // Compiles only if every type sent here is Sendable; the assertions keep the values alive.
        let card = Card.queenOfSpades
        let seat = Seat.south
        let trick = try Trick.mock([.twoOfClubs], leadingFrom: .south)
        let phase = GamePhase.awaitingPlay(.south)
        let configuration = GameConfiguration.withJackBonus
        let player = Player(name: "Bot", type: .bot(difficulty: .hard))
        let snapshot = Game.seededBots(seed: 1).snapshot()
        let result = await Task.detached {
            (card, seat, trick, phase, configuration, player, snapshot)
        }.value
        XCTAssertEqual(result.0, card)
        XCTAssertEqual(result.1, seat)
        XCTAssertEqual(result.2, trick)
        XCTAssertEqual(result.3, phase)
        XCTAssertEqual(result.4, configuration)
        XCTAssertEqual(result.5, player)
        XCTAssertEqual(result.6, snapshot)
    }
}
