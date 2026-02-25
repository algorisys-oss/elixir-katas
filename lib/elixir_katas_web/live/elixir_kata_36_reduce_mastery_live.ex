defmodule ElixirKatasWeb.ElixirKata36ReduceMasteryLive do
  use ElixirKatasWeb, :live_component

  @reduce_examples [
    %{
      id: "sum",
      title: "Sum (using reduce)",
      description: "Implement Enum.sum using only reduce.",
      code: "Enum.reduce([10, 20, 30, 40], 0, fn x, acc -> x + acc end)",
      data: [10, 20, 30, 40],
      initial_acc: 0,
      steps: [
        %{element: 10, acc_before: 0, expression: "10 + 0", acc_after: 10},
        %{element: 20, acc_before: 10, expression: "20 + 10", acc_after: 30},
        %{element: 30, acc_before: 30, expression: "30 + 30", acc_after: 60},
        %{element: 40, acc_before: 60, expression: "40 + 60", acc_after: 100}
      ],
      final: "100",
      equivalent: "Enum.sum([10, 20, 30, 40])"
    },
    %{
      id: "map",
      title: "Map (using reduce)",
      description: "Build Enum.map from reduce by accumulating a new list.",
      code: "Enum.reduce([1, 2, 3, 4], [], fn x, acc -> acc ++ [x * 2] end)",
      data: [1, 2, 3, 4],
      initial_acc: "[]",
      steps: [
        %{element: 1, acc_before: "[]", expression: "[] ++ [1 * 2]", acc_after: "[2]"},
        %{element: 2, acc_before: "[2]", expression: "[2] ++ [2 * 2]", acc_after: "[2, 4]"},
        %{element: 3, acc_before: "[2, 4]", expression: "[2, 4] ++ [3 * 2]", acc_after: "[2, 4, 6]"},
        %{element: 4, acc_before: "[2, 4, 6]", expression: "[2, 4, 6] ++ [4 * 2]", acc_after: "[2, 4, 6, 8]"}
      ],
      final: "[2, 4, 6, 8]",
      equivalent: "Enum.map([1, 2, 3, 4], &(&1 * 2))"
    },
    %{
      id: "filter",
      title: "Filter (using reduce)",
      description: "Build Enum.filter from reduce by conditionally accumulating.",
      code: "Enum.reduce([1, 2, 3, 4, 5, 6], [], fn x, acc ->\n  if rem(x, 2) == 0, do: acc ++ [x], else: acc\nend)",
      data: [1, 2, 3, 4, 5, 6],
      initial_acc: "[]",
      steps: [
        %{element: 1, acc_before: "[]", expression: "odd? skip", acc_after: "[]"},
        %{element: 2, acc_before: "[]", expression: "even! [] ++ [2]", acc_after: "[2]"},
        %{element: 3, acc_before: "[2]", expression: "odd? skip", acc_after: "[2]"},
        %{element: 4, acc_before: "[2]", expression: "even! [2] ++ [4]", acc_after: "[2, 4]"},
        %{element: 5, acc_before: "[2, 4]", expression: "odd? skip", acc_after: "[2, 4]"},
        %{element: 6, acc_before: "[2, 4]", expression: "even! [2, 4] ++ [6]", acc_after: "[2, 4, 6]"}
      ],
      final: "[2, 4, 6]",
      equivalent: "Enum.filter([1, 2, 3, 4, 5, 6], &(rem(&1, 2) == 0))"
    },
    %{
      id: "max",
      title: "Max (using reduce)",
      description: "Find the maximum by tracking the largest value seen so far.",
      code: "Enum.reduce([3, 7, 2, 9, 4], fn x, acc ->\n  if x > acc, do: x, else: acc\nend)",
      data: [3, 7, 2, 9, 4],
      initial_acc: "3 (first element)",
      steps: [
        %{element: 7, acc_before: "3", expression: "7 > 3? yes!", acc_after: "7"},
        %{element: 2, acc_before: "7", expression: "2 > 7? no", acc_after: "7"},
        %{element: 9, acc_before: "7", expression: "9 > 7? yes!", acc_after: "9"},
        %{element: 4, acc_before: "9", expression: "4 > 9? no", acc_after: "9"}
      ],
      final: "9",
      equivalent: "Enum.max([3, 7, 2, 9, 4])"
    },
    %{
      id: "frequencies",
      title: "Frequencies (using reduce)",
      description: "Count occurrences by accumulating into a map.",
      code: ~s|Enum.reduce(["a", "b", "a", "c", "b", "a"], %{}, fn x, acc ->\n  Map.update(acc, x, 1, &(&1 + 1))\nend)|,
      data: ["a", "b", "a", "c", "b", "a"],
      initial_acc: "%{}",
      steps: [
        %{element: "a", acc_before: "%{}", expression: ~s|put "a" => 1|, acc_after: ~s|%{"a" => 1}|},
        %{element: "b", acc_before: ~s|%{"a" => 1}|, expression: ~s|put "b" => 1|, acc_after: ~s|%{"a" => 1, "b" => 1}|},
        %{element: "a", acc_before: ~s|%{"a" => 1, "b" => 1}|, expression: ~s|update "a" => 2|, acc_after: ~s|%{"a" => 2, "b" => 1}|},
        %{element: "c", acc_before: ~s|%{"a" => 2, "b" => 1}|, expression: ~s|put "c" => 1|, acc_after: ~s|%{"a" => 2, "b" => 1, "c" => 1}|},
        %{element: "b", acc_before: ~s|%{"a" => 2, "b" => 1, "c" => 1}|, expression: ~s|update "b" => 2|, acc_after: ~s|%{"a" => 2, "b" => 2, "c" => 1}|},
        %{element: "a", acc_before: ~s|%{"a" => 2, "b" => 2, "c" => 1}|, expression: ~s|update "a" => 3|, acc_after: ~s|%{"a" => 3, "b" => 2, "c" => 1}|}
      ],
      final: ~s|%{"a" => 3, "b" => 2, "c" => 1}|,
      equivalent: ~s|Enum.frequencies(["a", "b", "a", "c", "b", "a"])|
    },
    %{
      id: "reverse",
      title: "Reverse (using reduce)",
      description: "Reverse a list by prepending each element to the accumulator.",
      code: "Enum.reduce([1, 2, 3, 4], [], fn x, acc -> [x | acc] end)",
      data: [1, 2, 3, 4],
      initial_acc: "[]",
      steps: [
        %{element: 1, acc_before: "[]", expression: "[1 | []]", acc_after: "[1]"},
        %{element: 2, acc_before: "[1]", expression: "[2 | [1]]", acc_after: "[2, 1]"},
        %{element: 3, acc_before: "[2, 1]", expression: "[3 | [2, 1]]", acc_after: "[3, 2, 1]"},
        %{element: 4, acc_before: "[3, 2, 1]", expression: "[4 | [3, 2, 1]]", acc_after: "[4, 3, 2, 1]"}
      ],
      final: "[4, 3, 2, 1]",
      equivalent: "Enum.reverse([1, 2, 3, 4])"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@reduce_examples) end)
     |> assign_new(:visible_step, fn -> 0 end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:show_acc_types, fn -> false end)
     |> assign_new(:show_reduce_vs, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Reduce Mastery</h2>
      <p class="text-sm opacity-70 mb-6">
        <code class="font-mono bg-base-300 px-1 rounded">Enum.reduce/3</code> is the most fundamental
        Enum function. Every other Enum function (map, filter, sum, max, frequencies) can be
        built using reduce alone. Master reduce and you master data processing.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for ex <- reduce_examples() do %>
          <button
            phx-click="select_example"
            phx-target={@myself}
            phx-value-id={ex.id}
            class={"btn btn-sm " <> if(@active_example.id == ex.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= ex.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Example -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-1"><%= @active_example.title %></h3>
          <p class="text-xs opacity-60 mb-3"><%= @active_example.description %></p>

          <!-- Code Display -->
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4 whitespace-pre-wrap"><%= @active_example.code %></div>

          <!-- Step-Through Animation -->
          <div class="mb-4">
            <div class="flex items-center justify-between mb-3">
              <h4 class="text-xs font-bold opacity-60">Accumulator step-through:</h4>
              <div class="flex gap-2">
                <button
                  phx-click="step_prev"
                  phx-target={@myself}
                  disabled={@visible_step <= 0}
                  class="btn btn-xs btn-outline"
                >
                  &larr;
                </button>
                <span class="text-xs opacity-50 self-center">
                  <%= @visible_step %>/<%= length(@active_example.steps) %>
                </span>
                <button
                  phx-click="step_next"
                  phx-target={@myself}
                  disabled={@visible_step >= length(@active_example.steps)}
                  class="btn btn-xs btn-primary"
                >
                  &rarr;
                </button>
                <button
                  phx-click="step_all"
                  phx-target={@myself}
                  class="btn btn-xs btn-accent"
                >
                  All
                </button>
              </div>
            </div>

            <!-- Initial Accumulator -->
            <div class="bg-info/10 border border-info/30 rounded-lg p-2 mb-2 flex items-center gap-3">
              <span class="badge badge-info badge-sm">init</span>
              <span class="font-mono text-sm">
                <span class="opacity-50">acc = </span>
                <span class="text-info font-bold"><%= @active_example.initial_acc %></span>
              </span>
            </div>

            <!-- Data Elements -->
            <div class="flex flex-wrap gap-1 mb-3">
              <%= for {item, idx} <- Enum.with_index(@active_example.data) do %>
                <div class={"w-10 h-10 rounded-lg flex items-center justify-center font-mono text-sm font-bold transition-all " <>
                  cond do
                    idx < @visible_step -> "bg-success/20 border border-success/30 opacity-60"
                    idx == @visible_step and @visible_step < length(@active_example.steps) -> "bg-primary text-primary-content ring-2 ring-primary"
                    true -> "bg-base-300 opacity-40"
                  end}>
                  <%= inspect(item) %>
                </div>
              <% end %>
            </div>

            <!-- Steps -->
            <div class="space-y-1">
              <%= for {step, idx} <- Enum.with_index(@active_example.steps) do %>
                <div class={"rounded-lg p-2 transition-all " <>
                  cond do
                    idx >= @visible_step -> "opacity-20 bg-base-100"
                    idx == @visible_step - 1 -> "bg-accent/15 border border-accent/30"
                    true -> "bg-base-100"
                  end}>
                  <div class="flex items-center gap-3">
                    <div class="flex-shrink-0 w-6 h-6 rounded-full bg-base-300 flex items-center justify-center text-xs font-bold">
                      <%= idx + 1 %>
                    </div>
                    <div class="font-mono text-sm flex-1">
                      <span class="text-info"><%= inspect(step.element) %></span>
                      <span class="opacity-30 mx-1">|</span>
                      <span class="opacity-50">acc=<%= step.acc_before %></span>
                      <span class="opacity-30 mx-1">&rarr;</span>
                      <span class="text-xs"><%= step.expression %></span>
                      <span class="opacity-30 mx-1">&rarr;</span>
                      <span class="text-accent font-bold">acc=<%= step.acc_after %></span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Current Accumulator State -->
            <div class="mt-3 bg-accent/10 border border-accent/30 rounded-lg p-3 flex items-center gap-3">
              <span class="badge badge-accent badge-sm">
                <%= if @visible_step >= length(@active_example.steps), do: "final", else: "current" %>
              </span>
              <span class="font-mono text-sm">
                <span class="opacity-50">acc = </span>
                <span class="text-accent font-bold text-lg">
                  <%= if @visible_step == 0 do %>
                    <%= @active_example.initial_acc %>
                  <% else %>
                    <%= (@active_example.steps |> Enum.at(@visible_step - 1)).acc_after %>
                  <% end %>
                </span>
              </span>
            </div>

            <!-- Equivalent -->
            <%= if @visible_step >= length(@active_example.steps) do %>
              <div class="mt-3 bg-success/10 border border-success/30 rounded-lg p-3">
                <div class="text-xs font-bold opacity-60 mb-1">Equivalent built-in:</div>
                <div class="font-mono text-sm text-success"><%= @active_example.equivalent %></div>
                <div class="font-mono text-sm text-success font-bold mt-1">&rArr; <%= @active_example.final %></div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Accumulator Types -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Accumulator Types</h3>
            <button
              phx-click="toggle_acc_types"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_acc_types, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_acc_types do %>
            <p class="text-xs opacity-60 mb-4">
              The accumulator can be any data type. This is what makes reduce so powerful.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div class="bg-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-info badge-sm">Integer</span>
                  <span class="text-xs opacity-60">Sum, count, product</span>
                </div>
                <div class="font-mono text-xs">
                  <div>Enum.reduce(list, 0, fn x, acc -&gt;</div>
                  <div class="ml-2">x + acc</div>
                  <div>end)</div>
                </div>
              </div>

              <div class="bg-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-success badge-sm">List</span>
                  <span class="text-xs opacity-60">Map, filter, reverse</span>
                </div>
                <div class="font-mono text-xs">
                  <div>Enum.reduce(list, [], fn x, acc -&gt;</div>
                  <div class="ml-2">[transform(x) | acc]</div>
                  <div>end)</div>
                </div>
              </div>

              <div class="bg-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-warning badge-sm">Map</span>
                  <span class="text-xs opacity-60">Frequencies, group_by, index</span>
                </div>
                <div class="font-mono text-xs">
                  <div>Enum.reduce(list, %&lbrace;&rbrace;, fn x, acc -&gt;</div>
                  <div class="ml-2">Map.update(acc, x, 1, &amp;(&amp;1 + 1))</div>
                  <div>end)</div>
                </div>
              </div>

              <div class="bg-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-error badge-sm">Tuple</span>
                  <span class="text-xs opacity-60">Multiple accumulators at once</span>
                </div>
                <div class="font-mono text-xs">
                  <div>Enum.reduce(list, &lbrace;0, 0&rbrace;, fn x, &lbrace;sum, count&rbrace; -&gt;</div>
                  <div class="ml-2">&lbrace;sum + x, count + 1&rbrace;</div>
                  <div>end)</div>
                </div>
              </div>

              <div class="bg-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-accent badge-sm">String</span>
                  <span class="text-xs opacity-60">Building strings</span>
                </div>
                <div class="font-mono text-xs">
                  <div>Enum.reduce(words, "", fn w, acc -&gt;</div>
                  <div class="ml-2">acc &lt;&gt; " " &lt;&gt; w</div>
                  <div>end)</div>
                </div>
              </div>

              <div class="bg-base-300 rounded-lg p-3">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-primary badge-sm">Boolean</span>
                  <span class="text-xs opacity-60">All?, any?, none?</span>
                </div>
                <div class="font-mono text-xs">
                  <div>Enum.reduce(list, true, fn x, acc -&gt;</div>
                  <div class="ml-2">acc and predicate(x)</div>
                  <div>end)</div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Reduce vs Specialized Functions -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Reduce vs Specialized Functions</h3>
            <button
              phx-click="toggle_reduce_vs"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_reduce_vs, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_reduce_vs do %>
            <p class="text-xs opacity-60 mb-4">
              While reduce can do everything, specialized functions are more readable and often faster.
              Use reduce when no built-in function fits your needs.
            </p>

            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Task</th>
                    <th>With Reduce</th>
                    <th>Better Alternative</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>Sum</td>
                    <td class="font-mono text-xs">reduce(list, 0, &amp;(&amp;1 + &amp;2))</td>
                    <td class="font-mono text-xs text-success">Enum.sum(list)</td>
                  </tr>
                  <tr>
                    <td>Transform</td>
                    <td class="font-mono text-xs">reduce(list, [], fn x, acc -&gt; acc ++ [f.(x)] end)</td>
                    <td class="font-mono text-xs text-success">Enum.map(list, f)</td>
                  </tr>
                  <tr>
                    <td>Select</td>
                    <td class="font-mono text-xs">reduce(list, [], fn x, acc -&gt; if(p.(x), do: acc ++ [x], else: acc) end)</td>
                    <td class="font-mono text-xs text-success">Enum.filter(list, p)</td>
                  </tr>
                  <tr>
                    <td>Maximum</td>
                    <td class="font-mono text-xs">reduce(list, fn x, acc -&gt; max(x, acc) end)</td>
                    <td class="font-mono text-xs text-success">Enum.max(list)</td>
                  </tr>
                  <tr>
                    <td>Count values</td>
                    <td class="font-mono text-xs">reduce(list, %&lbrace;&rbrace;, ...)</td>
                    <td class="font-mono text-xs text-success">Enum.frequencies(list)</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="alert alert-info text-sm mt-4">
              <div>
                <div class="font-bold">When to use reduce</div>
                <span>Use reduce when you need custom accumulation logic that doesn't fit any built-in function,
                  or when you need to compute multiple things in a single pass through the data.</span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try It Yourself -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Try It Yourself</h3>

          <form phx-submit="sandbox_eval" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <input
                type="text"
                name="code"
                value={@sandbox_code}
                placeholder="Enum.reduce([1, 2, 3, 4], 0, &(&1 + &2))"
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Run</button>
          </form>

          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="Enum.reduce(1..10, 1, &(&1 * &2))" class="btn btn-xs btn-outline">factorial(10)</button>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="Enum.reduce([1, 2, 3, 4, 5], [], fn x, acc -> [x * x | acc] end) |> Enum.reverse()" class="btn btn-xs btn-outline">map via reduce</button>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code={~s|Enum.reduce(String.graphemes("hello world"), %{}, fn char, acc -> Map.update(acc, char, 1, &(&1 + 1)) end)|} class="btn btn-xs btn-outline">char freq</button>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="Enum.reduce(1..10, {0, 0}, fn x, {sum, count} -> {sum + x, count + 1} end)" class="btn btn-xs btn-outline">sum+count</button>
          </div>

          <%= if @sandbox_result do %>
            <div class={"alert text-sm " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @sandbox_result.code %></div>
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
              <span><strong>reduce/3</strong> takes: enumerable, initial accumulator, and a function <code class="font-mono bg-base-100 px-1 rounded">fn element, acc -&gt; new_acc end</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>reduce/2</strong> (no initial acc) uses the first element as the initial accumulator. Fails on empty collections.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>The <strong>accumulator</strong> can be any type: integer, list, map, tuple, string, or even a struct.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>Every Enum function (<strong>map, filter, sum, max, frequencies, group_by</strong>) can be implemented using reduce.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Use <strong>tuple accumulators</strong> to compute multiple values in a single pass: <code class="font-mono bg-base-100 px-1 rounded">&lbrace;sum, count&rbrace;</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">6</span>
              <span>Prefer <strong>specialized functions</strong> (map, filter, sum) for readability. Use reduce when no built-in fits.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    example = Enum.find(reduce_examples(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_example: example)
     |> assign(visible_step: 0)}
  end

  def handle_event("step_next", _params, socket) do
    max_step = length(socket.assigns.active_example.steps)
    new_step = min(socket.assigns.visible_step + 1, max_step)
    {:noreply, assign(socket, visible_step: new_step)}
  end

  def handle_event("step_prev", _params, socket) do
    new_step = max(socket.assigns.visible_step - 1, 0)
    {:noreply, assign(socket, visible_step: new_step)}
  end

  def handle_event("step_all", _params, socket) do
    {:noreply, assign(socket, visible_step: length(socket.assigns.active_example.steps))}
  end

  def handle_event("toggle_acc_types", _params, socket) do
    {:noreply, assign(socket, show_acc_types: !socket.assigns.show_acc_types)}
  end

  def handle_event("toggle_reduce_vs", _params, socket) do
    {:noreply, assign(socket, show_reduce_vs: !socket.assigns.show_reduce_vs)}
  end

  def handle_event("sandbox_eval", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  def handle_event("quick_example", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp reduce_examples, do: @reduce_examples

  defp evaluate_code(code) do
    code = String.trim(code)

    if code == "" do
      nil
    else
      try do
        {result, _bindings} = Code.eval_string(code)
        %{ok: true, code: code, output: inspect(result, pretty: true, limit: 50)}
      rescue
        e ->
          %{ok: false, code: code, output: "Error: #{Exception.message(e)}"}
      end
    end
  end
end
