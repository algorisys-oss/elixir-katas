# Kata 78: ExUnit Testing Basics

## The Concept

**ExUnit** is Elixir's built-in testing framework. Every Mix project comes with ExUnit pre-configured. It provides a rich set of assertions, test organization tools, setup callbacks, async test execution, and doctest support.

```elixir
# test/test_helper.exs (auto-generated)
ExUnit.start()

# test/my_module_test.exs
defmodule MyModuleTest do
  use ExUnit.Case, async: true

  test "greets the world" do
    assert MyModule.hello() == :world
  end
end
```

## Running Tests

```bash
mix test                              # run all tests
mix test test/my_module_test.exs      # run a specific file
mix test test/my_module_test.exs:5    # run test at line 5
mix test --only slow                  # run only tagged tests
mix test --exclude slow               # skip tagged tests
mix test --failed                     # re-run only failures
mix test --trace                      # show test names as they run
mix test --seed 0                     # use a fixed seed for ordering
```

## Assertions

### assert / refute

```elixir
# assert checks truthiness
assert 1 + 1 == 2
assert {:ok, _value} = {:ok, 42}       # pattern match assertion
assert :apple in [:apple, :banana]      # membership check
assert is_binary("hello")              # guard-style checks

# refute checks falsiness (opposite of assert)
refute 1 + 1 == 3
refute nil
refute false
```

### assert_raise

```elixir
# Verify a specific exception is raised
assert_raise RuntimeError, fn ->
  raise "boom"
end

# Also check the message
assert_raise RuntimeError, "boom", fn ->
  raise "boom"
end

# Works with any exception type
assert_raise ArithmeticError, fn -> 1 / 0 end
assert_raise ArgumentError, fn -> String.to_integer("abc") end
```

### assert_receive / refute_receive

```elixir
# Wait for a message in the test process mailbox
send(self(), :hello)
assert_receive :hello                    # default 100ms timeout

# Pattern matching on received messages
send(self(), {:ok, 42})
assert_receive {:ok, value}              # value is now bound to 42

# Custom timeout
send(self(), :done)
assert_receive :done, 5000              # wait up to 5 seconds

# Assert a message is NOT received
refute_receive :nope, 100               # passes if no :nope within 100ms
```

### assert_in_delta

```elixir
# For floating-point comparisons (avoids precision issues)
assert_in_delta 3.14159, 3.14, 0.01    # differ by at most 0.01
assert_in_delta 0.1 + 0.2, 0.3, 1.0e-10

refute_in_delta 3.14, 4.0, 0.5         # differ by MORE than 0.5
```

## Test Organization

### describe blocks

Group related tests and apply shared setup:

```elixir
defmodule CalculatorTest do
  use ExUnit.Case, async: true

  describe "add/2" do
    test "adds positive numbers" do
      assert Calculator.add(1, 2) == 3
    end

    test "adds negative numbers" do
      assert Calculator.add(-1, -2) == -3
    end

    test "adding zero returns the same number" do
      assert Calculator.add(5, 0) == 5
    end
  end

  describe "divide/2" do
    test "divides evenly" do
      assert Calculator.divide(10, 2) == {:ok, 5.0}
    end

    test "returns error for division by zero" do
      assert Calculator.divide(10, 0) == {:error, :div_by_zero}
    end
  end
end
```

### setup and setup_all

```elixir
defmodule UserTest do
  use ExUnit.Case, async: true

  # Runs before EACH test
  setup do
    user = %{name: "Alice", age: 30, role: :admin}
    {:ok, user: user}
  end

  # Access setup data via the test context
  test "user has a name", %{user: user} do
    assert user.name == "Alice"
  end

  # setup_all runs ONCE before all tests in the module
  # Useful for expensive setup like database connections
  setup_all do
    {:ok, shared_data: "available to all tests"}
  end
end
```

### Setup inside describe

```elixir
describe "admin users" do
  setup do
    {:ok, user: %{role: :admin, permissions: [:read, :write, :delete]}}
  end

  test "has delete permission", %{user: user} do
    assert :delete in user.permissions
  end
end

describe "regular users" do
  setup do
    {:ok, user: %{role: :user, permissions: [:read]}}
  end

  test "cannot delete", %{user: user} do
    refute :delete in user.permissions
  end
end
```

## Async Tests

```elixir
defmodule FastTest do
  use ExUnit.Case, async: true  # tests in this module run concurrently

  # Safe when tests don't share mutable state (databases, files, etc.)
  test "pure function 1" do
    assert String.upcase("hello") == "HELLO"
  end

  test "pure function 2" do
    assert Enum.sum([1, 2, 3]) == 6
  end
end
```

**When NOT to use async: true:**
- Tests that write to a shared database
- Tests that modify files on disk
- Tests that use global process state (e.g., Application.put_env)

## Tags

```elixir
# Tag individual tests
@tag :slow
test "a slow integration test" do
  Process.sleep(5000)
  assert true
end

# Skip a test
@tag :skip
test "work in progress" do
  assert false
end

# Tag all tests in a describe block
@describetag :api
describe "API tests" do
  test "fetches data" do
    assert true
  end
end

# Tag with a value
@tag timeout: 10_000
test "needs more time", context do
  assert context[:timeout] == 10_000
end
```

## doctest

Automatically test `iex>` examples in your `@doc` attributes:

```elixir
# In the module:
defmodule StringHelper do
  @doc """
  Upcases the first letter of a string.

  ## Examples

      iex> StringHelper.upcase_first("hello")
      "Hello"

      iex> StringHelper.upcase_first("")
      ""
  """
  def upcase_first(<<first::utf8, rest::binary>>),
    do: String.upcase(<<first::utf8>>) <> rest
  def upcase_first(""), do: ""
end

# In the test file:
defmodule StringHelperTest do
  use ExUnit.Case, async: true
  doctest StringHelper
end
```

## Common Test Patterns

### Testing {:ok, _} / {:error, _}

```elixir
test "successful operation" do
  assert {:ok, result} = MyModule.do_thing("valid_input")
  assert result.status == :active
end

test "failure case" do
  assert {:error, :invalid_input} = MyModule.do_thing(nil)
end
```

### Testing Lists

```elixir
test "returns expected items" do
  items = Store.list_items()

  assert length(items) == 3
  assert "apple" in Enum.map(items, & &1.name)
  assert Enum.all?(items, & &1.price > 0)
end
```

### Testing Exceptions

```elixir
test "raises on bad input" do
  assert_raise ArgumentError, fn ->
    Parser.parse!(nil)
  end
end

test "raises with specific message" do
  assert_raise RuntimeError, "not found", fn ->
    Repo.get!(:users, -1)
  end
end
```

### Testing Maps and Structs

```elixir
test "returns user with expected fields" do
  user = Users.build("Alice", "alice@example.com")

  # Pattern match -- extra keys are OK
  assert %{name: "Alice", email: "alice@example.com"} = user
end
```

## Test Naming Conventions

- Test files go in `test/` and end with `_test.exs`
- Test file names mirror the source: `lib/my_app/parser.ex` -> `test/my_app/parser_test.exs`
- Test names should describe the behavior: `test "returns error when email is missing"`
- Use `describe` to group by function: `describe "parse/1" do`

## Key Takeaways

1. **assert and refute are your workhorses** -- assert checks truthiness, refute checks falsiness. Pattern-matching asserts are especially powerful in Elixir.
2. **describe groups related tests** -- each describe block can have its own setup callback, keeping tests focused and DRY.
3. **setup runs before each test** -- setup_all runs once before all tests. Return `{:ok, map}` to make data available via the test context.
4. **async: true enables parallel tests** -- only safe when tests don't share mutable state (databases, files, global config).
5. **doctest verifies documentation examples** -- add `doctest MyModule` in your test file to automatically test all `iex>` examples in @doc attributes.
