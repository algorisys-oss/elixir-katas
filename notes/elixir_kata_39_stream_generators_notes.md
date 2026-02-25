# Kata 39: Stream Generators

## The Concept

Stream generators create sequences on-the-fly, including **infinite sequences**. They produce values lazily -- only when requested -- making them memory-efficient for generating large or unbounded data.

## Stream.iterate/2

Generates an infinite stream by repeatedly applying a function to the previous value:

```elixir
# Syntax: Stream.iterate(start_value, next_fn)

# Powers of 2
Stream.iterate(1, &(&1 * 2)) |> Enum.take(8)
# => [1, 2, 4, 8, 16, 32, 64, 128]

# Counting by 3s
Stream.iterate(0, &(&1 + 3)) |> Enum.take(6)
# => [0, 3, 6, 9, 12, 15]
```

**Key property:** The emitted value IS the accumulator. The function takes the current value and returns the next value.

## Stream.unfold/2

The most flexible generator. The function receives an accumulator and returns either `{emit_value, next_acc}` to continue, or `nil` to halt:

```elixir
# Syntax: Stream.unfold(initial_acc, fn acc -> {emit, next_acc} | nil end)

# Fibonacci sequence
Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
|> Enum.take(10)
# => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
# Accumulator: {a, b} pair
# Emits: a (first of pair)
# Next acc: {b, a+b}

# Countdown (halts at 0)
Stream.unfold(5, fn
  0 -> nil              # halt the stream
  n -> {n, n - 1}       # emit n, continue with n-1
end) |> Enum.to_list()
# => [5, 4, 3, 2, 1]
```

**Key insight:** Unlike `iterate/2`, the emitted value can differ from the accumulator. This separation enables complex generation patterns.

## Stream.cycle/1

Creates an infinite stream that repeats the given enumerable forever:

```elixir
# Repeat a pattern
Stream.cycle(["red", "green", "blue"]) |> Enum.take(7)
# => ["red", "green", "blue", "red", "green", "blue", "red"]

# Round-robin assignment
teams = ["Alpha", "Beta", "Gamma"]
tasks = ["T1", "T2", "T3", "T4", "T5"]

Stream.cycle(teams) |> Stream.zip(tasks) |> Enum.to_list()
# => [{"Alpha", "T1"}, {"Beta", "T2"}, {"Gamma", "T3"},
#     {"Alpha", "T4"}, {"Beta", "T5"}]
```

## Stream.resource/3

For streams backed by external resources (files, databases, APIs). Manages setup, emission, and cleanup:

```elixir
# Syntax: Stream.resource(start_fn, next_fn, close_fn)

# Read file lines lazily
Stream.resource(
  fn -> File.open!("data.txt") end,        # setup
  fn file ->
    case IO.read(file, :line) do
      :eof -> {:halt, file}                  # signal end
      line -> {[String.trim(line)], file}    # emit line
    end
  end,
  fn file -> File.close(file) end           # cleanup
)
```

## Choosing the Right Generator

| Generator | Use When | Halts? |
|-----------|----------|--------|
| `iterate/2` | Simple: next value depends only on current value | Never (infinite) |
| `unfold/2` | Need separate emit vs accumulator, or need to halt | When function returns nil |
| `cycle/1` | Repeating a known pattern | Never (infinite) |
| `resource/3` | External resources requiring setup/cleanup | When next_fn returns {:halt, acc} |
| `repeatedly/1` | Same computation each time (e.g., random numbers) | Never (infinite) |

## Practical Example: Paginated API

```elixir
# Simulate fetching pages from an API
fetch_all_items = fn ->
  Stream.unfold(1, fn page ->
    case MyAPI.fetch_page(page) do
      {:ok, %{items: items, has_next: true}} ->
        {items, page + 1}
      {:ok, %{items: items, has_next: false}} ->
        {items, nil}
      _ ->
        nil
    end
  end)
  |> Stream.flat_map(&Function.identity/1)
  |> Enum.to_list()
end
```

## Fibonacci Deep Dive

The Fibonacci sequence demonstrates unfold beautifully:

```elixir
fib = Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)

# Step by step:
# acc = {0, 1} => emit 0, next = {1, 1}
# acc = {1, 1} => emit 1, next = {1, 2}
# acc = {1, 2} => emit 1, next = {2, 3}
# acc = {2, 3} => emit 2, next = {3, 5}
# acc = {3, 5} => emit 3, next = {5, 8}
# ...

fib |> Enum.take(10)
# => [0, 1, 1, 2, 3, 5, 8, 13, 21, 34]
```

## Common Pitfalls

1. **Infinite loops**: Generators without halt conditions produce infinite streams. Always use `Enum.take/2`, `Enum.take_while/2`, or similar to bound them.
2. **iterate vs unfold**: If you need to halt the stream or emit a different value than the next state, use `unfold`. If next value = emitted value, `iterate` is simpler.
3. **Performance of cycle**: `Stream.cycle/1` holds the entire source in memory. Don't cycle over huge collections.
4. **Resource cleanup**: Always use `Stream.resource/3` (not `unfold`) when working with external resources that need cleanup.
