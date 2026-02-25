defmodule ElixirKatasWeb.ElixirKata29PipeOperatorLive do
  use ElixirKatasWeb, :live_component

  @nested_vs_piped [
    %{
      id: "basic",
      title: "Basic Transformation",
      nested: ~s[String.upcase(String.trim("  hello  "))],
      piped: "\"  hello  \"\n|> String.trim()\n|> String.upcase()",
      result: ~s["HELLO"],
      explanation: "The pipe passes the result of each step as the first argument to the next function."
    },
    %{
      id: "enum_chain",
      title: "Enum Chain",
      nested: "Enum.sum(Enum.map(Enum.filter(1..10, &(rem(&1, 2) == 0)), &(&1 * &1)))",
      piped: "1..10\n|> Enum.filter(&(rem(&1, 2) == 0))\n|> Enum.map(&(&1 * &1))\n|> Enum.sum()",
      result: "220",
      explanation: "Nested calls read inside-out. Pipes read top-to-bottom, matching the data flow."
    },
    %{
      id: "string_processing",
      title: "String Processing",
      nested: ~s[Enum.join(Enum.map(String.split("hello world elixir"), &String.capitalize/1), " ")],
      piped: "\"hello world elixir\"\n|> String.split()\n|> Enum.map(&String.capitalize/1)\n|> Enum.join(\" \")",
      result: ~s["Hello World Elixir"],
      explanation: "String processing pipelines are extremely common in Elixir."
    },
    %{
      id: "data_pipeline",
      title: "Data Pipeline",
      nested: "Enum.take(Enum.sort_by(Enum.filter(users, &(&1.active)), & &1.name), 3)",
      piped: "users\n|> Enum.filter(& &1.active)\n|> Enum.sort_by(& &1.name)\n|> Enum.take(3)",
      result: "[top 3 active users by name]",
      explanation: "Real-world data pipelines become dramatically more readable with pipes."
    }
  ]

  @pipeline_steps_lib [
    %{id: "trim", label: "String.trim", code: "String.trim()", type: :string, description: "Remove leading/trailing whitespace"},
    %{id: "downcase", label: "String.downcase", code: "String.downcase()", type: :string, description: "Convert to lowercase"},
    %{id: "upcase", label: "String.upcase", code: "String.upcase()", type: :string, description: "Convert to uppercase"},
    %{id: "split", label: "String.split", code: "String.split()", type: :string_to_list, description: "Split into list of words"},
    %{id: "capitalize", label: "Enum.map(&String.capitalize/1)", code: "Enum.map(&String.capitalize/1)", type: :list_strings, description: "Capitalize each word"},
    %{id: "sort", label: "Enum.sort", code: "Enum.sort()", type: :list, description: "Sort the list"},
    %{id: "reverse", label: "Enum.reverse", code: "Enum.reverse()", type: :list, description: "Reverse the list"},
    %{id: "join_space", label: ~s|Enum.join(" ")|, code: ~s|Enum.join(" ")|, type: :list_to_string, description: "Join with spaces"},
    %{id: "join_comma", label: ~s|Enum.join(", ")|, code: ~s|Enum.join(", ")|, type: :list_to_string, description: "Join with commas"},
    %{id: "length", label: "length", code: "then(fn list -> length(list) end)", type: :list_to_int, description: "Count elements"},
    %{id: "uniq", label: "Enum.uniq", code: "Enum.uniq()", type: :list, description: "Remove duplicates"},
    %{id: "filter_long", label: ~s|Enum.filter (len > 3)|, code: ~s|Enum.filter(&(String.length(&1) > 3))|, type: :list_strings, description: "Keep words longer than 3 chars"}
  ]

  @common_patterns [
    %{
      id: "enum_pipeline",
      title: "Enum Pipeline",
      code: "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]\n|> Enum.filter(&(rem(&1, 2) == 0))\n|> Enum.map(&(&1 * &1))\n|> Enum.sum()",
      description: "Filter, transform, and aggregate - the most common pattern."
    },
    %{
      id: "string_pipeline",
      title: "String Pipeline",
      code: "\"  Hello, World!  \"\n|> String.trim()\n|> String.downcase()\n|> String.replace(~r/[^a-z0-9\\s]/, \"\")\n|> String.split()\n|> Enum.join(\"-\")",
      description: "Cleaning and transforming strings step by step."
    },
    %{
      id: "map_pipeline",
      title: "Map Pipeline",
      code: "%{name: \"Alice\", age: 30, role: :admin}\n|> Map.put(:last_login, ~U[2024-01-15 10:30:00Z])\n|> Map.update!(:age, &(&1 + 1))\n|> Map.delete(:role)",
      description: "Building and transforming maps step by step."
    },
    %{
      id: "then_pattern",
      title: "Using then/1",
      code: "\"42\"\n|> String.trim()\n|> String.to_integer()\n|> then(fn n -> n * n end)\n|> then(fn n -> \"Result: \#{n}\" end)",
      description: "then/1 lets you pipe into any position, not just the first argument."
    },
    %{
      id: "tap_pattern",
      title: "Using tap/1 for Debugging",
      code: "[3, 1, 4, 1, 5, 9]\n|> tap(fn data -> IO.inspect(data, label: \"input\") end)\n|> Enum.sort()\n|> tap(fn data -> IO.inspect(data, label: \"sorted\") end)\n|> Enum.take(3)",
      description: "tap/1 executes a side effect and returns the value unchanged - perfect for debugging."
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_comparison, fn -> hd(@nested_vs_piped) end)
     |> assign_new(:builder_input, fn -> "  hello world elixir is great  " end)
     |> assign_new(:builder_steps, fn -> [] end)
     |> assign_new(:builder_results, fn -> [] end)
     |> assign_new(:active_pattern, fn -> nil end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:show_animation, fn -> false end)
     |> assign_new(:animation_step, fn -> 0 end)
     |> assign_new(:show_rules, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Pipe Operator</h2>
      <p class="text-sm opacity-70 mb-6">
        The <code class="font-mono bg-base-300 px-1 rounded">|&gt;</code> operator takes the result
        of the expression on its left and passes it as the <strong>first argument</strong> to
        the function on its right. It turns deeply nested calls into readable, top-to-bottom pipelines.
      </p>

      <!-- Nested vs Piped Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Nested vs Piped</h3>
          <p class="text-xs opacity-60 mb-4">
            Compare the nested (inside-out) style with the piped (top-to-bottom) style.
          </p>

          <!-- Comparison Selector -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for item <- nested_vs_piped() do %>
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

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <!-- Nested -->
            <div class="bg-error/10 border border-error/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-error badge-sm">Nested</span>
                <span class="text-xs opacity-60">Read inside-out</span>
              </div>
              <div class="bg-base-100 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap"><%= @active_comparison.nested %></div>
            </div>

            <!-- Piped -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-success badge-sm">Piped</span>
                <span class="text-xs opacity-60">Read top-to-bottom</span>
              </div>
              <div class="bg-base-100 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap"><%= @active_comparison.piped %></div>
            </div>
          </div>

          <!-- Result and explanation -->
          <div class="bg-info/10 border border-info/30 rounded-lg p-3 mb-3">
            <div class="text-xs font-bold opacity-60 mb-1">Result</div>
            <div class="font-mono text-sm text-success font-bold"><%= @active_comparison.result %></div>
          </div>
          <div class="text-sm opacity-70"><%= @active_comparison.explanation %></div>

          <!-- Animation Toggle -->
          <div class="mt-4">
            <button
              phx-click="toggle_animation"
              phx-target={@myself}
              class="btn btn-sm btn-accent"
            >
              <%= if @show_animation, do: "Hide Animation", else: "Show Data Flow Animation" %>
            </button>
          </div>

          <%= if @show_animation do %>
            <div class="mt-4 bg-base-300 rounded-lg p-4">
              <h4 class="text-xs font-bold opacity-60 mb-3">Data flowing through the pipe:</h4>
              <% pipe_steps = parse_pipe_animation(@active_comparison.piped) %>
              <div class="space-y-2">
                <%= for {step, idx} <- Enum.with_index(pipe_steps) do %>
                  <div class={"flex items-center gap-3 transition-all duration-300 " <> if(idx <= @animation_step, do: "opacity-100", else: "opacity-20")}>
                    <div class={"w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold " <> if(idx <= @animation_step, do: "bg-primary text-primary-content", else: "bg-base-100")}>
                      <%= idx + 1 %>
                    </div>
                    <div class={"flex-1 rounded-lg p-2 font-mono text-sm " <> if(idx <= @animation_step, do: "bg-base-100", else: "bg-base-200")}>
                      <%= step %>
                    </div>
                    <%= if idx < length(pipe_steps) - 1 do %>
                      <span class={"text-lg " <> if(idx < @animation_step, do: "text-success", else: "opacity-30")}>|&gt;</span>
                    <% end %>
                  </div>
                <% end %>
              </div>
              <div class="flex gap-2 mt-4">
                <button
                  phx-click="animation_prev"
                  phx-target={@myself}
                  disabled={@animation_step <= 0}
                  class="btn btn-xs btn-outline"
                >
                  &larr; Prev
                </button>
                <button
                  phx-click="animation_next"
                  phx-target={@myself}
                  disabled={@animation_step >= length(pipe_steps) - 1}
                  class="btn btn-xs btn-primary"
                >
                  Next &rarr;
                </button>
                <button
                  phx-click="animation_reset"
                  phx-target={@myself}
                  class="btn btn-xs btn-ghost"
                >
                  Reset
                </button>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Interactive Pipeline Builder -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Pipeline Builder</h3>
          <p class="text-xs opacity-60 mb-4">
            Start with a string and build a pipeline by clicking steps. Watch the data transform at each stage.
          </p>

          <!-- Starting Input -->
          <form phx-submit="set_builder_input" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Starting value (string)</span></label>
              <input
                type="text"
                name="input"
                value={@builder_input}
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Set</button>
          </form>

          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <span class="opacity-50">start = </span>
            <span class="text-info"><%= inspect(@builder_input) %></span>
          </div>

          <!-- Available Steps -->
          <div class="mb-4">
            <div class="text-xs font-bold opacity-60 mb-2">Add a pipe step:</div>
            <div class="flex flex-wrap gap-2">
              <%= for step <- available_builder_steps(@builder_steps, @builder_input) do %>
                <button
                  phx-click="add_builder_step"
                  phx-target={@myself}
                  phx-value-id={step.id}
                  class="btn btn-xs btn-outline btn-info"
                  title={step.description}
                >
                  <%= step.label %>
                </button>
              <% end %>
            </div>
          </div>

          <!-- Pipeline Steps & Results -->
          <%= if length(@builder_steps) > 0 do %>
            <div class="space-y-2 mb-4">
              <%= for {step, idx} <- Enum.with_index(@builder_steps) do %>
                <% result_at = Enum.at(@builder_results, idx) %>
                <div class="flex items-center gap-2">
                  <div class="flex-shrink-0 w-7 h-7 rounded-full bg-primary text-primary-content flex items-center justify-center text-xs font-bold">
                    <%= idx + 1 %>
                  </div>
                  <div class="flex-1 bg-base-100 rounded-lg p-2 border border-base-300">
                    <div class="flex items-center justify-between">
                      <span class="font-mono text-xs text-primary">|&gt; <%= step.code %></span>
                      <button
                        phx-click="remove_builder_step"
                        phx-target={@myself}
                        phx-value-idx={idx}
                        class="btn btn-ghost btn-xs text-error"
                      >
                        x
                      </button>
                    </div>
                    <div class="font-mono text-xs mt-1">
                      <span class="opacity-50">&rArr; </span>
                      <span class="text-success"><%= if result_at, do: inspect_safe(result_at.value), else: "..." %></span>
                      <%= if result_at && result_at.error do %>
                        <span class="text-error ml-2"><%= result_at.error %></span>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>

            <!-- Generated Code -->
            <div class="bg-base-300 rounded-lg p-3 mb-4">
              <div class="text-xs font-bold opacity-60 mb-1">Generated Elixir code:</div>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= builder_as_code(@builder_input, @builder_steps) %></div>
            </div>

            <button
              phx-click="clear_builder"
              phx-target={@myself}
              class="btn btn-ghost btn-sm"
            >
              Clear Pipeline
            </button>
          <% end %>
        </div>
      </div>

      <!-- Common Pipe Patterns -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Common Pipe Patterns</h3>
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for pattern <- common_patterns() do %>
              <button
                phx-click="select_pattern"
                phx-target={@myself}
                phx-value-id={pattern.id}
                class={"btn btn-sm " <> if(@active_pattern && @active_pattern.id == pattern.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= pattern.title %>
              </button>
            <% end %>
          </div>

          <%= if @active_pattern do %>
            <div class="space-y-3">
              <p class="text-sm opacity-70"><%= @active_pattern.description %></p>
              <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_pattern.code %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own Pipeline</h3>
          <p class="text-xs opacity-60 mb-4">
            Write an Elixir pipeline expression using <code class="font-mono bg-base-300 px-1 rounded">|&gt;</code>.
          </p>

          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="code"
                value={@sandbox_code}
                placeholder={"\"hello world\" |> String.split() |> Enum.map(&String.upcase/1) |> Enum.join(\"-\")"}
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
              <span class="text-xs opacity-50 self-center">Try piping String, Enum, and Map functions together</span>
            </div>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
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

      <!-- Pipe Rules -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Pipe Operator Rules &amp; Gotchas</h3>
            <button
              phx-click="toggle_rules"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_rules, do: "Hide", else: "Show Rules" %>
            </button>
          </div>

          <%= if @show_rules do %>
            <div class="space-y-4">
              <div class="bg-success/10 border border-success/30 rounded-lg p-3">
                <div class="font-bold text-sm text-success mb-2">How it works</div>
                <div class="font-mono text-xs bg-base-100 rounded p-3 whitespace-pre-wrap">{pipe_rewrite_code()}</div>
              </div>

              <div class="bg-warning/10 border border-warning/30 rounded-lg p-3">
                <div class="font-bold text-sm text-warning mb-2">Gotcha: Always pipes into first argument</div>
                <div class="font-mono text-xs bg-base-100 rounded p-3 whitespace-pre-wrap">{pipe_gotcha_code()}</div>
              </div>

              <div class="bg-info/10 border border-info/30 rounded-lg p-3">
                <div class="font-bold text-sm text-info mb-2">Best practices</div>
                <ul class="list-disc list-inside text-sm space-y-1 opacity-80">
                  <li>Start the pipeline with a <strong>raw value</strong>, not a function call</li>
                  <li>Each step should take the piped value as the <strong>first argument</strong></li>
                  <li>Use <code class="font-mono bg-base-100 px-1 rounded">then/1</code> when you need the value in a non-first position</li>
                  <li>Use <code class="font-mono bg-base-100 px-1 rounded">tap/1</code> for side effects (logging, debugging) without changing the value</li>
                  <li>Keep pipelines focused - one concern per pipeline</li>
                  <li>Don't pipe into single functions - <code class="font-mono bg-base-100 px-1 rounded">a |&gt; f()</code> is worse than <code class="font-mono bg-base-100 px-1 rounded">f(a)</code></li>
                </ul>
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
              <span><code class="font-mono bg-base-100 px-1 rounded">|&gt;</code> passes the left-hand result as the <strong>first argument</strong> to the right-hand function.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>Pipes transform nested calls <code class="font-mono bg-base-100 px-1 rounded">f(g(h(x)))</code> into readable <code class="font-mono bg-base-100 px-1 rounded">x |&gt; h() |&gt; g() |&gt; f()</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Use <code class="font-mono bg-base-100 px-1 rounded">then/1</code> when you need to pipe into a non-first argument position.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>Use <code class="font-mono bg-base-100 px-1 rounded">tap/1</code> for side effects like <code class="font-mono bg-base-100 px-1 rounded">IO.inspect</code> without changing the piped value.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Elixir's standard library is designed for pipes: most functions take the "subject" as the first argument.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_comparison", %{"id" => id}, socket) do
    item = Enum.find(nested_vs_piped(), &(&1.id == id))
    {:noreply, assign(socket, active_comparison: item, show_animation: false, animation_step: 0)}
  end

  def handle_event("toggle_animation", _params, socket) do
    {:noreply, assign(socket, show_animation: !socket.assigns.show_animation, animation_step: 0)}
  end

  def handle_event("animation_next", _params, socket) do
    steps = parse_pipe_animation(socket.assigns.active_comparison.piped)
    max_step = length(steps) - 1
    new_step = min(socket.assigns.animation_step + 1, max_step)
    {:noreply, assign(socket, animation_step: new_step)}
  end

  def handle_event("animation_prev", _params, socket) do
    new_step = max(socket.assigns.animation_step - 1, 0)
    {:noreply, assign(socket, animation_step: new_step)}
  end

  def handle_event("animation_reset", _params, socket) do
    {:noreply, assign(socket, animation_step: 0)}
  end

  def handle_event("set_builder_input", %{"input" => input}, socket) do
    {:noreply,
     socket
     |> assign(builder_input: input)
     |> assign(builder_steps: [])
     |> assign(builder_results: [])}
  end

  def handle_event("add_builder_step", %{"id" => id}, socket) do
    step = Enum.find(pipeline_steps_lib(), &(&1.id == id))
    new_steps = socket.assigns.builder_steps ++ [step]
    results = recompute_builder(socket.assigns.builder_input, new_steps)

    {:noreply,
     socket
     |> assign(builder_steps: new_steps)
     |> assign(builder_results: results)}
  end

  def handle_event("remove_builder_step", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    new_steps = List.delete_at(socket.assigns.builder_steps, idx)
    results = recompute_builder(socket.assigns.builder_input, new_steps)

    {:noreply,
     socket
     |> assign(builder_steps: new_steps)
     |> assign(builder_results: results)}
  end

  def handle_event("clear_builder", _params, socket) do
    {:noreply,
     socket
     |> assign(builder_steps: [])
     |> assign(builder_results: [])}
  end

  def handle_event("select_pattern", %{"id" => id}, socket) do
    pattern = Enum.find(common_patterns(), &(&1.id == id))
    {:noreply, assign(socket, active_pattern: pattern)}
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

  def handle_event("toggle_rules", _params, socket) do
    {:noreply, assign(socket, show_rules: !socket.assigns.show_rules)}
  end

  # Helpers

  defp nested_vs_piped, do: @nested_vs_piped
  defp pipeline_steps_lib, do: @pipeline_steps_lib
  defp common_patterns, do: @common_patterns

  defp parse_pipe_animation(piped_code) do
    piped_code
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(fn line ->
      line
      |> String.replace(~r/^\|>\s*/, "")
    end)
  end

  defp available_builder_steps(current_steps, _input) do
    current_type = infer_current_type(current_steps)

    Enum.filter(pipeline_steps_lib(), fn step ->
      compatible_step?(step.type, current_type)
    end)
  end

  defp infer_current_type([]), do: :string

  defp infer_current_type(steps) do
    last = List.last(steps)

    case last.type do
      :string_to_list -> :list_strings
      :list_to_string -> :string
      :list_to_int -> :integer
      :list_strings -> :list_strings
      :list -> :list
      :string -> :string
      _ -> :string
    end
  end

  defp compatible_step?(:string, :string), do: true
  defp compatible_step?(:string_to_list, :string), do: true
  defp compatible_step?(:list, :list), do: true
  defp compatible_step?(:list, :list_strings), do: true
  defp compatible_step?(:list_strings, :list_strings), do: true
  defp compatible_step?(:list_to_string, :list), do: true
  defp compatible_step?(:list_to_string, :list_strings), do: true
  defp compatible_step?(:list_to_int, :list), do: true
  defp compatible_step?(:list_to_int, :list_strings), do: true
  defp compatible_step?(_, _), do: false

  defp recompute_builder(input, steps) do
    {results, _} =
      Enum.reduce(steps, {[], input}, fn step, {results, current_value} ->
        code = "#{inspect(current_value)} |> #{step.code}"

        case safe_eval(code) do
          {:ok, new_value} ->
            {results ++ [%{value: new_value, error: nil}], new_value}

          {:error, msg} ->
            {results ++ [%{value: current_value, error: msg}], current_value}
        end
      end)

    results
  end

  defp safe_eval(code) do
    try do
      {result, _} = Code.eval_string(code)
      {:ok, result}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end

  defp builder_as_code(input, steps) do
    lines = Enum.map(steps, fn step -> "|> #{step.code}" end)
    Enum.join([inspect(input) | lines], "\n")
  end

  defp inspect_safe(value) do
    inspect(value, pretty: true, limit: 50)
  end

  defp sandbox_quick_examples do
    [
      {"titlecase", "\"hello world\" |> String.split() |> Enum.map(&String.capitalize/1) |> Enum.join(\" \")"},
      {"sum evens", "1..20 |> Enum.filter(&(rem(&1, 2) == 0)) |> Enum.sum()"},
      {"slug", "\"Hello World!\" |> String.downcase() |> String.replace(~r/[^a-z0-9\\s]/, \"\") |> String.replace(\" \", \"-\")"},
      {"with then", "42 |> then(fn x -> x * x end) |> then(fn x -> \"square: \#{x}\" end)"}
    ]
  end

  defp pipe_rewrite_code do
    """
    value |> function(arg2, arg3)
    # is rewritten by the compiler to:
    function(value, arg2, arg3)\
    """
  end

  defp pipe_gotcha_code do
    String.trim("""
    # This won't work as expected:
    "hello" |> String.replace("world", &String.upcase/1)
    # Because it becomes: String.replace("hello", "world", &String.upcase/1)

    # Use then/1 when you need a different position:
    42 |> then(fn x -> "The answer is: \#{x}" end)
    """)
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
