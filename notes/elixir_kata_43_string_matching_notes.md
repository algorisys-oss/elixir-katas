# Kata 43: String Pattern Matching

## The Concept

Since Elixir strings are binaries, you can use **binary pattern matching** (`<<>>`) to destructure them. This provides a powerful, fast way to parse strings without regex.

```elixir
<<first::utf8, rest::binary>> = "hello"
# first = 104 (codepoint for 'h')
# rest = "ello"
```

## Extracting the First Character

Use `::utf8` to safely extract one UTF-8 codepoint:

```elixir
<<char::utf8, rest::binary>> = "Elixir"
# char = 69 (codepoint for 'E')
# rest = "lixir"

# Convert codepoint back to string:
<<69::utf8>>   # "E"
```

## Matching String Prefixes

Match on known prefixes directly:

```elixir
<<"Hello", name::binary>> = "Hello Alice"
# name = " Alice"

# In function heads:
def greet(<<"Hello", _::binary>>), do: :english
def greet(<<"Hola", _::binary>>), do: :spanish
def greet(_), do: :unknown
```

## Fixed-Width Field Extraction

Use `binary-size(n)` to extract exactly `n` bytes:

```elixir
<<year::binary-size(4), ?-, month::binary-size(2), ?-, day::binary-size(2)>> = "2024-03-15"
# year = "2024", month = "03", day = "15"

# Parse a fixed-width record
<<id::binary-size(3), name::binary-size(5)>> = "001Alice"
# id = "001", name = "Alice"
```

## Raw Byte Matching

Without `::utf8`, each variable matches one byte:

```elixir
<<a, b, c, rest::binary>> = "hello"
# a = 104, b = 101, c = 108, rest = "lo"
```

## Integer Extraction from Binaries

Common in network protocols and file formats:

```elixir
# 16-bit big-endian integer
<<length::16, data::binary>> = <<0, 5, "hello">>
# length = 5, data = "hello"

# 32-bit with explicit endianness
<<value::little-32>> = <<1, 0, 0, 0>>
# value = 1
```

## Binary Pattern Syntax Reference

| Syntax | Meaning |
|--------|---------|
| `<<x>>` | One byte (0-255) |
| `<<x::utf8>>` | One UTF-8 codepoint |
| `<<x::binary-size(n)>>` | Exactly n bytes |
| `<<x::binary>>` | Rest of binary (must be last) |
| `<<x::16>>` | 16-bit integer |
| `<<x::little-32>>` | 32-bit little-endian integer |
| `<<"prefix", rest::binary>>` | Literal prefix match |

## Practical: Recursive String Walker

```elixir
def each_char(""), do: :done
def each_char(<<char::utf8, rest::binary>>) do
  IO.puts("#{<<char::utf8>>} = #{char}")
  each_char(rest)
end
```

## Using in Function Heads

Binary patterns work in multi-clause functions:

```elixir
def parse_method(<<"GET ", path::binary>>), do: {:get, path}
def parse_method(<<"POST ", path::binary>>), do: {:post, path}
def parse_method(<<"PUT ", path::binary>>), do: {:put, path}
def parse_method(<<"DELETE ", path::binary>>), do: {:delete, path}
def parse_method(_), do: {:error, :unknown_method}
```

## Common Pitfalls

1. **Forgetting `::utf8`**: Without it, you match one raw byte, which may split a multibyte character.
2. **`::binary` must be last**: The rest-of-binary match can only appear at the end of the pattern.
3. **Fixed sizes only**: `binary-size(n)` requires a compile-time constant or a variable already bound.
4. **Empty string**: `<<_::utf8, _::binary>> = ""` will raise `MatchError`.
5. **Byte vs character count**: `binary-size(n)` counts bytes, not graphemes.
