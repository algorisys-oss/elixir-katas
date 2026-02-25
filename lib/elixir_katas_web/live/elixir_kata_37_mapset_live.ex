defmodule ElixirKatasWeb.ElixirKata37MapsetLive do
  use ElixirKatasWeb, :live_component

  @operations [
    %{
      id: "new_put",
      title: "Creating & Adding",
      description: "MapSet.new/0 creates an empty set. MapSet.new/1 creates from a list (duplicates removed). MapSet.put/2 adds an element.",
      examples: [
        %{
          label: "MapSet.new/0",
          code: "MapSet.new()",
          result: "MapSet.new([])",
          note: "Creates an empty set"
        },
        %{
          label: "MapSet.new/1",
          code: "MapSet.new([1, 2, 3, 2, 1])",
          result: "MapSet.new([1, 2, 3])",
          note: "Duplicates are automatically removed"
        },
        %{
          label: "MapSet.put/2",
          code: "MapSet.new([1, 2, 3]) |> MapSet.put(4)",
          result: "MapSet.new([1, 2, 3, 4])",
          note: "Adding an element that already exists is a no-op"
        }
      ]
    },
    %{
      id: "query",
      title: "Querying",
      description: "Check membership, size, and emptiness of sets.",
      examples: [
        %{
          label: "member?/2",
          code: "MapSet.new([1, 2, 3]) |> MapSet.member?(2)",
          result: "true",
          note: "O(log n) lookup - much faster than Enum.member? on lists for large collections"
        },
        %{
          label: "size/1",
          code: "MapSet.new([1, 2, 3]) |> MapSet.size()",
          result: "3",
          note: "Returns the number of elements"
        },
        %{
          label: "equal?/2",
          code: "MapSet.equal?(MapSet.new([1, 2, 3]), MapSet.new([3, 2, 1]))",
          result: "true",
          note: "Sets have no order - these are equal"
        }
      ]
    },
    %{
      id: "delete_filter",
      title: "Removing & Filtering",
      description: "Remove elements by value or by predicate.",
      examples: [
        %{
          label: "delete/2",
          code: "MapSet.new([1, 2, 3]) |> MapSet.delete(2)",
          result: "MapSet.new([1, 3])",
          note: "Deleting a non-existent element is a no-op (no error)"
        },
        %{
          label: "filter/2",
          code: "MapSet.new([1, 2, 3, 4, 5]) |> MapSet.filter(&(rem(&1, 2) == 0))",
          result: "MapSet.new([2, 4])",
          note: "Keep only elements matching the predicate"
        },
        %{
          label: "reject/2",
          code: "MapSet.new([1, 2, 3, 4, 5]) |> MapSet.reject(&(rem(&1, 2) == 0))",
          result: "MapSet.new([1, 3, 5])",
          note: "Remove elements matching the predicate"
        }
      ]
    },
    %{
      id: "set_ops",
      title: "Set Operations",
      description: "Union, intersection, and difference are the core set algebra operations.",
      examples: [
        %{
          label: "union/2",
          code: "MapSet.union(MapSet.new([1, 2, 3]), MapSet.new([3, 4, 5]))",
          result: "MapSet.new([1, 2, 3, 4, 5])",
          note: "All elements from both sets (duplicates merged)"
        },
        %{
          label: "intersection/2",
          code: "MapSet.intersection(MapSet.new([1, 2, 3]), MapSet.new([2, 3, 4]))",
          result: "MapSet.new([2, 3])",
          note: "Only elements present in BOTH sets"
        },
        %{
          label: "difference/2",
          code: "MapSet.difference(MapSet.new([1, 2, 3]), MapSet.new([2, 3, 4]))",
          result: "MapSet.new([1])",
          note: "Elements in the first set but NOT in the second"
        },
        %{
          label: "subset?/2",
          code: "MapSet.subset?(MapSet.new([1, 2]), MapSet.new([1, 2, 3]))",
          result: "true",
          note: "True if every element in set A is also in set B"
        },
        %{
          label: "disjoint?/2",
          code: "MapSet.disjoint?(MapSet.new([1, 2]), MapSet.new([3, 4]))",
          result: "true",
          note: "True if sets share no elements"
        }
      ]
    }
  ]

  @when_to_use [
    %{
      structure: "MapSet",
      use_when: "Uniqueness matters, fast membership checks, set algebra",
      example: "Tags, permissions, visited nodes",
      lookup: "O(log n)"
    },
    %{
      structure: "List",
      use_when: "Order matters, duplicates allowed, pattern matching on head/tail",
      example: "Ordered items, stack operations",
      lookup: "O(n)"
    },
    %{
      structure: "Map",
      use_when: "Key-value associations, fast key lookup",
      example: "User profiles, config, caches",
      lookup: "O(log n)"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_section, fn -> hd(@operations) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:set_a_input, fn -> "1, 2, 3, 4, 5" end)
     |> assign_new(:set_b_input, fn -> "3, 4, 5, 6, 7" end)
     |> assign_new(:set_a, fn -> MapSet.new([1, 2, 3, 4, 5]) end)
     |> assign_new(:set_b, fn -> MapSet.new([3, 4, 5, 6, 7]) end)
     |> assign_new(:venn_op, fn -> "union" end)
     |> assign_new(:builder_input, fn -> "" end)
     |> assign_new(:builder_set, fn -> MapSet.new() end)
     |> assign_new(:builder_history, fn -> [] end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">MapSet</h2>
      <p class="text-sm opacity-70 mb-6">
        A <strong>MapSet</strong> is an unordered collection of unique values. It provides efficient
        membership testing and set algebra operations like union, intersection, and difference.
      </p>

      <!-- Section Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for op <- operations() do %>
          <button
            phx-click="select_section"
            phx-target={@myself}
            phx-value-id={op.id}
            class={"btn btn-sm " <> if(@active_section.id == op.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= op.title %>
          </button>
        <% end %>
      </div>

      <!-- Operations Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_section.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @active_section.description %></p>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(@active_section.examples) do %>
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

          <% example = Enum.at(@active_section.examples, @active_example_idx) %>
          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= example.code %></div>
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold"><%= example.result %></div>
            </div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Note</div>
              <div class="text-sm"><%= example.note %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Venn Diagram Visualization -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Venn Diagram: Set Operations</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter two sets and see union, intersection, and difference visualized.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <form phx-change="update_sets" phx-target={@myself}>
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">Set A (comma-separated)</span></label>
                <input
                  type="text"
                  name="set_a"
                  value={@set_a_input}
                  class="input input-bordered input-sm font-mono"
                  autocomplete="off"
                />
              </div>
              <div class="form-control mt-2">
                <label class="label py-0"><span class="label-text text-xs">Set B (comma-separated)</span></label>
                <input
                  type="text"
                  name="set_b"
                  value={@set_b_input}
                  class="input input-bordered input-sm font-mono"
                  autocomplete="off"
                />
              </div>
            </form>

            <div>
              <div class="text-xs font-bold opacity-60 mb-2">Operation</div>
              <div class="flex flex-wrap gap-2">
                <%= for op <- ["union", "intersection", "difference", "symmetric_diff"] do %>
                  <button
                    phx-click="set_venn_op"
                    phx-target={@myself}
                    phx-value-op={op}
                    class={"btn btn-xs " <> if(@venn_op == op, do: "btn-primary", else: "btn-outline")}
                  >
                    <%= format_op_name(op) %>
                  </button>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Venn Display -->
          <div class="bg-base-300 rounded-lg p-4">
            <div class="flex flex-wrap items-center justify-center gap-8 mb-4">
              <!-- Set A circle -->
              <div class="text-center">
                <div class="text-xs font-bold text-info mb-1">Set A</div>
                <div class="flex flex-wrap gap-1 justify-center max-w-[10rem]">
                  <%= for val <- Enum.sort(MapSet.to_list(@set_a)) do %>
                    <span class={"badge badge-sm " <> venn_element_class(val, @set_a, @set_b, @venn_op, :a)}>
                      <%= val %>
                    </span>
                  <% end %>
                </div>
              </div>

              <!-- Overlap / Result -->
              <div class="text-center">
                <div class="text-xs font-bold text-warning mb-1"><%= format_op_name(@venn_op) %></div>
                <div class="flex flex-wrap gap-1 justify-center max-w-[10rem]">
                  <%= for val <- Enum.sort(MapSet.to_list(compute_venn(@set_a, @set_b, @venn_op))) do %>
                    <span class="badge badge-sm badge-warning"><%= val %></span>
                  <% end %>
                </div>
              </div>

              <!-- Set B circle -->
              <div class="text-center">
                <div class="text-xs font-bold text-secondary mb-1">Set B</div>
                <div class="flex flex-wrap gap-1 justify-center max-w-[10rem]">
                  <%= for val <- Enum.sort(MapSet.to_list(@set_b)) do %>
                    <span class={"badge badge-sm " <> venn_element_class(val, @set_a, @set_b, @venn_op, :b)}>
                      <%= val %>
                    </span>
                  <% end %>
                </div>
              </div>
            </div>

            <!-- Code equivalent -->
            <div class="bg-base-100 rounded-lg p-3 font-mono text-xs">
              <span class="opacity-50">iex&gt; </span><%= venn_code(@venn_op) %>
              <br />
              <span class="text-success font-bold"><%= inspect(compute_venn(@set_a, @set_b, @venn_op)) %></span>
            </div>
          </div>
        </div>
      </div>

      <!-- Interactive Set Builder -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive Set Builder</h3>
          <p class="text-xs opacity-60 mb-4">
            Build a MapSet step-by-step. Try adding duplicates and see what happens!
          </p>

          <div class="flex gap-2 mb-4">
            <form phx-submit="builder_add" phx-target={@myself} class="flex gap-2 flex-1">
              <input
                type="text"
                name="value"
                value={@builder_input}
                placeholder="Enter a value..."
                class="input input-bordered input-sm font-mono flex-1"
                autocomplete="off"
              />
              <button type="submit" class="btn btn-primary btn-sm">Put</button>
            </form>
            <button phx-click="builder_clear" phx-target={@myself} class="btn btn-ghost btn-sm">
              Clear
            </button>
          </div>

          <!-- Current Set -->
          <div class="bg-base-300 rounded-lg p-4 mb-4">
            <div class="text-xs font-bold opacity-60 mb-2">Current MapSet</div>
            <div class="flex flex-wrap gap-2 min-h-[2rem]">
              <%= if MapSet.size(@builder_set) == 0 do %>
                <span class="text-xs opacity-40 italic">Empty set</span>
              <% else %>
                <%= for val <- Enum.sort(MapSet.to_list(@builder_set)) do %>
                  <div class="badge badge-lg badge-primary gap-1">
                    <%= val %>
                    <button
                      phx-click="builder_remove"
                      phx-target={@myself}
                      phx-value-val={val}
                      class="text-primary-content/50 hover:text-primary-content"
                    >
                      x
                    </button>
                  </div>
                <% end %>
              <% end %>
            </div>
            <div class="mt-2 font-mono text-xs opacity-60">
              size: <%= MapSet.size(@builder_set) %>
            </div>
          </div>

          <!-- History Log -->
          <%= if length(@builder_history) > 0 do %>
            <div class="space-y-1">
              <div class="text-xs font-bold opacity-60 mb-1">History</div>
              <%= for entry <- Enum.reverse(@builder_history) do %>
                <div class={"text-xs font-mono p-1.5 rounded " <> if(entry.changed, do: "bg-success/10 text-success", else: "bg-warning/10 text-warning")}>
                  <%= entry.action %> &rarr; <%= if entry.changed, do: "set changed", else: "no change (already present)" %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- When to Use -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">When to Use: MapSet vs List vs Map</h3>
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
                    <th>Structure</th>
                    <th>Use When</th>
                    <th>Example</th>
                    <th>Lookup</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for item <- when_to_use() do %>
                    <tr>
                      <td class="font-bold font-mono"><%= item.structure %></td>
                      <td class="text-xs"><%= item.use_when %></td>
                      <td class="text-xs opacity-70"><%= item.example %></td>
                      <td><span class="badge badge-sm badge-ghost"><%= item.lookup %></span></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own</h3>
          <form phx-submit="run_custom" phx-target={@myself} class="space-y-3">
            <input
              type="text"
              name="code"
              value={@custom_code}
              placeholder="MapSet.new([1, 2, 3]) |> MapSet.put(4) |> MapSet.member?(2)"
              class="input input-bordered input-sm font-mono w-full"
              autocomplete="off"
            />
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
              <span class="text-xs opacity-50 self-center">Try MapSet operations</span>
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

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>MapSet stores unique values</strong> &mdash; adding a duplicate is silently ignored.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Sets are unordered</strong> &mdash; don't rely on element position or iteration order.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Membership checks are fast</strong> &mdash; O(log n) vs O(n) for lists.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Set algebra</strong>: <code class="font-mono bg-base-100 px-1 rounded">union</code>, <code class="font-mono bg-base-100 px-1 rounded">intersection</code>, <code class="font-mono bg-base-100 px-1 rounded">difference</code> solve many real-world problems elegantly.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>MapSet implements the <strong>Enumerable</strong> protocol &mdash; you can use all <code class="font-mono bg-base-100 px-1 rounded">Enum</code> functions on it.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_section", %{"id" => id}, socket) do
    section = Enum.find(operations(), &(&1.id == id))
    {:noreply, socket |> assign(active_section: section) |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, active_example_idx: String.to_integer(idx_str))}
  end

  def handle_event("update_sets", %{"set_a" => a_str, "set_b" => b_str}, socket) do
    set_a = parse_set_input(a_str)
    set_b = parse_set_input(b_str)

    {:noreply,
     socket
     |> assign(set_a_input: a_str, set_b_input: b_str)
     |> assign(set_a: set_a, set_b: set_b)}
  end

  def handle_event("set_venn_op", %{"op" => op}, socket) do
    {:noreply, assign(socket, venn_op: op)}
  end

  def handle_event("builder_add", %{"value" => val}, socket) do
    val = String.trim(val)

    if val == "" do
      {:noreply, socket}
    else
      parsed = parse_single_value(val)
      already_present = MapSet.member?(socket.assigns.builder_set, parsed)
      new_set = MapSet.put(socket.assigns.builder_set, parsed)

      entry = %{
        action: "put(#{inspect(parsed)})",
        changed: !already_present
      }

      {:noreply,
       socket
       |> assign(builder_set: new_set)
       |> assign(builder_input: "")
       |> assign(builder_history: socket.assigns.builder_history ++ [entry])}
    end
  end

  def handle_event("builder_remove", %{"val" => val}, socket) do
    parsed = parse_single_value(val)
    new_set = MapSet.delete(socket.assigns.builder_set, parsed)

    entry = %{
      action: "delete(#{inspect(parsed)})",
      changed: true
    }

    {:noreply,
     socket
     |> assign(builder_set: new_set)
     |> assign(builder_history: socket.assigns.builder_history ++ [entry])}
  end

  def handle_event("builder_clear", _params, socket) do
    {:noreply,
     socket
     |> assign(builder_set: MapSet.new())
     |> assign(builder_history: [])}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
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

  defp operations, do: @operations
  defp when_to_use, do: @when_to_use

  defp parse_set_input(str) do
    str
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&parse_single_value/1)
    |> MapSet.new()
  end

  defp parse_single_value(str) do
    str = String.trim(str)

    case Integer.parse(str) do
      {int, ""} -> int
      _ -> str
    end
  end

  defp compute_venn(set_a, set_b, "union"), do: MapSet.union(set_a, set_b)
  defp compute_venn(set_a, set_b, "intersection"), do: MapSet.intersection(set_a, set_b)
  defp compute_venn(set_a, set_b, "difference"), do: MapSet.difference(set_a, set_b)

  defp compute_venn(set_a, set_b, "symmetric_diff") do
    MapSet.union(
      MapSet.difference(set_a, set_b),
      MapSet.difference(set_b, set_a)
    )
  end

  defp format_op_name("union"), do: "Union"
  defp format_op_name("intersection"), do: "Intersection"
  defp format_op_name("difference"), do: "Difference (A - B)"
  defp format_op_name("symmetric_diff"), do: "Symmetric Diff"

  defp venn_code("union"), do: "MapSet.union(a, b)"
  defp venn_code("intersection"), do: "MapSet.intersection(a, b)"
  defp venn_code("difference"), do: "MapSet.difference(a, b)"
  defp venn_code("symmetric_diff"), do: "MapSet.union(MapSet.difference(a, b), MapSet.difference(b, a))"

  defp venn_element_class(val, set_a, set_b, op, side) do
    in_a = MapSet.member?(set_a, val)
    in_b = MapSet.member?(set_b, val)
    in_result = MapSet.member?(compute_venn(set_a, set_b, op), val)

    cond do
      in_result && in_a && in_b -> "badge-warning"
      in_result && side == :a && in_a -> "badge-warning"
      in_result && side == :b && in_b -> "badge-warning"
      side == :a && in_a -> "badge-info badge-outline"
      side == :b && in_b -> "badge-secondary badge-outline"
      true -> "badge-ghost"
    end
  end

  defp quick_examples do
    [
      {"unique words", "\"the cat sat on the mat\" |> String.split() |> MapSet.new() |> MapSet.size()"},
      {"set from range", "1..10 |> MapSet.new() |> MapSet.member?(5)"},
      {"union", "MapSet.union(MapSet.new([1,2,3]), MapSet.new([3,4,5]))"},
      {"to sorted list", "MapSet.new([3,1,4,1,5]) |> MapSet.to_list() |> Enum.sort()"}
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
