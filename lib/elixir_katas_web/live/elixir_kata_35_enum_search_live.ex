defmodule ElixirKatasWeb.ElixirKata35EnumSearchLive do
  use ElixirKatasWeb, :live_component

  @search_fns [
    %{
      id: "find",
      title: "Enum.find/2,3",
      description: "Returns the first element for which the function returns a truthy value, or a default.",
      signature: "Enum.find(enumerable, default \\\\ nil, fun)",
      examples: [
        %{code: "Enum.find([2, 4, 6, 7, 8], &(rem(&1, 2) != 0))", result: "7", label: "First odd"},
        %{code: "Enum.find([2, 4, 6], &(rem(&1, 2) != 0))", result: "nil", label: "Not found"},
        %{code: ~s|Enum.find(["cat", "car", "dog"], &String.starts_with?(&1, "ca"))|, result: ~s|"cat"|, label: "First match"}
      ],
      short_circuit: true,
      short_circuit_note: "find stops as soon as it finds a match. Elements after the match are never checked."
    },
    %{
      id: "any",
      title: "Enum.any?/2",
      description: "Returns true if at least one element satisfies the predicate.",
      signature: "Enum.any?(enumerable, fun)",
      examples: [
        %{code: "Enum.any?([1, 2, 3, 4], &(&1 > 3))", result: "true", label: "Any > 3?"},
        %{code: "Enum.any?([1, 2, 3], &(&1 > 5))", result: "false", label: "Any > 5?"},
        %{code: ~s|Enum.any?(["a", "bb", "ccc"], &(String.length(&1) > 2))|, result: "true", label: "Any long?"}
      ],
      short_circuit: true,
      short_circuit_note: "any? returns true immediately on the first truthy result. It only checks all elements if none match."
    },
    %{
      id: "all",
      title: "Enum.all?/2",
      description: "Returns true only if every element satisfies the predicate.",
      signature: "Enum.all?(enumerable, fun)",
      examples: [
        %{code: "Enum.all?([2, 4, 6, 8], &(rem(&1, 2) == 0))", result: "true", label: "All even?"},
        %{code: "Enum.all?([2, 4, 5, 8], &(rem(&1, 2) == 0))", result: "false", label: "All even? (no)"},
        %{code: "Enum.all?([], &(&1 > 0))", result: "true", label: "Empty list (vacuous truth)"}
      ],
      short_circuit: true,
      short_circuit_note: "all? returns false immediately on the first falsy result. It only checks all elements if all match."
    },
    %{
      id: "member",
      title: "Enum.member?/2",
      description: "Checks if an element exists in the enumerable using equality (==).",
      signature: "Enum.member?(enumerable, element)",
      examples: [
        %{code: "Enum.member?([1, 2, 3, 4, 5], 3)", result: "true", label: "Contains 3?"},
        %{code: "Enum.member?([1, 2, 3], 7)", result: "false", label: "Contains 7?"},
        %{code: ~s|Enum.member?(["a", "b", "c"], "b")|, result: "true", label: "Contains b?"}
      ],
      short_circuit: true,
      short_circuit_note: "member? stops as soon as the element is found. For lists, it is O(n) in the worst case."
    },
    %{
      id: "take_while",
      title: "Enum.take_while/2",
      description: "Takes elements from the front as long as the function returns true. Stops at the first false.",
      signature: "Enum.take_while(enumerable, fun)",
      examples: [
        %{code: "Enum.take_while([1, 2, 3, 4, 5, 1], &(&1 < 4))", result: "[1, 2, 3]", label: "Take while < 4"},
        %{code: "Enum.take_while([5, 4, 3, 2, 1], &(&1 > 2))", result: "[5, 4, 3]", label: "Take while > 2"},
        %{code: "Enum.take_while([1, 2, 3], &(&1 < 10))", result: "[1, 2, 3]", label: "All match"}
      ],
      short_circuit: true,
      short_circuit_note: "take_while stops processing as soon as the predicate returns false. The remaining elements are ignored."
    },
    %{
      id: "drop_while",
      title: "Enum.drop_while/2",
      description: "Drops elements from the front as long as the function returns true. Keeps the rest.",
      signature: "Enum.drop_while(enumerable, fun)",
      examples: [
        %{code: "Enum.drop_while([1, 2, 3, 4, 5], &(&1 < 3))", result: "[3, 4, 5]", label: "Drop while < 3"},
        %{code: "Enum.drop_while([1, 2, 3, 1, 2], &(&1 < 3))", result: "[3, 1, 2]", label: "Only drops from front"},
        %{code: "Enum.drop_while([5, 4, 3], &(&1 > 10))", result: "[5, 4, 3]", label: "None dropped"}
      ],
      short_circuit: true,
      short_circuit_note: "drop_while stops dropping as soon as the predicate returns false. It only drops from the front, not later elements."
    }
  ]

  @search_data [10, 25, 3, 42, 7, 18, 33, 5, 29, 14]

  @filter_predicates [
    %{id: "gt_10", label: "> 10", code: "&(&1 > 10)"},
    %{id: "lt_20", label: "< 20", code: "&(&1 < 20)"},
    %{id: "even", label: "Even", code: "&(rem(&1, 2) == 0)"},
    %{id: "gt_30", label: "> 30", code: "&(&1 > 30)"},
    %{id: "div_5", label: "Div by 5", code: "&(rem(&1, 5) == 0)"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_fn, fn -> hd(@search_fns) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:show_short_circuit, fn -> false end)
     |> assign_new(:sc_data, fn -> [2, 4, 6, 7, 8, 10, 12] end)
     |> assign_new(:sc_step, fn -> 0 end)
     |> assign_new(:sc_mode, fn -> "find_odd" end)
     |> assign_new(:filter_predicate, fn -> nil end)
     |> assign_new(:filter_result, fn -> nil end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Enum Search</h2>
      <p class="text-sm opacity-70 mb-6">
        Search functions locate elements in collections. Many use <strong>short-circuit evaluation</strong>,
        meaning they stop processing as soon as the answer is determined.
      </p>

      <!-- Function Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for func <- search_fns() do %>
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
          <p class="text-xs opacity-60 mb-2"><%= @active_fn.description %></p>

          <!-- Signature -->
          <div class="bg-base-300 rounded-lg p-2 font-mono text-sm mb-4">
            <span class="opacity-50">Signature: </span><span class="text-info"><%= @active_fn.signature %></span>
          </div>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(@active_fn.examples) do %>
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
          <% example = Enum.at(@active_fn.examples, @active_example_idx) %>
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <span class="opacity-50">iex&gt; </span><%= example.code %>
            <div class="text-success font-bold mt-1"><%= example.result %></div>
          </div>

          <!-- Short-circuit note -->
          <%= if @active_fn.short_circuit do %>
            <div class="alert alert-info text-sm">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              <span><strong>Short-circuit:</strong> <%= @active_fn.short_circuit_note %></span>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Short-Circuit Visualization -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Short-Circuit Behavior</h3>
            <button
              phx-click="toggle_short_circuit"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_short_circuit, do: "Hide", else: "Show Demo" %>
            </button>
          </div>

          <%= if @show_short_circuit do %>
            <p class="text-xs opacity-60 mb-4">
              Watch how <code class="font-mono bg-base-300 px-1 rounded">Enum.find</code> stops checking
              once it finds a match. Step through to see which elements get checked.
            </p>

            <div class="bg-base-300 rounded-lg p-2 font-mono text-sm mb-4">
              <span class="opacity-50">Enum.find(</span><span class="text-info"><%= inspect(@sc_data) %></span><span class="opacity-50">, &amp;(rem(&amp;1, 2) != 0))</span>
            </div>

            <!-- Visual elements -->
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for {item, idx} <- Enum.with_index(@sc_data) do %>
                <div class={"w-12 h-12 rounded-lg flex items-center justify-center font-mono font-bold text-sm transition-all " <>
                  cond do
                    idx >= @sc_step -> "bg-base-300 opacity-50"
                    rem(item, 2) != 0 -> "bg-success text-success-content ring-2 ring-success"
                    true -> "bg-error/20 border border-error/40"
                  end}>
                  <%= item %>
                </div>
              <% end %>
            </div>

            <!-- Status -->
            <% sc_result = compute_sc_result(@sc_data, @sc_step) %>
            <div class={"rounded-lg p-3 mb-4 " <> if(sc_result.found, do: "bg-success/10 border border-success/30", else: "bg-base-100 border border-base-300")}>
              <div class="text-sm">
                <span class="opacity-60">Elements checked: </span>
                <span class="font-bold"><%= sc_result.checked %> / <%= length(@sc_data) %></span>
                <%= if sc_result.found do %>
                  <span class="ml-3 text-success font-bold">Found: <%= sc_result.value %></span>
                  <span class="ml-2 text-xs opacity-60">(remaining elements skipped!)</span>
                <% end %>
              </div>
            </div>

            <!-- Controls -->
            <div class="flex gap-2">
              <button
                phx-click="sc_step_prev"
                phx-target={@myself}
                disabled={@sc_step <= 0}
                class="btn btn-sm btn-outline"
              >
                &larr; Back
              </button>
              <button
                phx-click="sc_step_next"
                phx-target={@myself}
                disabled={sc_result.found or @sc_step >= length(@sc_data)}
                class="btn btn-sm btn-primary"
              >
                Check Next &rarr;
              </button>
              <button
                phx-click="sc_reset"
                phx-target={@myself}
                class="btn btn-sm btn-ghost"
              >
                Reset
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Interactive Search Highlighting -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Filter Builder</h3>
          <p class="text-xs opacity-60 mb-3">
            Pick a predicate to see which elements match from the dataset.
          </p>

          <div class="bg-base-300 rounded-lg p-2 font-mono text-sm mb-4">
            <span class="opacity-50">data = </span><span class="text-info"><%= inspect(search_data()) %></span>
          </div>

          <!-- Predicate Buttons -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for pred <- filter_predicates() do %>
              <button
                phx-click="apply_predicate"
                phx-target={@myself}
                phx-value-id={pred.id}
                class={"btn btn-sm " <> if(@filter_predicate == pred.id, do: "btn-accent", else: "btn-outline")}
              >
                <%= pred.label %>
              </button>
            <% end %>
          </div>

          <!-- Highlighted Results -->
          <%= if @filter_result do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for item <- search_data() do %>
                <div class={"w-12 h-12 rounded-lg flex items-center justify-center font-mono font-bold text-sm " <>
                  if(item in @filter_result.matching, do: "bg-success text-success-content", else: "bg-base-300 opacity-40")}>
                  <%= item %>
                </div>
              <% end %>
            </div>

            <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
              <div class="bg-base-300 rounded-lg p-2 text-center">
                <div class="text-xs opacity-60">find</div>
                <div class="font-mono text-sm font-bold text-success"><%= inspect(@filter_result.find_result) %></div>
              </div>
              <div class="bg-base-300 rounded-lg p-2 text-center">
                <div class="text-xs opacity-60">any?</div>
                <div class="font-mono text-sm font-bold"><%= inspect(@filter_result.any_result) %></div>
              </div>
              <div class="bg-base-300 rounded-lg p-2 text-center">
                <div class="text-xs opacity-60">all?</div>
                <div class="font-mono text-sm font-bold"><%= inspect(@filter_result.all_result) %></div>
              </div>
              <div class="bg-base-300 rounded-lg p-2 text-center">
                <div class="text-xs opacity-60">count matching</div>
                <div class="font-mono text-sm font-bold"><%= @filter_result.count_result %></div>
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
                placeholder="Enum.find([1, 2, 3, 4], &(&1 > 2))"
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Run</button>
          </form>

          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="Enum.find(1..100, &(rem(&1, 13) == 0))" class="btn btn-xs btn-outline">find div 13</button>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="Enum.any?(1..5, &(&1 > 3))" class="btn btn-xs btn-outline">any? > 3</button>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="Enum.all?([2, 4, 6, 8], &(rem(&1, 2) == 0))" class="btn btn-xs btn-outline">all? even</button>
            <button phx-click="quick_example" phx-target={@myself} phx-value-code="Enum.take_while(1..20, &(&1 * &1 < 100))" class="btn btn-xs btn-outline">take_while</button>
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
              <span><strong>find</strong> returns the first matching element or a default (nil). Use <code class="font-mono bg-base-100 px-1 rounded">find_index</code> to get the position.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>any?</strong> returns true on the first match. <strong>all?</strong> returns false on the first non-match. Both short-circuit.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>member?</strong> checks for exact equality. For lists it is O(n). Consider MapSet for frequent lookups.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>take_while</strong> takes from the front until the predicate fails. <strong>drop_while</strong> drops from the front until it fails.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Short-circuit</strong> functions avoid unnecessary work, which matters for large collections or expensive predicates.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">6</span>
              <span><strong>all?</strong> on an empty collection returns <code class="font-mono bg-base-100 px-1 rounded">true</code> (vacuous truth), while <strong>any?</strong> returns <code class="font-mono bg-base-100 px-1 rounded">false</code>.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_fn", %{"id" => id}, socket) do
    func = Enum.find(search_fns(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_fn: func)
     |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, active_example_idx: idx)}
  end

  def handle_event("toggle_short_circuit", _params, socket) do
    {:noreply, assign(socket, show_short_circuit: !socket.assigns.show_short_circuit)}
  end

  def handle_event("sc_step_next", _params, socket) do
    new_step = min(socket.assigns.sc_step + 1, length(socket.assigns.sc_data))
    {:noreply, assign(socket, sc_step: new_step)}
  end

  def handle_event("sc_step_prev", _params, socket) do
    new_step = max(socket.assigns.sc_step - 1, 0)
    {:noreply, assign(socket, sc_step: new_step)}
  end

  def handle_event("sc_reset", _params, socket) do
    {:noreply, assign(socket, sc_step: 0)}
  end

  def handle_event("apply_predicate", %{"id" => id}, socket) do
    pred_def = Enum.find(filter_predicates(), &(&1.id == id))
    data = search_data()

    result =
      try do
        {fun, _} = Code.eval_string(pred_def.code)
        matching = Enum.filter(data, fun)
        find_result = Enum.find(data, fun)
        any_result = Enum.any?(data, fun)
        all_result = Enum.all?(data, fun)
        count_result = Enum.count(data, fun)

        %{
          matching: matching,
          find_result: find_result,
          any_result: any_result,
          all_result: all_result,
          count_result: count_result
        }
      rescue
        _ ->
          %{matching: [], find_result: nil, any_result: false, all_result: false, count_result: 0}
      end

    {:noreply,
     socket
     |> assign(filter_predicate: id)
     |> assign(filter_result: result)}
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

  defp search_fns, do: @search_fns
  defp search_data, do: @search_data
  defp filter_predicates, do: @filter_predicates

  defp compute_sc_result(data, step) do
    checked = Enum.take(data, step)
    found_item = Enum.find(checked, &(rem(&1, 2) != 0))

    %{
      checked: step,
      found: found_item != nil,
      value: found_item
    }
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
