# Kata 125: State Machine (Vending Machine)

## Goal
Model complex logic using `:gen_statem` (Erlang's State Machine behavior).

## Core Concepts

### 1. Finite State Machine (FSM)
States: `:idle`, `:ready` (has coins), `:dispensing`.
Transitions are strict. You cannot go from `:idle` to `:dispensing` without `:ready`.

### 2. Events
`cast` or `call` triggers state transitions. The machine broadcasts updates to the UI.

## Implementation Details

1.  **State**: Displayed visually in the UI.
2.  **Logic**: Enforced in the `VendingMachine` process.

## Tips
- `:gen_statem` is powerful for hardware integration, game logic, or complex workflows (payment processing).

## Challenge
**Restock**.
Add a "Maintenance Mode".
1. Authenticate (simulate with a button).
2. Transition to `:maintenance` state (machine ignores coins).
3. "Refill All" button sets stock to 10.
4. Exit maintenance -> `:idle`.

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Add `:maintenance` state to callback module.
# Handle `refill` event only in maintenance state.
</code></pre>
</details>
