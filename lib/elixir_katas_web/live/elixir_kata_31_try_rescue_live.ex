defmodule ElixirKatasWeb.ElixirKata31TryRescueLive do
  use ElixirKatasWeb, :live_component

  @error_types [
    %{
      id: "runtime",
      title: "RuntimeError",
      code: ~s|raise "something went wrong"|,
      rescue_code: ~s|try do\n  raise "something went wrong"\nrescue\n  e in RuntimeError -> "Caught: \#{e.message}"\nend|,
      result: ~s|"Caught: something went wrong"|,
      explanation: "RuntimeError is the default error raised by raise/1 with a string message."
    },
    %{
      id: "arithmetic",
      title: "ArithmeticError",
      code: "1 / 0",
      rescue_code: "try do\n  1 / 0\nrescue\n  e in ArithmeticError -> \"Caught: \#{e.message}\"\nend",
      result: ~s|"Caught: bad argument in arithmetic expression"|,
      explanation: "ArithmeticError occurs for invalid arithmetic operations like division by zero."
    },
    %{
      id: "function_clause",
      title: "FunctionClauseError",
      code: "List.first(:not_a_list)",
      rescue_code: "try do\n  List.first(:not_a_list)\nrescue\n  e in FunctionClauseError -> \"Caught: no matching function clause\"\nend",
      result: ~s|"Caught: no matching function clause"|,
      explanation: "FunctionClauseError occurs when no function clause matches the given arguments."
    },
    %{
      id: "argument",
      title: "ArgumentError",
      code: ~s|String.to_integer("abc")|,
      rescue_code: ~s|try do\n  String.to_integer("abc")\nrescue\n  e in ArgumentError -> "Caught: \#{e.message}"\nend|,
      result: ~s|"Caught: argument error"|,
      explanation: "ArgumentError occurs when a function receives an argument of the wrong type or value."
    },
    %{
      id: "key",
      title: "KeyError",
      code: ~s|%{a: 1}.b|,
      rescue_code: ~s|try do\n  map = %{a: 1}\n  map.b\nrescue\n  e in KeyError -> "Caught: key :b not found"\nend|,
      result: ~s|"Caught: key :b not found"|,
      explanation: "KeyError occurs when accessing a map key with dot notation that doesn't exist."
    },
    %{
      id: "match",
      title: "MatchError",
      code: ~s|{:ok, val} = {:error, "oops"}|,
      rescue_code: ~s|try do\n  {:ok, val} = {:error, "oops"}\n  val\nrescue\n  e in MatchError -> "Caught: no match"\nend|,
      result: ~s|"Caught: no match"|,
      explanation: "MatchError occurs when a pattern match (=) fails."
    }
  ]

  @try_blocks [
    %{
      id: "try_rescue",
      title: "try/rescue",
      code: ~s|try do\n  dangerous_operation()\nrescue\n  e in RuntimeError ->\n    "Runtime error: \#{e.message}"\n  e in ArgumentError ->\n    "Bad argument: \#{e.message}"\n  e ->\n    "Unknown error: \#{inspect(e)}"\nend|,
      explanation: "rescue catches exceptions (errors raised with raise/1). You can match specific error types or catch all."
    },
    %{
      id: "try_rescue_after",
      title: "try/rescue/after",
      code: ~s|try do\n  file = File.open!("data.txt")\n  process(file)\nrescue\n  e -> IO.puts("Error: \#{e.message}")\nafter\n  # Always runs, even if an error occurred\n  File.close(file)\n  IO.puts("Cleanup complete")\nend|,
      explanation: "The after block ALWAYS runs, whether or not an exception was raised. Use it for cleanup (closing files, connections, etc.)."
    },
    %{
      id: "try_catch",
      title: "try/catch",
      code: "try do\n  throw(:abort)\ncatch\n  :throw, value -> \"Caught throw: \#{inspect(value)}\"\nend",
      explanation: "catch handles throw/1 values. throw is rarely used in Elixir - it's mainly for non-local returns in deeply nested code."
    },
    %{
      id: "try_catch_exit",
      title: "try/catch (exit)",
      code: "try do\n  exit(:shutdown)\ncatch\n  :exit, reason -> \"Caught exit: \#{inspect(reason)}\"\nend",
      explanation: "catch can also handle exit signals. Exits are used in OTP for process termination. You rarely need to catch these."
    }
  ]

  @tagged_tuples_examples [
    %{
      id: "file_read",
      title: "File.read",
      with_tuples: ~s|case File.read("config.txt") do\n  {:ok, content} -> process(content)\n  {:error, :enoent} -> "File not found"\n  {:error, reason} -> "Error: \#{reason}"\nend|,
      with_rescue: ~s|try do\n  content = File.read!("config.txt")\n  process(content)\nrescue\n  e in File.Error -> "Error: \#{e.reason}"\nend|,
      preferred: :tuples,
      note: "Prefer tagged tuples for expected failures. File.read returns {:ok, _} or {:error, _}."
    },
    %{
      id: "integer_parse",
      title: "Integer.parse",
      with_tuples: ~s|case Integer.parse(input) do\n  {number, ""} -> {:ok, number}\n  {_number, _rest} -> {:error, "trailing characters"}\n  :error -> {:error, "not a number"}\nend|,
      with_rescue: ~s|try do\n  String.to_integer(input)\nrescue\n  ArgumentError -> {:error, "not a number"}\nend|,
      preferred: :tuples,
      note: "Integer.parse/1 returns a tagged tuple. String.to_integer/1 raises. Choose the non-raising version."
    },
    %{
      id: "map_fetch",
      title: "Map.fetch",
      with_tuples: ~s|case Map.fetch(map, :key) do\n  {:ok, value} -> use(value)\n  :error -> default_value\nend|,
      with_rescue: ~s|try do\n  value = Map.fetch!(map, :key)\n  use(value)\nrescue\n  KeyError -> default_value\nend|,
      preferred: :tuples,
      note: "Map.fetch/2 returns {:ok, val} or :error. Map.fetch!/2 raises. Use the non-bang version."
    }
  ]

  @philosophy_points [
    %{
      title: "Let It Crash",
      icon: "1",
      description: "In Elixir/Erlang, processes are isolated and cheap. Instead of defensively catching every possible error, let processes crash and have supervisors restart them. This leads to simpler, more robust code."
    },
    %{
      title: "Tagged Tuples Over Exceptions",
      icon: "2",
      description: "Use {:ok, value} and {:error, reason} for expected failures (file not found, invalid input, network timeout). Reserve exceptions for truly unexpected situations (bugs, programming errors)."
    },
    %{
      title: "Bang (!) Functions",
      icon: "3",
      description: "Elixir convention: File.read/1 returns {:ok, _}/{:error, _}, while File.read!/1 raises on error. Use bang functions when failure is unexpected and should crash the process."
    },
    %{
      title: "Supervisors Handle Recovery",
      icon: "4",
      description: "OTP supervisors automatically restart crashed processes with clean state. try/rescue is for local recovery; supervisors handle system-level recovery."
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_error, fn -> hd(@error_types) end)
     |> assign_new(:active_block, fn -> hd(@try_blocks) end)
     |> assign_new(:active_tuple_example, fn -> hd(@tagged_tuples_examples) end)
     |> assign_new(:show_philosophy, fn -> false end)
     |> assign_new(:show_tagged_tuples, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:error_demo_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Try / Rescue / Catch</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir provides <code class="font-mono bg-base-300 px-1 rounded">try/rescue</code> for handling exceptions,
        but idiomatic Elixir prefers <strong>tagged tuples</strong>
        (<code class="font-mono bg-base-300 px-1 rounded">&lbrace;:ok, value&rbrace;</code> /
        <code class="font-mono bg-base-300 px-1 rounded">&lbrace;:error, reason&rbrace;</code>)
        and the <strong>"let it crash"</strong> philosophy for most error handling.
      </p>

      <!-- Error Types -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Common Error Types</h3>
          <p class="text-xs opacity-60 mb-4">
            Explore different exception types in Elixir and how to rescue them.
          </p>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for err <- error_types() do %>
              <button
                phx-click="select_error"
                phx-target={@myself}
                phx-value-id={err.id}
                class={"btn btn-sm " <> if(@active_error.id == err.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= err.title %>
              </button>
            <% end %>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-3">
            <!-- Code that raises -->
            <div class="bg-error/10 border border-error/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-error badge-sm">Raises</span>
                <span class="text-xs opacity-60"><%= @active_error.title %></span>
              </div>
              <div class="bg-base-100 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap"><%= @active_error.code %></div>
            </div>

            <!-- Code that rescues -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-success badge-sm">Rescued</span>
              </div>
              <div class="bg-base-100 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap"><%= @active_error.rescue_code %></div>
            </div>
          </div>

          <div class="bg-success/10 border border-success/30 rounded-lg p-3 mb-3">
            <div class="text-xs font-bold opacity-60 mb-1">Result</div>
            <div class="font-mono text-sm text-success font-bold"><%= @active_error.result %></div>
          </div>

          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
            <%= @active_error.explanation %>
          </div>

          <!-- Try running the error -->
          <div class="mt-4">
            <button
              phx-click="demo_error"
              phx-target={@myself}
              class="btn btn-sm btn-warning"
            >
              Run the raise (safely rescued)
            </button>
            <%= if @error_demo_result do %>
              <div class={"alert text-sm mt-2 " <> if(@error_demo_result.ok, do: "alert-success", else: "alert-error")}>
                <div class="font-mono text-xs"><%= @error_demo_result.output %></div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Try Block Variants -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Try Block Variants</h3>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for block <- try_blocks() do %>
              <button
                phx-click="select_block"
                phx-target={@myself}
                phx-value-id={block.id}
                class={"btn btn-sm " <> if(@active_block.id == block.id, do: "btn-accent", else: "btn-outline")}
              >
                <%= block.title %>
              </button>
            <% end %>
          </div>

          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_block.code %></div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
              <%= @active_block.explanation %>
            </div>
          </div>

          <!-- Summary table -->
          <div class="overflow-x-auto mt-4">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Keyword</th>
                  <th>Catches</th>
                  <th>When to use</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="font-mono font-bold text-error">rescue</td>
                  <td>Exceptions (raise)</td>
                  <td>Most common. Catching errors from raise/1 or raise/2.</td>
                </tr>
                <tr>
                  <td class="font-mono font-bold text-warning">catch :throw</td>
                  <td>throw/1 values</td>
                  <td>Rare. Non-local returns in deeply nested code.</td>
                </tr>
                <tr>
                  <td class="font-mono font-bold text-info">catch :exit</td>
                  <td>exit/1 signals</td>
                  <td>Rare. Process termination signals.</td>
                </tr>
                <tr>
                  <td class="font-mono font-bold text-success">after</td>
                  <td>Nothing (always runs)</td>
                  <td>Cleanup: closing files, connections, releasing resources.</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Tagged Tuples vs Rescue -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Tagged Tuples vs try/rescue</h3>
            <button
              phx-click="toggle_tagged_tuples"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_tagged_tuples, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_tagged_tuples do %>
            <p class="text-xs opacity-60 mb-4">
              Most Elixir functions offer two variants: a non-raising version that returns tagged tuples, and a bang (!) version that raises on error.
            </p>

            <div class="flex flex-wrap gap-2 mb-4">
              <%= for ex <- tagged_tuples_examples() do %>
                <button
                  phx-click="select_tuple_example"
                  phx-target={@myself}
                  phx-value-id={ex.id}
                  class={"btn btn-sm " <> if(@active_tuple_example.id == ex.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= ex.title %>
                </button>
              <% end %>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-3">
              <div class={"rounded-lg p-4 " <> if(@active_tuple_example.preferred == :tuples, do: "bg-success/10 border border-success/30", else: "bg-base-300")}>
                <div class="flex items-center gap-2 mb-2">
                  <span class={"badge badge-sm " <> if(@active_tuple_example.preferred == :tuples, do: "badge-success", else: "badge-ghost")}>Tagged Tuples</span>
                  <%= if @active_tuple_example.preferred == :tuples do %>
                    <span class="text-xs text-success font-bold">Preferred</span>
                  <% end %>
                </div>
                <div class="bg-base-100 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><%= @active_tuple_example.with_tuples %></div>
              </div>

              <div class={"rounded-lg p-4 " <> if(@active_tuple_example.preferred == :rescue, do: "bg-success/10 border border-success/30", else: "bg-base-300")}>
                <div class="flex items-center gap-2 mb-2">
                  <span class={"badge badge-sm " <> if(@active_tuple_example.preferred == :rescue, do: "badge-success", else: "badge-ghost")}>try/rescue</span>
                  <%= if @active_tuple_example.preferred == :rescue do %>
                    <span class="text-xs text-success font-bold">Preferred</span>
                  <% end %>
                </div>
                <div class="bg-base-100 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><%= @active_tuple_example.with_rescue %></div>
              </div>
            </div>

            <div class="alert text-sm">
              <span><%= @active_tuple_example.note %></span>
            </div>

            <!-- Convention table -->
            <div class="overflow-x-auto mt-4">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Returns tuples</th>
                    <th>Raises (bang !)</th>
                    <th>Use tuples when</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="font-mono text-xs">File.read/1</td>
                    <td class="font-mono text-xs">File.read!/1</td>
                    <td>File might not exist</td>
                  </tr>
                  <tr>
                    <td class="font-mono text-xs">Map.fetch/2</td>
                    <td class="font-mono text-xs">Map.fetch!/2</td>
                    <td>Key might not be present</td>
                  </tr>
                  <tr>
                    <td class="font-mono text-xs">Integer.parse/1</td>
                    <td class="font-mono text-xs">String.to_integer/1</td>
                    <td>Input might not be numeric</td>
                  </tr>
                  <tr>
                    <td class="font-mono text-xs">Jason.decode/1</td>
                    <td class="font-mono text-xs">Jason.decode!/1</td>
                    <td>JSON might be malformed</td>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Let It Crash Philosophy -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">The "Let It Crash" Philosophy</h3>
            <button
              phx-click="toggle_philosophy"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_philosophy, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_philosophy do %>
            <div class="space-y-4">
              <%= for point <- philosophy_points() do %>
                <div class="flex items-start gap-3 p-3 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5"><%= point.icon %></span>
                  <div>
                    <div class="font-bold text-sm"><%= point.title %></div>
                    <div class="text-xs opacity-70 mt-1"><%= point.description %></div>
                  </div>
                </div>
              <% end %>

              <!-- Decision flowchart -->
              <div class="bg-base-300 rounded-lg p-4">
                <h4 class="text-xs font-bold opacity-60 mb-3">Error Handling Decision Tree:</h4>
                <div class="space-y-2 font-mono text-xs">
                  <div>Is the failure <strong>expected</strong> (user input, file I/O, network)?</div>
                  <div class="ml-4 text-success">&rarr; YES: Use tagged tuples &lbrace;:ok, val&rbrace; / &lbrace;:error, reason&rbrace;</div>
                  <div class="ml-4 text-info">&rarr; NO: Is it a <strong>programming error</strong> (bug)?</div>
                  <div class="ml-8 text-warning">&rarr; YES: Let it crash! Fix the bug.</div>
                  <div class="ml-8 text-info">&rarr; NO: Is <strong>local recovery</strong> possible?</div>
                  <div class="ml-12 text-success">&rarr; YES: Use try/rescue for local cleanup</div>
                  <div class="ml-12 text-error">&rarr; NO: Let it crash, supervisor restarts</div>
                </div>
              </div>

              <div class="alert alert-warning text-sm">
                <div>
                  <div class="font-bold">Anti-pattern: Defensive try/rescue everywhere</div>
                  <span>Wrapping everything in try/rescue makes code harder to read and hides bugs.
                    In Elixir, an unhandled exception in a process is caught by its supervisor,
                    which restarts it with clean state. This is usually the right behavior.</span>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Sandbox -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try It Yourself</h3>
          <p class="text-xs opacity-60 mb-4">
            Write a try/rescue expression or raise an error to see what happens.
          </p>

          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="code"
                value={@sandbox_code}
                placeholder={~s|try do raise "boom" rescue e -> e.message end|}
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
            </div>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <%= for {label, code} <- sandbox_quick_examples() do %>
              <button
                phx-click="quick_sandbox"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @sandbox_result do %>
            <div class={"alert text-sm " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @sandbox_result.input %></div>
                <div class="font-mono font-bold mt-1"><%= @sandbox_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">rescue</code> catches exceptions raised with <code class="font-mono bg-base-100 px-1 rounded">raise/1</code>. Match specific error types or catch all.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">after</code> always runs (like <code class="font-mono bg-base-100 px-1 rounded">finally</code> in other languages). Use for cleanup.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Prefer <strong>tagged tuples</strong> (<code class="font-mono bg-base-100 px-1 rounded">&lbrace;:ok, val&rbrace;</code> / <code class="font-mono bg-base-100 px-1 rounded">&lbrace;:error, reason&rbrace;</code>) over try/rescue for expected failures.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>The <strong>"let it crash"</strong> philosophy: let supervisors handle process recovery instead of defensive try/rescue.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Bang functions (<code class="font-mono bg-base-100 px-1 rounded">File.read!/1</code>) raise on error; non-bang (<code class="font-mono bg-base-100 px-1 rounded">File.read/1</code>) return tagged tuples.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">6</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">throw</code> and <code class="font-mono bg-base-100 px-1 rounded">exit</code> are rarely used directly in application code.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_error", %{"id" => id}, socket) do
    err = Enum.find(error_types(), &(&1.id == id))
    {:noreply, assign(socket, active_error: err, error_demo_result: nil)}
  end

  def handle_event("demo_error", _params, socket) do
    result = evaluate_code(socket.assigns.active_error.rescue_code)
    {:noreply, assign(socket, error_demo_result: result)}
  end

  def handle_event("select_block", %{"id" => id}, socket) do
    block = Enum.find(try_blocks(), &(&1.id == id))
    {:noreply, assign(socket, active_block: block)}
  end

  def handle_event("toggle_tagged_tuples", _params, socket) do
    {:noreply, assign(socket, show_tagged_tuples: !socket.assigns.show_tagged_tuples)}
  end

  def handle_event("select_tuple_example", %{"id" => id}, socket) do
    ex = Enum.find(tagged_tuples_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_tuple_example: ex)}
  end

  def handle_event("toggle_philosophy", _params, socket) do
    {:noreply, assign(socket, show_philosophy: !socket.assigns.show_philosophy)}
  end

  def handle_event("run_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  def handle_event("quick_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp error_types, do: @error_types
  defp try_blocks, do: @try_blocks
  defp tagged_tuples_examples, do: @tagged_tuples_examples
  defp philosophy_points, do: @philosophy_points

  defp sandbox_quick_examples do
    [
      {"rescue runtime", ~s|try do raise "boom" rescue e in RuntimeError -> "Caught: \#{e.message}" end|},
      {"rescue any", ~s|try do 1 / 0 rescue e -> "Caught: \#{inspect(e)}" end|},
      {"with after", ~s|try do raise "oops" rescue e -> e.message after IO.puts("cleanup!") end|},
      {"catch throw", ~s|try do throw(:done) catch :throw, val -> "Thrown: \#{val}" end|},
      {"reraise", ~s|try do try do raise "inner" rescue e -> reraise e, __STACKTRACE__ end rescue e -> "Final: \#{e.message}" end|}
    ]
  end

  defp evaluate_code(code) do
    try do
      {result, _} = Code.eval_string(code)

      %{
        ok: true,
        input: code,
        output: inspect(result, pretty: true, limit: 50)
      }
    rescue
      e ->
        %{
          ok: false,
          input: code,
          output: "Error: #{Exception.message(e)}"
        }
    end
  end
end
