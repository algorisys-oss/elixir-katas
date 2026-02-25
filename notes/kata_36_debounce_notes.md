# Kata 36: Debounce

## Goal
Implement **Debouncing** to limit the rate of event handling. This is critical for search inputs to prevent flooding the server with requests on every keystroke.

## Core Concepts

### 1. `phx-debounce`
A built-in attribute that delays the sending of an event.
- `phx-debounce="300"`: Waits 300ms after the last keystroke before sending.
- `phx-debounce="blur"`: Waits until the user leaves the field.

### 2. Loading State
LiveView automatically applies CSS classes when an event is processing.
- `phx-change-loading`: Applied to the form/input while waiting for the server response.

## Implementation Details

1.  **State**: `query` and `results`.
2.  **UI**: Search input with `phx-debounce="500"`.
3.  **Events**:
    *   `handle_event("search", ...)`: Performs the actual search logic.

## Tips
- Use a spinner with CSS opacity toggled by `.phx-change-loading` class on the container for a smooth "Searching..." indicator.

## Challenge
Add a **Minimum Length** check. Do not perform the search (or searching for empty list) if the query is **less than 3 characters**.

<details>
<summary>View Solution</summary>

<pre><code class="elixir">def handle_event("search", %{"query" => query}, socket) do
  results = 
    if String.length(query) >= 3 do
      perform_search(query)
    else
      [] 
    end
  {:noreply, assign(socket, query: query, results: results)}
end
</code></pre>
</details>
