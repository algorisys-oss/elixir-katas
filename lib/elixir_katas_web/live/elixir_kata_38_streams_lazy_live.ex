defmodule ElixirKatasWeb.ElixirKata38StreamsLazyLive do
  use ElixirKatasWeb, :live_component

  @comparisons [
    %{
      id: "map_filter",
      title: "Map + Filter",
      eager: %{
        code: "[1, 2, 3, 4, 5]\n|> Enum.map(&(&1 * &1))\n|> Enum.filter(&(&1 > 5))",
        steps: [
          %{label: "Start", data: "[1, 2, 3, 4, 5]", note: "Original list"},
          %{label: "Enum.map", data: "[1, 4, 9, 16, 25]", note: "ALL elements squared - creates intermediate list"},
          %{label: "Enum.filter", data: "[9, 16, 25]", note: "ALL elements checked - creates final list"}
        ],
        result: "[9, 16, 25]",
        passes: 2,
        intermediates: 1
      },
      lazy: %{
        code: "[1, 2, 3, 4, 5]\n|> Stream.map(&(&1 * &1))\n|> Stream.filter(&(&1 > 5))\n|> Enum.to_list()",
        steps: [
          %{label: "Start", data: "[1, 2, 3, 4, 5]", note: "Original list"},
          %{label: "Stream.map", data: "#Stream<...>", note: "No computation yet! Just a recipe."},
          %{label: "Stream.filter", data: "#Stream<...>", note: "Still no computation! Composing recipes."},
          %{label: "Enum.to_list", data: "[9, 16, 25]", note: "NOW processes each element through the whole pipeline, one at a time"}
        ],
        result: "[9, 16, 25]",
        passes: 1,
        intermediates: 0
      }
    },
    %{
      id: "take_first",
      title: "Take First N",
      eager: %{
        code: "1..1_000_000\n|> Enum.map(&(&1 * 2))\n|> Enum.take(3)",
        steps: [
          %{label: "Start", data: "1..1_000_000", note: "Range of 1 million"},
          %{label: "Enum.map", data: "[2, 4, 6, ..., 2_000_000]", note: "Maps ALL 1 million elements first!"},
          %{label: "Enum.take", data: "[2, 4, 6]", note: "Takes first 3 from the full million-element list"}
        ],
        result: "[2, 4, 6]",
        passes: 2,
        intermediates: 1
      },
      lazy: %{
        code: "1..1_000_000\n|> Stream.map(&(&1 * 2))\n|> Stream.take(3)\n|> Enum.to_list()",
        steps: [
          %{label: "Start", data: "1..1_000_000", note: "Range of 1 million"},
          %{label: "Stream.map", data: "#Stream<...>", note: "No computation. Just a recipe."},
          %{label: "Stream.take(3)", data: "#Stream<...>", note: "Adds a 'stop after 3' instruction."},
          %{label: "Enum.to_list", data: "[2, 4, 6]", note: "Only processes 3 elements! Stops immediately."}
        ],
        result: "[2, 4, 6]",
        passes: 1,
        intermediates: 0
      }
    },
    %{
      id: "chained",
      title: "Multiple Transforms",
      eager: %{
        code: "1..10\n|> Enum.map(&(&1 * 3))\n|> Enum.filter(&(rem(&1, 2) == 0))\n|> Enum.map(&div(&1, 2))\n|> Enum.take(3)",
        steps: [
          %{label: "Start", data: "1..10", note: "10 elements"},
          %{label: "Enum.map(*3)", data: "[3, 6, 9, 12, 15, 18, 21, 24, 27, 30]", note: "10 elements mapped"},
          %{label: "Enum.filter(even)", data: "[6, 12, 18, 24, 30]", note: "5 elements remain"},
          %{label: "Enum.map(div 2)", data: "[3, 6, 9, 12, 15]", note: "5 elements mapped"},
          %{label: "Enum.take(3)", data: "[3, 6, 9]", note: "Final 3 elements"}
        ],
        result: "[3, 6, 9]",
        passes: 4,
        intermediates: 3
      },
      lazy: %{
        code: "1..10\n|> Stream.map(&(&1 * 3))\n|> Stream.filter(&(rem(&1, 2) == 0))\n|> Stream.map(&div(&1, 2))\n|> Stream.take(3)\n|> Enum.to_list()",
        steps: [
          %{label: "Start", data: "1..10", note: "10 elements"},
          %{label: "Stream.map(*3)", data: "#Stream<...>", note: "Recipe step 1"},
          %{label: "Stream.filter(even)", data: "#Stream<...>", note: "Recipe step 2"},
          %{label: "Stream.map(div 2)", data: "#Stream<...>", note: "Recipe step 3"},
          %{label: "Stream.take(3)", data: "#Stream<...>", note: "Recipe step 4: stop after 3 results"},
          %{label: "Enum.to_list", data: "[3, 6, 9]", note: "Runs pipeline. Processes elements until 3 pass through."}
        ],
        result: "[3, 6, 9]",
        passes: 1,
        intermediates: 0
      }
    }
  ]

  @stream_functions [
    %{
      name: "Stream.map/2",
      desc: "Lazily transforms each element",
      code: "Stream.map(1..5, &(&1 * 2))",
      eager_equiv: "Enum.map/2"
    },
    %{
      name: "Stream.filter/2",
      desc: "Lazily keeps elements matching predicate",
      code: "Stream.filter(1..10, &(rem(&1, 2) == 0))",
      eager_equiv: "Enum.filter/2"
    },
    %{
      name: "Stream.take/2",
      desc: "Lazily takes first N elements, then halts",
      code: "Stream.take(1..1_000_000, 5)",
      eager_equiv: "Enum.take/2"
    },
    %{
      name: "Stream.drop/2",
      desc: "Lazily skips first N elements",
      code: "Stream.drop(1..10, 3)",
      eager_equiv: "Enum.drop/2"
    },
    %{
      name: "Stream.take_while/2",
      desc: "Takes elements while predicate is true, then halts",
      code: "Stream.take_while(1..100, &(&1 < 10))",
      eager_equiv: "Enum.take_while/2"
    },
    %{
      name: "Stream.flat_map/2",
      desc: "Lazily maps and flattens",
      code: "Stream.flat_map(1..3, fn x -> [x, x * 10] end)",
      eager_equiv: "Enum.flat_map/2"
    },
    %{
      name: "Stream.chunk_every/2",
      desc: "Lazily groups into chunks of N",
      code: "Stream.chunk_every(1..10, 3)",
      eager_equiv: "Enum.chunk_every/2"
    },
    %{
      name: "Stream.uniq/1",
      desc: "Lazily removes consecutive duplicates",
      code: "Stream.uniq([1, 1, 2, 2, 3, 1])",
      eager_equiv: "Enum.uniq/1"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_comparison, fn -> hd(@comparisons) end)
     |> assign_new(:show_step, fn -> 0 end)
     |> assign_new(:show_lazy_step, fn -> 0 end)
     |> assign_new(:active_func_idx, fn -> 0 end)
     |> assign_new(:show_memory, fn -> false end)
     |> assign_new(:pipeline_code, fn -> "" end)
     |> assign_new(:pipeline_result, fn -> nil end)
     |> assign_new(:show_functions, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Streams: Lazy Evaluation</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>Streams</strong> are lazy, composable enumerables. Unlike <code class="font-mono bg-base-300 px-1 rounded">Enum</code>
        which processes collections eagerly (computing everything immediately), Streams build up a recipe of
        computations that only execute when you consume them with an <code class="font-mono bg-base-300 px-1 rounded">Enum</code> function.
      </p>

      <!-- Comparison Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for comp <- comparisons() do %>
          <button
            phx-click="select_comparison"
            phx-target={@myself}
            phx-value-id={comp.id}
            class={"btn btn-sm " <> if(@active_comparison.id == comp.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= comp.title %>
          </button>
        <% end %>
      </div>

      <!-- Eager vs Lazy Side-by-Side -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">
            Eager (Enum) vs Lazy (Stream): <%= @active_comparison.title %>
          </h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Eager Side -->
            <div class="bg-error/5 border border-error/20 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-3">
                <span class="badge badge-error badge-sm">Eager (Enum)</span>
                <span class="text-xs opacity-60">Processes everything immediately</span>
              </div>
              <div class="bg-base-100 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap mb-3"><%= @active_comparison.eager.code %></div>

              <!-- Step-by-step visualization -->
              <div class="space-y-2">
                <%= for {step, idx} <- Enum.with_index(@active_comparison.eager.steps) do %>
                  <div
                    phx-click="show_eager_step"
                    phx-target={@myself}
                    phx-value-idx={idx}
                    class={"rounded-lg p-2 cursor-pointer transition-all " <> if(idx <= @show_step, do: "bg-base-100 opacity-100", else: "bg-base-300/50 opacity-40")}
                  >
                    <div class="flex items-center gap-2">
                      <span class={"badge badge-xs " <> if(idx == 0, do: "badge-ghost", else: "badge-error")}>
                        <%= idx + 1 %>
                      </span>
                      <span class="text-xs font-bold"><%= step.label %></span>
                    </div>
                    <%= if idx <= @show_step do %>
                      <div class="font-mono text-xs mt-1 text-info"><%= step.data %></div>
                      <div class="text-xs opacity-60 mt-0.5"><%= step.note %></div>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <div class="mt-3 flex gap-2">
                <span class="badge badge-error badge-sm">
                  <%= @active_comparison.eager.passes %> pass(es) over data
                </span>
                <span class="badge badge-warning badge-sm">
                  <%= @active_comparison.eager.intermediates %> intermediate list(s)
                </span>
              </div>
            </div>

            <!-- Lazy Side -->
            <div class="bg-success/5 border border-success/20 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-3">
                <span class="badge badge-success badge-sm">Lazy (Stream)</span>
                <span class="text-xs opacity-60">Computes only when consumed</span>
              </div>
              <div class="bg-base-100 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap mb-3"><%= @active_comparison.lazy.code %></div>

              <!-- Step-by-step visualization -->
              <div class="space-y-2">
                <%= for {step, idx} <- Enum.with_index(@active_comparison.lazy.steps) do %>
                  <div
                    phx-click="show_lazy_step"
                    phx-target={@myself}
                    phx-value-idx={idx}
                    class={"rounded-lg p-2 cursor-pointer transition-all " <> if(idx <= @show_lazy_step, do: "bg-base-100 opacity-100", else: "bg-base-300/50 opacity-40")}
                  >
                    <div class="flex items-center gap-2">
                      <span class={"badge badge-xs " <> if(idx == 0, do: "badge-ghost", else: if(String.contains?(step.data, "#Stream"), do: "badge-info", else: "badge-success"))}>
                        <%= idx + 1 %>
                      </span>
                      <span class="text-xs font-bold"><%= step.label %></span>
                    </div>
                    <%= if idx <= @show_lazy_step do %>
                      <div class={"font-mono text-xs mt-1 " <> if(String.contains?(step.data, "#Stream"), do: "text-warning", else: "text-success")}>
                        <%= step.data %>
                      </div>
                      <div class="text-xs opacity-60 mt-0.5"><%= step.note %></div>
                    <% end %>
                  </div>
                <% end %>
              </div>

              <div class="mt-3 flex gap-2">
                <span class="badge badge-success badge-sm">
                  <%= @active_comparison.lazy.passes %> pass over data
                </span>
                <span class="badge badge-success badge-sm">
                  <%= @active_comparison.lazy.intermediates %> intermediate list(s)
                </span>
              </div>
            </div>
          </div>

          <!-- Step controls -->
          <div class="flex gap-2 mt-4 justify-center">
            <button
              phx-click="step_back"
              phx-target={@myself}
              class="btn btn-sm btn-outline"
              disabled={@show_step <= 0 and @show_lazy_step <= 0}
            >
              &larr; Back
            </button>
            <button
              phx-click="step_forward"
              phx-target={@myself}
              class="btn btn-sm btn-primary"
            >
              Forward &rarr;
            </button>
            <button
              phx-click="show_all_steps"
              phx-target={@myself}
              class="btn btn-sm btn-accent"
            >
              Show All
            </button>
            <button
              phx-click="reset_steps"
              phx-target={@myself}
              class="btn btn-sm btn-ghost"
            >
              Reset
            </button>
          </div>
        </div>
      </div>

      <!-- Memory Efficiency -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Memory Efficiency</h3>
            <button
              phx-click="toggle_memory"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_memory, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_memory do %>
            <div class="space-y-4">
              <p class="text-sm opacity-70">
                Streams avoid creating intermediate collections. With Enum, each step creates a new list
                in memory. With Stream, elements flow through the entire pipeline one at a time.
              </p>

              <!-- Visual memory comparison -->
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                  <h4 class="text-sm font-bold text-error mb-2">Enum: Multiple Lists in Memory</h4>
                  <div class="space-y-2 font-mono text-xs">
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Step 1: Original</div>
                      <div>[1, 2, 3, ..., 1_000_000] <span class="text-error">~8 MB</span></div>
                    </div>
                    <div class="text-center opacity-30">&darr; Enum.map creates new list</div>
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Step 2: Mapped</div>
                      <div>[2, 4, 6, ..., 2_000_000] <span class="text-error">~8 MB</span></div>
                    </div>
                    <div class="text-center opacity-30">&darr; Enum.filter creates new list</div>
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Step 3: Filtered</div>
                      <div>[2, 4, 6, ..., 2_000_000] <span class="text-error">~4 MB</span></div>
                    </div>
                    <div class="text-center text-error text-xs font-bold">Peak: ~20 MB in memory</div>
                  </div>
                </div>

                <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                  <h4 class="text-sm font-bold text-success mb-2">Stream: One Element at a Time</h4>
                  <div class="space-y-2 font-mono text-xs">
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Element 1 flows through</div>
                      <div>1 &rarr; map(1*2)=2 &rarr; filter(even?)=true &rarr; <span class="text-success">[2]</span></div>
                    </div>
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Element 2 flows through</div>
                      <div>2 &rarr; map(2*2)=4 &rarr; filter(even?)=true &rarr; <span class="text-success">[2, 4]</span></div>
                    </div>
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Element 3 flows through</div>
                      <div>3 &rarr; map(3*2)=6 &rarr; filter(even?)=true &rarr; <span class="text-success">[2, 4, 6]</span></div>
                    </div>
                    <div class="text-center opacity-30">... one element at a time ...</div>
                    <div class="text-center text-success text-xs font-bold">Peak: only result list in memory</div>
                  </div>
                </div>
              </div>

              <div class="alert alert-info text-sm">
                <div>
                  <strong>Key insight:</strong> Streams don't compute anything until consumed by an Enum function.
                  <code class="font-mono bg-base-100 px-1 rounded">Stream.map/2</code> returns a struct, not a result.
                  Only when you call <code class="font-mono bg-base-100 px-1 rounded">Enum.to_list/1</code>,
                  <code class="font-mono bg-base-100 px-1 rounded">Enum.take/2</code>, etc. does the work happen.
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Stream Functions Reference -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Common Stream Functions</h3>
            <button
              phx-click="toggle_functions"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_functions, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_functions do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for {func, idx} <- Enum.with_index(stream_functions()) do %>
                <button
                  phx-click="select_func"
                  phx-target={@myself}
                  phx-value-idx={idx}
                  class={"btn btn-xs " <> if(idx == @active_func_idx, do: "btn-accent", else: "btn-ghost")}
                >
                  <%= func.name %>
                </button>
              <% end %>
            </div>

            <% func = Enum.at(stream_functions(), @active_func_idx) %>
            <div class="space-y-3">
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm"><%= func.code %></div>
              <p class="text-sm"><%= func.desc %></p>
              <div class="text-xs opacity-60">
                Eager equivalent: <code class="font-mono bg-base-300 px-1 rounded"><%= func.eager_equiv %></code>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own Pipeline</h3>
          <form phx-submit="run_pipeline" phx-target={@myself} class="space-y-3">
            <input
              type="text"
              name="code"
              value={@pipeline_code}
              placeholder="1..100 |> Stream.filter(&(rem(&1, 3) == 0)) |> Stream.map(&(&1 * 2)) |> Enum.take(5)"
              class="input input-bordered input-sm font-mono w-full"
              autocomplete="off"
            />
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
              <span class="text-xs opacity-50 self-center">Remember: streams need an Enum function to produce a result</span>
            </div>
          </form>

          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, code} <- quick_examples() do %>
              <button
                phx-click="quick_pipeline"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @pipeline_result do %>
            <div class={"alert text-sm mt-3 " <> if(@pipeline_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @pipeline_result.input %></div>
                <div class="font-mono font-bold mt-1"><%= @pipeline_result.output %></div>
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
              <span><strong>Streams are lazy</strong> &mdash; they describe computations but don't execute until consumed by an Enum function.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>No intermediate collections</strong> &mdash; elements flow through the entire pipeline one at a time.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Early termination</strong> &mdash; <code class="font-mono bg-base-100 px-1 rounded">Stream.take/2</code> stops processing after N results, avoiding unnecessary work.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Use Enum for small data</strong>, Streams for large/infinite data or when you only need a portion of results.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Streams are <strong>composable</strong> &mdash; chain multiple Stream operations, then trigger with one Enum call.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_comparison", %{"id" => id}, socket) do
    comp = Enum.find(comparisons(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_comparison: comp)
     |> assign(show_step: 0)
     |> assign(show_lazy_step: 0)}
  end

  def handle_event("show_eager_step", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, show_step: String.to_integer(idx_str))}
  end

  def handle_event("show_lazy_step", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, show_lazy_step: String.to_integer(idx_str))}
  end

  def handle_event("step_forward", _params, socket) do
    max_eager = length(socket.assigns.active_comparison.eager.steps) - 1
    max_lazy = length(socket.assigns.active_comparison.lazy.steps) - 1

    {:noreply,
     socket
     |> assign(show_step: min(socket.assigns.show_step + 1, max_eager))
     |> assign(show_lazy_step: min(socket.assigns.show_lazy_step + 1, max_lazy))}
  end

  def handle_event("step_back", _params, socket) do
    {:noreply,
     socket
     |> assign(show_step: max(socket.assigns.show_step - 1, 0))
     |> assign(show_lazy_step: max(socket.assigns.show_lazy_step - 1, 0))}
  end

  def handle_event("show_all_steps", _params, socket) do
    max_eager = length(socket.assigns.active_comparison.eager.steps) - 1
    max_lazy = length(socket.assigns.active_comparison.lazy.steps) - 1

    {:noreply,
     socket
     |> assign(show_step: max_eager)
     |> assign(show_lazy_step: max_lazy)}
  end

  def handle_event("reset_steps", _params, socket) do
    {:noreply, socket |> assign(show_step: 0) |> assign(show_lazy_step: 0)}
  end

  def handle_event("toggle_memory", _params, socket) do
    {:noreply, assign(socket, show_memory: !socket.assigns.show_memory)}
  end

  def handle_event("toggle_functions", _params, socket) do
    {:noreply, assign(socket, show_functions: !socket.assigns.show_functions)}
  end

  def handle_event("select_func", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, active_func_idx: String.to_integer(idx_str))}
  end

  def handle_event("run_pipeline", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))
    {:noreply, socket |> assign(pipeline_code: code) |> assign(pipeline_result: result)}
  end

  def handle_event("quick_pipeline", %{"code" => code}, socket) do
    result = evaluate_code(code)
    {:noreply, socket |> assign(pipeline_code: code) |> assign(pipeline_result: result)}
  end

  # Helpers

  defp comparisons, do: @comparisons
  defp stream_functions, do: @stream_functions

  defp quick_examples do
    [
      {"lazy filter+take", "1..1_000_000 |> Stream.filter(&(rem(&1, 7) == 0)) |> Enum.take(5)"},
      {"chained streams", "1..100 |> Stream.map(&(&1 * 3)) |> Stream.filter(&(rem(&1, 2) == 0)) |> Enum.take(5)"},
      {"chunk+sum", "1..20 |> Stream.chunk_every(5) |> Enum.map(&Enum.sum/1)"},
      {"flat_map", "1..5 |> Stream.flat_map(fn x -> [x, x * 10] end) |> Enum.to_list()"}
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
