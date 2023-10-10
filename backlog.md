Creating a Hearts card game in Swift is a great project to work on. To start, you should focus on modeling the game logic. Here's a step-by-step guide on how to get started:

1. **Understand the Rules of Hearts:**
   Ensure you have a clear understanding of the rules of the Hearts card game. This includes how cards are dealt, how players take turns, scoring, and the objective of the game.

2. **Create a Card Class:**
   Begin by defining a `Card` class that represents a playing card. Each card should have properties like suit (hearts, diamonds, clubs, spades) and rank (2-10, Jack, Queen, King, Ace).

3. **Create a Deck Class:**
   Build a `Deck` class that contains a collection of `Card` objects. This class should initialize with a full deck of 52 cards, and you may want to include methods for shuffling and dealing cards.

4. **Create a Player Class:**
   Define a `Player` class to represent each player in the game. A player should have a hand (a collection of cards) and methods for playing cards.

5. **Implement Game Logic:**
   Model the core game logic. This involves handling the rules for card play, determining the winner of each trick, managing the passing of cards between players at the start of each round, and keeping track of the score.

6. **Manage Game State:**
   Create a `GameState` class that keeps track of the state of the game, including the current player's turn, the cards played in the current trick, and the scores.

7. **Implement Game Loop:**
   Set up a game loop that allows players to take turns, play cards, and update the game state accordingly. Ensure that the game loop continues until the game ends based on the rules.

8. **Test Your Model:**
   Write test cases to ensure that your game model functions correctly. Test various scenarios to verify that the rules are enforced and the game state is updated accurately.

9. **User Interface (Optional):**
   If you plan to create a graphical user interface (GUI) for your game, you can start working on that after you've completed the game logic. This might involve creating a card layout, user input handling, and displaying the game state.

10. **Iterate and Improve:**
    Continuously refine and expand your game model as needed. You can add features like computer players for single-player mode or implement networking for multiplayer functionality.

Remember to break down your project into smaller tasks and tackle them one at a time. Building a card game like Hearts is a complex task, but taking it step by step will make it more manageable. Swift offers a lot of support for object-oriented programming, making it a suitable choice for this project. Good luck!