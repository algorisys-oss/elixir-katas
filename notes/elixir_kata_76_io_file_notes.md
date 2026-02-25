# Kata 76: IO & File Operations

## The Concept

Elixir provides three key modules for input/output and file system work: **IO** for reading/writing to devices, **File** for file system operations, and **Path** for manipulating file paths as strings.

```elixir
# IO: write to stdout
IO.puts("Hello, world!")

# File: read/write files
{:ok, content} = File.read("data.txt")
File.write("output.txt", "Hello!")

# Path: manipulate paths (pure string operations)
Path.join("lib", "my_app.ex")  # => "lib/my_app.ex"
```

## IO Module

### Output Functions

```elixir
IO.puts("hello")           # prints "hello\n", returns :ok
IO.write("hello")          # prints "hello" (no newline), returns :ok
IO.inspect(%{a: 1})        # prints and RETURNS the value (pipeline-safe)
```

### IO.inspect -- The Debugging Powerhouse

```elixir
# IO.inspect returns its argument, so it slots into any pipeline
[1, 2, 3]
|> Enum.map(& &1 * 2)
|> IO.inspect(label: "doubled")    # prints "doubled: [2, 4, 6]"
|> Enum.sum()                       # continues with [2, 4, 6]
# => 12

# Useful options
IO.inspect(data, label: "debug")        # prefix output with a label
IO.inspect(data, pretty: true)          # multiline formatting
IO.inspect(data, limit: 5)              # truncate long collections
IO.inspect(data, charlists: :as_lists)  # show charlists as integer lists
```

### IO Devices

```elixir
IO.puts(:stdio, "to stdout")     # default device
IO.puts(:stderr, "to stderr")    # error output
```

### IO.gets

```elixir
name = IO.gets("Your name: ") |> String.trim()
# Reads a line from stdin. Always trim -- it includes the newline!
```

## File Module

### Read & Write

```elixir
# Tuple-returning versions (safe)
{:ok, content} = File.read("file.txt")
{:error, :enoent} = File.read("missing.txt")

# Bang versions (raise on error)
content = File.read!("file.txt")        # raises File.Error if missing

# Writing
File.write("out.txt", "content")        # creates or overwrites
File.write("log.txt", "msg\n", [:append])  # append mode
```

### Query & Metadata

```elixir
File.exists?("file.txt")    # true/false
File.dir?("/tmp")            # true if directory
File.stat("file.txt")        # {:ok, %File.Stat{size: ..., type: :regular}}
File.ls("/tmp")               # {:ok, ["file1.txt", "file2.txt"]}
```

### File.stream! (Lazy Reading)

```elixir
# Read a file lazily -- crucial for large files
File.stream!("huge.csv")
|> Stream.map(&String.trim/1)
|> Stream.filter(&(&1 != ""))
|> Enum.take(10)

# File.stream! is also Collectable (write via streaming)
["line 1\n", "line 2\n"]
|> Stream.into(File.stream!("output.txt"))
|> Stream.run()
```

### File Management

```elixir
File.cp("src.txt", "dst.txt")     # copy
File.rm("file.txt")                # delete
File.mkdir_p("path/to/dir")        # create directories recursively
File.rename("old.txt", "new.txt")  # move/rename
```

## Path Module

Path functions are **pure string operations** -- they never touch the filesystem.

```elixir
Path.join("foo", "bar")            # "foo/bar"
Path.join(["usr", "local", "bin"]) # "usr/local/bin"
Path.expand("~/projects")          # "/home/user/projects"
Path.basename("/home/user/app.ex") # "app.ex"
Path.dirname("/home/user/app.ex")  # "/home/user"
Path.extname("photo.jpg")          # ".jpg"
Path.rootname("photo.jpg")         # "photo"
Path.split("/home/user/app.ex")    # ["/", "home", "user", "app.ex"]
Path.type("/absolute/path")        # :absolute
Path.type("relative/path")         # :relative
Path.wildcard("lib/**/*.ex")       # ["lib/app.ex", "lib/web/router.ex", ...]
```

## IO Lists

IO lists are a performance optimization for building output. They are nested lists of strings, charlists, and integer codepoints.

```elixir
# String concatenation: O(n^2) -- copies data at each step
result = "Hello" <> " " <> "World" <> "!"

# IO list: O(n) -- zero-copy until final output
iolist = ["Hello", " ", "World", ?!]
IO.iodata_to_binary(iolist)  # => "Hello World!"
```

### What Can Go in an IO List?

```elixir
# Strings (binaries), integers (codepoints), and nested IO lists
iolist = ["Name: ", "Alice", ?\n, "Age: ", Integer.to_string(30)]
IO.iodata_to_binary(iolist)
# => "Name: Alice\nAge: 30"
```

### Why IO Lists Matter

```elixir
# Phoenix templates compile to IO lists -- that's why they're fast!
# When building HTML, JSON, or any text output in loops, prefer IO lists:
items = ["Elixir", "Erlang", "Phoenix"]

html = [
  "<ul>",
  Enum.map(items, fn item -> ["<li>", item, "</li>"] end),
  "</ul>"
]

IO.iodata_to_binary(html)
# => "<ul><li>Elixir</li><li>Erlang</li><li>Phoenix</li></ul>"
```

### IO List Utility Functions

```elixir
IO.iodata_to_binary(iolist)   # flatten to a single binary string
IO.iodata_length(iolist)      # byte size without flattening
:erlang.iolist_to_binary(iolist)  # same as IO.iodata_to_binary
```

## Common Patterns

### Reading Config Files

```elixir
case File.read("config.json") do
  {:ok, content} -> Jason.decode!(content)
  {:error, :enoent} -> %{}  # default if missing
  {:error, reason} -> raise "Cannot read config: #{reason}"
end
```

### Processing CSV Line by Line

```elixir
File.stream!("data.csv")
|> Stream.drop(1)                          # skip header
|> Stream.map(&String.trim/1)
|> Stream.map(&String.split(&1, ","))
|> Enum.map(fn [name, age | _] ->
  %{name: name, age: String.to_integer(age)}
end)
```

### Safe Temp File Pattern

```elixir
tmp_path = Path.join(System.tmp_dir!(), "myapp_#{System.unique_integer()}.tmp")
File.write!(tmp_path, data)
# ... use the file ...
File.rm(tmp_path)
```

## Common Pitfalls

1. **Forgetting to trim IO.gets**: `IO.gets/1` includes the trailing newline. Always pipe through `String.trim/1`.
2. **Using bang functions without rescue**: `File.read!/1` raises on error. Use the tuple version when the file might not exist.
3. **String concatenation in loops**: Building strings with `<>` in a loop is O(n^2). Use IO lists instead.
4. **Confusing Path and File**: Path functions are pure string operations. They don't check if paths exist. Use `File.exists?/1` for that.
5. **Reading large files eagerly**: `File.read/1` loads the entire file into memory. Use `File.stream!/1` for large files.
6. **Forgetting :append mode**: `File.write/2` overwrites by default. Pass `[:append]` to add to an existing file.
