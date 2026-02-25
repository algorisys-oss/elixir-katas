# Kata 83: Game State (Multiplayer)

## Goal
Synchronize complex game state between players.

## Core Concepts

### 1. Source of Truth
Ideally, a GenServer holds the game state. The LiveViews are just viewports.
(In this simple Kata, state might be shared via PubSub or just local logic for demo).

### 2. Turn Management
`current_turn: :player1`. Disable Player 2's buttons.

## Implementation Details

1.  **State**: `p1_score`, `p2_score`.
2.  **Logic**: Simple increment and turn swap.

## Tips
- For real games, prevent cheating by verifying the user ID matches the `current_turn` on the server.

## Challenge
Add a **Win Condition**. The game ends when a player reaches **10 points**.
Show a "Game Over" modal and a "New Game" button.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">if new_score >= 10 do
  assign(socket, game_over: true, winner: player)
else
  # continue
end
</code></pre>
</details>
