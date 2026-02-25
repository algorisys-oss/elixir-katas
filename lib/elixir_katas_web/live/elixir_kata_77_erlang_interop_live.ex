defmodule ElixirKatasWeb.ElixirKata77ErlangInteropLive do
  use ElixirKatasWeb, :live_component

  @erlang_modules [
    %{
      id: "math",
      title: ":math",
      description: "Mathematical functions: trigonometry, logarithms, powers, and constants.",
      examples: [
        %{
          label: ":math.pi",
          code: ":math.pi()",
          note: "Returns the value of pi. Note the parentheses -- Erlang functions always need them."
        },
        %{
          label: ":math.sqrt",
          code: ":math.sqrt(144)",
          note: "Square root. All :math functions work with numbers (integers or floats)."
        },
        %{
          label: ":math.pow",
          code: ":math.pow(2, 10)",
          note: "Power function. Returns a float (1024.0). Use trunc/1 or round/1 if you need an integer."
        },
        %{
          label: ":math.log",
          code: ":math.log(2.718281828)",
          note: "Natural logarithm (base e). Use :math.log2/1 or :math.log10/1 for other bases."
        }
      ]
    },
    %{
      id: "timer",
      title: ":timer",
      description: "Time utilities: sleep, conversions, and periodic execution.",
      examples: [
        %{
          label: ":timer.seconds",
          code: ":timer.seconds(5)",
          note: "Converts 5 seconds to 5000 milliseconds. Useful for timeouts and Process.send_after."
        },
        %{
          label: ":timer.minutes",
          code: ":timer.minutes(2)",
          note: "Converts 2 minutes to 120000 milliseconds. Clearer than writing 120_000."
        },
        %{
          label: ":timer.hours",
          code: ":timer.hours(1)",
          note: "Converts 1 hour to 3600000 milliseconds. Great for GenServer timeout values."
        },
        %{
          label: ":timer.tc",
          code: ":timer.tc(fn -> Enum.sum(1..1_000_000) end)",
          note: "Measures execution time. Returns {microseconds, result}. Divide by 1000 for ms."
        }
      ]
    },
    %{
      id: "crypto",
      title: ":crypto",
      description: "Cryptographic functions: hashing, random bytes, and HMAC.",
      examples: [
        %{
          label: ":crypto.hash",
          code: ":crypto.hash(:sha256, \"hello\") |> Base.encode16(case: :lower)",
          note: "SHA-256 hash. Returns raw bytes -- pipe to Base.encode16 for a hex string."
        },
        %{
          label: ":crypto.strong_rand_bytes",
          code: ":crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)",
          note: "Cryptographically secure random bytes. Use for tokens, session IDs, etc."
        },
        %{
          label: ":crypto.mac",
          code: ":crypto.mac(:hmac, :sha256, \"secret\", \"message\") |> Base.encode16(case: :lower)",
          note: "HMAC for message authentication. Verifies both integrity and authenticity."
        }
      ]
    },
    %{
      id: "rand",
      title: ":rand",
      description: "Random number generation with configurable algorithms.",
      examples: [
        %{
          label: ":rand.uniform",
          code: ":rand.uniform()",
          note: "Random float between 0.0 (inclusive) and 1.0 (exclusive)."
        },
        %{
          label: ":rand.uniform/1",
          code: ":rand.uniform(100)",
          note: "Random integer between 1 and N (inclusive). For 0-based, subtract 1."
        },
        %{
          label: "Enum.random",
          code: "Enum.random(1..100)",
          note: "Elixir's Enum.random uses :rand under the hood. Often more convenient."
        }
      ]
    },
    %{
      id: "erlang",
      title: ":erlang",
      description: "Core BEAM functions: system info, process info, type conversions.",
      examples: [
        %{
          label: "system_info",
          code: ":erlang.system_info(:process_count)",
          note: "Returns the number of currently running processes in the BEAM."
        },
        %{
          label: "memory",
          code: ":erlang.memory(:total)",
          note: "Total memory used by the BEAM in bytes. Divide by 1_048_576 for MB."
        },
        %{
          label: "atom_to_binary",
          code: ":erlang.atom_to_binary(:hello)",
          note: "Converts an atom to a binary string. Elixir's Atom.to_string/1 wraps this."
        },
        %{
          label: "binary_to_term",
          code: ":erlang.term_to_binary(%{a: 1}) |> :erlang.binary_to_term()",
          note: "Serialize/deserialize any Erlang term to/from binary. Used by distributed Erlang."
        }
      ]
    },
    %{
      id: "calendar",
      title: ":calendar",
      description: "Date and time functions from Erlang's calendar module.",
      examples: [
        %{
          label: "local_time",
          code: ":calendar.local_time()",
          note: "Returns {{year, month, day}, {hour, min, sec}} as nested tuples."
        },
        %{
          label: "universal_time",
          code: ":calendar.universal_time()",
          note: "UTC time as nested tuples. Prefer Elixir's DateTime for new code."
        },
        %{
          label: "day_of_the_week",
          code: ":calendar.day_of_the_week(2025, 1, 1)",
          note: "Returns 1 (Monday) through 7 (Sunday). ISO 8601 weekday numbering."
        },
        %{
          label: "valid_date?",
          code: ":calendar.valid_date(2024, 2, 29)",
          note: "Checks if a date is valid. 2024 is a leap year, so Feb 29 is valid."
        }
      ]
    },
    %{
      id: "lists",
      title: ":lists",
      description: "Erlang's list operations. Most are available via Elixir's Enum, but some are unique.",
      examples: [
        %{
          label: ":lists.flatten",
          code: ":lists.flatten([1, [2, [3, 4]], 5])",
          note: "Deep flattens nested lists. Elixir's List.flatten/1 wraps this."
        },
        %{
          label: ":lists.seq",
          code: ":lists.seq(1, 10)",
          note: "Generates a sequence. Elixir's Range (1..10) is usually preferred."
        },
        %{
          label: ":lists.keyfind",
          code: ":lists.keyfind(:b, 1, [a: 1, b: 2, c: 3])",
          note: "Finds a tuple by element position. Keyword lists are lists of 2-tuples."
        }
      ]
    },
    %{
      id: "string_mod",
      title: ":string",
      description: "Erlang's string module works on charlists, not Elixir binaries.",
      examples: [
        %{
          label: ":string.uppercase",
          code: ":string.uppercase('hello')",
          note: "Uppercases a charlist. Note the single quotes -- Erlang strings are charlists!"
        },
        %{
          label: ":string.tokens",
          code: ":string.tokens('hello world foo', ' ')",
          note: "Splits a charlist by separator chars. Returns a list of charlists."
        },
        %{
          label: "List.to_string",
          code: ":string.uppercase('elixir') |> List.to_string()",
          note: "Convert charlist result back to an Elixir binary string with List.to_string/1."
        }
      ]
    }
  ]

  @type_mappings [
    %{
      elixir_type: "String (binary)",
      elixir_example: "\"hello\"",
      erlang_type: "Charlist",
      erlang_example: "'hello'",
      convert_to_erlang: "String.to_charlist(\"hello\")",
      convert_to_elixir: "List.to_string('hello')",
      note: "Most common gotcha! Erlang functions often expect/return charlists."
    },
    %{
      elixir_type: "Map",
      elixir_example: "%{key: \"val\"}",
      erlang_type: "Proplist / Record",
      erlang_example: "[{:key, \"val\"}]",
      convert_to_erlang: "Map.to_list(%{a: 1})",
      convert_to_elixir: "Map.new([{:a, 1}])",
      note: "Erlang has no maps (pre-OTP 17). Proplists are lists of {key, val} tuples."
    },
    %{
      elixir_type: "Atom",
      elixir_example: ":hello",
      erlang_type: "Atom",
      erlang_example: "hello",
      convert_to_erlang: "(same)",
      convert_to_elixir: "(same)",
      note: "Atoms are identical in both languages. Elixir just adds the colon prefix."
    },
    %{
      elixir_type: "Tuple",
      elixir_example: "{:ok, 42}",
      erlang_type: "Tuple",
      erlang_example: "{ok, 42}",
      convert_to_erlang: "(same)",
      convert_to_elixir: "(same)",
      note: "Tuples are identical. Erlang uses unquoted atoms in tuples."
    },
    %{
      elixir_type: "nil / false / true",
      elixir_example: "nil",
      erlang_type: "Atom",
      erlang_example: "nil / false / true",
      convert_to_erlang: "(same atoms)",
      convert_to_elixir: "(same atoms)",
      note: "nil, true, false are just atoms in both languages."
    }
  ]

  @system_info_keys [
    %{key: "process_count", label: "Running Processes", description: "Current number of BEAM processes"},
    %{key: "atom_count", label: "Atom Count", description: "Number of atoms in the atom table"},
    %{key: "port_count", label: "Port Count", description: "Open ports (files, sockets, etc.)"},
    %{key: "schedulers", label: "Schedulers", description: "Number of scheduler threads"},
    %{key: "otp_release", label: "OTP Release", description: "Erlang/OTP version string"},
    %{key: "wordsize", label: "Word Size", description: "System word size in bytes (4 or 8)"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_module, fn -> "math" end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:show_type_mapping, fn -> true end)
     |> assign_new(:show_system_info, fn -> false end)
     |> assign_new(:system_info_data, fn -> nil end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Erlang Interop</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir runs on the BEAM and can call any Erlang module directly.
        Erlang modules are accessed as atoms (e.g., <code class="font-mono bg-base-300 px-1 rounded">:math.sqrt(2)</code>).
        This gives you access to a vast ecosystem of battle-tested libraries.
      </p>

      <!-- Section 1: Module Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Erlang Module Explorer</h3>
          <p class="text-xs opacity-60 mb-4">
            Select a module to explore its commonly-used functions in Elixir.
          </p>

          <!-- Module Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for mod <- erlang_modules() do %>
              <button
                phx-click="select_module"
                phx-target={@myself}
                phx-value-id={mod.id}
                class={"btn btn-sm " <> if(@active_module == mod.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= mod.title %>
              </button>
            <% end %>
          </div>

          <% active_mod = Enum.find(erlang_modules(), &(&1.id == @active_module)) %>
          <p class="text-xs opacity-60 mb-4"><%= active_mod.description %></p>

          <!-- Example Subtabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(active_mod.examples) do %>
              <button
                phx-click="select_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"btn btn-xs " <> if(idx == @active_example_idx, do: "btn-accent", else: "btn-ghost")}
              >
                <%= example.label %>
              </button>
            <% end %>
          </div>

          <% example = Enum.at(active_mod.examples, @active_example_idx) %>
          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= example.code %></div>

            <!-- Live evaluation -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result (evaluated live)</div>
              <div class="font-mono text-sm text-success font-bold"><%= evaluate_example(example.code) %></div>
            </div>

            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Note</div>
              <div class="text-sm"><%= example.note %></div>
            </div>
          </div>

          <!-- Calling convention callout -->
          <div class="alert alert-info mt-4 text-xs">
            <div>
              <strong>Calling Convention:</strong> Erlang modules are atoms in Elixir.
              Write <code class="font-mono bg-base-100 px-1 rounded">:module.function(args)</code> --
              the colon makes it an atom, the dot calls the function.
              Example: <code class="font-mono bg-base-100 px-1 rounded">:math.pi()</code> calls the Erlang
              <code class="font-mono bg-base-100 px-1 rounded">math:pi()</code> function.
            </div>
          </div>
        </div>
      </div>

      <!-- Section 2: Type Mapping -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Elixir vs Erlang Type Mapping</h3>
            <button
              phx-click="toggle_type_mapping"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_type_mapping, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_type_mapping do %>
            <p class="text-xs opacity-60 mb-4">
              The biggest interop gotcha is the string/charlist difference.
              Elixir strings are UTF-8 binaries; Erlang strings are lists of character codepoints.
            </p>

            <div class="space-y-3">
              <%= for mapping <- type_mappings() do %>
                <div class="bg-base-300 rounded-lg p-3">
                  <div class="grid grid-cols-1 md:grid-cols-2 gap-3 mb-2">
                    <div>
                      <div class="text-xs font-bold text-primary mb-1">Elixir: <%= mapping.elixir_type %></div>
                      <div class="bg-base-100 rounded p-2 font-mono text-xs"><%= mapping.elixir_example %></div>
                    </div>
                    <div>
                      <div class="text-xs font-bold text-secondary mb-1">Erlang: <%= mapping.erlang_type %></div>
                      <div class="bg-base-100 rounded p-2 font-mono text-xs"><%= mapping.erlang_example %></div>
                    </div>
                  </div>

                  <div class="grid grid-cols-1 md:grid-cols-2 gap-2 mb-2">
                    <div class="text-xs">
                      <span class="opacity-60">To Erlang:</span>
                      <code class="font-mono bg-base-100 px-1 rounded"><%= mapping.convert_to_erlang %></code>
                    </div>
                    <div class="text-xs">
                      <span class="opacity-60">To Elixir:</span>
                      <code class="font-mono bg-base-100 px-1 rounded"><%= mapping.convert_to_elixir %></code>
                    </div>
                  </div>

                  <div class="text-xs opacity-70"><%= mapping.note %></div>
                </div>
              <% end %>
            </div>

            <!-- String vs Charlist demo -->
            <div class="alert alert-warning mt-4 text-xs">
              <div>
                <strong>Key difference:</strong>
                <code class="font-mono bg-base-100 px-1 rounded">"hello"</code> is a binary (Elixir string).
                <code class="font-mono bg-base-100 px-1 rounded">'hello'</code> is a charlist (Erlang string).
                They look similar in IEx but are completely different types!
                Use <code class="font-mono bg-base-100 px-1 rounded">String.to_charlist/1</code> and
                <code class="font-mono bg-base-100 px-1 rounded">List.to_string/1</code> to convert.
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 3: System Info -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Live System Info</h3>
            <button
              phx-click="refresh_system_info"
              phx-target={@myself}
              class="btn btn-sm btn-primary"
            >
              <%= if @system_info_data, do: "Refresh", else: "Load System Info" %>
            </button>
          </div>
          <p class="text-xs opacity-60 mb-4">
            The <code class="font-mono bg-base-300 px-1 rounded">:erlang</code> module exposes live BEAM runtime information.
            Click the button to query your running system.
          </p>

          <%= if @system_info_data do %>
            <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3 mb-4">
              <%= for info <- @system_info_data do %>
                <div class="bg-base-300 rounded-lg p-3">
                  <div class="text-xs opacity-60"><%= info.description %></div>
                  <div class="font-bold text-lg"><%= info.value %></div>
                  <div class="font-mono text-xs text-primary mt-1"><%= info.label %></div>
                </div>
              <% end %>
            </div>

            <!-- Memory breakdown -->
            <div class="bg-base-300 rounded-lg p-4">
              <div class="text-xs font-bold opacity-60 mb-3">Memory Breakdown</div>
              <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
                <%= for {mem_key, mem_val} <- @memory_data do %>
                  <div class="text-center">
                    <div class="font-bold text-sm"><%= format_bytes(mem_val) %></div>
                    <div class="text-xs opacity-60"><%= mem_key %></div>
                  </div>
                <% end %>
              </div>
            </div>

            <div class="bg-base-300 rounded-lg p-4 mt-3">
              <div class="text-xs font-bold opacity-60 mb-2">Code used to fetch this data</div>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= system_info_code() %></div>
            </div>
          <% else %>
            <div class="text-center py-6 opacity-40 text-sm">
              Click &quot;Load System Info&quot; to query the live BEAM runtime.
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 4: Try Erlang Functions -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Erlang Functions</h3>
          <form phx-submit="run_custom" phx-target={@myself} class="space-y-3">
            <input
              type="text"
              name="code"
              value={@custom_code}
              placeholder={custom_placeholder()}
              class="input input-bordered input-sm font-mono w-full"
              autocomplete="off"
            />
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
              <span class="text-xs opacity-50 self-center">Call any Erlang module from Elixir</span>
            </div>
          </form>

          <!-- Quick examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, code} <- quick_examples() do %>
              <button
                phx-click="quick_example"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @custom_result do %>
            <div class={"alert text-sm mt-3 " <> if(@custom_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @custom_result.input %></div>
                <div class="font-mono font-bold mt-1"><%= @custom_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 5: Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>Erlang modules are atoms</strong> &mdash; call them with <code class="font-mono bg-base-100 px-1 rounded">:module.function(args)</code>. No wrappers or adapters needed.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Strings vs charlists</strong> &mdash; Elixir uses binaries (<code class="font-mono bg-base-100 px-1 rounded">"hello"</code>), Erlang uses charlists (<code class="font-mono bg-base-100 px-1 rounded">'hello'</code>). Convert with <code class="font-mono bg-base-100 px-1 rounded">String.to_charlist/1</code> and <code class="font-mono bg-base-100 px-1 rounded">List.to_string/1</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Zero-cost interop</strong> &mdash; calling Erlang from Elixir has no performance overhead. They compile to the same BEAM bytecode.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Prefer Elixir wrappers</strong> &mdash; many Erlang functions have Elixir equivalents (e.g., <code class="font-mono bg-base-100 px-1 rounded">Enum</code> over <code class="font-mono bg-base-100 px-1 rounded">:lists</code>). Use Erlang directly only when no Elixir alternative exists.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>The BEAM is your toolkit</strong> &mdash; <code class="font-mono bg-base-100 px-1 rounded">:crypto</code>, <code class="font-mono bg-base-100 px-1 rounded">:timer</code>, <code class="font-mono bg-base-100 px-1 rounded">:ets</code>, <code class="font-mono bg-base-100 px-1 rounded">:erlang</code> give you crypto, timing, storage, and system introspection without any dependencies.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_module", %{"id" => id}, socket) do
    {:noreply, socket |> assign(active_module: id) |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, active_example_idx: String.to_integer(idx_str))}
  end

  def handle_event("toggle_type_mapping", _params, socket) do
    {:noreply, assign(socket, show_type_mapping: !socket.assigns.show_type_mapping)}
  end

  def handle_event("refresh_system_info", _params, socket) do
    system_data = fetch_system_info()
    memory_data = fetch_memory_info()

    {:noreply,
     socket
     |> assign(show_system_info: true)
     |> assign(system_info_data: system_data)
     |> assign(memory_data: memory_data)}
  end

  def handle_event("run_custom", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))
    {:noreply, socket |> assign(custom_code: code) |> assign(custom_result: result)}
  end

  def handle_event("quick_example", %{"code" => code}, socket) do
    result = evaluate_code(code)
    {:noreply, socket |> assign(custom_code: code) |> assign(custom_result: result)}
  end

  # Helpers

  defp erlang_modules, do: @erlang_modules
  defp type_mappings, do: @type_mappings

  defp evaluate_example(code) do
    try do
      {result, _} = Code.eval_string(code)
      inspect(result, pretty: true, limit: 50)
    rescue
      e -> "Error: #{Exception.message(e)}"
    end
  end

  defp fetch_system_info do
    Enum.map(@system_info_keys, fn info ->
      key = String.to_existing_atom(info.key)
      value = :erlang.system_info(key)

      %{
        label: info.label,
        description: info.description,
        value: to_string(value)
      }
    end)
  end

  defp fetch_memory_info do
    memory = :erlang.memory()

    [:total, :processes, :atom, :binary, :ets]
    |> Enum.map(fn key ->
      {Atom.to_string(key), Keyword.get(memory, key, 0)}
    end)
  end

  defp format_bytes(bytes) when bytes >= 1_048_576 do
    mb = Float.round(bytes / 1_048_576, 1)
    "#{mb} MB"
  end

  defp format_bytes(bytes) when bytes >= 1024 do
    kb = Float.round(bytes / 1024, 1)
    "#{kb} KB"
  end

  defp format_bytes(bytes), do: "#{bytes} B"

  defp system_info_code do
    """
    :erlang.system_info(:process_count)  # running processes
    :erlang.system_info(:atom_count)     # atoms in table
    :erlang.system_info(:schedulers)     # scheduler threads
    :erlang.memory(:total)               # total memory (bytes)
    :erlang.memory()                     # full memory breakdown\
    """
  end

  defp custom_placeholder do
    ":math.pow(2, 10) |> trunc()"
  end

  defp quick_examples do
    [
      {":math.pi", ":math.pi()"},
      {"sqrt(2)", ":math.sqrt(2)"},
      {"time a fn", ":timer.tc(fn -> Enum.sum(1..100_000) end) |> elem(0)"},
      {"rand int", ":rand.uniform(100)"},
      {"SHA256", ":crypto.hash(:sha256, \"hello\") |> Base.encode16(case: :lower)"},
      {"process count", ":erlang.system_info(:process_count)"},
      {"charlist round-trip", "\"hello\" |> String.to_charlist() |> List.to_string()"}
    ]
  end

  defp evaluate_code(code) do
    try do
      {result, _} = Code.eval_string(code)
      %{ok: true, input: code, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, input: code, output: "Error: #{Exception.message(e)}"}
    end
  end
end
