# Kata 77: Erlang Interop

## The Concept

Elixir runs on the BEAM virtual machine and can call **any Erlang module** with zero overhead. Erlang modules are referenced as atoms, and their functions are called with the dot syntax.

```elixir
# Elixir syntax: :module.function(args)
:math.sqrt(144)    # => 12.0
:rand.uniform(10)  # => 7 (random 1-10)

# Equivalent Erlang syntax: module:function(Args)
# math:sqrt(144).
# rand:uniform(10).
```

## Calling Convention

Erlang modules are atoms in Elixir. The colon prefix makes it an atom, and the dot calls the function:

```elixir
:module_name.function_name(arg1, arg2)
```

This is a direct function call -- no wrapper, no adapter, no performance penalty.

## Commonly Used Erlang Modules

### :math -- Mathematical Functions

```elixir
:math.pi()              # 3.141592653589793
:math.sqrt(2)           # 1.4142135623730951
:math.pow(2, 10)        # 1024.0 (always returns float)
:math.log(100)          # 4.605... (natural log)
:math.log2(1024)        # 10.0
:math.log10(1000)       # 3.0
:math.sin(:math.pi())   # ~0.0 (trig functions use radians)
:math.ceil(3.2)         # 4.0
:math.floor(3.8)        # 3.0
```

### :timer -- Time Utilities

```elixir
:timer.seconds(5)       # 5000 (milliseconds)
:timer.minutes(2)       # 120000
:timer.hours(1)         # 3600000

# Measure execution time
{microseconds, result} = :timer.tc(fn -> Enum.sum(1..1_000_000) end)
milliseconds = microseconds / 1000

# Sleep (blocks the current process)
:timer.sleep(1000)      # sleep 1 second
```

### :crypto -- Cryptography

```elixir
# Hashing
:crypto.hash(:sha256, "hello") |> Base.encode16(case: :lower)
# => "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"

# Secure random bytes
:crypto.strong_rand_bytes(16) |> Base.encode16()
# => "A1B2C3D4E5F6..." (random hex string)

# HMAC
:crypto.mac(:hmac, :sha256, "secret_key", "message")
|> Base.encode16(case: :lower)
```

### :rand -- Random Numbers

```elixir
:rand.uniform()         # random float 0.0..1.0
:rand.uniform(100)      # random integer 1..100
:rand.uniform_real()    # random float excluding 0.0

# Seeding (for reproducible sequences)
:rand.seed(:exsss, {1, 2, 3})
:rand.uniform(100)      # always same sequence with same seed
```

### :erlang -- Core BEAM Functions

```elixir
# System information
:erlang.system_info(:process_count)   # running processes
:erlang.system_info(:atom_count)      # atoms in table
:erlang.system_info(:schedulers)      # scheduler threads
:erlang.system_info(:otp_release)     # OTP version

# Memory
:erlang.memory(:total)                # total bytes
:erlang.memory()                      # full breakdown

# Process info
self() |> :erlang.process_info(:memory)  # memory used by current process

# Serialization
binary = :erlang.term_to_binary(%{key: "value"})
:erlang.binary_to_term(binary)
# => %{key: "value"}

# Type conversions
:erlang.atom_to_binary(:hello)        # "hello"
:erlang.binary_to_atom("hello")       # :hello (use with caution!)
```

### :calendar -- Date & Time

```elixir
:calendar.local_time()
# => {{2025, 1, 15}, {14, 30, 45}}

:calendar.universal_time()
# => {{2025, 1, 15}, {19, 30, 45}}

:calendar.day_of_the_week(2025, 1, 1)
# => 3 (Wednesday, 1=Monday..7=Sunday)

:calendar.valid_date(2024, 2, 29)
# => true (leap year)
```

### :lists -- List Operations

```elixir
:lists.flatten([1, [2, [3, 4]], 5])   # [1, 2, 3, 4, 5]
:lists.seq(1, 10)                      # [1, 2, 3, ..., 10]
:lists.seq(1, 10, 2)                   # [1, 3, 5, 7, 9] (with step)
:lists.keyfind(:b, 1, [a: 1, b: 2])   # {:b, 2}
:lists.usort([3, 1, 2, 1, 3])         # [1, 2, 3] (unique + sort)
```

### :string -- Charlist Operations

```elixir
# WARNING: :string works on charlists, not binaries!
:string.uppercase('hello')            # 'HELLO'
:string.lowercase('HELLO')            # 'hello'
:string.tokens('hello world', ' ')    # ['hello', 'world']

# Convert between charlists and binaries
String.to_charlist("hello")           # 'hello'
List.to_string('hello')               # "hello"
```

## Data Type Mapping

This is the most important concept for Erlang interop:

| Elixir | Erlang | Convert To Erlang | Convert To Elixir |
|--------|--------|-------------------|-------------------|
| `"hello"` (binary) | `'hello'` (charlist) | `String.to_charlist/1` | `List.to_string/1` |
| `%{a: 1}` (map) | `[{a, 1}]` (proplist) | `Map.to_list/1` | `Map.new/1` |
| `:atom` | `atom` | same | same |
| `{:ok, 1}` | `{ok, 1}` | same | same |
| `nil` | `nil` | same atom | same atom |

### The String/Charlist Gotcha

```elixir
# This is the #1 Erlang interop issue!
"hello" == 'hello'  # false!

# "hello" is a binary (Elixir string)
is_binary("hello")  # true

# 'hello' is a charlist (list of integers)
is_list('hello')    # true
'hello' == [104, 101, 108, 108, 111]  # true

# When calling Erlang functions that expect strings:
:string.uppercase("hello")     # ** (FunctionClauseError)
:string.uppercase('hello')     # 'HELLO' -- correct!

# When getting charlists from Erlang, convert back:
:string.uppercase('hello') |> List.to_string()  # "HELLO"
```

## Discovering Available Modules

```elixir
# List all loaded modules
:code.all_loaded() |> length()

# Check if a module exists
:code.ensure_loaded(:crypto)  # {:module, :crypto}

# Get exported functions
:math.module_info(:exports)
# => [pi: 0, sqrt: 1, pow: 2, ...]

# Elixir wrapper
Math.__info__(:functions)  # only for Elixir modules
```

## Common Patterns

### Using :timer for GenServer Timeouts

```elixir
defmodule MyWorker do
  use GenServer

  def init(state) do
    # Schedule periodic work
    Process.send_after(self(), :tick, :timer.seconds(30))
    {:ok, state}
  end

  def handle_info(:tick, state) do
    # do work...
    Process.send_after(self(), :tick, :timer.seconds(30))
    {:noreply, state}
  end
end
```

### Using :crypto for Token Generation

```elixir
defmodule Token do
  def generate(length \\ 32) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, length)
  end
end
```

### Using :erlang.term_to_binary for Caching

```elixir
# Serialize any Elixir term to binary (for storage, caching, etc.)
data = %{users: [%{name: "Alice"}, %{name: "Bob"}]}
binary = :erlang.term_to_binary(data)
# Store binary in Redis, file, etc.

# Deserialize
data = :erlang.binary_to_term(binary)
```

## Common Pitfalls

1. **Strings vs charlists**: Erlang string functions (`:`string`) expect charlists (`'hello'`), not Elixir binaries (`"hello"`). Always convert with `String.to_charlist/1`.
2. **:math.pow returns float**: `:math.pow(2, 10)` returns `1024.0`, not `1024`. Use `trunc/1` or `round/1` for integers.
3. **:erlang.binary_to_atom is dangerous**: Creating atoms from user input can exhaust the atom table (atoms are never garbage collected). Use `String.to_existing_atom/1` instead.
4. **:timer.sleep blocks the process**: It blocks the current BEAM process, not a system thread. Other processes continue. But don't use it in GenServer callbacks -- use `Process.send_after/3` instead.
5. **Prefer Elixir wrappers when available**: Use `Enum` over `:lists`, `String` over `:string`, `DateTime` over `:calendar`. Erlang functions are a fallback for when no Elixir equivalent exists.
6. **:erlang.binary_to_term is unsafe**: Deserializing untrusted data can create atoms or execute code. Use the `:safe` option: `:erlang.binary_to_term(binary, [:safe])`.
