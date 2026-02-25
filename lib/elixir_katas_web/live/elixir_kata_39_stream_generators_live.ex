defmodule ElixirKatasWeb.ElixirKata39StreamGeneratorsLive do
  use ElixirKatasWeb, :live_component

  @generators [
    %{
      id: "iterate",
      title: "Stream.iterate/2",
      description: "Generates an infinite stream starting from a value and applying a function repeatedly to produce the next value.",
      syntax: "Stream.iterate(start_value, next_fn)",
      examples: [
        %{
          label: "Powers of 2",
          code: "Stream.iterate(1, &(&1 * 2)) |> Enum.take(10)",
          result: "[1, 2, 4, 8, 16, 32, 64, 128, 256, 512]",
          trace: ["1", "1*2=2", "2*2=4", "4*2=8", "8*2=16", "..."]
        },
        %{
          label: "Counting by 3",
          code: "Stream.iterate(0, &(&1 + 3)) |> Enum.take(8)",
          result: "[0, 3, 6, 9, 12, 15, 18, 21]",
          trace: ["0", "0+3=3", "3+3=6", "6+3=9", "9+3=12", "..."]
        },
        %{
          label: "Collatz sequence",
          code: "Stream.iterate(27, fn\n  n when rem(n, 2) == 0 -> div(n, 2)\n  n -> 3 * n + 1\nend) |> Enum.take_while(&(&1 != 1)) |> then(&(&1 ++ [1]))",
          result: "[27, 82, 41, 124, 62, 31, 94, 47, ...]",
          trace: ["27", "27*3+1=82", "82/2=41", "41*3+1=124", "..."]
        }
      ]
    },
    %{
      id: "unfold",
      title: "Stream.unfold/2",
      description: "The most flexible generator. Takes an initial accumulator and a function that returns either {emit_value, next_acc} to continue or nil to halt.",
      syntax: "Stream.unfold(initial_acc, fn acc -> {emit, next_acc} | nil end)",
      examples: [
        %{
          label: "Fibonacci",
          code: "Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)\n|> Enum.take(10)",
          result: "[0, 1, 1, 2, 3, 5, 8, 13, 21, 34]",
          trace: [
            "acc={0,1} emit=0",
            "acc={1,1} emit=1",
            "acc={1,2} emit=1",
            "acc={2,3} emit=2",
            "acc={3,5} emit=3",
            "..."
          ]
        },
        %{
          label: "Countdown",
          code: "Stream.unfold(5, fn\n  0 -> nil\n  n -> {n, n - 1}\nend) |> Enum.to_list()",
          result: "[5, 4, 3, 2, 1]",
          trace: ["acc=5 emit=5", "acc=4 emit=4", "acc=3 emit=3", "acc=2 emit=2", "acc=1 emit=1", "acc=0 -> nil (halt)"]
        },
        %{
          label: "Paginated API",
          code: ~s[Stream.unfold(1, fn\n  page when page > 5 -> nil\n  page ->\n    items = Enum.map(1..3, &(&1 + (page-1) * 3))\n    {items, page + 1}\nend) |> Enum.to_list()],
          result: "[[1,2,3], [4,5,6], [7,8,9], [10,11,12], [13,14,15]]",
          trace: ["page=1 emit=[1,2,3]", "page=2 emit=[4,5,6]", "page=3 emit=[7,8,9]", "page=4 emit=[10,11,12]", "page=5 emit=[13,14,15]", "page=6 -> nil (halt)"]
        }
      ]
    },
    %{
      id: "cycle",
      title: "Stream.cycle/1",
      description: "Creates an infinite stream that repeats the given enumerable forever.",
      syntax: "Stream.cycle(enumerable)",
      examples: [
        %{
          label: "Repeat pattern",
          code: "Stream.cycle([\"red\", \"green\", \"blue\"]) |> Enum.take(7)",
          result: ~s|["red", "green", "blue", "red", "green", "blue", "red"]|,
          trace: ["red", "green", "blue", "red", "green", "blue", "red"]
        },
        %{
          label: "Alternating signs",
          code: "Stream.cycle([1, -1])\n|> Stream.zip(1..6)\n|> Enum.map(fn {sign, n} -> sign * n end)",
          result: "[1, -2, 3, -4, 5, -6]",
          trace: ["1*1=1", "-1*2=-2", "1*3=3", "-1*4=-4", "1*5=5", "-1*6=-6"]
        },
        %{
          label: "Round-robin assignment",
          code: "teams = [\"Alpha\", \"Beta\", \"Gamma\"]\ntasks = [\"T1\", \"T2\", \"T3\", \"T4\", \"T5\", \"T6\"]\n\nStream.cycle(teams)\n|> Stream.zip(tasks)\n|> Enum.to_list()",
          result: ~s|[{"Alpha","T1"}, {"Beta","T2"}, {"Gamma","T3"}, {"Alpha","T4"}, {"Beta","T5"}, {"Gamma","T6"}]|,
          trace: ["Alpha+T1", "Beta+T2", "Gamma+T3", "Alpha+T4", "Beta+T5", "Gamma+T6"]
        }
      ]
    },
    %{
      id: "resource",
      title: "Stream.resource/3",
      description: "Creates a stream from an external resource (file, DB cursor, API). Handles setup, emission, and cleanup.",
      syntax: "Stream.resource(start_fn, next_fn, close_fn)",
      examples: [
        %{
          label: "File lines",
          code: "Stream.resource(\n  fn -> File.open!(\"data.txt\") end,\n  fn file ->\n    case IO.read(file, :line) do\n      :eof -> {:halt, file}\n      line -> {[String.trim(line)], file}\n    end\n  end,\n  fn file -> File.close(file) end\n)",
          result: "# Stream of lines from file (lazy)",
          trace: ["open file", "read line 1", "read line 2", "... on demand ...", "close file on halt"]
        },
        %{
          label: "Timer ticks",
          code: "Stream.resource(\n  fn -> 0 end,\n  fn count ->\n    Process.sleep(1000)\n    {[count], count + 1}\n  end,\n  fn _count -> :ok end\n) |> Enum.take(3)",
          result: "[0, 1, 2]  # with 1s delay between",
          trace: ["emit 0 (wait 1s)", "emit 1 (wait 1s)", "emit 2 (take 3 halts)"]
        }
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_generator, fn -> hd(@generators) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:fib_count, fn -> 10 end)
     |> assign_new(:fib_result, fn -> compute_fibonacci(10) end)
     |> assign_new(:iterate_start, fn -> "1" end)
     |> assign_new(:iterate_op, fn -> "double" end)
     |> assign_new(:iterate_count, fn -> 8 end)
     |> assign_new(:iterate_result, fn -> compute_iterate(1, "double", 8) end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)
     |> assign_new(:show_paginated, fn -> false end)
     |> assign_new(:pages_loaded, fn -> 0 end)
     |> assign_new(:paginated_data, fn -> [] end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Stream Generators</h2>
      <p class="text-sm opacity-70 mb-6">
        Stream generators create sequences on-the-fly, including <strong>infinite sequences</strong>.
        They produce values one at a time, only when requested, making them memory-efficient
        for generating large or unbounded data.
      </p>

      <!-- Generator Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for gen <- generators() do %>
          <button
            phx-click="select_generator"
            phx-target={@myself}
            phx-value-id={gen.id}
            class={"btn btn-sm " <> if(@active_generator.id == gen.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= gen.title %>
          </button>
        <% end %>
      </div>

      <!-- Generator Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-1"><%= @active_generator.title %></h3>
          <p class="text-xs opacity-60 mb-2"><%= @active_generator.description %></p>
          <div class="bg-base-300 rounded-lg p-2 font-mono text-xs mb-4">
            <span class="opacity-50">Syntax: </span><%= @active_generator.syntax %>
          </div>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(@active_generator.examples) do %>
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

          <% example = Enum.at(@active_generator.examples, @active_example_idx) %>
          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= example.code %></div>

            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold"><%= example.result %></div>
            </div>

            <!-- Trace visualization -->
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-2">Generation trace</div>
              <div class="flex flex-wrap gap-1">
                <%= for {step, idx} <- Enum.with_index(example.trace) do %>
                  <div class="flex items-center gap-1">
                    <span class="badge badge-sm badge-info badge-outline font-mono"><%= step %></span>
                    <%= if idx < length(example.trace) - 1 do %>
                      <span class="opacity-30">&rarr;</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Interactive Fibonacci Generator -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive: Fibonacci with Stream.unfold</h3>
          <p class="text-xs opacity-60 mb-4">
            The Fibonacci sequence is a classic example of Stream.unfold. The accumulator holds
            the current pair <code class="font-mono bg-base-300 px-1 rounded">&lbrace;a, b&rbrace;</code>, and each
            step emits <code class="font-mono bg-base-300 px-1 rounded">a</code> while advancing to
            <code class="font-mono bg-base-300 px-1 rounded">&lbrace;b, a+b&rbrace;</code>.
          </p>

          <div class="flex gap-4 items-end mb-4">
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Take first N</span></label>
              <input
                type="range"
                min="1"
                max="20"
                value={@fib_count}
                phx-change="update_fib"
                phx-target={@myself}
                name="count"
                class="range range-primary range-sm w-40"
              />
              <div class="text-xs text-center opacity-60"><%= @fib_count %> terms</div>
            </div>
          </div>

          <!-- Fibonacci result -->
          <div class="bg-base-300 rounded-lg p-3 mb-3 font-mono text-xs">
            <span class="opacity-50">Stream.unfold(&lbrace;0, 1&rbrace;, fn &lbrace;a, b&rbrace; -&gt; &lbrace;a, &lbrace;b, a+b&rbrace;&rbrace; end) |&gt; Enum.take(<%= @fib_count %>)</span>
          </div>

          <div class="flex flex-wrap gap-2">
            <%= for {val, idx} <- Enum.with_index(@fib_result) do %>
              <div class="flex flex-col items-center">
                <span class="text-xs opacity-40">F<sub><%= idx %></sub></span>
                <span class={"badge badge-lg font-mono " <> if(idx < 2, do: "badge-info", else: "badge-primary")}><%= val %></span>
              </div>
            <% end %>
          </div>

          <div class="mt-3 bg-info/10 border border-info/30 rounded-lg p-3 text-xs">
            <strong>Pattern:</strong> Each number is the sum of the two before it.
            F(<%= @fib_count - 1 %>) = <%= List.last(@fib_result) %>
          </div>
        </div>
      </div>

      <!-- Interactive Stream.iterate -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive: Stream.iterate</h3>
          <p class="text-xs opacity-60 mb-4">
            Choose a starting value and operation to generate a sequence.
          </p>

          <div class="flex flex-wrap gap-4 items-end mb-4">
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Start value</span></label>
              <input
                type="number"
                name="start"
                value={@iterate_start}
                phx-change="update_iterate"
                phx-target={@myself}
                class="input input-bordered input-sm w-24 font-mono"
              />
            </div>
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Operation</span></label>
              <div class="flex gap-1">
                <%= for {label, op} <- iterate_operations() do %>
                  <button
                    phx-click="set_iterate_op"
                    phx-target={@myself}
                    phx-value-op={op}
                    class={"btn btn-xs " <> if(@iterate_op == op, do: "btn-primary", else: "btn-outline")}
                  >
                    <%= label %>
                  </button>
                <% end %>
              </div>
            </div>
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Take</span></label>
              <input
                type="range"
                min="1"
                max="15"
                value={@iterate_count}
                phx-change="update_iterate_count"
                phx-target={@myself}
                name="count"
                class="range range-sm range-primary w-28"
              />
              <div class="text-xs text-center opacity-60"><%= @iterate_count %></div>
            </div>
          </div>

          <div class="bg-base-300 rounded-lg p-3 font-mono text-xs mb-3">
            <span class="opacity-50">Stream.iterate(<%= @iterate_start %>, <%= iterate_op_code(@iterate_op) %>) |&gt; Enum.take(<%= @iterate_count %>)</span>
          </div>

          <div class="flex flex-wrap gap-2">
            <%= for {val, idx} <- Enum.with_index(@iterate_result) do %>
              <div class="flex items-center gap-1">
                <span class="badge badge-lg badge-primary font-mono"><%= val %></span>
                <%= if idx < length(@iterate_result) - 1 do %>
                  <span class="opacity-30">&rarr;</span>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Paginated API Simulation -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Practical: Paginated API Simulation</h3>
            <button
              phx-click="toggle_paginated"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_paginated, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_paginated do %>
            <p class="text-xs opacity-60 mb-4">
              Stream.unfold is perfect for paginated APIs. Each call to the function fetches the next page,
              and the stream halts when there are no more pages.
            </p>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-4">{paginated_api_code()}</div>

            <div class="flex gap-2 mb-4">
              <button
                phx-click="load_next_page"
                phx-target={@myself}
                disabled={@pages_loaded >= 5}
                class="btn btn-primary btn-sm"
              >
                Load Next Page
              </button>
              <button
                phx-click="load_all_pages"
                phx-target={@myself}
                class="btn btn-accent btn-sm"
              >
                Load All
              </button>
              <button
                phx-click="reset_pages"
                phx-target={@myself}
                class="btn btn-ghost btn-sm"
              >
                Reset
              </button>
              <span class="text-xs opacity-50 self-center">
                Page <%= @pages_loaded %> / 5
              </span>
            </div>

            <!-- Pages display -->
            <div class="space-y-2">
              <%= for {page_data, idx} <- Enum.with_index(@paginated_data) do %>
                <div class="flex items-center gap-2">
                  <span class="badge badge-sm badge-info">Page <%= idx + 1 %></span>
                  <div class="flex gap-1">
                    <%= for item <- page_data do %>
                      <span class="badge badge-outline font-mono"><%= item %></span>
                    <% end %>
                  </div>
                </div>
              <% end %>
              <%= if @pages_loaded >= 5 do %>
                <div class="text-xs text-success font-bold">All pages loaded! Stream halted.</div>
              <% end %>
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
              placeholder="Stream.iterate(1, &(&1 * 2)) |> Enum.take(10)"
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
              <span><strong>Stream.iterate/2</strong> &mdash; simple: one value in, one value out. Good for arithmetic sequences and repeated application.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Stream.unfold/2</strong> &mdash; flexible: separate emitted value from accumulator. Can halt by returning nil. Perfect for Fibonacci, pagination, stateful generation.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Stream.cycle/1</strong> &mdash; repeats a pattern infinitely. Great for round-robin, alternating patterns, repeating sequences.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Stream.resource/3</strong> &mdash; for external resources (files, connections). Handles setup, emission, and cleanup.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Always consume with Enum</strong> &mdash; generators produce infinite streams. Use <code class="font-mono bg-base-100 px-1 rounded">Enum.take/2</code> or <code class="font-mono bg-base-100 px-1 rounded">Enum.take_while/2</code> to bound them.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_generator", %{"id" => id}, socket) do
    gen = Enum.find(generators(), &(&1.id == id))
    {:noreply, socket |> assign(active_generator: gen) |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, active_example_idx: String.to_integer(idx_str))}
  end

  def handle_event("update_fib", %{"count" => count_str}, socket) do
    count = String.to_integer(count_str)
    {:noreply, socket |> assign(fib_count: count) |> assign(fib_result: compute_fibonacci(count))}
  end

  def handle_event("update_iterate", %{"start" => start_str}, socket) do
    case Integer.parse(start_str) do
      {start, _} ->
        result = compute_iterate(start, socket.assigns.iterate_op, socket.assigns.iterate_count)
        {:noreply, socket |> assign(iterate_start: start_str) |> assign(iterate_result: result)}

      _ ->
        {:noreply, socket}
    end
  end

  def handle_event("set_iterate_op", %{"op" => op}, socket) do
    case Integer.parse(socket.assigns.iterate_start) do
      {start, _} ->
        result = compute_iterate(start, op, socket.assigns.iterate_count)
        {:noreply, socket |> assign(iterate_op: op) |> assign(iterate_result: result)}

      _ ->
        {:noreply, assign(socket, iterate_op: op)}
    end
  end

  def handle_event("update_iterate_count", %{"count" => count_str}, socket) do
    count = String.to_integer(count_str)

    case Integer.parse(socket.assigns.iterate_start) do
      {start, _} ->
        result = compute_iterate(start, socket.assigns.iterate_op, count)
        {:noreply, socket |> assign(iterate_count: count) |> assign(iterate_result: result)}

      _ ->
        {:noreply, assign(socket, iterate_count: count)}
    end
  end

  def handle_event("toggle_paginated", _params, socket) do
    {:noreply, assign(socket, show_paginated: !socket.assigns.show_paginated)}
  end

  def handle_event("load_next_page", _params, socket) do
    page = socket.assigns.pages_loaded + 1

    if page <= 5 do
      items = Enum.map(1..3, &(&1 + (page - 1) * 3))
      new_data = socket.assigns.paginated_data ++ [items]
      {:noreply, socket |> assign(pages_loaded: page) |> assign(paginated_data: new_data)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("load_all_pages", _params, socket) do
    all_pages =
      Enum.map(1..5, fn page ->
        Enum.map(1..3, &(&1 + (page - 1) * 3))
      end)

    {:noreply, socket |> assign(pages_loaded: 5) |> assign(paginated_data: all_pages)}
  end

  def handle_event("reset_pages", _params, socket) do
    {:noreply, socket |> assign(pages_loaded: 0) |> assign(paginated_data: [])}
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

  defp generators, do: @generators

  defp compute_fibonacci(count) do
    Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end)
    |> Enum.take(count)
  end

  defp compute_iterate(start, op, count) do
    fun = iterate_fun(op)

    Stream.iterate(start, fun)
    |> Enum.take(count)
  end

  defp iterate_fun("double"), do: &(&1 * 2)
  defp iterate_fun("add_5"), do: &(&1 + 5)
  defp iterate_fun("square"), do: &(&1 * &1)
  defp iterate_fun("plus_one"), do: &(&1 + 1)
  defp iterate_fun(_), do: &(&1 + 1)

  defp iterate_operations do
    [
      {"x * 2", "double"},
      {"x + 5", "add_5"},
      {"x + 1", "plus_one"},
      {"x * x", "square"}
    ]
  end

  defp iterate_op_code("double"), do: "&(&1 * 2)"
  defp iterate_op_code("add_5"), do: "&(&1 + 5)"
  defp iterate_op_code("plus_one"), do: "&(&1 + 1)"
  defp iterate_op_code("square"), do: "&(&1 * &1)"
  defp iterate_op_code(_), do: "&(&1 + 1)"

  defp quick_examples do
    [
      {"powers of 3", "Stream.iterate(1, &(&1 * 3)) |> Enum.take(8)"},
      {"fibonacci", "Stream.unfold({0, 1}, fn {a, b} -> {a, {b, a + b}} end) |> Enum.take(15)"},
      {"triangular numbers", "Stream.unfold({1, 0}, fn {n, sum} -> {sum + n, {n + 1, sum + n}} end) |> Enum.take(10)"},
      {"cycle zip", "Stream.cycle([:a, :b, :c]) |> Enum.take(7)"}
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

  defp paginated_api_code do
    "fetch_page = fn page ->\n" <>
    "  # Simulate API: 3 items per page, 5 pages total\n" <>
    "  if page > 5 do\n" <>
    "    nil\n" <>
    "  else\n" <>
    "    items = Enum.map(1..3, &(&1 + (page - 1) * 3))\n" <>
    "    {items, page + 1}\n" <>
    "  end\n" <>
    "end\n" <>
    "\n" <>
    "Stream.unfold(1, fetch_page)\n" <>
    "|> Stream.flat_map(&Function.identity/1)\n" <>
    "|> Enum.to_list()"
  end
end
