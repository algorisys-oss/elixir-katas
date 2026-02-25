# Kata 71: ETS Tables

## The Concept

**ETS (Erlang Term Storage)** provides fast, in-memory key-value storage that lives outside any process's heap. ETS tables support concurrent reads without locking, making them ideal for caches, counters, and lookup tables.

```elixir
# Create a table
table = :ets.new(:my_cache, [:set, :public, :named_table])

# Insert data (tuples, first element is the key)
:ets.insert(:my_cache, {"user:1", %{name: "Alice", role: :admin}})
:ets.insert(:my_cache, {"user:2", %{name: "Bob", role: :user}})

# Lookup by key
:ets.lookup(:my_cache, "user:1")
# => [{"user:1", %{name: "Alice", role: :admin}}]
```

## Table Types

### :set (default)
One value per key. Duplicate key insertions overwrite.

```elixir
table = :ets.new(:demo, [:set])
:ets.insert(table, {"a", 1})
:ets.insert(table, {"a", 2})   # Overwrites!
:ets.lookup(table, "a")
# => [{"a", 2}]
```

### :ordered_set
Like `:set`, but keys are ordered. Iteration returns entries in key order.

```elixir
table = :ets.new(:demo, [:ordered_set])
:ets.insert(table, {"c", 3})
:ets.insert(table, {"a", 1})
:ets.insert(table, {"b", 2})
:ets.tab2list(table)
# => [{"a", 1}, {"b", 2}, {"c", 3}]
```

### :bag
Multiple values per key, but no exact duplicate tuples.

```elixir
table = :ets.new(:demo, [:bag])
:ets.insert(table, {"x", 1})
:ets.insert(table, {"x", 2})   # OK, different value
:ets.insert(table, {"x", 1})   # Ignored, exact duplicate
:ets.lookup(table, "x")
# => [{"x", 1}, {"x", 2}]
```

### :duplicate_bag
Full duplicates allowed.

```elixir
table = :ets.new(:demo, [:duplicate_bag])
:ets.insert(table, {"x", 1})
:ets.insert(table, {"x", 1})   # Allowed!
:ets.lookup(table, "x")
# => [{"x", 1}, {"x", 1}]
```

## Access Levels

| Level | Owner Process | Other Processes |
|-------|--------------|-----------------|
| `:private` | Read + Write | No access |
| `:protected` (default) | Read + Write | Read only |
| `:public` | Read + Write | Read + Write |

## Core API

```elixir
# Create
table = :ets.new(:name, [:set, :public, :named_table])

# Insert
:ets.insert(table, {"key", "value"})
:ets.insert(table, [{"k1", "v1"}, {"k2", "v2"}])  # Batch

# Lookup
:ets.lookup(table, "key")           # => [{"key", "value"}]
:ets.lookup_element(table, "key", 2) # => "value" (element at position 2)

# Delete
:ets.delete(table, "key")     # Delete by key
:ets.delete(table)             # Delete entire table

# List all
:ets.tab2list(table)           # All entries as list

# Count
:ets.info(table, :size)        # Number of entries

# Pattern matching
:ets.match(table, {:"$1", :_}) # Get all keys
:ets.match_object(table, {"user:" <> :_, :_}) # Get matching tuples
```

## Named Tables

```elixir
# Named table - accessed by atom name
:ets.new(:my_cache, [:named_table])
:ets.insert(:my_cache, {"key", "value"})

# Unnamed table - accessed by reference
ref = :ets.new(:temp, [])
:ets.insert(ref, {"key", "value"})
```

## Match Specifications

```elixir
# Find all entries where value > 10
:ets.select(table, [
  {{"$1", "$2"}, [{:>, "$2", 10}], [:"$_"]}
])

# fun2ms helper for readable match specs
import :ets, only: [fun2ms: 1]
:ets.select(table, fun2ms(fn {key, val} when val > 10 -> {key, val} end))
```

## ETS vs Agent vs GenServer

| | ETS | Agent | GenServer |
|---|-----|-------|-----------|
| **Concurrent reads** | Lock-free, fast | Sequential | Sequential |
| **Writes** | Can race (:public) | Serialized | Serialized |
| **Data location** | Separate memory | Process heap | Process heap |
| **GC impact** | None | GC pauses | GC pauses |
| **Logic** | CRUD only | Simple | Complex |
| **Best for** | Caches, counters | Simple state | Stateful services |

## Ownership & Lifecycle

- The process that creates an ETS table **owns** it.
- When the owner process dies, the table is **automatically deleted**.
- Use `:ets.give_away/3` to transfer ownership.
- For application-lifetime tables, have a supervisor-owned process create them.

## Common Pitfalls

1. **Owner dies = table deleted**: If you create an ETS table in a short-lived process, it disappears. Use a long-lived GenServer or supervisor.
2. **No persistence**: ETS is in-memory only. Use DETS or a database for persistence.
3. **Large copies**: `tab2list/1` copies ALL data into the calling process. Use iterators for large tables.
4. **Race conditions**: With `:public` tables, concurrent writes can cause races. Use `:ets.update_counter/3` for atomic increments.
