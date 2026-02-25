# Kata 42: Charlists vs Strings

## The Concept

Elixir has two text representations:
- **Strings** (`"hello"`) — UTF-8 encoded binaries
- **Charlists** (`'hello'`) — lists of Unicode codepoint integers

```elixir
"hello"  # string (binary)
'hello'  # charlist (list)

is_binary("hello")  # true
is_list('hello')    # true
```

## Why Two Types?

Elixir runs on the BEAM (Erlang VM). Erlang predates Unicode and uses lists of integers for text. Elixir strings are modern UTF-8 binaries, but charlist support is needed for **Erlang interoperability**.

## Internal Representation

```elixir
# String: contiguous bytes in memory
"hello" == <<104, 101, 108, 108, 111>>

# Charlist: linked list of integers
'hello' == [104, 101, 108, 108, 111]
```

## The IEx Display Gotcha

IEx displays a list of integers as a charlist if **all** values are printable ASCII (32-126):

```elixir
[104, 101, 108, 108, 111]   # IEx shows: 'hello'
[65, 66, 67]                 # IEx shows: 'ABC'
[1, 2, 3]                    # IEx shows: [1, 2, 3]  (not printable)
```

**Fix**: Use `inspect(list, charlists: :as_lists)` or configure IEx:
```elixir
IEx.configure(inspect: [charlists: :as_lists])
```

## Converting Between Types

```elixir
# Charlist to String
to_string('hello')            # "hello"
List.to_string([104, 101])    # "he"

# String to Charlist
to_charlist("hello")           # 'hello'
String.to_charlist("hello")    # 'hello'
```

## Operations Comparison

| Operation | String | Charlist |
|-----------|--------|----------|
| Concatenate | `"a" <> "b"` | `'a' ++ 'b'` |
| Interpolate | `"Hi #{name}"` | N/A (use `to_charlist`) |
| Length | `String.length("hi")` | `length('hi')` |
| Pattern match | `<<h, rest::binary>>` | `[h \| rest]` |
| Type check | `is_binary/1` | `is_list/1` |

## Erlang Interop

Many Erlang functions work with charlists:

```elixir
# :os.cmd expects and returns charlists
result = :os.cmd('whoami')
name = to_string(result) |> String.trim()

# :io.format uses charlist format strings
:io.format('Name: ~s~n', ['world'])

# Convert when calling Erlang
:erlang.list_to_atom('my_atom')
```

## When to Use Which

- **Always prefer strings** in Elixir code
- Only use charlists when an Erlang API requires them
- Convert Erlang results to strings immediately with `to_string/1`

## Common Pitfalls

1. **Mixing types**: `"hello" <> 'world'` will fail. Convert first.
2. **Single vs double quotes**: They are completely different types in Elixir (unlike Ruby or JavaScript).
3. **IEx confusion**: `[65, 66, 67]` displaying as `'ABC'` confuses beginners.
4. **Performance**: Strings (binaries) are more memory-efficient than charlists (linked lists).
5. **Pattern matching differences**: String patterns use binary syntax `<<>>`, charlist patterns use list syntax `[]`.
