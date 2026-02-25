defmodule ElixirKatasWeb.ElixirKata24HigherOrderLive do
  use ElixirKatasWeb, :live_component

  @hof_demos [
    %{
      id: "passing",
      title: "Passing Functions as Arguments",
      description: "Functions can be passed to other functions as arguments. This is the foundation of map, filter, and reduce.",
      examples: [
        %{
          id: "map",
          label: "Enum.map",
          code: "Enum.map([1, 2, 3, 4, 5], fn x -> x * 2 end)",
          result: "[2, 4, 6, 8, 10]",
          explanation: "map applies the function to each element and returns a new list"
        },
        %{
          id: "filter",
          label: "Enum.filter",
          code: "Enum.filter([1, 2, 3, 4, 5, 6], fn x -> rem(x, 2) == 0 end)",
          result: "[2, 4, 6]",
          explanation: "filter keeps only elements where the function returns true"
        },
        %{
          id: "reduce",
          label: "Enum.reduce",
          code: "Enum.reduce([1, 2, 3, 4, 5], 0, fn x, acc -> x + acc end)",
          result: "15",
          explanation: "reduce accumulates a single value by applying the function to each element and the accumulator"
        },
        %{
          id: "sort",
          label: "Enum.sort_by",
          code: ~s|Enum.sort_by(["banana", "apple", "cherry"], fn s -> String.length(s) end)|,
          result: ~s|["apple", "banana", "cherry"]|,
          explanation: "sort_by uses the function to extract a comparison key from each element"
        }
      ]
    },
    %{
      id: "returning",
      title: "Returning Functions from Functions",
      description: "Functions can return other functions, creating 'function factories' that generate specialized behavior.",
      examples: [
        %{
          id: "multiplier",
          label: "Multiplier Factory",
          code: "multiplier = fn factor ->\n  fn x -> x * factor end\nend\n\ndouble = multiplier.(2)\ntriple = multiplier.(3)\n{double.(5), triple.(5)}",
          result: "{10, 15}",
          explanation: "multiplier returns a new function that remembers the factor via closure"
        },
        %{
          id: "greeter",
          label: "Greeter Factory",
          code: ~s|make_greeter = fn greeting ->\n  fn name -> "\#{greeting}, \#{name}!" end\nend\n\nhello = make_greeter.("Hello")\nhola = make_greeter.("Hola")\n{hello.("Alice"), hola.("Bob")}|,
          result: ~s|{"Hello, Alice!", "Hola, Bob!"}|,
          explanation: "The inner function closes over the greeting variable from the outer function"
        },
        %{
          id: "validator",
          label: "Validator Factory",
          code: "min_length = fn min ->\n  fn str -> String.length(str) >= min end\nend\n\nat_least_3 = min_length.(3)\n{at_least_3.(\"ab\"), at_least_3.(\"abc\"), at_least_3.(\"abcd\")}",
          result: "{false, true, true}",
          explanation: "Creates reusable validation functions with different thresholds"
        }
      ]
    }
  ]

  @pipeline_transforms [
    %{id: "double", label: "Double", code: "&(&1 * 2)", description: "Multiply each element by 2"},
    %{id: "add_10", label: "Add 10", code: "&(&1 + 10)", description: "Add 10 to each element"},
    %{id: "square", label: "Square", code: "&(&1 * &1)", description: "Square each element"},
    %{id: "negate", label: "Negate", code: "&(-&1)", description: "Negate each element"},
    %{id: "filter_even", label: "Keep Even", code: "&(rem(&1, 2) == 0)", description: "Keep only even numbers", type: :filter},
    %{id: "filter_pos", label: "Keep Positive", code: "&(&1 > 0)", description: "Keep only positive numbers", type: :filter},
    %{id: "filter_gt5", label: "Keep > 5", code: "&(&1 > 5)", description: "Keep numbers greater than 5", type: :filter},
    %{id: "to_string", label: "To String", code: "&Integer.to_string/1", description: "Convert to string", type: :map_final}
  ]

  @patterns [
    %{
      id: "middleware",
      title: "Middleware / Plug Pattern",
      description: "Chain functions that wrap each other, like Plug in Phoenix. Each middleware can modify the input, call the next, and modify the output.",
      code: "# A simplified middleware chain\nlogger = fn next ->\n  fn conn ->\n    IO.puts(\"Request: \#{conn.path}\")\n    result = next.(conn)\n    IO.puts(\"Response: \#{result.status}\")\n    result\n  end\nend\n\nauth = fn next ->\n  fn conn ->\n    if conn.token do\n      next.(conn)\n    else\n      %{status: 401}\n    end\n  end\nend\n\n# Build pipeline: auth -> logger -> handler\nhandler = fn conn -> %{status: 200, body: \"Hello!\"} end\npipeline = auth.(logger.(handler))",
      visual_steps: [
        "Request comes in",
        "auth middleware checks token",
        "logger middleware logs request",
        "handler processes request",
        "logger middleware logs response",
        "Response goes out"
      ]
    },
    %{
      id: "strategy",
      title: "Strategy Pattern",
      description: "Pass different functions to change behavior without changing the algorithm structure.",
      code: "defmodule Sorter do\n  def sort(list, strategy) do\n    Enum.sort(list, strategy)\n  end\nend\n\n# Different strategies:\nasc  = &(&1 <= &2)\ndesc = &(&1 >= &2)\nby_abs = &(abs(&1) <= abs(&2))\n\ndata = [3, -1, 4, -1, 5, -9]\nSorter.sort(data, asc)    # [-9, -1, -1, 3, 4, 5]\nSorter.sort(data, desc)   # [5, 4, 3, -1, -1, -9]\nSorter.sort(data, by_abs)  # [-1, -1, 3, 4, 5, -9]",
      visual_steps: [
        "Same data, same algorithm",
        "Different function = different behavior",
        "No if/else or case needed",
        "Easy to add new strategies"
      ]
    },
    %{
      id: "composition",
      title: "Function Composition",
      description: "Combine simple functions into complex ones. Each function's output becomes the next function's input.",
      code: "# Manual composition\ncompose = fn f, g ->\n  fn x -> f.(g.(x)) end\nend\n\nadd_one = &(&1 + 1)\ndouble = &(&1 * 2)\n\nadd_then_double = compose.(double, add_one)\ndouble_then_add = compose.(add_one, double)\n\nadd_then_double.(5)  # double(add_one(5)) = double(6) = 12\ndouble_then_add.(5)  # add_one(double(5)) = add_one(10) = 11",
      visual_steps: [
        "Define small, focused functions",
        "Compose them into pipelines",
        "Order matters: f(g(x)) != g(f(x))",
        "Elixir's |> operator does this naturally"
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_demo, fn -> hd(@hof_demos) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:pipeline_data, fn -> [1, 2, 3, 4, 5] end)
     |> assign_new(:pipeline_steps, fn -> [] end)
     |> assign_new(:pipeline_results, fn -> [[1, 2, 3, 4, 5]] end)
     |> assign_new(:active_pattern, fn -> hd(@patterns) end)
     |> assign_new(:show_patterns, fn -> false end)
     |> assign_new(:custom_pipeline_input, fn -> "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]" end)
     |> assign_new(:custom_pipeline_code, fn -> "" end)
     |> assign_new(:custom_pipeline_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Higher-Order Functions</h2>
      <p class="text-sm opacity-70 mb-6">
        A <strong>higher-order function</strong> is one that takes functions as arguments, returns functions,
        or both. This is one of the most powerful concepts in functional programming, enabling
        composable, reusable code.
      </p>

      <!-- Demo Selector: Passing vs Returning -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for demo <- hof_demos() do %>
          <button
            phx-click="select_demo"
            phx-target={@myself}
            phx-value-id={demo.id}
            class={"btn btn-sm " <> if(@active_demo.id == demo.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= demo.title %>
          </button>
        <% end %>
      </div>

      <!-- Functions as Arguments / Returning Functions -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_demo.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @active_demo.description %></p>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(@active_demo.examples) do %>
              <button
                phx-click="select_hof_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"btn btn-xs " <> if(idx == @active_example_idx, do: "btn-accent", else: "btn-ghost")}
              >
                <%= example.label %>
              </button>
            <% end %>
          </div>

          <!-- Selected Example -->
          <% example = Enum.at(@active_demo.examples, @active_example_idx) %>
          <div class="space-y-3">
            <!-- Code -->
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= example.code %></div>

            <!-- Result -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold"><%= example.result %></div>
            </div>

            <!-- Explanation -->
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">How it works</div>
              <div class="text-sm"><%= example.explanation %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Interactive Pipeline Builder -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Pipeline Builder</h3>
          <p class="text-xs opacity-60 mb-4">
            Build a data transformation pipeline by adding steps. Each step applies a higher-order
            function to the data. Watch the data transform at each stage.
          </p>

          <!-- Starting Data -->
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <span class="opacity-50">data = </span>
            <span class="text-info"><%= inspect(@pipeline_data) %></span>
          </div>

          <!-- Available Transforms -->
          <div class="mb-4">
            <div class="text-xs font-bold opacity-60 mb-2">Add a transformation step:</div>
            <div class="flex flex-wrap gap-2">
              <%= for transform <- pipeline_transforms() do %>
                <button
                  phx-click="add_pipeline_step"
                  phx-target={@myself}
                  phx-value-id={transform.id}
                  class={"btn btn-xs " <> transform_btn_class(transform)}
                  title={transform.description}
                >
                  <%= transform.label %>
                  <span class="opacity-50 text-xs ml-1">
                    <%= if Map.get(transform, :type) == :filter, do: "(filter)", else: if(Map.get(transform, :type) == :map_final, do: "(map)", else: "(map)") %>
                  </span>
                </button>
              <% end %>
            </div>
          </div>

          <!-- Pipeline Steps & Results -->
          <%= if length(@pipeline_steps) > 0 do %>
            <div class="space-y-2 mb-4">
              <%= for {step, idx} <- Enum.with_index(@pipeline_steps) do %>
                <% result_at = Enum.at(@pipeline_results, idx + 1, []) %>
                <div class="flex items-center gap-2">
                  <!-- Step Number -->
                  <div class="flex-shrink-0 w-7 h-7 rounded-full bg-primary text-primary-content flex items-center justify-center text-xs font-bold">
                    <%= idx + 1 %>
                  </div>

                  <!-- Step Info -->
                  <div class="flex-1 bg-base-100 rounded-lg p-2 border border-base-300">
                    <div class="flex items-center justify-between">
                      <div>
                        <span class={"badge badge-xs mr-2 " <> if(Map.get(step, :type) == :filter, do: "badge-warning", else: "badge-info")}>
                          <%= if Map.get(step, :type) == :filter, do: "filter", else: "map" %>
                        </span>
                        <span class="font-mono text-xs"><%= step.label %>: </span>
                        <span class="font-mono text-xs text-primary"><%= step.code %></span>
                      </div>
                      <button
                        phx-click="remove_pipeline_step"
                        phx-target={@myself}
                        phx-value-idx={idx}
                        class="btn btn-ghost btn-xs text-error"
                      >
                        x
                      </button>
                    </div>
                    <div class="font-mono text-xs mt-1">
                      <span class="opacity-50">&rArr; </span>
                      <span class="text-success"><%= inspect(result_at) %></span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Pipeline as Code -->
            <div class="bg-base-300 rounded-lg p-3 mb-4">
              <div class="text-xs font-bold opacity-60 mb-1">Equivalent Elixir code:</div>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= pipeline_as_code(@pipeline_data, @pipeline_steps) %></div>
            </div>

            <!-- Controls -->
            <div class="flex gap-2">
              <button
                phx-click="clear_pipeline"
                phx-target={@myself}
                class="btn btn-ghost btn-sm"
              >
                Clear Pipeline
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Custom Pipeline -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own Pipeline</h3>
          <p class="text-xs opacity-60 mb-4">
            Write an Elixir pipeline expression using <code class="font-mono bg-base-300 px-1 rounded">|&gt;</code> with Enum functions.
          </p>

          <form phx-submit="run_custom_pipeline" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="code"
                value={@custom_pipeline_code}
                placeholder="[1,2,3,4,5] |> Enum.map(&(&1 * 2)) |> Enum.filter(&(&1 > 4))"
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
              <span class="text-xs opacity-50 self-center">Try piping Enum.map, Enum.filter, Enum.reduce together</span>
            </div>
          </form>

          <!-- Quick Pipeline Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, code} <- pipeline_quick_examples() do %>
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

          <%= if @custom_pipeline_result do %>
            <div class={"alert text-sm " <> if(@custom_pipeline_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @custom_pipeline_result.input %></div>
                <div class="font-mono font-bold mt-1"><%= @custom_pipeline_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Real-World Patterns -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Real-World Patterns</h3>
            <button
              phx-click="toggle_patterns"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_patterns, do: "Hide", else: "Show Patterns" %>
            </button>
          </div>

          <%= if @show_patterns do %>
            <!-- Pattern Selector -->
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for pattern <- patterns() do %>
                <button
                  phx-click="select_pattern"
                  phx-target={@myself}
                  phx-value-id={pattern.id}
                  class={"btn btn-sm " <> if(@active_pattern.id == pattern.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= pattern.title %>
                </button>
              <% end %>
            </div>

            <div class="space-y-4">
              <p class="text-sm opacity-70"><%= @active_pattern.description %></p>

              <!-- Code -->
              <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap"><%= @active_pattern.code %></div>

              <!-- Visual Flow -->
              <div class="bg-base-100 rounded-lg p-4">
                <h4 class="text-xs font-bold opacity-60 mb-3">How it works:</h4>
                <div class="flex flex-wrap gap-2">
                  <%= for {step, idx} <- Enum.with_index(@active_pattern.visual_steps) do %>
                    <div class="flex items-center gap-2">
                      <div class="flex items-center gap-1 bg-base-300 rounded-lg px-3 py-1.5">
                        <span class="badge badge-primary badge-xs"><%= idx + 1 %></span>
                        <span class="text-xs"><%= step %></span>
                      </div>
                      <%= if idx < length(@active_pattern.visual_steps) - 1 do %>
                        <span class="opacity-30">&rarr;</span>
                      <% end %>
                    </div>
                  <% end %>
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
              <span><strong>Functions are values</strong> in Elixir - they can be assigned to variables, stored in data structures, and passed around.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Passing functions as arguments</strong> enables generic algorithms like map, filter, reduce that work with any transformation.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Returning functions</strong> creates <em>function factories</em> - functions that generate specialized functions via closures.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Function composition</strong> builds complex behavior from simple, focused functions chained together.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Elixir's <code class="font-mono bg-base-100 px-1 rounded">|&gt;</code> pipe operator is the idiomatic way to compose transformations into readable pipelines.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_demo", %{"id" => id}, socket) do
    demo = Enum.find(hof_demos(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_demo: demo)
     |> assign(active_example_idx: 0)}
  end

  def handle_event("select_hof_example", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, active_example_idx: idx)}
  end

  def handle_event("add_pipeline_step", %{"id" => id}, socket) do
    transform = Enum.find(pipeline_transforms(), &(&1.id == id))
    new_steps = socket.assigns.pipeline_steps ++ [transform]
    new_results = recompute_pipeline(socket.assigns.pipeline_data, new_steps)

    {:noreply,
     socket
     |> assign(pipeline_steps: new_steps)
     |> assign(pipeline_results: new_results)}
  end

  def handle_event("remove_pipeline_step", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    new_steps = List.delete_at(socket.assigns.pipeline_steps, idx)
    new_results = recompute_pipeline(socket.assigns.pipeline_data, new_steps)

    {:noreply,
     socket
     |> assign(pipeline_steps: new_steps)
     |> assign(pipeline_results: new_results)}
  end

  def handle_event("clear_pipeline", _params, socket) do
    {:noreply,
     socket
     |> assign(pipeline_steps: [])
     |> assign(pipeline_results: [socket.assigns.pipeline_data])}
  end

  def handle_event("toggle_patterns", _params, socket) do
    {:noreply, assign(socket, show_patterns: !socket.assigns.show_patterns)}
  end

  def handle_event("select_pattern", %{"id" => id}, socket) do
    pattern = Enum.find(patterns(), &(&1.id == id))
    {:noreply, assign(socket, active_pattern: pattern)}
  end

  def handle_event("run_custom_pipeline", %{"code" => code}, socket) do
    result = evaluate_pipeline(String.trim(code))

    {:noreply,
     socket
     |> assign(custom_pipeline_code: code)
     |> assign(custom_pipeline_result: result)}
  end

  def handle_event("quick_pipeline", %{"code" => code}, socket) do
    result = evaluate_pipeline(code)

    {:noreply,
     socket
     |> assign(custom_pipeline_code: code)
     |> assign(custom_pipeline_result: result)}
  end

  # Helpers

  defp hof_demos, do: @hof_demos
  defp pipeline_transforms, do: @pipeline_transforms
  defp patterns, do: @patterns

  defp recompute_pipeline(data, steps) do
    Enum.reduce(steps, {[data], data}, fn step, {results, current_data} ->
      next_data = apply_transform(current_data, step)
      {results ++ [next_data], next_data}
    end)
    |> elem(0)
  end

  defp apply_transform(data, step) when is_list(data) do
    type = Map.get(step, :type, :map)

    case type do
      :filter ->
        try do
          {fun, _} = Code.eval_string(step.code)
          Enum.filter(data, fun)
        rescue
          _ -> data
        end

      :map_final ->
        try do
          {fun, _} = Code.eval_string(step.code)
          Enum.map(data, fun)
        rescue
          _ -> data
        end

      _ ->
        try do
          {fun, _} = Code.eval_string(step.code)
          Enum.map(data, fn item ->
            if is_number(item), do: fun.(item), else: item
          end)
        rescue
          _ -> data
        end
    end
  end

  defp apply_transform(data, _step), do: data

  defp pipeline_as_code(data, steps) do
    base = inspect(data)

    lines =
      Enum.map(steps, fn step ->
        type = Map.get(step, :type, :map)

        case type do
          :filter -> "|> Enum.filter(#{step.code})"
          _ -> "|> Enum.map(#{step.code})"
        end
      end)

    Enum.join([base | lines], "\n")
  end

  defp transform_btn_class(transform) do
    case Map.get(transform, :type) do
      :filter -> "btn-outline btn-warning"
      :map_final -> "btn-outline btn-accent"
      _ -> "btn-outline btn-info"
    end
  end

  defp pipeline_quick_examples do
    [
      {"double & filter", "[1, 2, 3, 4, 5] |> Enum.map(&(&1 * 2)) |> Enum.filter(&(&1 > 4))"},
      {"sum of squares", "1..10 |> Enum.map(&(&1 * &1)) |> Enum.sum()"},
      {"word lengths", "[\"hello\", \"world\", \"elixir\"] |> Enum.map(&String.length/1)"},
      {"chain ops", "1..10 |> Enum.filter(&(rem(&1, 2) == 0)) |> Enum.map(&(&1 * 3)) |> Enum.sum()"},
      {"sort & take", "1..20 |> Enum.shuffle() |> Enum.sort(:desc) |> Enum.take(5)"}
    ]
  end

  defp evaluate_pipeline(code) do
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
