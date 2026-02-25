defmodule ElixirKatasWeb.ElixirKata30ComprehensionsLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "basic",
      title: "Basic Generator",
      code: "for x <- [1, 2, 3, 4, 5], do: x * x",
      result: "[1, 4, 9, 16, 25]",
      explanation: "The simplest comprehension: one generator that iterates over a list and transforms each element."
    },
    %{
      id: "filter",
      title: "With Filter",
      code: "for x <- 1..10, rem(x, 2) == 0, do: x * x",
      result: "[4, 16, 36, 64, 100]",
      explanation: "Filters (boolean expressions after generators) keep only matching elements. Like Enum.filter + Enum.map combined."
    },
    %{
      id: "multi_gen",
      title: "Multiple Generators",
      code: ~s|for x <- [:a, :b], y <- [1, 2, 3], do: {x, y}|,
      result: ~s|[a: 1, a: 2, a: 3, b: 1, b: 2, b: 3]|,
      explanation: "Multiple generators produce a Cartesian product: every combination of x and y."
    },
    %{
      id: "multi_filter",
      title: "Multiple Generators + Filter",
      code: "for x <- 1..5, y <- 1..5, x < y, do: {x, y}",
      result: ~s|[{1, 2}, {1, 3}, {1, 4}, {1, 5}, {2, 3}, {2, 4}, {2, 5}, {3, 4}, {3, 5}, {4, 5}]|,
      explanation: "Filters can reference variables from any generator. Here we keep only pairs where x < y."
    },
    %{
      id: "string_gen",
      title: "String Generator",
      code: ~s|for <<c <- "hello">>, do: c + 1|,
      result: "[105, 102, 109, 109, 112]",
      explanation: "Binary generators iterate over bytes. Each byte of the string becomes the variable c."
    },
    %{
      id: "pattern_gen",
      title: "Pattern in Generator",
      code: ~s|for {:ok, val} <- [{:ok, 1}, {:error, "bad"}, {:ok, 3}], do: val * 10|,
      result: "[10, 30]",
      explanation: "When a generator has a pattern, non-matching elements are silently skipped (no error)."
    }
  ]

  @into_examples [
    %{
      id: "into_map",
      title: "Into Map",
      code: ~s|for {k, v} <- [a: 1, b: 2, c: 3], into: %{}, do: {k, v * 10}|,
      result: ~s|%{a: 10, b: 20, c: 30}|,
      explanation: "Use :into to collect results into a map. The do block must return {key, value} tuples."
    },
    %{
      id: "into_mapset",
      title: "Into MapSet",
      code: "for x <- [1, 2, 2, 3, 3, 3], into: MapSet.new(), do: x",
      result: "MapSet.new([1, 2, 3])",
      explanation: "Collect into a MapSet for automatic deduplication."
    },
    %{
      id: "into_string",
      title: "Into String",
      code: ~s|for <<c <- "hello">>, into: "", do: <<c - 32>>|,
      result: ~s|"HELLO"|,
      explanation: ~s|Collect into a string (binary). Each iteration must produce a binary. Here we subtract 32 to convert lowercase to uppercase ASCII.|
    },
    %{
      id: "into_existing_map",
      title: "Into Existing Map",
      code: ~s|for {k, v} <- [b: 20, c: 30], into: %{a: 1}, do: {k, v}|,
      result: ~s|%{a: 1, b: 20, c: 30}|,
      explanation: "You can merge into an existing map by passing it as the :into value."
    }
  ]

  @comparison_items [
    %{
      id: "map_filter",
      title: "Map + Filter",
      comprehension: "for x <- 1..10, rem(x, 2) == 0, do: x * x",
      enum_version: "1..10\n|> Enum.filter(&(rem(&1, 2) == 0))\n|> Enum.map(&(&1 * &1))",
      result: "[4, 16, 36, 64, 100]",
      note: "For simple filter+map, both are equivalent. The comprehension is one pass."
    },
    %{
      id: "cartesian",
      title: "Cartesian Product",
      comprehension: "for x <- 1..3, y <- 1..3, do: {x, y}",
      enum_version: "Enum.flat_map(1..3, fn x ->\n  Enum.map(1..3, fn y -> {x, y} end)\nend)",
      result: ~s|[{1, 1}, {1, 2}, {1, 3}, {2, 1}, {2, 2}, ...]|,
      note: "For Cartesian products, comprehensions are much cleaner than nested Enum calls."
    },
    %{
      id: "into_map_comp",
      title: "Collect Into Map",
      comprehension: ~s|for {k, v} <- list, v > 0, into: %{}, do: {k, v}|,
      enum_version: "list\n|> Enum.filter(fn {_k, v} -> v > 0 end)\n|> Map.new()",
      result: "filtered map",
      note: "Both work. The comprehension combines filtering and collection in one expression."
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@examples) end)
     |> assign_new(:active_into, fn -> hd(@into_examples) end)
     |> assign_new(:active_comparison, fn -> hd(@comparison_items) end)
     |> assign_new(:show_cartesian, fn -> false end)
     |> assign_new(:cartesian_a, fn -> "1..4" end)
     |> assign_new(:cartesian_b, fn -> "1..4" end)
     |> assign_new(:cartesian_result, fn -> nil end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:show_comparison, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Comprehensions</h2>
      <p class="text-sm opacity-70 mb-6">
        The <code class="font-mono bg-base-300 px-1 rounded">for</code> special form provides a concise
        way to iterate over enumerables, filter elements, and collect results. Comprehensions support
        multiple generators, filters, pattern matching, and collecting into different data structures.
      </p>

      <!-- Basic Examples -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Generators &amp; Filters</h3>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for ex <- examples() do %>
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

          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_example.code %></div>

            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold"><%= @active_example.result %></div>
            </div>

            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">How it works</div>
              <div class="text-sm"><%= @active_example.explanation %></div>
            </div>
          </div>

          <!-- Comprehension anatomy -->
          <div class="mt-4 bg-base-300 rounded-lg p-4">
            <div class="text-xs font-bold opacity-60 mb-2">Anatomy of a comprehension:</div>
            <div class="font-mono text-sm">
              <span class="text-primary font-bold">for</span>
              <span class="text-info"> x &lt;- enumerable</span><span class="opacity-50">,</span>
              <span class="text-warning"> filter_expr</span><span class="opacity-50">,</span>
              <span class="text-accent"> into: collectable</span><span class="opacity-50">,</span>
              <span class="text-primary font-bold"> do:</span>
              <span class="text-success"> transform(x)</span>
            </div>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-2 mt-3 text-xs">
              <div class="bg-info/10 rounded p-2"><span class="text-info font-bold">generator</span> - binds each element</div>
              <div class="bg-warning/10 rounded p-2"><span class="text-warning font-bold">filter</span> - optional boolean guard</div>
              <div class="bg-accent/10 rounded p-2"><span class="text-accent font-bold">:into</span> - output collectable</div>
              <div class="bg-success/10 rounded p-2"><span class="text-success font-bold">do</span> - transformation body</div>
            </div>
          </div>
        </div>
      </div>

      <!-- :into Option -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">The :into Option</h3>
          <p class="text-xs opacity-60 mb-4">
            By default, <code class="font-mono bg-base-300 px-1 rounded">for</code> returns a list.
            Use <code class="font-mono bg-base-300 px-1 rounded">:into</code> to collect into any collectable: maps, MapSets, strings, or existing collections.
          </p>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for ex <- into_examples() do %>
              <button
                phx-click="select_into"
                phx-target={@myself}
                phx-value-id={ex.id}
                class={"btn btn-sm " <> if(@active_into.id == ex.id, do: "btn-accent", else: "btn-outline")}
              >
                <%= ex.title %>
              </button>
            <% end %>
          </div>

          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_into.code %></div>

            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold"><%= @active_into.result %></div>
            </div>

            <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
              <%= @active_into.explanation %>
            </div>
          </div>
        </div>
      </div>

      <!-- Cartesian Product Visualization -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Cartesian Product Visualizer</h3>
            <button
              phx-click="toggle_cartesian"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_cartesian, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_cartesian do %>
            <p class="text-xs opacity-60 mb-4">
              Multiple generators produce every combination (Cartesian product). Enter two ranges to visualize.
            </p>

            <form phx-submit="compute_cartesian" phx-target={@myself} class="flex gap-2 items-end mb-4">
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">Generator A</span></label>
                <input
                  type="text"
                  name="gen_a"
                  value={@cartesian_a}
                  class="input input-bordered input-sm font-mono w-28"
                  autocomplete="off"
                />
              </div>
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">Generator B</span></label>
                <input
                  type="text"
                  name="gen_b"
                  value={@cartesian_b}
                  class="input input-bordered input-sm font-mono w-28"
                  autocomplete="off"
                />
              </div>
              <button type="submit" class="btn btn-primary btn-sm">Generate</button>
            </form>

            <!-- Generated Code -->
            <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
              for a &lt;- <%= @cartesian_a %>, b &lt;- <%= @cartesian_b %>, do: &lbrace;a, b&rbrace;
            </div>

            <%= if @cartesian_result do %>
              <%= if @cartesian_result.ok do %>
                <!-- Grid Visualization -->
                <div class="overflow-x-auto mb-3">
                  <table class="table table-xs">
                    <thead>
                      <tr>
                        <th class="font-mono text-xs opacity-50">a \ b</th>
                        <%= for b <- @cartesian_result.b_values do %>
                          <th class="font-mono text-xs text-info"><%= inspect(b) %></th>
                        <% end %>
                      </tr>
                    </thead>
                    <tbody>
                      <%= for a <- @cartesian_result.a_values do %>
                        <tr>
                          <td class="font-mono text-xs text-info font-bold"><%= inspect(a) %></td>
                          <%= for b <- @cartesian_result.b_values do %>
                            <td class="font-mono text-xs bg-success/10">&lbrace;<%= inspect(a) %>, <%= inspect(b) %>&rbrace;</td>
                          <% end %>
                        </tr>
                      <% end %>
                    </tbody>
                  </table>
                </div>

                <div class="text-xs opacity-60">
                  Total combinations: <span class="font-bold"><%= @cartesian_result.count %></span>
                  (<%= length(@cartesian_result.a_values) %> x <%= length(@cartesian_result.b_values) %>)
                </div>
              <% else %>
                <div class="alert alert-error text-sm"><%= @cartesian_result.error %></div>
              <% end %>
            <% end %>
          <% end %>
        </div>
      </div>

      <!-- Comprehension vs Enum -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Comprehension vs Enum</h3>
            <button
              phx-click="toggle_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for item <- comparison_items() do %>
                <button
                  phx-click="select_comparison"
                  phx-target={@myself}
                  phx-value-id={item.id}
                  class={"btn btn-sm " <> if(@active_comparison.id == item.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= item.title %>
                </button>
              <% end %>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-3">
              <div class="bg-accent/10 border border-accent/30 rounded-lg p-4">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-accent badge-sm">Comprehension</span>
                </div>
                <div class="bg-base-100 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap"><%= @active_comparison.comprehension %></div>
              </div>

              <div class="bg-info/10 border border-info/30 rounded-lg p-4">
                <div class="flex items-center gap-2 mb-2">
                  <span class="badge badge-info badge-sm">Enum</span>
                </div>
                <div class="bg-base-100 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap"><%= @active_comparison.enum_version %></div>
              </div>
            </div>

            <div class="bg-success/10 border border-success/30 rounded-lg p-3 mb-2">
              <span class="font-mono text-sm text-success font-bold"><%= @active_comparison.result %></span>
            </div>

            <div class="alert text-sm">
              <span><%= @active_comparison.note %></span>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Sandbox -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own Comprehension</h3>
          <p class="text-xs opacity-60 mb-4">
            Write a <code class="font-mono bg-base-300 px-1 rounded">for</code> comprehension and see the result.
          </p>

          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="code"
                value={@sandbox_code}
                placeholder="for x <- 1..10, rem(x, 3) == 0, do: x * x"
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
              <span><strong>Generators</strong> (<code class="font-mono bg-base-100 px-1 rounded">x &lt;- enumerable</code>) bind each element to a variable.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Filters</strong> (boolean expressions after generators) keep only matching elements.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Multiple generators</strong> produce a Cartesian product of all combinations.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>:into</strong> collects into any collectable: <code class="font-mono bg-base-100 px-1 rounded">%&lbrace;&rbrace;</code>, <code class="font-mono bg-base-100 px-1 rounded">MapSet.new()</code>, <code class="font-mono bg-base-100 px-1 rounded">""</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Pattern matching in generators</strong> silently skips non-matching elements.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">6</span>
              <span>Comprehensions are often equivalent to <code class="font-mono bg-base-100 px-1 rounded">Enum.map</code> + <code class="font-mono bg-base-100 px-1 rounded">Enum.filter</code>, but shine with multiple generators.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    ex = Enum.find(examples(), &(&1.id == id))
    {:noreply, assign(socket, active_example: ex)}
  end

  def handle_event("select_into", %{"id" => id}, socket) do
    ex = Enum.find(into_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_into: ex)}
  end

  def handle_event("toggle_cartesian", _params, socket) do
    {:noreply, assign(socket, show_cartesian: !socket.assigns.show_cartesian)}
  end

  def handle_event("compute_cartesian", %{"gen_a" => gen_a, "gen_b" => gen_b}, socket) do
    result = build_cartesian(String.trim(gen_a), String.trim(gen_b))

    {:noreply,
     socket
     |> assign(cartesian_a: gen_a)
     |> assign(cartesian_b: gen_b)
     |> assign(cartesian_result: result)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  def handle_event("select_comparison", %{"id" => id}, socket) do
    item = Enum.find(comparison_items(), &(&1.id == id))
    {:noreply, assign(socket, active_comparison: item)}
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

  defp examples, do: @examples
  defp into_examples, do: @into_examples
  defp comparison_items, do: @comparison_items

  defp build_cartesian(gen_a_str, gen_b_str) do
    try do
      {a_values, _} = Code.eval_string("Enum.to_list(#{gen_a_str})")
      {b_values, _} = Code.eval_string("Enum.to_list(#{gen_b_str})")

      if length(a_values) > 10 or length(b_values) > 10 do
        %{ok: false, error: "Keep ranges to 10 or fewer elements for visualization."}
      else
        count = length(a_values) * length(b_values)
        %{ok: true, a_values: a_values, b_values: b_values, count: count}
      end
    rescue
      e -> %{ok: false, error: "Error: #{Exception.message(e)}"}
    end
  end

  defp sandbox_quick_examples do
    [
      {"squares", "for x <- 1..10, do: x * x"},
      {"even squares", "for x <- 1..10, rem(x, 2) == 0, do: x * x"},
      {"pairs", "for x <- [:a, :b, :c], y <- 1..3, do: {x, y}"},
      {"into map", ~s|for {k, v} <- [a: 1, b: 2, c: 3], into: %{}, do: {k, v * 100}|},
      {"pattern skip", ~s|for {:ok, v} <- [{:ok, 1}, {:error, 2}, {:ok, 3}], do: v|}
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
