# Changelog

All notable changes to the Hearts engine are recorded here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the package follows
[Semantic Versioning](https://semver.org/).

## [1.0.0] - 2026-09-13

First complete release of the engine. Everything below is new relative to `v0.0.1`, which
held only the card, deck and exchange models.

### Added

- Full trick-taking rules through a single `PlayRules` oracle: follow suit, hearts breaking,
  no points on the first trick, 2♣ leads, with `legalMoves()` derived from `validate(_:)`.
- Scoring via `Scoring` and `HandResult`: hearts, Q♠, shooting the moon (add to others or
  subtract from self), optional J♦ bonus, configurable winning score, and ties that play on.
- `GamePhase` state machine driving `Game`: each phase admits exactly one mutator, everything
  else throws `GameError.wrongPhase`, and `advance()` runs every bot-only step.
- Any mix of human and bot seats, keyed by `Seat` and `SeatMap`, with `Player` as an immutable
  profile.
- Three built-in bot levels (`RandomAIStrategy`, `BasicAIStrategy`, `AdvancedAIStrategy` with
  card counting, void inference and moon-shot pursuit) behind a public `AIStrategy` protocol.
- `GameEngineDelegate` events for every play, trick, hearts break, hand, game end, phase change
  and restore, each with a default no-op.
- `Codable` `GameSnapshot`, validated `restore(from:)`, and multi-step `undo()`.
- Injectable randomness: `SeededRandomNumberGenerator` reproduces whole games from one seed.
- `HeartsCLI`, a terminal client that plays a full game against the bots.
- Every public value type is `Sendable`, and `Card` is `Hashable`; the package builds without
  diagnostics in Swift 6 language mode.
- Doc comments on every public declaration.
- 380 tests at ~99% line coverage, run on macOS and Linux in CI.

### Changed

- Players are identified by `Seat`; hands and scores are `SeatMap`s on `Game` rather than
  properties of `Player`.
- The engine imports nothing beyond the Swift standard library.

### Removed

- Force unwraps, `fatalError` and `precondition` from `Sources/Hearts`; every failure is a
  typed `GameError` that leaves the game unchanged.

## [0.0.1] - 2024-05-06

Initial models: `Card`, `Deck`, `Player`, and card exchange with tests.

[1.0.0]: https://github.com/HassanSE/Hearts/compare/v0.0.1...v1.0.0
[0.0.1]: https://github.com/HassanSE/Hearts/releases/tag/v0.0.1
