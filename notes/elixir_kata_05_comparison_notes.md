# Kata 05: Comparison & Ordering

## The Concept

Elixir has two kinds of equality and a full set of comparison operators. Uniquely, Elixir can compare values of **any** two types using a defined term ordering.

## Equality Operators

### `==` and `!=` (Value Equality)
Compares values, with number type coercion:

```elixir
1 == 1       # => true
1 == 1.0     # => true  (integer and float are equal!)
:a == :a     # => true
"hi" == "hi" # => true
1 != 2       # => true
```

### `===` and `!==` (Strict Equality)
No type coercion — types must match exactly:

```elixir
1 === 1      # => true
1 === 1.0    # => false (different types!)
:a === :a    # => true
```

**When to use which?** Use `==` in most cases. Use `===` when you need to distinguish between `1` (integer) and `1.0` (float).

## Comparison Operators

```elixir
1 < 2      # => true
1 > 2      # => false
1 <= 2     # => true
1 >= 2     # => false
```

Note: Elixir uses `<=` and `>=`, not `=<` or `=>`.

## Cross-Type Comparison

Elixir can compare any two values, even of different types. This is possible because of a defined **term ordering**:

```
number < atom < reference < function < port < pid < tuple < map < list < bitstring
```

Examples:
```elixir
1 < :atom         # => true  (number < atom)
:atom < {1, 2}    # => true  (atom < tuple)
{1, 2} < [1, 2]   # => true  (tuple < list)
[1, 2] < "hello"  # => true  (list < bitstring/string)
```

This ordering exists so that data structures like maps and sorted sets can work with mixed types.

## Comparing Within the Same Type

### Numbers
Natural numeric ordering. Integers and floats can be compared:
```elixir
1 < 2.5    # => true
```

### Atoms
Alphabetical comparison of their string representation:
```elixir
:apple < :banana   # => true
:a < :b            # => true
```

### Strings
Lexicographic (dictionary) byte-by-byte comparison:
```elixir
"abc" < "abd"      # => true
"abc" < "abcd"     # => true
"B" < "a"          # => true (uppercase letters come before lowercase in UTF-8)
```

### Tuples
Compared element-by-element, size first:
```elixir
{1, 2} < {1, 3}     # => true  (first elements equal, compare second)
{1, 2} < {1, 2, 3}  # => true  (shorter tuple is "less")
```

### Lists
Compared element-by-element:
```elixir
[1, 2] < [1, 3]    # => true
[1, 2] < [1, 2, 3] # => true
```

## Common Pitfalls

1. **`1 == 1.0` is `true`** — Use `===` if you need to distinguish integer from float
2. **Cross-type comparison never raises** — `1 < :atom` returns `true`, doesn't error
3. **String comparison is byte-based** — `"B" < "a"` is `true` because uppercase B (66) < lowercase a (97) in UTF-8
4. **`<=` not `=<`** — Elixir uses `<=` and `>=` (the equals sign comes second)
