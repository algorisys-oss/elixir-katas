# Kata 02: The Counter

## The Concept
The "Counter" is the "Hello World" of State Management. It demonstrates how to persist and mutate data over time. In LiveView, this teaches us about **Immutability** and **socket transforms**.

## The Elixir Way
In JavaScript: `this.count++`. You mutate the object in place.
In Elixir: Data is **Immutable**. You cannot change the number 5 to 6. You must create a *new* socket state that contains the new number.
```elixir
# Bad (Impossible in Elixir)
socket.assigns.count = socket.assigns.count + 1

# Good
assign(socket, count: socket.assigns.count + 1)
```
This guarantees thread safety. No matter how many events flood in, each state transition is calculated cleanly from the previous one.

## Deep Dive

### 1. `update/3` vs `assign/2`
*   `assign(socket, count: 5)`: "Set the value to 5." (clobbering previous value).
*   `update(socket, :count, &(&1 + 1))`: "Take the *current* value and add 1."
Preferred pattern for counters, lists, or toggles where the next state depends on the previous state.

### 2. The Diff Payload
When you click "+", the server does NOT send a new HTML page. It calculates the diff.
**Initial Render**:
```javascript
{ 0: "0", static: ["<div>Count: ", "</div>"] }
```
**Update**:
```javascript
{ 0: "1" }
```
This generic JSON payload is extremely small (bytes), making LiveView performant even on slow 3G networks.

### 3. Multiple Event Bindings
You can attach multiple listeners to a single element, or even the window.
*   `phx-click`: Mouse click.
*   `phx-window-keydown`: Global keyboard shortcuts (great for accessibility).
*   `phx-throttle="500"`: Prevents users from spamming the button faster than 2 times a second.

## Common Pitfalls

1.  **State vs Data**: Don't put *everything* in assigns. Only put what the UI needs for rendering. Large user structs shouldn't be in assigns if you only need the display name.
2.  **Integer Overflow**: Elixir integers are arbitrary precision (they don't overflow like 32-bit ints), so your counter can go as high as memory allows!
3.  **Concurrency**: If you have two users on two different computers, they each have their *own* counter (own process). This is not a global shared counter (State is per-process).
