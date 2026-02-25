defmodule ElixirKatasWeb.ElixirKata40RangesSlicingLive do
  use ElixirKatasWeb, :live_component

  @sections [
    %{
      id: "ranges",
      title: "Range Basics",
      description: "Ranges represent a sequence of integers with optional step. They are lightweight, lazy, and implement the Enumerable protocol.",
      examples: [
        %{
          label: "Simple range",
          code: "1..10",
          result: "1..10",
          note: "A range is NOT a list. It's a struct that describes the sequence without materializing it."
        },
        %{
          label: "Descending",
          code: "10..1//-1",
          result: "10..1//-1",
          note: "Use a negative step to count down. Without //-1, 10..1 produces an empty sequence."
        },
        %{
          label: "Step ranges",
          code: "1..20//3",
          result: "1..20//3",
          note: "Step of 3: produces 1, 4, 7, 10, 13, 16, 19"
        },
        %{
          label: "To list",
          code: "Enum.to_list(1..10//2)",
          result: "[1, 3, 5, 7, 9]",
          note: "Use Enum functions to materialize a range into a list"
        },
        %{
          label: "In guards",
          code: "case 5 do\n  n when n in 1..10 -> \"in range\"\n  _ -> \"out of range\"\nend",
          result: ~s|"in range"|,
          note: "Ranges can be used in guards with the 'in' operator for efficient bounds checking"
        }
      ]
    },
    %{
      id: "slicing",
      title: "Slicing with Enum",
      description: "Enum provides several functions for extracting portions of enumerables.",
      examples: [
        %{
          label: "Enum.slice/2",
          code: "Enum.slice([10, 20, 30, 40, 50], 1..3)",
          result: "[20, 30, 40]",
          note: "Extracts elements at indices 1 through 3 (inclusive). Uses a range as the index spec."
        },
        %{
          label: "Enum.slice/3",
          code: "Enum.slice([10, 20, 30, 40, 50], 1, 2)",
          result: "[20, 30]",
          note: "Starting at index 1, take 2 elements."
        },
        %{
          label: "Negative indices",
          code: "Enum.slice([10, 20, 30, 40, 50], -3..-1)",
          result: "[30, 40, 50]",
          note: "Negative indices count from the end. -1 is the last element."
        },
        %{
          label: "Enum.take/2",
          code: "Enum.take([10, 20, 30, 40, 50], 3)",
          result: "[10, 20, 30]",
          note: "Takes first N elements. Negative N takes from the end."
        },
        %{
          label: "Enum.drop/2",
          code: "Enum.drop([10, 20, 30, 40, 50], 2)",
          result: "[30, 40, 50]",
          note: "Drops first N elements. Negative N drops from the end."
        },
        %{
          label: "Enum.take/2 negative",
          code: "Enum.take([10, 20, 30, 40, 50], -2)",
          result: "[40, 50]",
          note: "Negative count takes from the end."
        },
        %{
          label: "Enum.split/2",
          code: "Enum.split([10, 20, 30, 40, 50], 3)",
          result: "{[10, 20, 30], [40, 50]}",
          note: "Splits into two lists at position N."
        }
      ]
    },
    %{
      id: "patterns",
      title: "Practical Patterns",
      description: "Common patterns using ranges and slicing in real Elixir code.",
      examples: [
        %{
          label: "Pagination",
          code: "page = 2\nper_page = 3\ndata = Enum.to_list(1..20)\n\ndata\n|> Enum.drop((page - 1) * per_page)\n|> Enum.take(per_page)",
          result: "[4, 5, 6]",
          note: "Page 2 with 3 items per page: skip first 3, take next 3."
        },
        %{
          label: "Sliding window",
          code: "Enum.chunk_every([1,2,3,4,5,6], 3, 1, :discard)",
          result: "[[1,2,3], [2,3,4], [3,4,5], [4,5,6]]",
          note: "Overlapping windows of size 3, sliding by 1."
        },
        %{
          label: "Every Nth",
          code: "0..20//5 |> Enum.to_list()",
          result: "[0, 5, 10, 15, 20]",
          note: "Step ranges are perfect for sampling at regular intervals."
        },
        %{
          label: "Index generation",
          code: "list = [:a, :b, :c, :d]\nfor {item, idx} <- Enum.with_index(list),\n    do: {idx, item}",
          result: "[{0, :a}, {1, :b}, {2, :c}, {3, :d}]",
          note: "Combine with_index for indexed iteration."
        },
        %{
          label: "Range membership",
          code: "valid_port? = fn port -> port in 1..65535 end\n{valid_port?.(80), valid_port?.(0), valid_port?.(99999)}",
          result: "{true, false, false}",
          note: "Efficient bounds checking with the 'in' operator."
        }
      ]
    }
  ]

  @range_properties [
    %{property: "first", code: "range.first", example: "(1..10).first", result: "1"},
    %{property: "last", code: "range.last", example: "(1..10).last", result: "10"},
    %{property: "step", code: "range.step", example: "(1..10//3).step", result: "3"},
    %{property: "size", code: "Range.size(range)", example: "Range.size(1..10)", result: "10"},
    %{property: "member?", code: "value in range", example: "5 in 1..10", result: "true"},
    %{property: "disjoint?", code: "Range.disjoint?(a, b)", example: "Range.disjoint?(1..5, 6..10)", result: "true"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_section, fn -> hd(@sections) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:range_first, fn -> 1 end)
     |> assign_new(:range_last, fn -> 20 end)
     |> assign_new(:range_step, fn -> 1 end)
     |> assign_new(:slice_data, fn -> Enum.to_list(1..20) end)
     |> assign_new(:slice_start, fn -> 0 end)
     |> assign_new(:slice_end, fn -> 4 end)
     |> assign_new(:show_properties, fn -> false end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Ranges &amp; Slicing</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>Ranges</strong> are lightweight structs that represent integer sequences. Combined with
        Enum slicing functions, they provide powerful tools for extracting and generating portions
        of data.
      </p>

      <!-- Section Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for section <- sections() do %>
          <button
            phx-click="select_section"
            phx-target={@myself}
            phx-value-id={section.id}
            class={"btn btn-sm " <> if(@active_section.id == section.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= section.title %>
          </button>
        <% end %>
      </div>

      <!-- Section Explorer -->
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

      <!-- Interactive Range Builder -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive Range Builder</h3>
          <p class="text-xs opacity-60 mb-4">
            Adjust the first, last, and step values to see the resulting range and its elements.
          </p>

          <form phx-change="update_range" phx-target={@myself} class="space-y-3">
            <div class="grid grid-cols-3 gap-4">
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">First</span></label>
                <input
                  type="number"
                  name="first"
                  value={@range_first}
                  class="input input-bordered input-sm font-mono"
                />
              </div>
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">Last</span></label>
                <input
                  type="number"
                  name="last"
                  value={@range_last}
                  class="input input-bordered input-sm font-mono"
                />
              </div>
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">Step</span></label>
                <input
                  type="number"
                  name="step"
                  value={@range_step}
                  class="input input-bordered input-sm font-mono"
                />
              </div>
            </div>
          </form>

          <!-- Range display -->
          <div class="bg-base-300 rounded-lg p-3 mt-4 font-mono text-sm">
            <span class="opacity-50">iex&gt; </span>
            <%= range_display(@range_first, @range_last, @range_step) %>
            <span class="opacity-50"> |&gt; Enum.to_list()</span>
          </div>

          <div class="flex flex-wrap gap-2 mt-3">
            <% elements = compute_range(@range_first, @range_last, @range_step) %>
            <%= for val <- elements do %>
              <span class="badge badge-primary badge-lg font-mono"><%= val %></span>
            <% end %>
            <%= if length(elements) == 0 do %>
              <span class="text-xs opacity-40 italic">Empty range (check step direction)</span>
            <% end %>
          </div>

          <div class="mt-3 flex gap-4 text-xs opacity-60">
            <span>Size: <strong><%= length(compute_range(@range_first, @range_last, @range_step)) %></strong></span>
            <span>Range: <strong><%= range_display(@range_first, @range_last, @range_step) %></strong></span>
          </div>
        </div>
      </div>

      <!-- Interactive Slicer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive Slicer</h3>
          <p class="text-xs opacity-60 mb-4">
            Drag the start and end positions to slice the list visually.
          </p>

          <!-- Source data with highlights -->
          <div class="flex flex-wrap gap-1 mb-4">
            <%= for {val, idx} <- Enum.with_index(@slice_data) do %>
              <div class="flex flex-col items-center">
                <span class="text-xs opacity-30"><%= idx %></span>
                <span class={"badge font-mono " <> slice_badge_class(idx, @slice_start, @slice_end)}>
                  <%= val %>
                </span>
              </div>
            <% end %>
          </div>

          <form phx-change="update_slice" phx-target={@myself} class="space-y-3">
            <div class="grid grid-cols-2 gap-4">
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">Start index</span></label>
                <input
                  type="range"
                  name="start"
                  min="0"
                  max={length(@slice_data) - 1}
                  value={@slice_start}
                  class="range range-primary range-sm"
                />
                <div class="text-xs text-center opacity-60"><%= @slice_start %></div>
              </div>
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">End index</span></label>
                <input
                  type="range"
                  name="end"
                  min="0"
                  max={length(@slice_data) - 1}
                  value={@slice_end}
                  class="range range-accent range-sm"
                />
                <div class="text-xs text-center opacity-60"><%= @slice_end %></div>
              </div>
            </div>
          </form>

          <!-- Code and result -->
          <div class="bg-base-300 rounded-lg p-3 mt-3 font-mono text-xs">
            <div>
              <span class="opacity-50">iex&gt; </span>Enum.slice(<%= inspect(Enum.to_list(1..20)) %>, <%= @slice_start %>..<%= @slice_end %>)
            </div>
            <div class="text-success font-bold mt-1">
              <%= inspect(Enum.slice(@slice_data, @slice_start..@slice_end)) %>
            </div>
          </div>

          <!-- Quick slice patterns -->
          <div class="flex flex-wrap gap-2 mt-4">
            <span class="text-xs opacity-50 self-center">Quick patterns:</span>
            <button phx-click="slice_first_5" phx-target={@myself} class="btn btn-xs btn-outline">First 5</button>
            <button phx-click="slice_last_5" phx-target={@myself} class="btn btn-xs btn-outline">Last 5</button>
            <button phx-click="slice_middle" phx-target={@myself} class="btn btn-xs btn-outline">Middle</button>
            <button phx-click="slice_all" phx-target={@myself} class="btn btn-xs btn-outline">All</button>
          </div>

          <!-- Equivalent expressions -->
          <div class="mt-4 space-y-1 text-xs font-mono">
            <div class="opacity-60">Equivalent expressions:</div>
            <div>Enum.slice(data, <%= @slice_start %>..<%= @slice_end %>) <span class="text-success"># range-based</span></div>
            <div>Enum.slice(data, <%= @slice_start %>, <%= max(@slice_end - @slice_start + 1, 0) %>) <span class="text-success"># start + count</span></div>
            <%= if @slice_start == 0 do %>
              <div>Enum.take(data, <%= @slice_end + 1 %>) <span class="text-success"># take from front</span></div>
            <% end %>
            <%= if @slice_end == length(@slice_data) - 1 do %>
              <div>Enum.drop(data, <%= @slice_start %>) <span class="text-success"># drop from front</span></div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Range Properties -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Range Properties</h3>
            <button
              phx-click="toggle_properties"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_properties, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_properties do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Property</th>
                    <th>Access</th>
                    <th>Example</th>
                    <th>Result</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for prop <- range_properties() do %>
                    <tr>
                      <td class="font-bold"><%= prop.property %></td>
                      <td class="font-mono text-xs"><%= prop.code %></td>
                      <td class="font-mono text-xs"><%= prop.example %></td>
                      <td class="font-mono text-xs text-success"><%= prop.result %></td>
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
              placeholder="1..100//7 |> Enum.to_list()"
              class="input input-bordered input-sm font-mono w-full"
              autocomplete="off"
            />
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
            </div>
          </form>

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
              <span><strong>Ranges are lazy</strong> &mdash; <code class="font-mono bg-base-100 px-1 rounded">1..1_000_000</code> uses constant memory. Elements are computed on demand.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Step ranges</strong> with <code class="font-mono bg-base-100 px-1 rounded">first..last//step</code> control the increment. Use negative steps for descending.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Enum.slice/2</strong> extracts a sub-list by index range. <strong>Enum.take/2</strong> and <strong>Enum.drop/2</strong> work from the ends.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Negative indices</strong> in Enum.slice count from the end: <code class="font-mono bg-base-100 px-1 rounded">-1</code> is the last element.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Ranges implement <strong>Enumerable</strong> &mdash; use all Enum/Stream functions on them directly.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_section", %{"id" => id}, socket) do
    section = Enum.find(sections(), &(&1.id == id))
    {:noreply, socket |> assign(active_section: section) |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, active_example_idx: String.to_integer(idx_str))}
  end

  def handle_event("update_range", %{"first" => first_str, "last" => last_str, "step" => step_str}, socket) do
    with {first, _} <- Integer.parse(first_str),
         {last, _} <- Integer.parse(last_str),
         {step, _} <- Integer.parse(step_str),
         true <- step != 0 do
      {:noreply,
       socket
       |> assign(range_first: first)
       |> assign(range_last: last)
       |> assign(range_step: step)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("update_slice", %{"start" => start_str, "end" => end_str}, socket) do
    start_idx = String.to_integer(start_str)
    end_idx = String.to_integer(end_str)
    {:noreply, socket |> assign(slice_start: start_idx) |> assign(slice_end: end_idx)}
  end

  def handle_event("slice_first_5", _params, socket) do
    {:noreply, socket |> assign(slice_start: 0) |> assign(slice_end: 4)}
  end

  def handle_event("slice_last_5", _params, socket) do
    last = length(socket.assigns.slice_data) - 1
    {:noreply, socket |> assign(slice_start: last - 4) |> assign(slice_end: last)}
  end

  def handle_event("slice_middle", _params, socket) do
    len = length(socket.assigns.slice_data)
    mid = div(len, 2)
    {:noreply, socket |> assign(slice_start: mid - 2) |> assign(slice_end: mid + 2)}
  end

  def handle_event("slice_all", _params, socket) do
    last = length(socket.assigns.slice_data) - 1
    {:noreply, socket |> assign(slice_start: 0) |> assign(slice_end: last)}
  end

  def handle_event("toggle_properties", _params, socket) do
    {:noreply, assign(socket, show_properties: !socket.assigns.show_properties)}
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

  defp sections, do: @sections
  defp range_properties, do: @range_properties

  defp compute_range(_first, _last, step) when step == 0, do: []

  defp compute_range(first, last, step) do
    range = first..last//step
    elements = Enum.to_list(range)

    if length(elements) > 50 do
      Enum.take(elements, 50)
    else
      elements
    end
  end

  defp range_display(first, last, 1), do: "#{first}..#{last}"
  defp range_display(first, last, step), do: "#{first}..#{last}//#{step}"

  defp slice_badge_class(idx, slice_start, slice_end) do
    cond do
      slice_start <= slice_end && idx >= slice_start && idx <= slice_end ->
        "badge-primary badge-lg"

      slice_start > slice_end && (idx >= slice_start || idx <= slice_end) ->
        "badge-primary badge-lg"

      true ->
        "badge-ghost badge-lg"
    end
  end

  defp quick_examples do
    [
      {"even numbers", "Enum.to_list(2..20//2)"},
      {"slice middle", "Enum.slice(Enum.to_list(1..20), 5..14)"},
      {"take + drop", "1..20 |> Enum.to_list() |> Enum.drop(3) |> Enum.take(5)"},
      {"chunk pairs", "Enum.chunk_every(1..10 |> Enum.to_list(), 2)"},
      {"range size", "Range.size(1..100//3)"},
      {"split at 5", "Enum.split(Enum.to_list(1..10), 5)"}
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
