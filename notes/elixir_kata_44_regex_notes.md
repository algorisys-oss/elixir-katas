# Kata 44: Regex

## The Concept

Elixir uses the `~r//` sigil to create regular expressions, backed by Erlang's PCRE engine. The `Regex` module provides functions for matching, extracting, replacing, and splitting strings.

```elixir
~r/hello/          # compile-time regex
Regex.compile!("hello")  # runtime regex (when pattern is dynamic)
```

## Core Regex Functions

### Regex.match?/2 — Boolean Check

```elixir
Regex.match?(~r/\d+/, "age: 42")     # true
Regex.match?(~r/\d+/, "no numbers")  # false
```

Also works with the `=~` operator:
```elixir
"age: 42" =~ ~r/\d+/   # true
```

### Regex.run/2 — First Match

Returns the first match, or `nil`:

```elixir
Regex.run(~r/\d+/, "42 and 7")
# ["42"]

Regex.run(~r/(\w+)@(\w+)/, "user@host")
# ["user@host", "user", "host"]
#  ^full match   ^group1  ^group2
```

### Regex.scan/2 — All Matches

```elixir
Regex.scan(~r/\d+/, "42 and 7 and 100")
# [["42"], ["7"], ["100"]]

Regex.scan(~r/(\w+)=(\w+)/, "a=1&b=2")
# [["a=1", "a", "1"], ["b=2", "b", "2"]]
```

### Regex.replace/3 — Replace Matches

```elixir
Regex.replace(~r/\d+/, "a1b2c3", "X")
# "aXbXcX"

# With backreferences
Regex.replace(~r/(\w+)@(\w+)/, "user@host", "\\2/\\1")
# "host/user"
```

### Regex.split/2 — Split on Pattern

```elixir
Regex.split(~r/[,;\s]+/, "a, b; c  d")
# ["a", "b", "c", "d"]
```

## Named Captures

Use `(?<name>...)` for named capture groups:

```elixir
re = ~r/(?<year>\d{4})-(?<month>\d{2})-(?<day>\d{2})/
Regex.named_captures(re, "2024-03-15")
# %{"year" => "2024", "month" => "03", "day" => "15"}
```

## Regex Modifiers

```elixir
~r/hello/i    # case insensitive
~r/hello/m    # multiline (^ and $ match line boundaries)
~r/hello/s    # dotall (. matches newlines)
~r/hello/u    # unicode
~r/hello/x    # extended (ignore whitespace, allow comments)
```

## Common Patterns

| Pattern | Description |
|---------|-------------|
| `\d+` | One or more digits |
| `\w+` | One or more word characters |
| `\s+` | One or more whitespace characters |
| `^...$` | Anchor to start and end |
| `(...)` | Capture group |
| `(?<name>...)` | Named capture group |
| `[a-zA-Z]` | Character class |
| `\b` | Word boundary |

## Compile-Time vs Runtime

```elixir
# Compile-time (preferred — compiled once):
~r/\d+/

# Runtime (when pattern comes from user input):
{:ok, regex} = Regex.compile(user_pattern)
# or
regex = Regex.compile!(user_pattern)  # raises on invalid
```

## When to Use Regex vs Binary Pattern Matching

- **Binary patterns**: Fixed prefixes, known structure, fast and simple
- **Regex**: Complex patterns, flexible matching, capture groups, replacements

```elixir
# Binary pattern matching: simpler for known prefixes
<<"GET ", path::binary>> = request_line

# Regex: better for flexible patterns
Regex.scan(~r/\d{4}-\d{2}-\d{2}/, log_entry)
```

## Common Pitfalls

1. **Backslash escaping**: In `~r//`, use `\d` not `\\d`. But in `Regex.compile/1` strings, you need `"\\d"`.
2. **Greedy by default**: `.*` matches as much as possible. Use `.*?` for non-greedy.
3. **Performance**: Compile regexes with `~r//` (compile-time) rather than `Regex.compile!/1` (runtime) when possible.
4. **Anchoring**: `~r/\d+/` matches if digits appear *anywhere*. Use `~r/^\d+$/` to match the entire string.
5. **Unicode**: Use the `u` flag (`~r/\w+/u`) for proper Unicode word character matching.
