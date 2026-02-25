# Kata 46: Formatting

## The Concept

Elixir provides string padding, number formatting, and powerful debug output tools. These are essential for producing clean output and debugging effectively.

## String Padding

### String.pad_leading/3

Pads the beginning of a string to reach a target length:

```elixir
String.pad_leading("42", 5, "0")    # "00042"
String.pad_leading("42", 5)         # "   42"  (space by default)
String.pad_leading("hi", 10, ".")   # "........hi"
```

### String.pad_trailing/3

Pads the end of a string:

```elixir
String.pad_trailing("hi", 10, ".")   # "hi........"
String.pad_trailing("hi", 10)        # "hi        "
```

### Practical: Aligned Columns

```elixir
data = [{"Name", "Alice"}, {"Age", "30"}, {"City", "NYC"}]

Enum.each(data, fn {label, value} ->
  IO.puts("#{String.pad_trailing(label, 10)}: #{value}")
end)
# Name      : Alice
# Age       : 30
# City      : NYC
```

## Number Formatting

### Integer Base Conversion

```elixir
Integer.to_string(255, 16)     # "FF"
Integer.to_string(42, 2)       # "101010"
Integer.to_string(42, 8)       # "52"
Integer.to_string(42, 10)      # "42"
```

### Float Formatting

```elixir
Float.round(3.14159, 2)                          # 3.14
:erlang.float_to_binary(3.14159, decimals: 2)    # "3.14"
:erlang.float_to_binary(3.14159, decimals: 4)    # "3.1416"
```

### Thousand Separators

Elixir does not have a built-in comma formatter, but it is easy to build:

```elixir
def format_number(n) when is_integer(n) do
  n
  |> Integer.to_string()
  |> String.graphemes()
  |> Enum.reverse()
  |> Enum.chunk_every(3)
  |> Enum.map(&Enum.reverse/1)
  |> Enum.reverse()
  |> Enum.map(&Enum.join/1)
  |> Enum.join(",")
end

format_number(1234567)   # "1,234,567"
```

## IO.inspect/2 — The Debug Swiss Army Knife

`IO.inspect/2` prints a value AND returns it, making it perfect for pipeline debugging:

```elixir
[1, 2, 3]
|> IO.inspect(label: "input")        # prints: input: [1, 2, 3]
|> Enum.map(&(&1 * 2))
|> IO.inspect(label: "doubled")      # prints: doubled: [2, 4, 6]
|> Enum.sum()
|> IO.inspect(label: "total")        # prints: total: 12
```

### IO.inspect Options

| Option | Effect |
|--------|--------|
| `:label` | Prefix output with a label |
| `:limit` | Truncate long collections |
| `:pretty` | Multi-line formatted output |
| `:width` | Max line width for pretty printing |
| `:charlists` | `:as_lists` to always show integer lists |
| `:structs` | `false` to show struct as raw map |
| `:binaries` | `:as_binaries` to show raw bytes |
| `:syntax_colors` | ANSI color output |

```elixir
# Combine multiple options
IO.inspect(data,
  label: "debug",
  pretty: true,
  limit: 10,
  width: 60
)
```

## IO Output Functions

| Function | Newline? | Returns | Use Case |
|----------|----------|---------|----------|
| `IO.puts/1` | Yes | `:ok` | Print text for users |
| `IO.write/1` | No | `:ok` | Print without trailing newline |
| `IO.inspect/2` | Yes | The value | Debug in pipelines |

## Building Formatted Tables

Combine padding and Enum to build aligned tables:

```elixir
headers = ["Name", "Score", "Grade"]
rows = [["Alice", "95", "A"], ["Bob", "87", "B+"]]

# 1. Calculate max width for each column
widths = Enum.map(0..(length(headers) - 1), fn i ->
  [headers | rows]
  |> Enum.map(&Enum.at(&1, i))
  |> Enum.map(&String.length/1)
  |> Enum.max()
end)

# 2. Format row with padding
format_row = fn cells ->
  Enum.zip(cells, widths)
  |> Enum.map(fn {cell, w} -> String.pad_trailing(cell, w) end)
  |> Enum.join(" | ")
end

# 3. Build table
IO.puts(format_row.(headers))
IO.puts(Enum.map(widths, &String.duplicate("-", &1)) |> Enum.join("-+-"))
Enum.each(rows, &IO.puts(format_row.(&1)))
```

Output:
```
Name  | Score | Grade
------+-------+------
Alice | 95    | A
Bob   | 87    | B+
```

## Common Pitfalls

1. **Padding with multibyte characters**: `String.pad_leading/3` counts graphemes, not bytes. This is correct but may surprise you if you mix ASCII and emoji.
2. **IO.inspect vs IO.puts**: `IO.inspect` is for debugging (shows data structures). `IO.puts` is for user-facing output (converts to string).
3. **Float precision**: `Float.round/2` returns a float, not a string. Use `:erlang.float_to_binary/2` for string output with exact decimal places.
4. **No built-in currency formatting**: You need a library like `Cldr` or `Number` for locale-aware number formatting.
5. **IO.inspect in production**: Remember to remove debug `IO.inspect` calls before deploying. Use `Logger` instead.
