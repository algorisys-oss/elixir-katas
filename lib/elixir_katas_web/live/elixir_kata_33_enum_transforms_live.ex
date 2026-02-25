defmodule ElixirKatasWeb.ElixirKata33EnumTransformsLive do
  use ElixirKatasWeb, :live_component

  @transforms [
    %{
      id: "sort",
      title: "Enum.sort/1,2",
      description: "Sorts elements. Default is ascending. Pass a function or :asc/:desc for custom ordering.",
      examples: [
        %{code: "Enum.sort([3, 1, 4, 1, 5, 9, 2, 6])", result: "[1, 1, 2, 3, 4, 5, 6, 9]", label: "Default (ascending)"},
        %{code: "Enum.sort([3, 1, 4, 1, 5], :desc)", result: "[5, 4, 3, 1, 1]", label: "Descending"},
        %{code: ~s|Enum.sort_by(["banana", "fig", "apple"], &String.length/1)|, result: ~s|["fig", "apple", "banana"]|, label: "Sort by length"}
      ],
      before: [3, 1, 4, 1, 5, 9, 2, 6],
      after: [1, 1, 2, 3, 4, 5, 6, 9]
    },
    %{
      id: "reverse",
      title: "Enum.reverse/1",
      description: "Reverses the order of elements in the enumerable.",
      examples: [
        %{code: "Enum.reverse([1, 2, 3, 4, 5])", result: "[5, 4, 3, 2, 1]", label: "Reverse a list"},
        %{code: ~s|Enum.reverse(["a", "b", "c"])|, result: ~s|["c", "b", "a"]|, label: "Reverse strings"},
        %{code: "1..5 |> Enum.reverse()", result: "[5, 4, 3, 2, 1]", label: "Reverse a range"}
      ],
      before: [1, 2, 3, 4, 5],
      after: [5, 4, 3, 2, 1]
    },
    %{
      id: "uniq",
      title: "Enum.uniq/1",
      description: "Removes duplicate elements, keeping only the first occurrence.",
      examples: [
        %{code: "Enum.uniq([1, 2, 2, 3, 3, 3, 4])", result: "[1, 2, 3, 4]", label: "Remove duplicates"},
        %{code: ~s|Enum.uniq(["a", "b", "a", "c", "b"])|, result: ~s|["a", "b", "c"]|, label: "Unique strings"},
        %{code: ~s|Enum.uniq_by(["apple", "avocado", "banana"], &String.first/1)|, result: ~s|["apple", "banana"]|, label: "Unique by first letter"}
      ],
      before: [1, 2, 2, 3, 3, 3, 4],
      after: [1, 2, 3, 4]
    },
    %{
      id: "flat_map",
      title: "Enum.flat_map/2",
      description: "Maps a function over the enumerable, then flattens the result one level.",
      examples: [
        %{code: "Enum.flat_map([1, 2, 3], fn x -> [x, x * 10] end)", result: "[1, 10, 2, 20, 3, 30]", label: "Duplicate and multiply"},
        %{code: ~s|Enum.flat_map(["hello world", "foo bar"], &String.split/1)|, result: ~s|["hello", "world", "foo", "bar"]|, label: "Split and flatten"},
        %{code: "Enum.flat_map(1..3, fn x -> 1..x end)", result: "[1, 1, 2, 1, 2, 3]", label: "Expand ranges"}
      ],
      before: ["[1, 2, 3]", "fn x -> [x, x*10]"],
      after: [1, 10, 2, 20, 3, 30]
    },
    %{
      id: "zip",
      title: "Enum.zip/2",
      description: "Zips two enumerables together into a list of tuples. Stops at the shorter list.",
      examples: [
        %{code: "Enum.zip([1, 2, 3], [:a, :b, :c])", result: ~s|[{1, :a}, {2, :b}, {3, :c}]|, label: "Zip two lists"},
        %{code: ~s|Enum.zip(["Alice", "Bob"], [85, 92])|, result: ~s|[{"Alice", 85}, {"Bob", 92}]|, label: "Names with scores"},
        %{code: "Enum.zip(1..5, 1..3)", result: "[{1, 1}, {2, 2}, {3, 3}]", label: "Stops at shorter"}
      ],
      before: ["[1, 2, 3]", "[:a, :b, :c]"],
      after: ["{1, :a}", "{2, :b}", "{3, :c}"]
    },
    %{
      id: "chunk_every",
      title: "Enum.chunk_every/2,3",
      description: "Splits the enumerable into chunks of a given size.",
      examples: [
        %{code: "Enum.chunk_every([1, 2, 3, 4, 5, 6], 2)", result: "[[1, 2], [3, 4], [5, 6]]", label: "Pairs"},
        %{code: "Enum.chunk_every([1, 2, 3, 4, 5], 3)", result: "[[1, 2, 3], [4, 5]]", label: "Triples (last chunk smaller)"},
        %{code: "Enum.chunk_every(1..10, 4)", result: "[[1, 2, 3, 4], [5, 6, 7, 8], [9, 10]]", label: "Groups of 4"}
      ],
      before: [1, 2, 3, 4, 5, 6],
      after: ["[1, 2]", "[3, 4]", "[5, 6]"]
    }
  ]

  @chain_steps_available [
    %{id: "sort", label: "sort", code: "Enum.sort()", type: :transform},
    %{id: "reverse", label: "reverse", code: "Enum.reverse()", type: :transform},
    %{id: "uniq", label: "uniq", code: "Enum.uniq()", type: :transform},
    %{id: "take_3", label: "take(3)", code: "Enum.take(3)", type: :transform},
    %{id: "drop_2", label: "drop(2)", code: "Enum.drop(2)", type: :transform},
    %{id: "double", label: "map(*2)", code: "Enum.map(&(&1 * 2))", type: :map},
    %{id: "square", label: "map(^2)", code: "Enum.map(&(&1 * &1))", type: :map},
    %{id: "keep_even", label: "filter(even)", code: "Enum.filter(&(rem(&1, 2) == 0))", type: :filter},
    %{id: "keep_gt3", label: "filter(>3)", code: "Enum.filter(&(&1 > 3))", type: :filter},
    %{id: "chunk_2", label: "chunk(2)", code: "Enum.chunk_every(2)", type: :transform}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_transform, fn -> hd(@transforms) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:chain_data, fn -> [5, 3, 8, 1, 3, 9, 2, 5, 7, 1] end)
     |> assign_new(:chain_steps, fn -> [] end)
     |> assign_new(:chain_results, fn -> [[5, 3, 8, 1, 3, 9, 2, 5, 7, 1]] end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Enum Transforms</h2>
      <p class="text-sm opacity-70 mb-6">
        Beyond map and filter, <code class="font-mono bg-base-300 px-1 rounded">Enum</code> provides powerful
        transformation functions for sorting, deduplicating, reshaping, and combining collections.
      </p>

      <!-- Transform Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for t <- transforms() do %>
          <button
            phx-click="select_transform"
            phx-target={@myself}
            phx-value-id={t.id}
            class={"btn btn-sm " <> if(@active_transform.id == t.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= t.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Transform Display -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-1"><%= @active_transform.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @active_transform.description %></p>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(@active_transform.examples) do %>
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

          <!-- Selected Example -->
          <% example = Enum.at(@active_transform.examples, @active_example_idx) %>
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <span class="opacity-50">iex&gt; </span><%= example.code %>
            <div class="text-success font-bold mt-1"><%= example.result %></div>
          </div>

          <!-- Before/After Visualization -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-2">Before</div>
              <div class="flex flex-wrap gap-1">
                <%= for item <- @active_transform.before do %>
                  <span class="badge badge-info badge-sm font-mono"><%= item %></span>
                <% end %>
              </div>
            </div>
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-2">After</div>
              <div class="flex flex-wrap gap-1">
                <%= for item <- @active_transform.after do %>
                  <span class="badge badge-success badge-sm font-mono"><%= item %></span>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Interactive Chain Builder -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Chain Transforms</h3>
          <p class="text-xs opacity-60 mb-4">
            Build a pipeline by chaining transform operations. Watch how the data changes at each step.
          </p>

          <!-- Starting Data -->
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <span class="opacity-50">data = </span>
            <span class="text-info"><%= inspect(@chain_data) %></span>
          </div>

          <!-- Available Operations -->
          <div class="mb-4">
            <div class="text-xs font-bold opacity-60 mb-2">Add a step:</div>
            <div class="flex flex-wrap gap-2">
              <%= for step_def <- chain_steps_available() do %>
                <button
                  phx-click="add_chain_step"
                  phx-target={@myself}
                  phx-value-id={step_def.id}
                  class={"btn btn-xs " <> chain_step_class(step_def)}
                >
                  <%= step_def.label %>
                </button>
              <% end %>
            </div>
          </div>

          <!-- Chain Steps & Results -->
          <%= if length(@chain_steps) > 0 do %>
            <div class="space-y-2 mb-4">
              <%= for {step, idx} <- Enum.with_index(@chain_steps) do %>
                <% result_at = Enum.at(@chain_results, idx + 1, []) %>
                <div class="flex items-center gap-2">
                  <div class="flex-shrink-0 w-7 h-7 rounded-full bg-primary text-primary-content flex items-center justify-center text-xs font-bold">
                    <%= idx + 1 %>
                  </div>
                  <div class="flex-1 bg-base-100 rounded-lg p-2 border border-base-300">
                    <div class="flex items-center justify-between">
                      <span class="font-mono text-xs text-primary"><%= step.code %></span>
                      <button
                        phx-click="remove_chain_step"
                        phx-target={@myself}
                        phx-value-idx={idx}
                        class="btn btn-ghost btn-xs text-error"
                      >
                        x
                      </button>
                    </div>
                    <div class="font-mono text-xs mt-1">
                      <span class="opacity-50">&rArr; </span>
                      <span class="text-success"><%= inspect(result_at, limit: 20) %></span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Pipeline Code -->
            <div class="bg-base-300 rounded-lg p-3 mb-4">
              <div class="text-xs font-bold opacity-60 mb-1">Equivalent Elixir code:</div>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= chain_as_code(@chain_data, @chain_steps) %></div>
            </div>

            <button
              phx-click="clear_chain"
              phx-target={@myself}
              class="btn btn-ghost btn-sm"
            >
              Clear Pipeline
            </button>
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
                placeholder="Enum.sort([5, 3, 1, 4, 2])"
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Run</button>
          </form>

          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="Enum.zip(1..5, [:a, :b, :c, :d, :e])" class="btn btn-xs btn-outline">zip</button>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="Enum.chunk_every(1..12, 4)" class="btn btn-xs btn-outline">chunk</button>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code={~s|Enum.flat_map(["hi there", "bye now"], &String.split/1)|} class="btn btn-xs btn-outline">flat_map</button>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="[3, 1, 4, 1, 5, 9] |> Enum.sort() |> Enum.uniq() |> Enum.reverse()" class="btn btn-xs btn-outline">chain</button>
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
              <span><strong>sort</strong> defaults to ascending. Use <code class="font-mono bg-base-100 px-1 rounded">:desc</code> or a comparator function for custom order. <code class="font-mono bg-base-100 px-1 rounded">sort_by/2</code> sorts by a derived key.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>reverse</strong> flips the collection order. Often combined with sort for descending results.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>uniq</strong> removes duplicates, keeping first occurrences. <code class="font-mono bg-base-100 px-1 rounded">uniq_by/2</code> uses a key function.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>flat_map</strong> = map + flatten. Essential when your mapping function returns lists.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>zip</strong> pairs elements from two collections. Stops at the shorter one. Great for combining parallel data.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">6</span>
              <span><strong>chunk_every</strong> splits a collection into fixed-size groups. Useful for batching, pagination, or grid layouts.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_transform", %{"id" => id}, socket) do
    transform = Enum.find(transforms(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_transform: transform)
     |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, active_example_idx: idx)}
  end

  def handle_event("add_chain_step", %{"id" => id}, socket) do
    step_def = Enum.find(chain_steps_available(), &(&1.id == id))
    new_steps = socket.assigns.chain_steps ++ [step_def]
    new_results = recompute_chain(socket.assigns.chain_data, new_steps)

    {:noreply,
     socket
     |> assign(chain_steps: new_steps)
     |> assign(chain_results: new_results)}
  end

  def handle_event("remove_chain_step", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    new_steps = List.delete_at(socket.assigns.chain_steps, idx)
    new_results = recompute_chain(socket.assigns.chain_data, new_steps)

    {:noreply,
     socket
     |> assign(chain_steps: new_steps)
     |> assign(chain_results: new_results)}
  end

  def handle_event("clear_chain", _params, socket) do
    {:noreply,
     socket
     |> assign(chain_steps: [])
     |> assign(chain_results: [socket.assigns.chain_data])}
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

  defp transforms, do: @transforms
  defp chain_steps_available, do: @chain_steps_available

  defp chain_step_class(step_def) do
    case step_def.type do
      :transform -> "btn-outline btn-primary"
      :map -> "btn-outline btn-info"
      :filter -> "btn-outline btn-warning"
    end
  end

  defp recompute_chain(data, steps) do
    Enum.reduce(steps, {[data], data}, fn step, {results, current} ->
      next = apply_chain_step(current, step)
      {results ++ [next], next}
    end)
    |> elem(0)
  end

  defp apply_chain_step(data, step) when is_list(data) do
    try do
      code = "data |> #{step.code}"
      {result, _} = Code.eval_string(code, data: data)
      result
    rescue
      _ -> data
    end
  end

  defp apply_chain_step(data, _step), do: data

  defp chain_as_code(data, steps) do
    base = inspect(data)
    lines = Enum.map(steps, fn step -> "|> #{step.code}" end)
    Enum.join([base | lines], "\n")
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
