defmodule ElixirKatasWeb.ElixirKata32EnumBasicsLive do
  use ElixirKatasWeb, :live_component

  @functions [
    %{
      id: "map",
      title: "Enum.map/2",
      description: "Applies a function to each element and returns a new list with the results.",
      signature: "Enum.map(enumerable, fun)",
      code: "Enum.map([1, 2, 3, 4, 5], fn x -> x * 2 end)",
      result: "[2, 4, 6, 8, 10]",
      steps: [
        %{input: 1, output: 2, label: "1 * 2 = 2"},
        %{input: 2, output: 4, label: "2 * 2 = 4"},
        %{input: 3, output: 6, label: "3 * 2 = 6"},
        %{input: 4, output: 8, label: "4 * 2 = 8"},
        %{input: 5, output: 10, label: "5 * 2 = 10"}
      ],
      notes: "map always returns a list with the same number of elements. The original list is unchanged."
    },
    %{
      id: "filter",
      title: "Enum.filter/2",
      description: "Returns only the elements for which the function returns a truthy value.",
      signature: "Enum.filter(enumerable, fun)",
      code: "Enum.filter([1, 2, 3, 4, 5, 6], fn x -> rem(x, 2) == 0 end)",
      result: "[2, 4, 6]",
      steps: [
        %{input: 1, output: false, label: "rem(1, 2) == 0? false"},
        %{input: 2, output: true, label: "rem(2, 2) == 0? true"},
        %{input: 3, output: false, label: "rem(3, 2) == 0? false"},
        %{input: 4, output: true, label: "rem(4, 2) == 0? true"},
        %{input: 5, output: false, label: "rem(5, 2) == 0? false"},
        %{input: 6, output: true, label: "rem(6, 2) == 0? true"}
      ],
      notes: "filter can return fewer elements than the original. Use reject/2 for the inverse."
    },
    %{
      id: "reduce",
      title: "Enum.reduce/3",
      description: "Folds the entire enumerable into a single value using an accumulator.",
      signature: "Enum.reduce(enumerable, acc, fun)",
      code: "Enum.reduce([1, 2, 3, 4, 5], 0, fn x, acc -> x + acc end)",
      result: "15",
      steps: [
        %{input: 1, output: 1, label: "acc=0, 1 + 0 = 1"},
        %{input: 2, output: 3, label: "acc=1, 2 + 1 = 3"},
        %{input: 3, output: 6, label: "acc=3, 3 + 3 = 6"},
        %{input: 4, output: 10, label: "acc=6, 4 + 6 = 10"},
        %{input: 5, output: 15, label: "acc=10, 5 + 10 = 15"}
      ],
      notes: "reduce is the most powerful Enum function. You can implement map, filter, and more using reduce alone."
    },
    %{
      id: "each",
      title: "Enum.each/2",
      description: "Iterates over each element for side effects. Always returns :ok.",
      signature: "Enum.each(enumerable, fun)",
      code: ~s|Enum.each(["a", "b", "c"], fn x -> IO.puts(x) end)|,
      result: ":ok  (prints a, b, c as side effects)",
      steps: [
        %{input: "a", output: "IO.puts(a)", label: "prints \"a\""},
        %{input: "b", output: "IO.puts(b)", label: "prints \"b\""},
        %{input: "c", output: "IO.puts(c)", label: "prints \"c\""}
      ],
      notes: "each is for side effects only (logging, IO). It always returns :ok. Use map if you need the results."
    }
  ]

  @try_examples [
    %{label: "Double all", code: "Enum.map([1, 2, 3, 4, 5], &(&1 * 2))"},
    %{label: "Keep evens", code: "Enum.filter(1..10, &(rem(&1, 2) == 0))"},
    %{label: "Sum list", code: "Enum.reduce([10, 20, 30], 0, &(&1 + &2))"},
    %{label: "String lengths", code: ~s|Enum.map(["hello", "world", "elixir"], &String.length/1)|},
    %{label: "Pipeline", code: "1..10 |> Enum.filter(&(rem(&1, 2) == 0)) |> Enum.map(&(&1 * &1))"},
    %{label: "Product", code: "Enum.reduce([1, 2, 3, 4, 5], 1, &(&1 * &2))"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_fn, fn -> hd(@functions) end)
     |> assign_new(:visible_step, fn -> 0 end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:show_protocol, fn -> false end)
     |> assign_new(:show_comparison, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Enum Basics</h2>
      <p class="text-sm opacity-70 mb-6">
        The <code class="font-mono bg-base-300 px-1 rounded">Enum</code> module is the workhorse of Elixir
        data processing. It provides eager functions for working with any data type that implements
        the <strong>Enumerable</strong> protocol (lists, ranges, maps, and more).
      </p>

      <!-- Function Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for func <- functions() do %>
          <button
            phx-click="select_fn"
            phx-target={@myself}
            phx-value-id={func.id}
            class={"btn btn-sm " <> if(@active_fn.id == func.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= func.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Function Display -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-1"><%= @active_fn.title %></h3>
          <p class="text-xs opacity-60 mb-3"><%= @active_fn.description %></p>

          <!-- Signature -->
          <div class="bg-base-300 rounded-lg p-2 font-mono text-sm mb-4">
            <span class="opacity-50">Signature: </span><span class="text-info"><%= @active_fn.signature %></span>
          </div>

          <!-- Code Example -->
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <span class="opacity-50">iex&gt; </span><%= @active_fn.code %>
            <div class="text-success font-bold mt-1"><%= @active_fn.result %></div>
          </div>

          <!-- Step-Through Visualization -->
          <div class="mb-4">
            <div class="flex items-center justify-between mb-2">
              <h4 class="text-xs font-bold opacity-60">Step-by-step processing:</h4>
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
                  <%= @visible_step %>/<%= length(@active_fn.steps) %>
                </span>
                <button
                  phx-click="step_next"
                  phx-target={@myself}
                  disabled={@visible_step >= length(@active_fn.steps)}
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

            <div class="space-y-1">
              <%= for {step, idx} <- Enum.with_index(@active_fn.steps) do %>
                <div class={"flex items-center gap-3 rounded-lg p-2 transition-all " <>
                  cond do
                    idx >= @visible_step -> "opacity-20 bg-base-100"
                    idx == @visible_step - 1 -> "bg-primary/15 border border-primary/30"
                    true -> "bg-base-100"
                  end}>
                  <div class="flex-shrink-0 w-6 h-6 rounded-full bg-base-300 flex items-center justify-center text-xs font-bold">
                    <%= idx + 1 %>
                  </div>
                  <div class="font-mono text-sm flex-1">
                    <span class="text-info"><%= inspect(step.input) %></span>
                    <span class="opacity-30 mx-2">&rarr;</span>
                    <span class="text-xs opacity-60"><%= step.label %></span>
                    <span class="opacity-30 mx-2">&rarr;</span>
                    <%= if @active_fn.id == "filter" do %>
                      <span class={"font-bold " <> if(step.output == true, do: "text-success", else: "text-error")}>
                        <%= inspect(step.output) %>
                      </span>
                    <% else %>
                      <span class="text-success font-bold"><%= inspect(step.output) %></span>
                    <% end %>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Running result for reduce -->
            <%= if @active_fn.id == "reduce" and @visible_step > 0 do %>
              <div class="mt-3 bg-accent/10 border border-accent/30 rounded-lg p-3">
                <span class="text-xs font-bold opacity-60">Accumulator: </span>
                <span class="font-mono text-sm font-bold text-accent">
                  <%= @active_fn.steps |> Enum.at(@visible_step - 1) |> Map.get(:output) |> inspect() %>
                </span>
              </div>
            <% end %>

            <!-- Collected result for filter -->
            <%= if @active_fn.id == "filter" and @visible_step > 0 do %>
              <div class="mt-3 bg-success/10 border border-success/30 rounded-lg p-3">
                <span class="text-xs font-bold opacity-60">Kept elements: </span>
                <span class="font-mono text-sm font-bold text-success">
                  <%= @active_fn.steps
                      |> Enum.take(@visible_step)
                      |> Enum.filter(& &1.output)
                      |> Enum.map(& &1.input)
                      |> inspect() %>
                </span>
              </div>
            <% end %>

            <!-- Collected result for map -->
            <%= if @active_fn.id == "map" and @visible_step > 0 do %>
              <div class="mt-3 bg-success/10 border border-success/30 rounded-lg p-3">
                <span class="text-xs font-bold opacity-60">Result so far: </span>
                <span class="font-mono text-sm font-bold text-success">
                  <%= @active_fn.steps
                      |> Enum.take(@visible_step)
                      |> Enum.map(& &1.output)
                      |> inspect() %>
                </span>
              </div>
            <% end %>
          </div>

          <!-- Notes -->
          <div class="alert text-sm">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <span><%= @active_fn.notes %></span>
          </div>
        </div>
      </div>

      <!-- Comparison: map vs filter vs reduce vs each -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Quick Comparison</h3>
            <button
              phx-click="toggle_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Function</th>
                    <th>Purpose</th>
                    <th>Returns</th>
                    <th>Element Count</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="font-mono text-info font-bold">map</td>
                    <td>Transform each element</td>
                    <td>New list</td>
                    <td>Same as input</td>
                  </tr>
                  <tr>
                    <td class="font-mono text-info font-bold">filter</td>
                    <td>Keep matching elements</td>
                    <td>New list</td>
                    <td>Fewer or equal</td>
                  </tr>
                  <tr>
                    <td class="font-mono text-info font-bold">reduce</td>
                    <td>Fold into single value</td>
                    <td>Any type</td>
                    <td>Single value</td>
                  </tr>
                  <tr>
                    <td class="font-mono text-info font-bold">each</td>
                    <td>Side effects only</td>
                    <td>:ok</td>
                    <td>N/A</td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="mt-4 bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap">{enum_pipeline_code()}</div>
          <% end %>
        </div>
      </div>

      <!-- Enumerable Protocol -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">The Enumerable Protocol</h3>
            <button
              phx-click="toggle_protocol"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_protocol, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_protocol do %>
            <p class="text-xs opacity-60 mb-4">
              Enum functions work with <em>any</em> data type that implements the Enumerable protocol.
              This is why the same Enum.map works on lists, ranges, maps, and more.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div class="bg-base-300 rounded-lg p-3">
                <h4 class="text-xs font-bold opacity-60 mb-2">Lists</h4>
                <div class="font-mono text-sm">
                  <div>Enum.map([1, 2, 3], &amp;(&amp;1 * 2))</div>
                  <div class="text-success"># [2, 4, 6]</div>
                </div>
              </div>
              <div class="bg-base-300 rounded-lg p-3">
                <h4 class="text-xs font-bold opacity-60 mb-2">Ranges</h4>
                <div class="font-mono text-sm">
                  <div>Enum.map(1..5, &amp;(&amp;1 * 2))</div>
                  <div class="text-success"># [2, 4, 6, 8, 10]</div>
                </div>
              </div>
              <div class="bg-base-300 rounded-lg p-3">
                <h4 class="text-xs font-bold opacity-60 mb-2">Maps (as key-value tuples)</h4>
                <div class="font-mono text-sm">
                  <div>Enum.map(%&lbrace;a: 1, b: 2&rbrace;, fn &lbrace;k, v&rbrace; -&gt;</div>
                  <div class="ml-2">&lbrace;k, v * 10&rbrace; end)</div>
                  <div class="text-success"># [a: 10, b: 20]</div>
                </div>
              </div>
              <div class="bg-base-300 rounded-lg p-3">
                <h4 class="text-xs font-bold opacity-60 mb-2">MapSet</h4>
                <div class="font-mono text-sm">
                  <div>MapSet.new([1, 2, 3])</div>
                  <div>|&gt; Enum.map(&amp;(&amp;1 * 2))</div>
                  <div class="text-success"># [2, 4, 6]</div>
                </div>
              </div>
            </div>

            <div class="alert alert-info text-sm mt-4">
              <div>
                <div class="font-bold">Protocol = Polymorphism</div>
                <span>The Enumerable protocol defines how to iterate over a data structure.
                  Any module can implement it, making all Enum functions available for custom types.</span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try It Yourself -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Try It Yourself</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter any Enum expression to see the result.
          </p>

          <form phx-submit="sandbox_eval" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <input
                type="text"
                name="code"
                value={@sandbox_code}
                placeholder="Enum.map([1, 2, 3], &(&1 * 2))"
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Run</button>
          </form>

          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for ex <- try_examples() do %>
              <button
                phx-click="quick_example"
                phx-target={@myself}
                phx-value-code={ex.code}
                class="btn btn-xs btn-outline"
              >
                <%= ex.label %>
              </button>
            <% end %>
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
              <span><strong>Enum is eager:</strong> It processes the entire collection immediately and returns the result. For lazy evaluation, see Stream.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>map</strong> transforms every element 1-to-1. The output list has the same length as the input.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>filter</strong> selects elements matching a predicate. The output can have fewer elements.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>reduce</strong> collapses an entire collection into a single value using an accumulator.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>each</strong> is for side effects only. It returns <code class="font-mono bg-base-100 px-1 rounded">:ok</code>, not the results.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">6</span>
              <span>All Enum functions work with any type that implements the <strong>Enumerable protocol</strong> (lists, ranges, maps, MapSets).</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_fn", %{"id" => id}, socket) do
    func = Enum.find(functions(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_fn: func)
     |> assign(visible_step: 0)}
  end

  def handle_event("step_next", _params, socket) do
    max_step = length(socket.assigns.active_fn.steps)
    new_step = min(socket.assigns.visible_step + 1, max_step)
    {:noreply, assign(socket, visible_step: new_step)}
  end

  def handle_event("step_prev", _params, socket) do
    new_step = max(socket.assigns.visible_step - 1, 0)
    {:noreply, assign(socket, visible_step: new_step)}
  end

  def handle_event("step_all", _params, socket) do
    {:noreply, assign(socket, visible_step: length(socket.assigns.active_fn.steps))}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  def handle_event("toggle_protocol", _params, socket) do
    {:noreply, assign(socket, show_protocol: !socket.assigns.show_protocol)}
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

  defp functions, do: @functions
  defp try_examples, do: @try_examples

  defp enum_pipeline_code do
    """
    [1, 2, 3, 4, 5]
    |> Enum.map(&(&1 * 2))       # [2, 4, 6, 8, 10]  <- transform
    |> Enum.filter(&(&1 > 4))    # [6, 8, 10]         <- select
    |> Enum.reduce(0, &+/2)      # 24                  <- aggregate\
    """
  end

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
