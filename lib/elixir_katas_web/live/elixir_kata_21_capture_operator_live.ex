defmodule ElixirKatasWeb.ElixirKata21CaptureOperatorLive do
  use ElixirKatasWeb, :live_component

  @capture_forms [
    %{
      id: "mod_fun_arity",
      title: "&Module.fun/arity",
      description: "Capture a named function from a module to use as a value",
      examples: [
        %{capture: "&String.upcase/1", equivalent: "fn s -> String.upcase(s) end", demo_input: "hello", demo_output: "HELLO"},
        %{capture: "&String.length/1", equivalent: "fn s -> String.length(s) end", demo_input: "elixir", demo_output: "6"},
        %{capture: "&Enum.count/1", equivalent: "fn list -> Enum.count(list) end", demo_input: "[1, 2, 3]", demo_output: "3"},
        %{capture: "&Integer.to_string/1", equivalent: "fn n -> Integer.to_string(n) end", demo_input: "42", demo_output: "\"42\""}
      ]
    },
    %{
      id: "local_fun_arity",
      title: "&fun/arity",
      description: "Capture a local or imported function by name and arity",
      examples: [
        %{capture: "&is_atom/1", equivalent: "fn x -> is_atom(x) end", demo_input: ":hello", demo_output: "true"},
        %{capture: "&is_integer/1", equivalent: "fn x -> is_integer(x) end", demo_input: "42", demo_output: "true"},
        %{capture: "&length/1", equivalent: "fn list -> length(list) end", demo_input: "[1, 2, 3]", demo_output: "3"},
        %{capture: "&hd/1", equivalent: "fn list -> hd(list) end", demo_input: "[10, 20, 30]", demo_output: "10"}
      ]
    },
    %{
      id: "shorthand",
      title: "&(&1 + &2) shorthand",
      description: "Create inline anonymous functions using positional parameters &1, &2, &3...",
      examples: [
        %{capture: "&(&1 + 1)", equivalent: "fn x -> x + 1 end", demo_input: "5", demo_output: "6"},
        %{capture: "&(&1 * &2)", equivalent: "fn x, y -> x * y end", demo_input: "3, 4", demo_output: "12"},
        %{capture: "&(&1 <> \" world\")", equivalent: "fn s -> s <> \" world\" end", demo_input: "hello", demo_output: "hello world"},
        %{capture: "&(&1 * &1)", equivalent: "fn x -> x * x end", demo_input: "7", demo_output: "49"}
      ]
    }
  ]

  @enum_demos [
    %{
      id: "map",
      title: "Enum.map",
      data: "[1, 2, 3, 4, 5]",
      transforms: [
        %{label: "&(&1 * 2)", code: "&(&1 * 2)", result: "[2, 4, 6, 8, 10]"},
        %{label: "&(&1 + 10)", code: "&(&1 + 10)", result: "[11, 12, 13, 14, 15]"},
        %{label: "&Integer.to_string/1", code: "&Integer.to_string/1", result: "[\"1\", \"2\", \"3\", \"4\", \"5\"]"},
        %{label: "&(&1 * &1)", code: "&(&1 * &1)", result: "[1, 4, 9, 16, 25]"}
      ]
    },
    %{
      id: "filter",
      title: "Enum.filter",
      data: "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]",
      transforms: [
        %{label: "&(rem(&1, 2) == 0)", code: "&(rem(&1, 2) == 0)", result: "[2, 4, 6, 8, 10]"},
        %{label: "&(&1 > 5)", code: "&(&1 > 5)", result: "[6, 7, 8, 9, 10]"},
        %{label: "&(&1 <= 3)", code: "&(&1 <= 3)", result: "[1, 2, 3]"},
        %{label: "&(rem(&1, 3) == 0)", code: "&(rem(&1, 3) == 0)", result: "[3, 6, 9]"}
      ]
    },
    %{
      id: "reduce",
      title: "Enum.reduce",
      data: "[1, 2, 3, 4, 5]",
      transforms: [
        %{label: "&(&1 + &2)", code: "&(&1 + &2)", result: "15", acc: "0"},
        %{label: "&(&1 * &2)", code: "&(&1 * &2)", result: "120", acc: "1"},
        %{label: "&max(&1, &2)", code: "&max(&1, &2)", result: "5", acc: "0"},
        %{label: "&(&2 <> to_string(&1))", code: "&(&2 <> to_string(&1))", result: "\"12345\"", acc: "\"\""}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_form, fn -> hd(@capture_forms) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:active_enum_demo, fn -> hd(@enum_demos) end)
     |> assign_new(:selected_transform_idx, fn -> nil end)
     |> assign_new(:show_positional_demo, fn -> false end)
     |> assign_new(:show_gotchas, fn -> false end)
     |> assign_new(:transformer_input, fn -> "Enum.map([1,2,3], fn x -> x * 2 end)" end)
     |> assign_new(:transformer_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">The Capture Operator (&amp;)</h2>
      <p class="text-sm opacity-70 mb-6">
        The capture operator <code class="font-mono bg-base-300 px-1 rounded">&amp;</code> converts named functions into anonymous functions
        that you can pass as arguments. It comes in three flavors: <code class="font-mono bg-base-300 px-1 rounded">&amp;Module.fun/arity</code>,
        <code class="font-mono bg-base-300 px-1 rounded">&amp;fun/arity</code>, and the shorthand <code class="font-mono bg-base-300 px-1 rounded">&amp;(&amp;1 + &amp;2)</code>.
      </p>

      <!-- Three Forms of Capture -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Three Forms of Capture</h3>

          <!-- Form Selector -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for form <- capture_forms() do %>
              <button
                phx-click="select_form"
                phx-target={@myself}
                phx-value-id={form.id}
                class={"btn btn-sm " <> if(@active_form.id == form.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= form.title %>
              </button>
            <% end %>
          </div>

          <p class="text-xs opacity-60 mb-4"><%= @active_form.description %></p>

          <!-- Examples for selected form -->
          <div class="space-y-3">
            <%= for {example, idx} <- Enum.with_index(@active_form.examples) do %>
              <div
                phx-click="select_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"rounded-lg p-3 border-2 cursor-pointer transition-all " <>
                  if(idx == @active_example_idx, do: "border-primary bg-primary/10", else: "border-base-300 bg-base-100 hover:border-base-content/30")}
              >
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <!-- Capture Form -->
                  <div>
                    <div class="text-xs font-bold opacity-60 mb-1">Capture syntax</div>
                    <div class="font-mono text-sm bg-base-300 rounded p-2">
                      <span class="text-primary font-bold"><%= example.capture %></span>
                    </div>
                  </div>

                  <!-- Equivalent -->
                  <div>
                    <div class="text-xs font-bold opacity-60 mb-1">Equivalent anonymous function</div>
                    <div class="font-mono text-sm bg-base-300 rounded p-2">
                      <span class="opacity-70"><%= example.equivalent %></span>
                    </div>
                  </div>
                </div>

                <!-- Demo -->
                <%= if idx == @active_example_idx do %>
                  <div class="mt-3 bg-base-300 rounded-lg p-3 font-mono text-sm">
                    <div class="opacity-50 text-xs mb-1">Demo:</div>
                    <div>
                      <span class="opacity-50">iex&gt; f = </span><span class="text-primary"><%= example.capture %></span>
                    </div>
                    <div>
                      <span class="opacity-50">iex&gt; f.(<%= example.demo_input %>)</span>
                    </div>
                    <div class="text-success font-bold"><%= example.demo_output %></div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Side-by-Side Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Anonymous Function vs Capture: Side-by-Side</h3>
          <p class="text-xs opacity-60 mb-4">
            The capture operator creates an anonymous function from a named function. Both forms are equivalent
            but the capture syntax is more concise.
          </p>

          <div class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Anonymous Function (verbose)</th>
                  <th>Capture (concise)</th>
                  <th>Used With</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="font-mono text-xs">fn x -&gt; String.upcase(x) end</td>
                  <td class="font-mono text-xs text-primary">&amp;String.upcase/1</td>
                  <td class="text-xs">Enum.map(list, ...)</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">fn x -&gt; x * 2 end</td>
                  <td class="font-mono text-xs text-primary">&amp;(&amp;1 * 2)</td>
                  <td class="text-xs">Enum.map(list, ...)</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">fn x -&gt; rem(x, 2) == 0 end</td>
                  <td class="font-mono text-xs text-primary">&amp;(rem(&amp;1, 2) == 0)</td>
                  <td class="text-xs">Enum.filter(list, ...)</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">fn acc, x -&gt; acc + x end</td>
                  <td class="font-mono text-xs text-primary">&amp;(&amp;1 + &amp;2)</td>
                  <td class="text-xs">Enum.reduce(list, 0, ...)</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">fn x -&gt; is_atom(x) end</td>
                  <td class="font-mono text-xs text-primary">&amp;is_atom/1</td>
                  <td class="text-xs">Enum.filter(list, ...)</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">fn x -&gt; inspect(x) end</td>
                  <td class="font-mono text-xs text-primary">&amp;inspect/1</td>
                  <td class="text-xs">Enum.map(list, ...)</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Using Captures with Enum -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Using Captures with Enum</h3>
          <p class="text-xs opacity-60 mb-4">
            The capture operator shines when passing functions to higher-order functions like
            <code class="font-mono bg-base-300 px-1 rounded">Enum.map/2</code>,
            <code class="font-mono bg-base-300 px-1 rounded">Enum.filter/2</code>, and
            <code class="font-mono bg-base-300 px-1 rounded">Enum.reduce/3</code>.
          </p>

          <!-- Enum Demo Selector -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for demo <- enum_demos() do %>
              <button
                phx-click="select_enum_demo"
                phx-target={@myself}
                phx-value-id={demo.id}
                class={"btn btn-sm " <> if(@active_enum_demo.id == demo.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= demo.title %>
              </button>
            <% end %>
          </div>

          <!-- Data -->
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <span class="opacity-50">data = </span><span class="text-info"><%= @active_enum_demo.data %></span>
          </div>

          <!-- Transforms -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
            <%= for {transform, idx} <- Enum.with_index(@active_enum_demo.transforms) do %>
              <div
                phx-click="select_transform"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"rounded-lg p-3 border-2 cursor-pointer transition-all " <>
                  if(idx == @selected_transform_idx, do: "border-success bg-success/10", else: "border-base-300 bg-base-100 hover:border-base-content/30")}
              >
                <div class="font-mono text-sm mb-2">
                  <span class="opacity-50"><%= @active_enum_demo.title %>(data, </span>
                  <span class="text-primary font-bold"><%= transform.label %></span>
                  <%= if Map.has_key?(transform, :acc) do %>
                    <span class="opacity-50">, <%= transform.acc %>)</span>
                  <% else %>
                    <span class="opacity-50">)</span>
                  <% end %>
                </div>

                <%= if idx == @selected_transform_idx do %>
                  <div class="font-mono text-sm">
                    <span class="opacity-50">&rArr; </span>
                    <span class="text-success font-bold"><%= transform.result %></span>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Positional Parameters Demo -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Positional Parameters: &amp;1, &amp;2, &amp;3</h3>
            <button
              phx-click="toggle_positional"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_positional_demo, do: "Hide", else: "Show Details" %>
            </button>
          </div>

          <%= if @show_positional_demo do %>
            <p class="text-xs opacity-60 mb-4">
              In the shorthand form, <code class="font-mono bg-base-300 px-1 rounded">&amp;1</code> refers to the first argument,
              <code class="font-mono bg-base-300 px-1 rounded">&amp;2</code> to the second, and so on. The highest
              number determines the arity.
            </p>

            <div class="space-y-3">
              <!-- One parameter -->
              <div class="bg-base-100 border border-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-info badge-sm">arity: 1</span>
                  <span class="text-xs opacity-60">One parameter</span>
                </div>
                <div class="font-mono text-sm space-y-1">
                  <div><span class="text-primary">&amp;(&amp;1 * 2)</span> <span class="opacity-30">=</span> <span class="opacity-60">fn x -&gt; x * 2 end</span></div>
                  <div class="text-xs opacity-50">iex&gt; f = &amp;(&amp;1 * 2); f.(5) <span class="text-success"># 10</span></div>
                </div>
              </div>

              <!-- Two parameters -->
              <div class="bg-base-100 border border-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-warning badge-sm">arity: 2</span>
                  <span class="text-xs opacity-60">Two parameters</span>
                </div>
                <div class="font-mono text-sm space-y-1">
                  <div><span class="text-primary">&amp;(&amp;1 + &amp;2)</span> <span class="opacity-30">=</span> <span class="opacity-60">fn x, y -&gt; x + y end</span></div>
                  <div class="text-xs opacity-50">iex&gt; f = &amp;(&amp;1 + &amp;2); f.(3, 4) <span class="text-success"># 7</span></div>
                </div>
              </div>

              <!-- Three parameters -->
              <div class="bg-base-100 border border-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-error badge-sm">arity: 3</span>
                  <span class="text-xs opacity-60">Three parameters</span>
                </div>
                <div class="font-mono text-sm space-y-1">
                  <div><span class="text-primary">&amp;(&amp;1 + &amp;2 + &amp;3)</span> <span class="opacity-30">=</span> <span class="opacity-60">fn x, y, z -&gt; x + y + z end</span></div>
                  <div class="text-xs opacity-50">iex&gt; f = &amp;(&amp;1 + &amp;2 + &amp;3); f.(1, 2, 3) <span class="text-success"># 6</span></div>
                </div>
              </div>

              <!-- Reordering parameters -->
              <div class="bg-base-100 border border-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-accent badge-sm">reorder</span>
                  <span class="text-xs opacity-60">Parameters can be used in any order</span>
                </div>
                <div class="font-mono text-sm space-y-1">
                  <div><span class="text-primary">&amp;(&amp;2 - &amp;1)</span> <span class="opacity-30">=</span> <span class="opacity-60">fn x, y -&gt; y - x end</span></div>
                  <div class="text-xs opacity-50">iex&gt; f = &amp;(&amp;2 - &amp;1); f.(3, 10) <span class="text-success"># 7</span></div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Interactive Transformer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive Capture Transformer</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter an Elixir expression using capture syntax and see it evaluated live.
            Try expressions like <code class="font-mono bg-base-300 px-1 rounded">Enum.map([1,2,3], &amp;(&amp;1 * 10))</code>.
          </p>

          <form phx-submit="run_transformer" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <div class="flex gap-2">
                <input
                  type="text"
                  name="code"
                  value={@transformer_input}
                  placeholder="Enum.map([1,2,3], &(&1 * 2))"
                  class="input input-bordered input-sm font-mono flex-1"
                  autocomplete="off"
                />
                <button type="submit" class="btn btn-primary btn-sm">Run</button>
              </div>
            </div>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <%= for {label, code} <- quick_examples() do %>
              <button
                phx-click="quick_transform"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <!-- Result -->
          <%= if @transformer_result do %>
            <div class={"alert text-sm " <> if(@transformer_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @transformer_result.input %></div>
                <div class="font-mono font-bold mt-1"><%= @transformer_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Gotchas -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Gotchas &amp; Pitfalls</h3>
            <button
              phx-click="toggle_gotchas"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_gotchas, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_gotchas do %>
            <div class="space-y-4">
              <!-- Gotcha 1: &(&1) vs & &1 -->
              <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                <h4 class="font-bold text-error text-sm mb-2">Gotcha: &amp;(&amp;1) needs an expression</h4>
                <div class="font-mono text-sm space-y-2">
                  <div class="bg-base-100 rounded p-2">
                    <div class="text-error"># Invalid - &amp;(&amp;1) is just identity, use a real expression</div>
                    <div>&amp;(&amp;1) <span class="text-error"># Compiler warning!</span></div>
                  </div>
                  <div class="bg-base-100 rounded p-2">
                    <div class="text-success"># Valid - wrap in an expression or use Function.identity/1</div>
                    <div>&amp;Function.identity/1 <span class="text-success"># OK</span></div>
                    <div>fn x -&gt; x end <span class="text-success"># OK</span></div>
                  </div>
                </div>
              </div>

              <!-- Gotcha 2: Can't use with control flow -->
              <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
                <h4 class="font-bold text-warning text-sm mb-2">Gotcha: No control flow in &amp;()</h4>
                <div class="font-mono text-sm space-y-2">
                  <div class="bg-base-100 rounded p-2">
                    <div class="text-error"># Invalid - cannot use if/case/cond inside &amp;()</div>
                    <div>&amp;(if &amp;1 &gt; 0, do: &amp;1, else: 0) <span class="text-error"># Compile error!</span></div>
                  </div>
                  <div class="bg-base-100 rounded p-2">
                    <div class="text-success"># Use fn instead</div>
                    <div>fn x -&gt; if x &gt; 0, do: x, else: 0 end <span class="text-success"># OK</span></div>
                  </div>
                </div>
              </div>

              <!-- Gotcha 3: Arity must match -->
              <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
                <h4 class="font-bold text-warning text-sm mb-2">Gotcha: Arity must match usage</h4>
                <div class="font-mono text-sm space-y-2">
                  <div class="bg-base-100 rounded p-2">
                    <div class="text-error"># Wrong arity - String.split has multiple arities</div>
                    <div>Enum.map(["a b", "c d"], &amp;String.split/1) <span class="text-success"># splits on whitespace</span></div>
                    <div>Enum.map(["a-b", "c-d"], &amp;String.split/2) <span class="text-error"># needs 2 args!</span></div>
                  </div>
                  <div class="bg-base-100 rounded p-2">
                    <div class="text-success"># Fix: use shorthand to supply extra args</div>
                    <div>&amp;String.split(&amp;1, "-") <span class="text-success"># provides the delimiter</span></div>
                  </div>
                </div>
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
              <span><code class="font-mono bg-base-100 px-1 rounded">&amp;Module.fun/arity</code> captures a named function as a value you can pass around.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">&amp;fun/arity</code> captures local or imported functions the same way.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">&amp;(&amp;1 + &amp;2)</code> creates an inline anonymous function with positional args.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>The highest <code class="font-mono bg-base-100 px-1 rounded">&amp;N</code> used determines the function's arity.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Captures are most useful with <code class="font-mono bg-base-100 px-1 rounded">Enum</code> functions for concise data transformations.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_form", %{"id" => id}, socket) do
    form = Enum.find(capture_forms(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_form: form)
     |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, active_example_idx: idx)}
  end

  def handle_event("select_enum_demo", %{"id" => id}, socket) do
    demo = Enum.find(enum_demos(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_enum_demo: demo)
     |> assign(selected_transform_idx: nil)}
  end

  def handle_event("select_transform", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)

    new_idx =
      if idx == socket.assigns.selected_transform_idx, do: nil, else: idx

    {:noreply, assign(socket, selected_transform_idx: new_idx)}
  end

  def handle_event("toggle_positional", _params, socket) do
    {:noreply, assign(socket, show_positional_demo: !socket.assigns.show_positional_demo)}
  end

  def handle_event("toggle_gotchas", _params, socket) do
    {:noreply, assign(socket, show_gotchas: !socket.assigns.show_gotchas)}
  end

  def handle_event("run_transformer", %{"code" => code}, socket) do
    result = evaluate_capture(String.trim(code))

    {:noreply,
     socket
     |> assign(transformer_input: code)
     |> assign(transformer_result: result)}
  end

  def handle_event("quick_transform", %{"code" => code}, socket) do
    result = evaluate_capture(code)

    {:noreply,
     socket
     |> assign(transformer_input: code)
     |> assign(transformer_result: result)}
  end

  # Helpers

  defp capture_forms, do: @capture_forms
  defp enum_demos, do: @enum_demos

  defp quick_examples do
    [
      {"map * 10", "Enum.map([1, 2, 3, 4, 5], &(&1 * 10))"},
      {"filter even", "Enum.filter(1..10, &(rem(&1, 2) == 0))"},
      {"sum", "Enum.reduce([1, 2, 3, 4, 5], 0, &(&1 + &2))"},
      {"upcase", ~s|Enum.map(["hello", "world"], &String.upcase/1)|},
      {"to_string", "Enum.map([1, 2, 3], &Integer.to_string/1)"},
      {"sort desc", "Enum.sort([3, 1, 4, 1, 5], &(&1 >= &2))"}
    ]
  end

  defp evaluate_capture(code) do
    try do
      {result, _bindings} = Code.eval_string(code)

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
