# Kata 54: Use, Import, Alias & Require

## The Concept

Elixir provides four directives for working with modules:
- **alias** -- shorten module names
- **import** -- bring functions into scope
- **require** -- enable macro usage
- **use** -- invoke the `__using__` macro

All four are **lexically scoped** -- they only apply within the module, function, or block where they appear.

## alias

Creates a shortcut for a module name. Does not import any functions.

```elixir
alias MyApp.Accounts.User

# Now you can use User instead of MyApp.Accounts.User
User.get(1)
```

### Custom alias name

```elixir
alias MyApp.Accounts.User, as: U
U.get(1)
```

### Multi-alias

```elixir
alias MyApp.Accounts.{User, Permission, Role}

# Equivalent to:
alias MyApp.Accounts.User
alias MyApp.Accounts.Permission
alias MyApp.Accounts.Role
```

### Lexical scope

```elixir
defmodule MyModule do
  alias MyApp.User  # Available in entire module

  def example do
    alias MyApp.Admin  # Only available in this function
    {User.get(1), Admin.get(1)}
  end

  def another do
    # Admin is NOT available here
    User.get(1)
  end
end
```

**When to use**: Almost always when working with deeply nested module names. It is the most commonly used directive.

## import

Brings functions from another module into scope so you can call them without the module prefix.

```elixir
import Enum

# Can now call map directly instead of Enum.map
map([1, 2, 3], &(&1 * 2))
```

### Selective import with :only

```elixir
import Enum, only: [map: 2, filter: 2, reduce: 3]

# Only these three functions are imported
map([1, 2, 3], &(&1 * 2))
```

### Import with :except

```elixir
import Enum, except: [split: 2]
```

### Import only macros or functions

```elixir
import Kernel, only: :macros
import Kernel, only: :functions
```

**When to use**: When you call functions from another module very frequently. Always prefer `only:` to be explicit.

**Best practice**: In most code, prefer qualified calls (`Enum.map`) over imports. Imports are most useful in tests, DSLs, and when building custom macros.

## require

Makes macros from another module available. Required before you can use a module's macros.

```elixir
require Logger

def process(data) do
  Logger.info("Processing: #{inspect(data)}")
end

# Without require:
# ** (CompileError) you must require Logger before invoking the macro Logger.info/1
```

### Why require exists

Macros are expanded at **compile time**. The compiler needs to know about the macro module before it encounters the macro call. `require` ensures the module is compiled and its macros are registered.

```elixir
require Integer

def even?(n) when Integer.is_even(n), do: true
def even?(_), do: false

# Integer.is_even is a macro that expands to: rem(n, 2) == 0
```

**When to use**: When you need to use macros from another module. Logger is the most common example.

**Note**: `import` automatically requires the module. `use` also automatically requires the module.

## use

Invokes the `__using__/1` macro from another module. This is the most powerful directive.

```elixir
# When you write:
use GenServer

# It's equivalent to:
require GenServer
GenServer.__using__([])
```

### What __using__ can do

The `__using__` macro can inject **any code** into your module:

```elixir
defmodule MyLib do
  defmacro __using__(opts) do
    quote do
      @behaviour MyLib
      import MyLib.Helpers
      alias MyLib.{Config, State}

      def default_option, do: unquote(opts[:default] || :none)
    end
  end
end

defmodule MyModule do
  use MyLib, default: :something
  # Now has @behaviour, imports, aliases, and default_option/0
end
```

### use with options

```elixir
use GenServer, restart: :temporary
use Ecto.Schema, prefix: "my_app"
use Phoenix.Controller, namespace: MyAppWeb
```

Options are passed directly to `__using__/1`.

**When to use**: When a library provides `__using__` for setup (GenServer, Phoenix.Controller, Ecto.Schema, etc.).

## The Hierarchy

```
use = require + call __using__ macro
  (can inject imports, aliases, behaviours, functions, anything)

import = require + bring functions into scope
  (automatically requires the module)

require = make macros available
  (only needed for macros)

alias = rename a module
  (just a name shortcut, no code changes)
```

## Best Practices

1. **Prefer the least powerful directive**: `alias` > `require` > `import` (with `:only`) > `use`
2. **Always use `:only` with import**: `import Enum, only: [map: 2]` not `import Enum`
3. **Know what `use` does**: Read the documentation of any module before you `use` it
4. **Keep imports small**: Import only what you need
5. **Alias deeply nested modules**: `alias MyApp.Accounts.User` keeps code clean
6. **Prefer qualified calls**: `Enum.map` is clearer than importing `map`

## Quick Reference

| Directive | What it does | Requires | Example |
|-----------|-------------|----------|---------|
| `alias` | Shortens module name | Nothing | `alias MyApp.User` |
| `import` | Brings functions into scope | Nothing | `import Enum, only: [map: 2]` |
| `require` | Enables macro usage | Module compiled | `require Logger` |
| `use` | Calls `__using__` macro | `__using__/1` defined | `use GenServer` |

## Common Pitfalls

1. **import without :only**: Importing everything can cause name collisions and confusion.
2. **Forgetting require**: Using a macro without require gives a confusing compile error.
3. **use hides complexity**: `use SomeModule` might inject a lot of code. Always check the docs.
4. **Scope confusion**: All directives are lexically scoped. An import inside a function does not affect other functions.
5. **Circular dependencies**: `import`/`require`/`use` can create circular module dependencies that fail at compile time.
