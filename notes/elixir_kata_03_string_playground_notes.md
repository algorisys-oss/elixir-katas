# Kata 03: String Playground

## The Concept

Strings in Elixir are UTF-8 encoded binaries. They support interpolation, concatenation, and a rich set of functions in the `String` module.

## String Basics

```elixir
# Double quotes for strings
"hello"

# Interpolation with #{}
name = "world"
"Hello, #{name}!"    # => "Hello, world!"

# Escape sequences
"line1\nline2"       # newline
"tab\there"          # tab
"quote: \""          # escaped quote
```

## Concatenation

The `<>` operator joins strings:

```elixir
"Hello" <> " " <> "World"   # => "Hello World"
```

This is different from `+` in other languages. Elixir does NOT use `+` for strings.

## The String Module

```elixir
String.length("hello")      # => 5
String.upcase("hello")      # => "HELLO"
String.downcase("HELLO")    # => "hello"
String.reverse("hello")     # => "olleh"
String.trim("  hello  ")    # => "hello"
String.trim_leading("  hi") # => "hi"
String.trim_trailing("hi ") # => "hi"

String.split("a,b,c", ",")  # => ["a", "b", "c"]
String.split("hello world") # => ["hello", "world"]

String.replace("hello", "l", "r")  # => "herro"
String.contains?("hello", "ell")   # => true
String.starts_with?("hello", "he") # => true
String.ends_with?("hello", "lo")   # => true

String.first("hello")       # => "h"
String.last("hello")        # => "o"
String.at("hello", 2)       # => "l"
String.slice("hello", 1..3) # => "ell"

String.duplicate("ha", 3)   # => "hahaha"
String.capitalize("hello")  # => "Hello"
```

## Multi-line Strings (Heredocs)

```elixir
"""
This is a
multi-line string.
It preserves newlines.
"""
```

## String vs Charlist

- `"hello"` is a **string** (binary)
- `'hello'` is a **charlist** (list of integers)

These are completely different types! We'll explore this in Kata 42.

## Common Pitfalls

1. **No `+` for strings** — Use `<>` for concatenation
2. **`String.length` vs `byte_size`** — For ASCII they're the same, but for UTF-8 characters like emoji they differ
3. **Strings are immutable** — Every operation returns a new string
4. **Single vs double quotes** — `"hello"` (string) and `'hello'` (charlist) are NOT the same thing
