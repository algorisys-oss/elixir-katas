defmodule ElixirKatasWeb.ElixirKata26CondExpressionsLive do
  use ElixirKatasWeb, :live_component

  @cond_examples [
    %{
      id: "temperature",
      title: "Temperature Advisor",
      description: "Cond evaluates boolean conditions top-to-bottom. The first true condition wins.",
      conditions: [
        %{id: 0, condition: "temp >= 40", body: ~s|"Stay inside! Extreme heat."|, display: "temp >= 40"},
        %{id: 1, condition: "temp >= 30", body: ~s|"Hot day, stay hydrated."|, display: "temp >= 30"},
        %{id: 2, condition: "temp >= 20", body: ~s|"Nice weather!"|, display: "temp >= 20"},
        %{id: 3, condition: "temp >= 10", body: ~s|"Bring a jacket."|, display: "temp >= 10"},
        %{id: 4, condition: "true", body: ~s|"Bundle up, it is cold!"|, display: "true (catch-all)"}
      ],
      variable: "temp",
      test_values: [
        %{display: "45", code: "45"},
        %{display: "35", code: "35"},
        %{display: "22", code: "22"},
        %{display: "12", code: "12"},
        %{display: "5", code: "5"},
        %{display: "-10", code: "-10"}
      ]
    },
    %{
      id: "grade",
      title: "Letter Grade",
      description: "Classic grade classification using chained conditions.",
      conditions: [
        %{id: 0, condition: "score >= 90", body: ~s|"A"|, display: "score >= 90"},
        %{id: 1, condition: "score >= 80", body: ~s|"B"|, display: "score >= 80"},
        %{id: 2, condition: "score >= 70", body: ~s|"C"|, display: "score >= 70"},
        %{id: 3, condition: "score >= 60", body: ~s|"D"|, display: "score >= 60"},
        %{id: 4, condition: "true", body: ~s|"F"|, display: "true (catch-all)"}
      ],
      variable: "score",
      test_values: [
        %{display: "95", code: "95"},
        %{display: "85", code: "85"},
        %{display: "75", code: "75"},
        %{display: "65", code: "65"},
        %{display: "50", code: "50"},
        %{display: "100", code: "100"}
      ]
    },
    %{
      id: "fizzbuzz",
      title: "FizzBuzz",
      description: "The classic FizzBuzz problem is a natural fit for cond. Order matters here!",
      conditions: [
        %{id: 0, condition: "rem(n, 15) == 0", body: ~s|"FizzBuzz"|, display: "rem(n, 15) == 0"},
        %{id: 1, condition: "rem(n, 3) == 0", body: ~s|"Fizz"|, display: "rem(n, 3) == 0"},
        %{id: 2, condition: "rem(n, 5) == 0", body: ~s|"Buzz"|, display: "rem(n, 5) == 0"},
        %{id: 3, condition: "true", body: "n", display: "true (catch-all)"}
      ],
      variable: "n",
      test_values: [
        %{display: "1", code: "1"},
        %{display: "3", code: "3"},
        %{display: "5", code: "5"},
        %{display: "6", code: "6"},
        %{display: "10", code: "10"},
        %{display: "15", code: "15"},
        %{display: "30", code: "30"}
      ]
    },
    %{
      id: "bmi",
      title: "BMI Category",
      description: "Classify BMI ranges using cond with comparison chains.",
      conditions: [
        %{id: 0, condition: "bmi < 18.5", body: ~s|"Underweight"|, display: "bmi < 18.5"},
        %{id: 1, condition: "bmi < 25.0", body: ~s|"Normal"|, display: "bmi < 25.0"},
        %{id: 2, condition: "bmi < 30.0", body: ~s|"Overweight"|, display: "bmi < 30.0"},
        %{id: 3, condition: "true", body: ~s|"Obese"|, display: "true (catch-all)"}
      ],
      variable: "bmi",
      test_values: [
        %{display: "16.0", code: "16.0"},
        %{display: "18.5", code: "18.5"},
        %{display: "22.5", code: "22.5"},
        %{display: "27.0", code: "27.0"},
        %{display: "32.0", code: "32.0"}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@cond_examples) end)
     |> assign_new(:test_value, fn -> nil end)
     |> assign_new(:matched_condition, fn -> nil end)
     |> assign_new(:test_result, fn -> nil end)
     |> assign_new(:custom_input, fn -> "" end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:fizz_range_start, fn -> 1 end)
     |> assign_new(:fizz_range_end, fn -> 20 end)
     |> assign_new(:fizz_results, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Cond Expressions</h2>
      <p class="text-sm opacity-70 mb-6">
        <code class="font-mono bg-base-300 px-1 rounded">cond</code> evaluates a series of boolean
        conditions and executes the body of the <strong>first true</strong> condition.
        Use it when you need to check multiple unrelated conditions rather than pattern matching.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for example <- cond_examples() do %>
          <button
            phx-click="select_example"
            phx-target={@myself}
            phx-value-id={example.id}
            class={"btn btn-sm " <> if(@active_example.id == example.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= example.title %>
          </button>
        <% end %>
      </div>

      <!-- Interactive Cond Tester -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_example.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @active_example.description %></p>

          <!-- Conditions Display with Step-Through Highlighting -->
          <div class="flex items-start gap-3 mb-4">
            <div class="flex flex-col items-center">
              <span class="text-xs opacity-40 mb-1">eval</span>
              <div class="w-0.5 bg-info flex-1 min-h-[2rem]"></div>
              <span class="text-xs opacity-40 mt-1">&darr;</span>
            </div>

            <div class="flex-1 space-y-2">
              <div class="font-mono text-sm bg-base-300 rounded-lg p-2 opacity-60">cond do</div>
              <%= for cond_clause <- @active_example.conditions do %>
                <div class={"rounded-lg p-3 border-2 transition-all " <>
                  cond do
                    @matched_condition == cond_clause.id -> "border-success bg-success/15 shadow-lg"
                    @matched_condition != nil and cond_clause.id < @matched_condition -> "border-warning bg-warning/10"
                    @matched_condition != nil -> "border-base-300 bg-base-100 opacity-30"
                    true -> "border-base-300 bg-base-100"
                  end}>
                  <div class="flex items-center justify-between">
                    <div class="font-mono text-sm">
                      <span class="text-info font-bold"><%= cond_clause.display %></span>
                      <span class="opacity-50"> -&gt; </span>
                      <span><%= cond_clause.body %></span>
                    </div>
                    <div class="flex items-center gap-2">
                      <%= if cond_clause.condition == "true" do %>
                        <span class="badge badge-ghost badge-xs">catch-all</span>
                      <% end %>
                      <%= if @matched_condition == cond_clause.id do %>
                        <span class="badge badge-success badge-sm">TRUE</span>
                      <% end %>
                      <%= if @matched_condition != nil and cond_clause.id < @matched_condition do %>
                        <span class="badge badge-warning badge-sm">false</span>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
              <div class="font-mono text-sm bg-base-300 rounded-lg p-2 opacity-60">end</div>
            </div>
          </div>

          <!-- Test Value Buttons -->
          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center"><%= @active_example.variable %> =</span>
            <%= for tv <- @active_example.test_values do %>
              <button
                phx-click="test_cond"
                phx-target={@myself}
                phx-value-code={tv.code}
                phx-value-display={tv.display}
                class={"btn btn-sm " <> if(@test_value == tv.display, do: "btn-primary", else: "btn-outline")}
              >
                <%= tv.display %>
              </button>
            <% end %>
          </div>

          <!-- Custom Input -->
          <form phx-submit="test_custom_cond" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Custom value for <code class="font-mono"><%= @active_example.variable %></code></span></label>
              <input
                type="text"
                name="value"
                value={@custom_input}
                placeholder="Enter a number..."
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Test</button>
          </form>

          <!-- Result -->
          <%= if @test_result do %>
            <div class={"alert text-sm " <> if(@test_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @active_example.variable %> = <%= @test_value %></div>
                <div class="font-mono font-bold mt-1">&rArr; <%= @test_result.value %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- FizzBuzz Runner -->
      <%= if @active_example.id == "fizzbuzz" do %>
        <div class="card bg-base-200 shadow-md mb-6">
          <div class="card-body p-4">
            <h3 class="card-title text-sm mb-2">FizzBuzz Range Runner</h3>
            <p class="text-xs opacity-60 mb-4">
              Run FizzBuzz on a range to see the full output.
            </p>

            <form phx-submit="run_fizzbuzz" phx-target={@myself} class="flex gap-2 items-end mb-4">
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">From</span></label>
                <input
                  type="number"
                  name="start"
                  value={@fizz_range_start}
                  class="input input-bordered input-sm w-20 font-mono"
                />
              </div>
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">To</span></label>
                <input
                  type="number"
                  name="end"
                  value={@fizz_range_end}
                  class="input input-bordered input-sm w-20 font-mono"
                />
              </div>
              <button type="submit" class="btn btn-primary btn-sm">Run FizzBuzz</button>
            </form>

            <%= if @fizz_results do %>
              <div class="flex flex-wrap gap-2">
                <%= for {n, result} <- @fizz_results do %>
                  <div class={"rounded-lg px-3 py-1.5 text-center min-w-[3rem] " <>
                    cond do
                      result == "FizzBuzz" -> "bg-accent text-accent-content font-bold"
                      result == "Fizz" -> "bg-success/20 text-success"
                      result == "Buzz" -> "bg-info/20 text-info"
                      true -> "bg-base-300"
                    end}>
                    <div class="text-xs opacity-50"><%= n %></div>
                    <div class="font-mono text-sm font-bold"><%= result %></div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Case vs Cond Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Case vs Cond</h3>
            <button
              phx-click="toggle_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_comparison, do: "Hide", else: "Show Comparison" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-primary/10 border border-primary/30 rounded-lg p-4">
                <h4 class="font-bold text-primary text-sm mb-2">case &mdash; Pattern Matching</h4>
                <div class="font-mono text-xs space-y-1 bg-base-100 rounded p-3 mb-3">
                  <div>case value do</div>
                  <div class="ml-2">&lbrace;:ok, n&rbrace; -&gt; "got \#&lbrace;n&rbrace;"</div>
                  <div class="ml-2">&lbrace;:error, _&rbrace; -&gt; "failed"</div>
                  <div class="ml-2">_ -&gt; "other"</div>
                  <div>end</div>
                </div>
                <ul class="text-xs space-y-1 list-disc ml-4">
                  <li>Matches <strong>one value</strong> against patterns</li>
                  <li>Uses structural pattern matching</li>
                  <li>Binds variables from patterns</li>
                  <li>Guards add extra conditions</li>
                </ul>
              </div>

              <div class="bg-secondary/10 border border-secondary/30 rounded-lg p-4">
                <h4 class="font-bold text-secondary text-sm mb-2">cond &mdash; Boolean Conditions</h4>
                <div class="font-mono text-xs space-y-1 bg-base-100 rounded p-3 mb-3">
                  <div>cond do</div>
                  <div class="ml-2">score &gt;= 90 -&gt; "A"</div>
                  <div class="ml-2">score &gt;= 80 -&gt; "B"</div>
                  <div class="ml-2">true -&gt; "F"</div>
                  <div>end</div>
                </div>
                <ul class="text-xs space-y-1 list-disc ml-4">
                  <li>Evaluates <strong>boolean expressions</strong></li>
                  <li>No pattern matching involved</li>
                  <li>Each condition is independent</li>
                  <li><code class="font-mono bg-base-100 px-1 rounded">true</code> is the catch-all</li>
                </ul>
              </div>
            </div>

            <div class="alert alert-info text-sm mt-4">
              <div>
                <div class="font-bold">When to use which?</div>
                <span>
                  Use <code class="font-mono bg-base-100 px-1 rounded">case</code> when matching against
                  the <em>structure</em> of a value. Use
                  <code class="font-mono bg-base-100 px-1 rounded">cond</code> when checking multiple
                  <em>boolean conditions</em> that may involve different variables.
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own Cond Expression</h3>
          <p class="text-xs opacity-60 mb-4">
            Write a complete <code class="font-mono bg-base-300 px-1 rounded">cond</code> expression.
          </p>

          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <textarea
                name="code"
                rows="5"
                class="textarea textarea-bordered font-mono text-sm"
                placeholder={"x = 42\ncond do\n  rem(x, 15) == 0 -> \"FizzBuzz\"\n  rem(x, 3) == 0 -> \"Fizz\"\n  rem(x, 5) == 0 -> \"Buzz\"\n  true -> x\nend"}
                autocomplete="off"
              ><%= @sandbox_code %></textarea>
            </div>
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
              <span class="text-xs opacity-50 self-center">Write any cond expression to see the result</span>
            </div>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Quick examples:</span>
            <%= for {label, code} <- sandbox_examples() do %>
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
                <div class="font-mono font-bold"><%= @sandbox_result.output %></div>
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
              <span>
                <strong>cond</strong> evaluates boolean conditions top-to-bottom and executes the
                body of the <strong>first true</strong> condition.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>
                Always include <code class="font-mono bg-base-100 px-1 rounded">true -&gt;</code>
                as the last condition (catch-all). Without it, a
                <code class="font-mono bg-base-100 px-1 rounded">CondClauseError</code> is raised
                if nothing matches.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>
                <strong>No pattern matching</strong> &mdash; unlike <code class="font-mono bg-base-100 px-1 rounded">case</code>,
                cond checks boolean expressions, not patterns.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>
                <strong>Order matters</strong> &mdash; put more specific (restrictive) conditions first.
                In FizzBuzz, <code class="font-mono bg-base-100 px-1 rounded">rem(n, 15) == 0</code>
                must come before <code class="font-mono bg-base-100 px-1 rounded">rem(n, 3) == 0</code>.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>
                Use <code class="font-mono bg-base-100 px-1 rounded">cond</code> when conditions involve
                different variables or complex boolean logic that does not fit pattern matching.
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    example = Enum.find(cond_examples(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_example: example)
     |> assign(test_value: nil)
     |> assign(matched_condition: nil)
     |> assign(test_result: nil)
     |> assign(fizz_results: nil)}
  end

  def handle_event("test_cond", %{"code" => code, "display" => display}, socket) do
    run_cond_test(socket, code, display)
  end

  def handle_event("test_custom_cond", %{"value" => value}, socket) do
    value = String.trim(value)

    if value == "" do
      {:noreply, socket}
    else
      run_cond_test(socket, value, value)
    end
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  def handle_event("run_fizzbuzz", %{"start" => start_str, "end" => end_str}, socket) do
    start_n = String.to_integer(start_str)
    end_n = String.to_integer(end_str)
    end_n = min(end_n, start_n + 49)

    results =
      Enum.map(start_n..end_n, fn n ->
        result =
          cond do
            rem(n, 15) == 0 -> "FizzBuzz"
            rem(n, 3) == 0 -> "Fizz"
            rem(n, 5) == 0 -> "Buzz"
            true -> to_string(n)
          end
        {n, result}
      end)

    {:noreply,
     socket
     |> assign(fizz_range_start: start_n)
     |> assign(fizz_range_end: end_n)
     |> assign(fizz_results: results)}
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

  defp cond_examples, do: @cond_examples

  defp sandbox_examples do
    [
      {"day type", ~s|day = :saturday\ncond do\n  day in [:saturday, :sunday] -> "weekend"\n  day in [:monday, :friday] -> "almost weekend"\n  true -> "workday"\nend|},
      {"number sign", ~s|n = -7\ncond do\n  n > 0 -> "positive"\n  n < 0 -> "negative"\n  true -> "zero"\nend|},
      {"time of day", ~s|hour = 14\ncond do\n  hour < 6 -> "night"\n  hour < 12 -> "morning"\n  hour < 18 -> "afternoon"\n  true -> "evening"\nend|}
    ]
  end

  defp run_cond_test(socket, code, display) do
    example = socket.assigns.active_example

    conditions_code =
      example.conditions
      |> Enum.map(fn cond_clause ->
        "  #{cond_clause.condition} -> {#{cond_clause.id}, #{cond_clause.body}}"
      end)
      |> Enum.join("\n")

    eval_code = "#{example.variable} = #{code}\ncond do\n#{conditions_code}\nend"

    try do
      {result, _bindings} = Code.eval_string(eval_code)
      {condition_id, value} = result

      {:noreply,
       socket
       |> assign(test_value: display)
       |> assign(matched_condition: condition_id)
       |> assign(custom_input: display)
       |> assign(test_result: %{ok: true, value: inspect(value)})}
    rescue
      e ->
        {:noreply,
         socket
         |> assign(test_value: display)
         |> assign(matched_condition: nil)
         |> assign(custom_input: display)
         |> assign(test_result: %{ok: false, value: Exception.message(e)})}
    end
  end

  defp evaluate_code(code) do
    try do
      {result, _bindings} = Code.eval_string(code)
      %{ok: true, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, output: "Error: #{Exception.message(e)}"}
    end
  end
end
