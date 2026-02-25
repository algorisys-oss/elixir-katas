defmodule ElixirKatasWeb.ElixirKataData do
  @moduledoc """
  Shared data module for Elixir Katas sections, tags, and colors.
  Used by both the sidebar layout and the index page.
  """

  @tag_colors %{
    "types" => "bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-200",
    "pattern-matching" => "bg-purple-100 text-purple-800 dark:bg-purple-900 dark:text-purple-200",
    "functions" => "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200",
    "control-flow" => "bg-orange-100 text-orange-800 dark:bg-orange-900 dark:text-orange-200",
    "enum" => "bg-cyan-100 text-cyan-800 dark:bg-cyan-900 dark:text-cyan-200",
    "streams" => "bg-indigo-100 text-indigo-800 dark:bg-indigo-900 dark:text-indigo-200",
    "strings" => "bg-pink-100 text-pink-800 dark:bg-pink-900 dark:text-pink-200",
    "structs" => "bg-amber-100 text-amber-800 dark:bg-amber-900 dark:text-amber-200",
    "protocols" => "bg-violet-100 text-violet-800 dark:bg-violet-900 dark:text-violet-200",
    "processes" => "bg-rose-100 text-rose-800 dark:bg-rose-900 dark:text-rose-200",
    "otp" => "bg-emerald-100 text-emerald-800 dark:bg-emerald-900 dark:text-emerald-200",
    "metaprogramming" => "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200",
    "io" => "bg-teal-100 text-teal-800 dark:bg-teal-900 dark:text-teal-200",
    "testing" => "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200",
    "debugging" => "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200",
    "errors" => "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200"
  }

  def all_tags, do: Map.keys(@tag_colors) |> Enum.sort()
  def tag_color(tag), do: Map.get(@tag_colors, tag, "bg-gray-100 text-gray-800 dark:bg-gray-700 dark:text-gray-200")

  def sections do
    [
      %{title: "Section 0: Foundations", katas: [
        %{num: "00", slug: "00-the-beginning", label: "00 - The Beginning", color: "bg-violet-500", tags: ["processes", "otp"], description: "CPU cores, concurrency vs parallelism, threads vs processes, Actor model, OTP overview, let it crash"}
      ]},
      %{title: "Section 1: Types, Operators & Basics", katas: [
        %{num: "01", slug: "01-type-explorer", label: "01 - Type Explorer", color: "bg-emerald-400", tags: ["types"], description: "Basic types: integer, float, string, atom, boolean, nil"},
        %{num: "02", slug: "02-arithmetic-lab", label: "02 - Arithmetic Lab", color: "bg-teal-400", tags: ["types"], description: "Operators: +, -, *, /, div, rem; float vs integer division"},
        %{num: "03", slug: "03-string-playground", label: "03 - String Playground", color: "bg-emerald-500", tags: ["types", "strings"], description: "Concatenation, interpolation, String module functions"},
        %{num: "04", slug: "04-atoms-booleans", label: "04 - Atoms & Booleans", color: "bg-teal-500", tags: ["types"], description: "Atoms, boolean operators (and/or vs &&/||), truthy/falsy"},
        %{num: "05", slug: "05-comparison", label: "05 - Comparison", color: "bg-emerald-600", tags: ["types"], description: "==, ===, <, >, term ordering across types"},
        %{num: "06", slug: "06-tuples", label: "06 - Tuples", color: "bg-teal-600", tags: ["types"], description: "{a, b}, elem/2, put_elem/3, {:ok, val}/{:error, reason}"},
        %{num: "07", slug: "07-lists", label: "07 - Lists", color: "bg-emerald-400", tags: ["types"], description: "[head|tail], hd/tl, ++, --, prepend vs append performance"},
        %{num: "08", slug: "08-maps-keywords", label: "08 - Maps & Keywords", color: "bg-teal-400", tags: ["types"], description: "%{}, Map module, keyword lists, when to use each"}
      ]},
      %{title: "Section 2: Pattern Matching", katas: [
        %{num: "09", slug: "09-match-operator", label: "09 - Match Operator", color: "bg-emerald-500", tags: ["pattern-matching"], description: "= is match not assignment, binding vs matching"},
        %{num: "10", slug: "10-tuple-matching", label: "10 - Tuple Matching", color: "bg-teal-500", tags: ["pattern-matching", "types"], description: "{:ok, val}, {:error, reason} destructuring"},
        %{num: "11", slug: "11-list-matching", label: "11 - List Matching", color: "bg-emerald-600", tags: ["pattern-matching", "types"], description: "[h|t], fixed-length, nested matching"},
        %{num: "12", slug: "12-map-matching", label: "12 - Map Matching", color: "bg-teal-600", tags: ["pattern-matching", "types"], description: "Partial map matching, nested extraction"},
        %{num: "13", slug: "13-pin-operator", label: "13 - Pin Operator", color: "bg-emerald-400", tags: ["pattern-matching"], description: "^ to match against existing bindings"},
        %{num: "14", slug: "14-multi-clause", label: "14 - Multi-clause", color: "bg-teal-400", tags: ["pattern-matching", "functions"], description: "Multiple function clauses, first-match-wins"},
        %{num: "15", slug: "15-destructuring", label: "15 - Destructuring", color: "bg-emerald-500", tags: ["pattern-matching"], description: "Complex nested structures, chained extraction"},
        %{num: "16", slug: "16-matching-challenges", label: "16 - Challenges", color: "bg-teal-500", tags: ["pattern-matching"], description: "Pattern matching mini-challenges with scoring"}
      ]},
      %{title: "Section 3: Functions", katas: [
        %{num: "17", slug: "17-anonymous-functions", label: "17 - Anonymous Functions", color: "bg-emerald-500", tags: ["functions"], description: "fn -> end, closures, .() calling"},
        %{num: "18", slug: "18-named-functions", label: "18 - Named Functions", color: "bg-teal-500", tags: ["functions"], description: "def/defp, arity, defmodule"},
        %{num: "19", slug: "19-guards", label: "19 - Guards", color: "bg-emerald-600", tags: ["functions", "pattern-matching"], description: "when clauses, allowed guard expressions"},
        %{num: "20", slug: "20-default-arguments", label: "20 - Default Arguments", color: "bg-teal-600", tags: ["functions"], description: "\\\\ syntax, generated arities"},
        %{num: "21", slug: "21-capture-operator", label: "21 - Capture Operator", color: "bg-emerald-400", tags: ["functions"], description: "&, &Module.fun/arity, &(&1 + 1) shorthand"},
        %{num: "22", slug: "22-recursion", label: "22 - Recursion", color: "bg-teal-400", tags: ["functions"], description: "Base case + recursive case, visual call stack"},
        %{num: "23", slug: "23-tail-call", label: "23 - Tail Call", color: "bg-emerald-500", tags: ["functions"], description: "Accumulators, stack depth comparison"},
        %{num: "24", slug: "24-higher-order", label: "24 - Higher-Order Functions", color: "bg-teal-500", tags: ["functions"], description: "Functions as values, composition"}
      ]},
      %{title: "Section 4: Control Flow", katas: [
        %{num: "25", slug: "25-case-expressions", label: "25 - Case Expressions", color: "bg-emerald-400", tags: ["control-flow", "pattern-matching"], description: "Pattern matching on values, guards in case"},
        %{num: "26", slug: "26-cond-expressions", label: "26 - Cond Expressions", color: "bg-teal-400", tags: ["control-flow"], description: "Boolean conditions, first-true-wins"},
        %{num: "27", slug: "27-if-unless", label: "27 - If/Unless", color: "bg-emerald-500", tags: ["control-flow"], description: "Simple conditionals, macros not special forms"},
        %{num: "28", slug: "28-with-expressions", label: "28 - With Expressions", color: "bg-teal-500", tags: ["control-flow", "pattern-matching"], description: "Happy path chaining, else clauses"},
        %{num: "29", slug: "29-pipe-operator", label: "29 - Pipe Operator", color: "bg-emerald-600", tags: ["control-flow", "functions"], description: "|> pipelines, nested-to-piped refactoring"},
        %{num: "30", slug: "30-comprehensions", label: "30 - Comprehensions", color: "bg-teal-600", tags: ["control-flow", "enum"], description: "for generators, filters, :into"},
        %{num: "31", slug: "31-try-rescue", label: "31 - Try/Rescue", color: "bg-emerald-400", tags: ["control-flow", "errors"], description: "Error handling, let it crash philosophy"}
      ]},
      %{title: "Section 5: Enum & Stream", katas: [
        %{num: "32", slug: "32-enum-basics", label: "32 - Enum Basics", color: "bg-emerald-500", tags: ["enum"], description: "map, filter, reduce, each"},
        %{num: "33", slug: "33-enum-transforms", label: "33 - Enum Transforms", color: "bg-teal-500", tags: ["enum"], description: "sort, reverse, uniq, flat_map, zip, chunk_every"},
        %{num: "34", slug: "34-enum-aggregates", label: "34 - Enum Aggregates", color: "bg-emerald-600", tags: ["enum"], description: "count, sum, min/max, frequencies, group_by"},
        %{num: "35", slug: "35-enum-search", label: "35 - Enum Search", color: "bg-teal-600", tags: ["enum"], description: "find, any?, all?, take_while, drop_while"},
        %{num: "36", slug: "36-reduce-mastery", label: "36 - Reduce Mastery", color: "bg-emerald-400", tags: ["enum", "functions"], description: "Step-through animation, implement map/filter with reduce"},
        %{num: "37", slug: "37-mapset", label: "37 - MapSet", color: "bg-teal-400", tags: ["types", "enum"], description: "Set operations: union, intersection, difference"},
        %{num: "38", slug: "38-streams-lazy", label: "38 - Streams: Lazy", color: "bg-emerald-500", tags: ["streams", "enum"], description: "Eager vs lazy, Stream.map/filter/take"},
        %{num: "39", slug: "39-stream-generators", label: "39 - Stream Generators", color: "bg-teal-500", tags: ["streams"], description: "iterate, unfold, cycle, infinite streams"},
        %{num: "40", slug: "40-ranges-slicing", label: "40 - Ranges & Slicing", color: "bg-emerald-600", tags: ["types", "enum"], description: "1..10, step ranges, Enum.slice/take/drop"}
      ]},
      %{title: "Section 6: Strings & Binaries", katas: [
        %{num: "41", slug: "41-string-deep-dive", label: "41 - String Deep Dive", color: "bg-emerald-400", tags: ["strings", "types"], description: "UTF-8 binaries, byte_size vs String.length, graphemes"},
        %{num: "42", slug: "42-charlists-strings", label: "42 - Charlists vs Strings", color: "bg-teal-400", tags: ["strings", "types"], description: "Single vs double quotes, conversion"},
        %{num: "43", slug: "43-string-matching", label: "43 - String Matching", color: "bg-emerald-500", tags: ["strings", "pattern-matching"], description: "Binary matching <<h::utf8, rest::binary>>"},
        %{num: "44", slug: "44-regex", label: "44 - Regex", color: "bg-teal-500", tags: ["strings"], description: "~r//, Regex.match?/run/scan/replace"},
        %{num: "45", slug: "45-sigils", label: "45 - Sigils", color: "bg-emerald-600", tags: ["strings", "metaprogramming"], description: "~s, ~w, ~D, ~T, ~r, uppercase vs lowercase"},
        %{num: "46", slug: "46-formatting", label: "46 - Formatting", color: "bg-teal-600", tags: ["strings", "io"], description: "String.pad, IO.inspect options, number formatting"}
      ]},
      %{title: "Section 7: Structs & Protocols", katas: [
        %{num: "47", slug: "47-structs", label: "47 - Structs", color: "bg-emerald-400", tags: ["structs", "types"], description: "defstruct, @enforce_keys, update syntax"},
        %{num: "48", slug: "48-struct-validation", label: "48 - Struct Validation", color: "bg-teal-400", tags: ["structs"], description: "Constructor patterns, new/1 returning tagged tuples"},
        %{num: "49", slug: "49-protocols", label: "49 - Protocols", color: "bg-emerald-500", tags: ["protocols"], description: "defprotocol/defimpl, dispatch on type"},
        %{num: "50", slug: "50-builtin-protocols", label: "50 - Built-in Protocols", color: "bg-teal-500", tags: ["protocols"], description: "String.Chars, Inspect, Enumerable"},
        %{num: "51", slug: "51-behaviours", label: "51 - Behaviours", color: "bg-emerald-600", tags: ["protocols", "otp"], description: "@callback, @behaviour, compile-time contracts"},
        %{num: "52", slug: "52-polymorphism", label: "52 - Polymorphism", color: "bg-teal-600", tags: ["protocols", "pattern-matching"], description: "Protocols vs behaviours vs pattern matching"},
        %{num: "53", slug: "53-module-attributes", label: "53 - Module Attributes", color: "bg-emerald-400", tags: ["functions", "metaprogramming"], description: "@moduledoc, @doc, @spec, @type, constants"},
        %{num: "54", slug: "54-use-import", label: "54 - Use & Import", color: "bg-teal-400", tags: ["functions", "metaprogramming"], description: "import, alias, require, use, __using__ macro"}
      ]},
      %{title: "Section 8: Processes", katas: [
        %{num: "55", slug: "55-spawn-processes", label: "55 - Spawn & Processes", color: "bg-emerald-500", tags: ["processes"], description: "spawn/1, self(), process isolation, PIDs"},
        %{num: "56", slug: "56-send-receive", label: "56 - Send & Receive", color: "bg-teal-500", tags: ["processes"], description: "Message passing, mailbox visualization"},
        %{num: "57", slug: "57-process-links", label: "57 - Process Links", color: "bg-emerald-600", tags: ["processes", "errors"], description: "spawn_link, bidirectional crash propagation"},
        %{num: "58", slug: "58-process-monitors", label: "58 - Process Monitors", color: "bg-teal-600", tags: ["processes"], description: "Process.monitor, :DOWN messages, unidirectional"},
        %{num: "59", slug: "59-process-state", label: "59 - Process State Loop", color: "bg-emerald-400", tags: ["processes", "otp"], description: "Recursive receive loop (DIY GenServer)"},
        %{num: "60", slug: "60-trapping-exits", label: "60 - Trapping Exits", color: "bg-teal-400", tags: ["processes", "errors"], description: "trap_exit flag, converting exits to messages"},
        %{num: "61", slug: "61-task-module", label: "61 - Task Module", color: "bg-emerald-500", tags: ["processes", "otp"], description: "Task.async/await, async_stream, concurrency"},
        %{num: "62", slug: "62-agent", label: "62 - Agent", color: "bg-teal-500", tags: ["processes", "otp"], description: "Simple state server, get/update/get_and_update"}
      ]},
      %{title: "Section 9: GenServer & OTP", katas: [
        %{num: "63", slug: "63-genserver-basics", label: "63 - GenServer Basics", color: "bg-emerald-600", tags: ["otp"], description: "init, handle_call, handle_cast, handle_info"},
        %{num: "64", slug: "64-call-vs-cast", label: "64 - Call vs Cast", color: "bg-teal-600", tags: ["otp"], description: "Sync vs async, blocking behavior, timeouts"},
        %{num: "65", slug: "65-genserver-state", label: "65 - GenServer State", color: "bg-emerald-400", tags: ["otp"], description: "Complex state, named processes, Registry"},
        %{num: "66", slug: "66-periodic-work", label: "66 - Periodic Work", color: "bg-teal-400", tags: ["otp", "processes"], description: "Process.send_after, timer patterns"},
        %{num: "67", slug: "67-supervisor-basics", label: "67 - Supervisor Basics", color: "bg-emerald-500", tags: ["otp"], description: "Restart strategies: one_for_one, one_for_all, rest_for_one"},
        %{num: "68", slug: "68-dynamic-supervisors", label: "68 - Dynamic Supervisors", color: "bg-teal-500", tags: ["otp"], description: "DynamicSupervisor, start_child/terminate_child"},
        %{num: "69", slug: "69-supervision-trees", label: "69 - Supervision Trees", color: "bg-emerald-600", tags: ["otp"], description: "Nested supervisors, fault tolerance"},
        %{num: "70", slug: "70-registry", label: "70 - Registry", color: "bg-teal-600", tags: ["otp", "processes"], description: "Process lookup, :unique vs :duplicate, pub/sub"},
        %{num: "71", slug: "71-ets-tables", label: "71 - ETS Tables", color: "bg-emerald-400", tags: ["otp", "types"], description: ":ets operations, table types, concurrent reads"}
      ]},
      %{title: "Section 10: Advanced", katas: [
        %{num: "72", slug: "72-quote-unquote", label: "72 - Quote & Unquote", color: "bg-emerald-500", tags: ["metaprogramming"], description: "AST representation, homoiconicity"},
        %{num: "73", slug: "73-macros", label: "73 - Macros", color: "bg-teal-500", tags: ["metaprogramming"], description: "defmacro, compile-time code generation"},
        %{num: "74", slug: "74-application-config", label: "74 - Application Config", color: "bg-emerald-600", tags: ["otp"], description: "Application.get_env, runtime vs compile-time"},
        %{num: "75", slug: "75-elixir-toolbox", label: "75 - The Elixir Toolbox", color: "bg-teal-600", tags: ["otp", "functions"], description: "Decision-tree quiz: choosing the right tool"}
      ]},
      %{title: "Section 11: Essentials", katas: [
        %{num: "76", slug: "76-io-file", label: "76 - IO & File Operations", color: "bg-emerald-500", tags: ["io"], description: "IO.puts/inspect, File.read/write/stream!, Path module, IO lists"},
        %{num: "77", slug: "77-erlang-interop", label: "77 - Erlang Interop", color: "bg-teal-500", tags: ["types", "functions"], description: "Calling :math, :timer, :crypto, :rand; type mapping"},
        %{num: "78", slug: "78-exunit-basics", label: "78 - ExUnit Basics", color: "bg-emerald-600", tags: ["testing"], description: "assert/refute, describe, setup, doctest, test patterns"},
        %{num: "79", slug: "79-date-time", label: "79 - Date & Time", color: "bg-teal-600", tags: ["types"], description: "Date, Time, DateTime, NaiveDateTime; arithmetic & formatting"},
        %{num: "80", slug: "80-nested-access", label: "80 - Nested Data Access", color: "bg-emerald-400", tags: ["types", "functions"], description: "get_in/put_in/update_in, Access module"},
        %{num: "81", slug: "81-custom-exceptions", label: "81 - Custom Exceptions", color: "bg-teal-400", tags: ["errors", "structs"], description: "defexception, raise/rescue, exceptions vs tagged tuples"},
        %{num: "82", slug: "82-debugging", label: "82 - Debugging Tools", color: "bg-emerald-500", tags: ["debugging", "io"], description: "IO.inspect, dbg, IEx helpers, Logger, process debugging"},
        %{num: "83", slug: "83-nodes-distribution", label: "83 - Nodes & Distribution", color: "bg-teal-500", tags: ["processes", "otp"], description: "Node.connect, :rpc.call, :global, distributed Erlang"},
        %{num: "84", slug: "84-scheduler-priorities", label: "84 - Scheduler & Priorities", color: "bg-emerald-600", tags: ["processes"], description: "Preemptive vs cooperative, reductions, Process.flag(:priority), dirty schedulers"}
      ]}
    ]
  end
end
