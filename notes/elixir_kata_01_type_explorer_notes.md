# Kata 01: Type Explorer

## The Concept

Every programming language has fundamental data types — the building blocks from which all data structures are composed. In Elixir, there are a handful of basic types you'll use constantly.

## Elixir's Basic Types

### Integers
Whole numbers with no size limit. Elixir supports arbitrarily large integers.

```elixir
42
-17
1_000_000    # underscores for readability
0xFF         # hexadecimal
0o777        # octal
0b1010       # binary
```

### Floats
64-bit double-precision numbers. Always written with a decimal point.

```elixir
3.14
-0.001
1.0e10       # scientific notation
```

**Important:** `1` is an integer, `1.0` is a float. They are different types.

### Strings
UTF-8 encoded binaries, written with double quotes.

```elixir
"hello"
"Hello, #{name}!"   # interpolation
"multi\nline"        # escape sequences
```

### Atoms
Constants whose name is their value. They start with `:` or are special words.

```elixir
:ok
:error
:hello_world
true    # same as :true
false   # same as :false
nil     # same as :nil
```

### Booleans
Just atoms `true` and `false`.

```elixir
true == :true    # => true
false == :false  # => true
```

### Nil
Represents the absence of a value. It's the atom `:nil`.

```elixir
nil == :nil   # => true
```

## Type Checking Functions

Elixir provides guard-safe functions to check types:

```elixir
is_integer(42)      # => true
is_float(3.14)      # => true
is_binary("hello")  # => true (strings are binaries)
is_atom(:ok)        # => true
is_boolean(true)    # => true
is_nil(nil)         # => true
is_number(42)       # => true (integer or float)
```

**Gotcha:** `is_binary("hello")` returns `true` because strings ARE binaries in Elixir.

## The Elixir Way

Unlike languages with implicit type coercion (JavaScript's `"5" + 3 == "53"`), Elixir is strict about types. You can't add a string to a number — you must be explicit:

```elixir
"5" + 3          # ** (ArithmeticError)
String.to_integer("5") + 3  # => 8
```

This strictness catches bugs early and makes code more predictable.

## Common Pitfalls

1. **Strings are binaries** — `is_binary("hello")` is `true`, not `is_string` (which doesn't exist)
2. **Booleans are atoms** — `is_atom(true)` is `true`
3. **No implicit coercion** — `1 + "2"` raises an error, not `3` or `"12"`
4. **Integer vs Float** — `1 == 1.0` is `true`, but `1 === 1.0` is `false`
