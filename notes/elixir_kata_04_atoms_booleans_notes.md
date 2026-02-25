# Kata 04: Atoms & Booleans

## The Concept

Atoms are constants whose name is their value. Booleans (`true`/`false`) and `nil` are just special atoms. Understanding truthy/falsy values and the difference between strict and relaxed boolean operators is essential.

## Atoms

```elixir
:ok
:error
:hello_world
:"atoms with spaces"   # quoted atoms

# Atoms are unique — same name always references the same atom
:ok == :ok    # => true
```

Atoms are heavily used in Elixir for:
- Return values: `{:ok, result}`, `{:error, reason}`
- Map keys: `%{name: "Alice"}` (shorthand for `%{:name => "Alice"}`)
- Module names: `String` is actually the atom `:"Elixir.String"`
- Boolean values: `true`, `false`, `nil`

## Booleans Are Atoms

```elixir
true == :true     # => true
false == :false   # => true
nil == :nil       # => true

is_atom(true)     # => true
is_atom(false)    # => true
is_atom(nil)      # => true

is_boolean(true)  # => true
is_boolean(nil)   # => false (nil is an atom, not a boolean)
```

## Strict Boolean Operators: `and`, `or`, `not`

These require their **first** argument to be a boolean (`true` or `false`):

```elixir
true and true     # => true
true and false    # => false
false or true     # => true
not true          # => false

nil and true      # ** (BadBooleanError) — nil is not a boolean!
0 and true        # ** (BadBooleanError) — 0 is not a boolean!
```

## Relaxed (Truthy) Operators: `&&`, `||`, `!`

These accept any value. Only `false` and `nil` are falsy; everything else is truthy:

```elixir
nil && true       # => nil    (short-circuits on falsy)
0 && true         # => true   (0 is truthy!)
"" && true        # => true   ("" is truthy!)
false || "hello"  # => "hello"
nil || "default"  # => "default"
!nil              # => true
!0                # => false  (0 is truthy, so !0 is false)
```

## Truthy vs Falsy

| Value | Truthy? |
|-------|---------|
| `false` | Falsy |
| `nil` | Falsy |
| `0` | **Truthy** |
| `""` | **Truthy** |
| `[]` | **Truthy** |
| `:ok` | **Truthy** |
| Everything else | **Truthy** |

**Only `false` and `nil` are falsy.** This is different from JavaScript/Python where `0`, `""`, `[]` are falsy.

## Short-Circuit Evaluation

Both `&&`/`||` and `and`/`or` short-circuit:

```elixir
false && expensive_function()    # never calls the function
true || expensive_function()     # never calls the function
```

The operators return the value that determined the result:

```elixir
1 && 2       # => 2  (1 is truthy, so evaluate and return right side)
nil && 2     # => nil (nil is falsy, short-circuit and return nil)
1 || 2       # => 1  (1 is truthy, short-circuit and return 1)
nil || 2     # => 2  (nil is falsy, so evaluate and return right side)
```

## Common Pitfalls

1. **`and`/`or` require booleans** — `nil and true` crashes. Use `&&`/`||` for non-boolean values.
2. **`0` and `""` are truthy** — Unlike many other languages
3. **`nil` is not `false`** — They're different values, both falsy
4. **Atoms are never garbage collected** — Don't create atoms dynamically from user input (`String.to_atom/1` is dangerous)
