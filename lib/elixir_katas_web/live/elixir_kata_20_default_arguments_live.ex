defmodule ElixirKatasWeb.ElixirKata20DefaultArgumentsLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "greet",
      title: "Basic Default Argument",
      description: "A greeting function with a default greeting message.",
      definition: "def greet(name, greeting \\\\ \"Hello\")",
      body: "\"\#{greeting}, \#{name}!\"",
      generated_arities: [
        %{arity: 1, signature: "greet(name)", expansion: "greet(name, \"Hello\")", note: "Uses default greeting"},
        %{arity: 2, signature: "greet(name, greeting)", expansion: "greet(name, greeting)", note: "Uses provided greeting"}
      ],
      test_cases: [
        %{call: "greet(\"Alice\")", args: ["\"Alice\""], result: "\"Hello, Alice!\""},
        %{call: "greet(\"Alice\", \"Hi\")", args: ["\"Alice\"", "\"Hi\""], result: "\"Hi, Alice!\""},
        %{call: "greet(\"Bob\", \"Hey\")", args: ["\"Bob\"", "\"Hey\""], result: "\"Hey, Bob!\""}
      ]
    },
    %{
      id: "paginate",
      title: "Multiple Defaults",
      description: "A pagination function with multiple default arguments.",
      definition: "def paginate(items, page \\\\ 1, per_page \\\\ 10)",
      body: "Enum.slice(items, (page - 1) * per_page, per_page)",
      generated_arities: [
        %{arity: 1, signature: "paginate(items)", expansion: "paginate(items, 1, 10)", note: "Page 1, 10 per page"},
        %{arity: 2, signature: "paginate(items, page)", expansion: "paginate(items, page, 10)", note: "Custom page, 10 per page"},
        %{arity: 3, signature: "paginate(items, page, per_page)", expansion: "paginate(items, page, per_page)", note: "All custom"}
      ],
      test_cases: [
        %{call: "paginate(1..50)", args: ["Enum.to_list(1..50)"], result: "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]"},
        %{call: "paginate(1..50, 2)", args: ["Enum.to_list(1..50)", "2"], result: "[11, 12, 13, 14, 15, 16, 17, 18, 19, 20]"},
        %{call: "paginate(1..50, 1, 5)", args: ["Enum.to_list(1..50)", "1", "5"], result: "[1, 2, 3, 4, 5]"}
      ]
    },
    %{
      id: "log_message",
      title: "Default with Function Call",
      description: "Defaults can be expressions including function calls.",
      definition: "def log(message, level \\\\ :info, timestamp \\\\ DateTime.utc_now())",
      body: "\"\#{timestamp} [\#{level}] \#{message}\"",
      generated_arities: [
        %{arity: 1, signature: "log(message)", expansion: "log(message, :info, DateTime.utc_now())", note: "Default level and timestamp"},
        %{arity: 2, signature: "log(message, level)", expansion: "log(message, level, DateTime.utc_now())", note: "Custom level, auto timestamp"},
        %{arity: 3, signature: "log(message, level, timestamp)", expansion: "log(message, level, timestamp)", note: "All explicit"}
      ],
      test_cases: [
        %{call: "log(\"server started\")", args: ["\"server started\""], result: "\"... [:info] server started\""},
        %{call: "log(\"oops\", :error)", args: ["\"oops\"", ":error"], result: "\"... [:error] oops\""},
        %{call: "log(\"done\", :debug, \"12:00\")", args: ["\"done\"", ":debug", "\"12:00\""], result: "\"12:00 [:debug] done\""}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:selected_example, fn -> hd(@examples) end)
     |> assign_new(:test_args, fn -> "" end)
     |> assign_new(:test_result, fn -> nil end)
     |> assign_new(:show_gotcha, fn -> false end)
     |> assign_new(:show_keyword_pattern, fn -> false end)
     |> assign_new(:highlighted_arity, fn -> nil end)
     |> assign_new(:call_mode, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Default Arguments</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir supports default argument values using the
        <code class="font-mono bg-base-300 px-1 rounded">\\\\</code> syntax.
        When you define <code class="font-mono bg-base-300 px-1 rounded">def greet(name, greeting \\\\ "Hello")</code>,
        Elixir automatically generates multiple function clauses with different arities.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for ex <- examples() do %>
          <button
            phx-click="select_example"
            phx-target={@myself}
            phx-value-id={ex.id}
            class={"btn btn-sm " <> if(@selected_example.id == ex.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= ex.title %>
          </button>
        <% end %>
      </div>

      <!-- Function Definition -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3"><%= @selected_example.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @selected_example.description %></p>

          <!-- Definition -->
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <div>
              <span class="opacity-50">def </span>
              <span class="font-bold"><%= @selected_example.definition %></span>
              <span class="opacity-50"> do</span>
            </div>
            <div class="ml-4 text-accent"><%= @selected_example.body %></div>
            <div class="opacity-50">end</div>
          </div>

          <!-- Generated Arities -->
          <h4 class="text-xs font-bold opacity-60 mb-2">Generated Function Clauses:</h4>
          <div class="space-y-2 mb-4">
            <%= for gen <- @selected_example.generated_arities do %>
              <div
                phx-click="highlight_arity"
                phx-target={@myself}
                phx-value-arity={gen.arity}
                class={"rounded-lg p-3 border-2 cursor-pointer transition-all " <>
                  if(@highlighted_arity == gen.arity, do: "border-primary bg-primary/10", else: "border-base-300 bg-base-100 hover:bg-base-300")}
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <span class="badge badge-primary badge-sm">/<%= gen.arity %></span>
                    <span class="font-mono text-sm font-bold"><%= gen.signature %></span>
                  </div>
                  <span class="text-xs opacity-60"><%= gen.note %></span>
                </div>
                <%= if @highlighted_arity == gen.arity do %>
                  <div class="mt-2 bg-base-300 rounded p-2 font-mono text-xs">
                    <span class="opacity-50">expands to: </span>
                    <span class="text-success"><%= gen.expansion %></span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>

          <div class="alert alert-info text-sm">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <span>
              The <code class="font-mono bg-base-100 px-1 rounded">\\\\</code> syntax generates
              <strong><%= length(@selected_example.generated_arities) %></strong> function clauses
              with arities
              <%= @selected_example.generated_arities |> Enum.map(& &1.arity) |> Enum.map(&to_string/1) |> Enum.join(", ") %>.
            </span>
          </div>
        </div>
      </div>

      <!-- Interactive Calling Demo -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Try Calling It</h3>
          <p class="text-xs opacity-60 mb-4">
            Click a preset call or type your own arguments to see which arity is used and what result you get.
          </p>

          <!-- Preset Calls -->
          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Preset calls:</span>
            <%= for tc <- @selected_example.test_cases do %>
              <button
                phx-click="preset_call"
                phx-target={@myself}
                phx-value-args={Enum.join(tc.args, "|||")}
                phx-value-display={tc.call}
                class={"btn btn-sm " <> if(@call_mode == tc.call, do: "btn-primary", else: "btn-outline")}
              >
                <%= tc.call %>
              </button>
            <% end %>
          </div>

          <!-- Custom Input -->
          <form phx-submit="test_call" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0">
                <span class="label-text text-xs">Arguments (comma-separated)</span>
              </label>
              <input
                type="text"
                name="args"
                value={@test_args}
                placeholder={"e.g. #{hd(@selected_example.test_cases).call |> String.replace(~r/^\w+\(/, "") |> String.trim_trailing(")") }"}
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Call</button>
          </form>

          <!-- Result -->
          <%= if @test_result do %>
            <div class={"alert text-sm " <> if(@test_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="flex items-center gap-2">
                  <span class="font-mono text-xs opacity-60"><%= @test_result.call_display %></span>
                  <%= if @test_result.arity do %>
                    <span class="badge badge-primary badge-xs">/<%= @test_result.arity %></span>
                  <% end %>
                </div>
                <div class="font-mono font-bold mt-1">&rArr; <%= @test_result.value %></div>
                <%= if @test_result.expansion do %>
                  <div class="font-mono text-xs mt-1 opacity-70">
                    Expands to: <span class="text-info"><%= @test_result.expansion %></span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Gotcha: Multiple Clauses -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Gotcha: Default Args with Multiple Clauses</h3>
            <button
              phx-click="toggle_gotcha"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_gotcha, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_gotcha do %>
            <p class="text-xs opacity-60 mb-4">
              When you have multiple clauses of the same function and want default arguments,
              you must declare a <strong>function head</strong> with the defaults. The actual clauses
              must NOT repeat the defaults.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Bad -->
              <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                <h4 class="font-bold text-error text-sm mb-2">&#x2717; Wrong: Defaults in each clause</h4>
                <div class="font-mono text-xs space-y-1">
                  <div class="line-through opacity-60">
                    <div>def greet("Alice", greeting \\\\ "Hello") do</div>
                    <div class="ml-2">"&lbrace;&rbrace;#&lbrace;greeting&rbrace;, Alice!"</div>
                    <div>end</div>
                  </div>
                  <div class="line-through opacity-60 mt-2">
                    <div>def greet(name, greeting \\\\ "Hello") do</div>
                    <div class="ml-2">"&lbrace;&rbrace;#&lbrace;greeting&rbrace;, &lbrace;&rbrace;#&lbrace;name&rbrace;!"</div>
                    <div>end</div>
                  </div>
                  <div class="text-error text-xs mt-2">
                    ** (CompileError) def greet/2 defines defaults multiple times
                  </div>
                </div>
              </div>

              <!-- Good -->
              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <h4 class="font-bold text-success text-sm mb-2">&#x2713; Correct: Function head</h4>
                <div class="font-mono text-xs space-y-1">
                  <div class="text-warning">
                    <div># Function head with defaults only</div>
                    <div>def greet(name, greeting \\\\ "Hello")</div>
                  </div>
                  <div class="mt-2">
                    <div>def greet("Alice", greeting) do</div>
                    <div class="ml-2">"&lbrace;&rbrace;#&lbrace;greeting&rbrace;, dear Alice!"</div>
                    <div>end</div>
                  </div>
                  <div class="mt-2">
                    <div>def greet(name, greeting) do</div>
                    <div class="ml-2">"&lbrace;&rbrace;#&lbrace;greeting&rbrace;, &lbrace;&rbrace;#&lbrace;name&rbrace;!"</div>
                    <div>end</div>
                  </div>
                </div>
              </div>
            </div>

            <div class="alert alert-warning text-sm mt-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-5 w-5" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
              <span>
                A <strong>function head</strong> is a function definition without a body:
                <code class="font-mono bg-base-100 px-1 rounded">def name(args \\\\ defaults)</code>.
                It declares the defaults, and the actual clauses below implement the logic.
              </span>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Common Pattern: Keyword Options -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Common Pattern: Keyword Options with Defaults</h3>
            <button
              phx-click="toggle_keyword"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_keyword_pattern, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_keyword_pattern do %>
            <p class="text-xs opacity-60 mb-4">
              A very common Elixir pattern is to accept an options keyword list with defaults,
              using <code class="font-mono bg-base-300 px-1 rounded">Keyword.get/3</code> or
              <code class="font-mono bg-base-300 px-1 rounded">Keyword.merge/2</code>.
            </p>

            <div class="space-y-4">
              <!-- Pattern 1: Keyword.get -->
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm">
                <div class="opacity-60"># Pattern: opts keyword list with defaults</div>
                <div>def connect(host, opts \\\\ []) do</div>
                <div class="ml-2">port = Keyword.get(opts, :port, 5432)</div>
                <div class="ml-2">timeout = Keyword.get(opts, :timeout, 5000)</div>
                <div class="ml-2">ssl = Keyword.get(opts, :ssl, false)</div>
                <div class="ml-2 text-accent"># use host, port, timeout, ssl...</div>
                <div>end</div>
              </div>

              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm">
                <div class="opacity-60"># Calling it</div>
                <div><span class="opacity-50">iex&gt; </span>connect("localhost")</div>
                <div class="text-xs opacity-60 ml-4"># port=5432, timeout=5000, ssl=false</div>
                <div class="mt-1"><span class="opacity-50">iex&gt; </span>connect("localhost", port: 3306, ssl: true)</div>
                <div class="text-xs opacity-60 ml-4"># port=3306, timeout=5000, ssl=true</div>
              </div>

              <!-- Pattern 2: Keyword.merge -->
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm">
                <div class="opacity-60"># Alternative: merge with defaults map</div>
                <div>@defaults [port: 5432, timeout: 5000, ssl: false]</div>
                <div class="mt-1">def connect(host, opts \\\\ []) do</div>
                <div class="ml-2">opts = Keyword.merge(@defaults, opts)</div>
                <div class="ml-2 text-accent"># opts now has all keys with defaults filled in</div>
                <div>end</div>
              </div>

              <div class="alert alert-info text-sm">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                <div>
                  <div class="font-bold">Why keyword lists for options?</div>
                  <span>
                    This pattern is pervasive in Elixir and Phoenix. It lets callers pass only
                    the options they care about, while sensible defaults fill in the rest.
                    You will see it in Ecto, Phoenix, Plug, and most Elixir libraries.
                  </span>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Visual: How Defaults Generate Arities -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">How Defaults Generate Arities</h3>
          <p class="text-xs opacity-60 mb-4">
            Each default argument adds one more arity. A function with N parameters and D defaults
            generates D + 1 arities (from N - D to N).
          </p>

          <div class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Definition</th>
                  <th>Defaults</th>
                  <th>Generated Arities</th>
                  <th>Total Clauses</th>
                </tr>
              </thead>
              <tbody>
                <tr class="hover:bg-base-300">
                  <td class="font-mono text-xs">def f(a, b \\\\ 1)</td>
                  <td>1</td>
                  <td>
                    <span class="badge badge-primary badge-xs mr-1">f/1</span>
                    <span class="badge badge-primary badge-xs">f/2</span>
                  </td>
                  <td>2</td>
                </tr>
                <tr class="hover:bg-base-300">
                  <td class="font-mono text-xs">def f(a, b \\\\ 1, c \\\\ 2)</td>
                  <td>2</td>
                  <td>
                    <span class="badge badge-primary badge-xs mr-1">f/1</span>
                    <span class="badge badge-primary badge-xs mr-1">f/2</span>
                    <span class="badge badge-primary badge-xs">f/3</span>
                  </td>
                  <td>3</td>
                </tr>
                <tr class="hover:bg-base-300">
                  <td class="font-mono text-xs">def f(a, b, c \\\\ 1)</td>
                  <td>1</td>
                  <td>
                    <span class="badge badge-primary badge-xs mr-1">f/2</span>
                    <span class="badge badge-primary badge-xs">f/3</span>
                  </td>
                  <td>2</td>
                </tr>
                <tr class="hover:bg-base-300">
                  <td class="font-mono text-xs">def f(a \\\\ 1, b \\\\ 2, c \\\\ 3)</td>
                  <td>3</td>
                  <td>
                    <span class="badge badge-primary badge-xs mr-1">f/0</span>
                    <span class="badge badge-primary badge-xs mr-1">f/1</span>
                    <span class="badge badge-primary badge-xs mr-1">f/2</span>
                    <span class="badge badge-primary badge-xs">f/3</span>
                  </td>
                  <td>4</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span>
                <strong>Syntax:</strong>
                <code class="font-mono bg-base-100 px-1 rounded">def f(arg \\\\ default)</code> sets a default value
                for an argument using the <code class="font-mono bg-base-100 px-1 rounded">\\\\</code> operator.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>
                <strong>Generated arities:</strong> Each default generates an additional function clause.
                <code class="font-mono bg-base-100 px-1 rounded">def greet(name, greeting \\\\ "Hello")</code>
                creates both <code class="font-mono bg-base-100 px-1 rounded">greet/1</code> and
                <code class="font-mono bg-base-100 px-1 rounded">greet/2</code>.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>
                <strong>Multi-clause gotcha:</strong> When a function has multiple clauses AND defaults,
                declare the defaults in a bodyless function head, not in the clause definitions.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>
                <strong>Options pattern:</strong> Use
                <code class="font-mono bg-base-100 px-1 rounded">def f(required, opts \\\\ [])</code>
                with <code class="font-mono bg-base-100 px-1 rounded">Keyword.get/3</code> for flexible APIs
                with many optional settings.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>
                <strong>Evaluation timing:</strong> Default expressions are evaluated at call time,
                not at definition time. So
                <code class="font-mono bg-base-100 px-1 rounded">DateTime.utc_now()</code> as a default
                gives the current time each call.
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    example = Enum.find(examples(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(selected_example: example)
     |> assign(test_args: "")
     |> assign(test_result: nil)
     |> assign(highlighted_arity: nil)
     |> assign(call_mode: nil)}
  end

  def handle_event("highlight_arity", %{"arity" => arity_str}, socket) do
    arity = String.to_integer(arity_str)

    new_arity =
      if socket.assigns.highlighted_arity == arity, do: nil, else: arity

    {:noreply, assign(socket, highlighted_arity: new_arity)}
  end

  def handle_event("preset_call", %{"args" => args_str, "display" => display}, socket) do
    args = String.split(args_str, "|||")
    example = socket.assigns.selected_example

    case evaluate_example(example.id, args) do
      {:ok, value} ->
        arity = length(args)

        gen =
          Enum.find(example.generated_arities, &(&1.arity == arity))

        expansion = if gen, do: gen.expansion, else: nil

        {:noreply,
         socket
         |> assign(test_args: Enum.join(args, ", "))
         |> assign(call_mode: display)
         |> assign(highlighted_arity: arity)
         |> assign(test_result: %{
           ok: true,
           value: value,
           call_display: display,
           arity: arity,
           expansion: expansion
         })}

      {:error, msg} ->
        {:noreply,
         socket
         |> assign(test_args: Enum.join(args, ", "))
         |> assign(call_mode: display)
         |> assign(test_result: %{ok: false, value: msg, call_display: display, arity: nil, expansion: nil})}
    end
  end

  def handle_event("test_call", %{"args" => args_str}, socket) do
    args_str = String.trim(args_str)

    if args_str == "" do
      {:noreply, socket}
    else
      args = split_args(args_str)
      example = socket.assigns.selected_example

      fn_name =
        example.definition
        |> String.replace(~r/^def\s+/, "")
        |> String.replace(~r/\(.*$/, "")

      call_display = "#{fn_name}(#{args_str})"

      case evaluate_example(example.id, args) do
        {:ok, value} ->
          arity = length(args)
          gen = Enum.find(example.generated_arities, &(&1.arity == arity))
          expansion = if gen, do: gen.expansion, else: nil

          {:noreply,
           socket
           |> assign(test_args: args_str)
           |> assign(call_mode: call_display)
           |> assign(highlighted_arity: arity)
           |> assign(test_result: %{
             ok: true,
             value: value,
             call_display: call_display,
             arity: arity,
             expansion: expansion
           })}

        {:error, msg} ->
          {:noreply,
           socket
           |> assign(test_args: args_str)
           |> assign(call_mode: call_display)
           |> assign(test_result: %{ok: false, value: msg, call_display: call_display, arity: nil, expansion: nil})}
      end
    end
  end

  def handle_event("toggle_gotcha", _params, socket) do
    {:noreply, assign(socket, show_gotcha: !socket.assigns.show_gotcha)}
  end

  def handle_event("toggle_keyword", _params, socket) do
    {:noreply, assign(socket, show_keyword_pattern: !socket.assigns.show_keyword_pattern)}
  end

  # Helpers

  defp examples, do: @examples

  # Evaluation functions (named functions instead of anonymous to avoid module attribute restriction)

  defp evaluate_example("greet", args) do
    case args do
      [name] ->
        n = String.trim(name, "\"")
        {:ok, "\"Hello, #{n}!\""}
      [name, greeting] ->
        n = String.trim(name, "\"")
        g = String.trim(greeting, "\"")
        {:ok, "\"#{g}, #{n}!\""}
      _ ->
        {:error, "Expected 1 or 2 arguments"}
    end
  end

  defp evaluate_example("paginate", args) do
    try do
      case args do
        [items_str] ->
          {items, _} = Code.eval_string(items_str)
          {:ok, inspect(Enum.slice(items, 0, 10))}
        [items_str, page_str] ->
          {items, _} = Code.eval_string(items_str)
          {page, _} = Integer.parse(String.trim(page_str))
          {:ok, inspect(Enum.slice(items, (page - 1) * 10, 10))}
        [items_str, page_str, per_page_str] ->
          {items, _} = Code.eval_string(items_str)
          {page, _} = Integer.parse(String.trim(page_str))
          {per_page, _} = Integer.parse(String.trim(per_page_str))
          {:ok, inspect(Enum.slice(items, (page - 1) * per_page, per_page))}
        _ ->
          {:error, "Expected 1, 2, or 3 arguments"}
      end
    rescue
      _ -> {:error, "Could not evaluate arguments"}
    end
  end

  defp evaluate_example("log_message", args) do
    case args do
      [msg] ->
        m = String.trim(msg, "\"")
        {:ok, "\"#{DateTime.utc_now() |> DateTime.truncate(:second)} [:info] #{m}\""}
      [msg, level] ->
        m = String.trim(msg, "\"")
        l = String.trim(level)
        {:ok, "\"#{DateTime.utc_now() |> DateTime.truncate(:second)} [#{l}] #{m}\""}
      [msg, level, ts] ->
        m = String.trim(msg, "\"")
        l = String.trim(level)
        t = String.trim(ts, "\"")
        {:ok, "\"#{t} [#{l}] #{m}\""}
      _ ->
        {:error, "Expected 1, 2, or 3 arguments"}
    end
  end

  defp evaluate_example(_, _), do: {:error, "Unknown example"}

  defp split_args(args_str) do
    args_str
    |> String.split(~r/,\s*(?=(?:[^"]*"[^"]*")*[^"]*$)(?![^\[]*\])(?![^\(]*\))/)
    |> Enum.map(&String.trim/1)
  end
end
