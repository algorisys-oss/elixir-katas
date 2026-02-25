# Kata 45: Sigils

## The Concept

Sigils are shortcuts for creating common data types with the `~` prefix. They provide concise syntax and compile-time validation.

```elixir
~s|hello "world"|     # string with easy quoting
~w[foo bar baz]       # ["foo", "bar", "baz"]
~r/\d+/              # compiled regex
~D[2024-03-15]       # Date struct
```

## Built-in Sigils

### ~s — String

Creates a string. Useful when the content contains quotes:

```elixir
~s|He said "hello"|          # "He said \"hello\""
~s{nested (parens) ok}       # "nested (parens) ok"
~s|with #{1 + 2} interpolation|  # "with 3 interpolation"
```

### ~S — Raw String (No Interpolation)

```elixir
~S|no #{interpolation}|      # "no \#{interpolation}"
~S|no \n escaping|           # "no \\n escaping"
```

### ~w — Word List

Creates a list of words split on whitespace:

```elixir
~w[hello world elixir]       # ["hello", "world", "elixir"]
~w[hello world elixir]a      # [:hello, :world, :elixir]
~w[hello world elixir]c      # ['hello', 'world', 'elixir']
```

Modifiers:
- No modifier or `s` — list of strings (default)
- `a` — list of atoms
- `c` — list of charlists

### ~r — Regex

Creates a compiled regular expression:

```elixir
~r/\d+/            # match digits
~r/hello/i         # case insensitive
~r{pattern}        # alternate delimiter
```

### ~D — Date

```elixir
~D[2024-03-15]     # %Date{year: 2024, month: 3, day: 15}
```

### ~T — Time

```elixir
~T[14:30:00]       # %Time{hour: 14, minute: 30, second: 0}
~T[14:30:00.123]   # with microseconds
```

### ~N — NaiveDateTime

```elixir
~N[2024-03-15 14:30:00]   # no timezone info
```

### ~U — UTC DateTime

```elixir
~U[2024-03-15 14:30:00Z]  # UTC timezone
```

## Uppercase vs Lowercase

| Feature | Lowercase (~s, ~w, ~r) | Uppercase (~S, ~W, ~R) |
|---------|----------------------|----------------------|
| Interpolation | Yes (`#{expr}`) | No |
| Escape sequences | Yes (`\n`, `\t`) | No |
| Use when | Dynamic content | Literal text, regex with many backslashes |

```elixir
name = "world"
~s|hello #{name}|    # "hello world"
~S|hello #{name}|    # "hello \#{name}"
```

## Delimiters

Sigils support 8 delimiter pairs:

| Delimiter | Example |
|-----------|---------|
| `/ /` | `~r/pattern/` |
| `\| \|` | `~s\|text\|` |
| `[ ]` | `~w[one two]` |
| `{ }` | `~s{text}` |
| `( )` | `~s(text)` |
| `< >` | `~s<text>` |
| `" "` | `~s"text"` |
| `' '` | `~s'text'` |

**Tip**: Choose the delimiter that avoids conflicts with your content. If content has `/`, use `~r{pattern}` instead of `~r/pattern/`.

## Custom Sigils

Define `sigil_x/2` in a module to create your own:

```elixir
defmodule MySigils do
  # Lowercase: supports interpolation
  def sigil_i(string, []) do
    String.to_integer(string)
  end

  # Uppercase: raw, no interpolation
  def sigil_I(string, []) do
    String.to_integer(string)
  end
end

import MySigils
~i[42]    # 42
```

The second argument receives modifier characters as a charlist:

```elixir
def sigil_v(string, 'r'), do: String.reverse(string)
def sigil_v(string, _), do: string

~v[hello]r   # "olleh"
```

## Common Pitfalls

1. **Delimiter conflicts**: If your `~s()` content contains `)`, use `~s||` or `~s[]` instead.
2. **Uppercase confusion**: `~S` does NOT interpolate — this trips up beginners expecting `~s` behavior.
3. **~w modifier placement**: The modifier goes AFTER the closing delimiter: `~w[a b]a` not `~wa[a b]`.
4. **Atom creation**: `~w[...]a` creates atoms at compile time — do not use with user input.
5. **Date/Time validation**: `~D[2024-13-45]` will fail at compile time, which is a feature, not a bug.
