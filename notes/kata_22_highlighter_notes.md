# Kata 22: The Highlighter

## Goal
Manipulate text presentation to **highlight matches** based on a search term. This demonstrates safe HTML string generation and `raw` rendering.

## Core Concepts

### 1. Safe HTML Injection
To highlight text, we must wrap it in a `<span>`. But we cannot just trust the input string.
**Process**:
1. Escape the *entire* original text (to prevent XSS).
2. Use Regex to find the match in the escaped text.
3. Replace the match with the highlighted version (which includes our specific classes).
4. Render the final result with `raw()`.

### 2. Regex Compilation
Use `Regex.escape(term)` to ensure special characters in the search term don't break the regex.

```elixir
Regex.compile!(Regex.escape(term), "i")
```

## Implementation Details

1.  **State**: `text`, `search_term`.
2.  **UI**: 
    - Text input for search.
    - Content block using `<%= raw(highlight(...)) %>`.
3.  **Events**:
    - `search`: Update state.

## Tips
- Always worry about XSS when using `raw`. In this kata, we manually ensure safety by escaping the source text first.

## Challenge
Add a **Case Sensitive** toggle (Checkbox). If checked, "elixir" should not match "Elixir".

<details>
<summary>View Solution</summary>

<pre><code class="elixir"># Pass options to Regex based on state
options = if @case_sensitive, do: "", else: "i"
Regex.compile!(Regex.escape(term), options)</code></pre>
</details>
