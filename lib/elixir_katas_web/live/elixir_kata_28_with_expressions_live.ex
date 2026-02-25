defmodule ElixirKatasWeb.ElixirKata28WithExpressionsLive do
  use ElixirKatasWeb, :live_component

  @with_scenarios [
    %{
      id: "user_auth",
      title: "User Authentication",
      description: "Chain multiple validation steps: find user, check password, check active status.",
      clauses: [
        %{id: 0, pattern: ~s|{:ok, user}|, source: "find_user(username)", description: "Find user by username"},
        %{id: 1, pattern: ~s|{:ok, user}|, source: "check_password(user, password)", description: "Verify password"},
        %{id: 2, pattern: ~s|{:ok, session}|, source: "create_session(user)", description: "Create session"}
      ],
      success_body: ~s|{:ok, session}|,
      else_clauses: [
        %{pattern: ~s|{:error, :not_found}|, body: ~s|{:error, "User not found"}|},
        %{pattern: ~s|{:error, :wrong_password}|, body: ~s|{:error, "Invalid password"}|},
        %{pattern: ~s|{:error, reason}|, body: ~s|{:error, "Failed: \#{reason}"}|}
      ],
      test_inputs: [
        %{display: "valid user + correct password", code: "valid_correct", expected_step: 3},
        %{display: "unknown user", code: "unknown", expected_step: 0},
        %{display: "valid user + wrong password", code: "wrong_pass", expected_step: 1},
        %{display: "valid user + session fail", code: "session_fail", expected_step: 2}
      ]
    },
    %{
      id: "config",
      title: "Config Loading",
      description: "Read a config file, parse it, and validate the contents step by step.",
      clauses: [
        %{id: 0, pattern: ~s|{:ok, content}|, source: ~s|File.read(path)|, description: "Read file"},
        %{id: 1, pattern: ~s|{:ok, parsed}|, source: "Jason.decode(content)", description: "Parse JSON"},
        %{id: 2, pattern: ~s|{:ok, config}|, source: "validate_config(parsed)", description: "Validate schema"}
      ],
      success_body: ~s|{:ok, config}|,
      else_clauses: [
        %{pattern: ~s|{:error, :enoent}|, body: ~s|{:error, "File not found"}|},
        %{pattern: ~s|{:error, %Jason.DecodeError{}}|, body: ~s|{:error, "Invalid JSON"}|},
        %{pattern: ~s|{:error, reason}|, body: ~s|{:error, "Config error: \#{reason}"}|}
      ],
      test_inputs: [
        %{display: "valid config file", code: "valid", expected_step: 3},
        %{display: "file not found", code: "no_file", expected_step: 0},
        %{display: "invalid JSON", code: "bad_json", expected_step: 1},
        %{display: "invalid schema", code: "bad_schema", expected_step: 2}
      ]
    },
    %{
      id: "order",
      title: "Order Processing",
      description: "Validate an order through multiple business rules before processing.",
      clauses: [
        %{id: 0, pattern: ~s|{:ok, items}|, source: "validate_items(order)", description: "Validate items exist"},
        %{id: 1, pattern: ~s|{:ok, priced}|, source: "calculate_total(items)", description: "Calculate total"},
        %{id: 2, pattern: ~s|{:ok, charged}|, source: "charge_payment(priced, payment)", description: "Charge payment"},
        %{id: 3, pattern: ~s|{:ok, receipt}|, source: "send_receipt(charged)", description: "Send receipt"}
      ],
      success_body: ~s|{:ok, receipt}|,
      else_clauses: [
        %{pattern: ~s|{:error, :out_of_stock}|, body: ~s|{:error, "Item out of stock"}|},
        %{pattern: ~s|{:error, :payment_declined}|, body: ~s|{:error, "Payment declined"}|},
        %{pattern: ~s|{:error, reason}|, body: ~s|{:error, "Order failed: \#{reason}"}|}
      ],
      test_inputs: [
        %{display: "everything succeeds", code: "success", expected_step: 4},
        %{display: "out of stock", code: "no_stock", expected_step: 0},
        %{display: "payment declined", code: "no_pay", expected_step: 2},
        %{display: "receipt fails", code: "no_receipt", expected_step: 3}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_scenario, fn -> hd(@with_scenarios) end)
     |> assign_new(:active_step, fn -> nil end)
     |> assign_new(:step_result, fn -> nil end)
     |> assign_new(:show_refactoring, fn -> false end)
     |> assign_new(:show_else_detail, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">With Expressions</h2>
      <p class="text-sm opacity-70 mb-6">
        <code class="font-mono bg-base-300 px-1 rounded">with</code> chains multiple pattern-matching
        operations along the "happy path." If any step fails to match, execution short-circuits
        and returns the non-matching value (or falls through to the
        <code class="font-mono bg-base-300 px-1 rounded">else</code> block).
      </p>

      <!-- Scenario Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for scenario <- with_scenarios() do %>
          <button
            phx-click="select_scenario"
            phx-target={@myself}
            phx-value-id={scenario.id}
            class={"btn btn-sm " <> if(@active_scenario.id == scenario.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= scenario.title %>
          </button>
        <% end %>
      </div>

      <!-- Interactive With Step-Through -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_scenario.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @active_scenario.description %></p>

          <!-- With Expression Visualization -->
          <div class="flex items-start gap-3 mb-4">
            <div class="flex flex-col items-center">
              <span class="text-xs opacity-40 mb-1">with</span>
              <div class="w-0.5 bg-success flex-1 min-h-[2rem]"></div>
              <span class="text-xs opacity-40 mt-1">&darr;</span>
            </div>

            <div class="flex-1 space-y-2">
              <!-- with keyword -->
              <div class="font-mono text-sm bg-base-300 rounded-lg p-2 opacity-60">with</div>

              <!-- Each clause -->
              <%= for clause <- @active_scenario.clauses do %>
                <div class={"rounded-lg p-3 border-2 transition-all " <>
                  cond do
                    @active_step != nil and clause.id < @active_step -> "border-success bg-success/15"
                    @active_step != nil and clause.id == @active_step and @step_result != nil and !@step_result.success -> "border-error bg-error/15 shadow-lg"
                    @active_step != nil and clause.id == @active_step -> "border-warning bg-warning/15 shadow-lg"
                    @active_step != nil and clause.id > @active_step -> "border-base-300 bg-base-100 opacity-30"
                    true -> "border-base-300 bg-base-100"
                  end}>
                  <div class="flex items-center justify-between">
                    <div class="font-mono text-sm">
                      <span class="text-accent font-bold"><%= clause.pattern %></span>
                      <span class="opacity-50"> &lt;- </span>
                      <span class="text-info"><%= clause.source %></span>
                    </div>
                    <div class="flex items-center gap-2">
                      <span class="text-xs opacity-50"><%= clause.description %></span>
                      <%= cond do %>
                        <% @active_step != nil and clause.id < @active_step -> %>
                          <span class="badge badge-success badge-sm">matched</span>
                        <% @active_step != nil and clause.id == @active_step and @step_result != nil and !@step_result.success -> %>
                          <span class="badge badge-error badge-sm">FAILED</span>
                        <% @active_step != nil and clause.id == @active_step -> %>
                          <span class="badge badge-warning badge-sm">evaluating...</span>
                        <% true -> %>
                      <% end %>
                    </div>
                  </div>
                </div>
                <%= if clause.id < length(@active_scenario.clauses) - 1 do %>
                  <div class="flex items-center gap-2 ml-4">
                    <span class="text-xs opacity-30">&darr; pattern matched, continue</span>
                  </div>
                <% end %>
              <% end %>

              <!-- do block -->
              <div class="font-mono text-sm bg-base-300 rounded-lg p-2 opacity-60">do</div>
              <div class={"rounded-lg p-3 border-2 transition-all " <>
                if(@active_step != nil and @step_result != nil and @step_result.success, do: "border-success bg-success/15 shadow-lg", else: "border-base-300 bg-base-100")}>
                <div class="flex items-center justify-between">
                  <div class="font-mono text-sm text-success font-bold">
                    <%= @active_scenario.success_body %>
                  </div>
                  <%= if @active_step != nil and @step_result != nil and @step_result.success do %>
                    <span class="badge badge-success badge-sm">RESULT</span>
                  <% end %>
                </div>
              </div>

              <!-- else block -->
              <div class="font-mono text-sm bg-base-300 rounded-lg p-2 opacity-60">else</div>
              <%= for else_clause <- @active_scenario.else_clauses do %>
                <div class={"rounded-lg p-2 border transition-all ml-4 " <>
                  if(@step_result != nil and !@step_result.success and @step_result.else_match == else_clause.pattern,
                    do: "border-error bg-error/15",
                    else: "border-base-300 bg-base-100 opacity-60")}>
                  <div class="font-mono text-xs">
                    <span class="text-accent"><%= else_clause.pattern %></span>
                    <span class="opacity-50"> -&gt; </span>
                    <span class="text-error"><%= else_clause.body %></span>
                  </div>
                </div>
              <% end %>

              <div class="font-mono text-sm bg-base-300 rounded-lg p-2 opacity-60">end</div>
            </div>
          </div>

          <!-- Test Inputs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Simulate:</span>
            <%= for input <- @active_scenario.test_inputs do %>
              <button
                phx-click="simulate_with"
                phx-target={@myself}
                phx-value-code={input.code}
                phx-value-step={input.expected_step}
                class={"btn btn-sm " <> if(@step_result != nil and @step_result.code == input.code, do: "btn-primary", else: "btn-outline")}
              >
                <%= input.display %>
              </button>
            <% end %>
          </div>

          <!-- Result -->
          <%= if @step_result do %>
            <div class={"alert text-sm " <> if(@step_result.success, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @step_result.explanation %></div>
                <div class="font-mono font-bold mt-1">&rArr; <%= @step_result.result %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- with else Block Detail -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">The else Block</h3>
            <button
              phx-click="toggle_else_detail"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_else_detail, do: "Hide", else: "Show Details" %>
            </button>
          </div>

          <%= if @show_else_detail do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div class="bg-primary/10 border border-primary/30 rounded-lg p-4">
                <h4 class="font-bold text-primary text-sm mb-2">Without else</h4>
                <div class="font-mono text-xs space-y-1 bg-base-100 rounded p-3 mb-3">
                  <div>with &lbrace;:ok, a&rbrace; &lt;- step1(),</div>
                  <div class="ml-5">&lbrace;:ok, b&rbrace; &lt;- step2(a) do</div>
                  <div class="ml-2">&lbrace;:ok, b&rbrace;</div>
                  <div>end</div>
                </div>
                <p class="text-xs opacity-70">
                  Without else, the non-matching value is returned directly.
                  If step1 returns <code class="font-mono bg-base-100 px-1 rounded">&lbrace;:error, :fail&rbrace;</code>,
                  that exact value becomes the result.
                </p>
              </div>

              <div class="bg-secondary/10 border border-secondary/30 rounded-lg p-4">
                <h4 class="font-bold text-secondary text-sm mb-2">With else</h4>
                <div class="font-mono text-xs space-y-1 bg-base-100 rounded p-3 mb-3">
                  <div>with &lbrace;:ok, a&rbrace; &lt;- step1(),</div>
                  <div class="ml-5">&lbrace;:ok, b&rbrace; &lt;- step2(a) do</div>
                  <div class="ml-2">&lbrace;:ok, b&rbrace;</div>
                  <div>else</div>
                  <div class="ml-2">&lbrace;:error, r&rbrace; -&gt; handle(r)</div>
                  <div>end</div>
                </div>
                <p class="text-xs opacity-70">
                  With else, unmatched values are pattern-matched against the else clauses.
                  This lets you normalize error responses.
                </p>
              </div>
            </div>

            <div class="alert alert-warning text-sm">
              <div>
                <div class="font-bold">else must be exhaustive</div>
                <span>
                  If you use <code class="font-mono bg-base-100 px-1 rounded">else</code>,
                  it must handle all possible non-matching values. Otherwise, you get a
                  <code class="font-mono bg-base-100 px-1 rounded">WithClauseError</code>.
                  Use <code class="font-mono bg-base-100 px-1 rounded">_ -&gt;</code> as a catch-all
                  in the else block.
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Refactoring Nested Case into With -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Refactoring Nested Case to With</h3>
            <button
              phx-click="toggle_refactoring"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_refactoring, do: "Hide", else: "Show Example" %>
            </button>
          </div>

          <%= if @show_refactoring do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                <h4 class="font-bold text-error text-sm mb-2">Before: Nested case</h4>
                <div class="font-mono text-xs space-y-1 bg-base-100 rounded p-3">
                  <div>case fetch_user(id) do</div>
                  <div class="ml-2">&lbrace;:ok, user&rbrace; -&gt;</div>
                  <div class="ml-4">case validate(user) do</div>
                  <div class="ml-6">&lbrace;:ok, valid&rbrace; -&gt;</div>
                  <div class="ml-8">case save(valid) do</div>
                  <div class="ml-10">&lbrace;:ok, saved&rbrace; -&gt;</div>
                  <div class="ml-12">&lbrace;:ok, saved&rbrace;</div>
                  <div class="ml-10">&lbrace;:error, r&rbrace; -&gt;</div>
                  <div class="ml-12">&lbrace;:error, r&rbrace;</div>
                  <div class="ml-8">end</div>
                  <div class="ml-6">&lbrace;:error, r&rbrace; -&gt;</div>
                  <div class="ml-8">&lbrace;:error, r&rbrace;</div>
                  <div class="ml-4">end</div>
                  <div class="ml-2">&lbrace;:error, r&rbrace; -&gt;</div>
                  <div class="ml-4">&lbrace;:error, r&rbrace;</div>
                  <div>end</div>
                </div>
                <p class="text-xs opacity-70 mt-2">
                  Deep nesting. Error handling repeated at every level. Difficult to read.
                </p>
              </div>

              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <h4 class="font-bold text-success text-sm mb-2">After: with</h4>
                <div class="font-mono text-xs space-y-1 bg-base-100 rounded p-3">
                  <div>with &lbrace;:ok, user&rbrace; &lt;- fetch_user(id),</div>
                  <div class="ml-5">&lbrace;:ok, valid&rbrace; &lt;- validate(user),</div>
                  <div class="ml-5">&lbrace;:ok, saved&rbrace; &lt;- save(valid) do</div>
                  <div class="ml-2">&lbrace;:ok, saved&rbrace;</div>
                  <div>else</div>
                  <div class="ml-2">&lbrace;:error, reason&rbrace; -&gt;</div>
                  <div class="ml-4">&lbrace;:error, reason&rbrace;</div>
                  <div>end</div>
                </div>
                <p class="text-xs opacity-70 mt-2">
                  Flat. Linear. Error handling in one place. Easy to read and extend.
                </p>
              </div>
            </div>

            <div class="mt-4 space-y-2">
              <div class="flex items-center gap-2 text-sm">
                <span class="badge badge-success badge-sm">1</span>
                <span>Each <code class="font-mono bg-base-300 px-1 rounded">&lt;-</code> clause runs in order</span>
              </div>
              <div class="flex items-center gap-2 text-sm">
                <span class="badge badge-success badge-sm">2</span>
                <span>If a pattern matches, its bound variables are available in later clauses</span>
              </div>
              <div class="flex items-center gap-2 text-sm">
                <span class="badge badge-success badge-sm">3</span>
                <span>If a pattern does NOT match, execution jumps to else (or returns the non-matching value)</span>
              </div>
              <div class="flex items-center gap-2 text-sm">
                <span class="badge badge-success badge-sm">4</span>
                <span>The do block runs only if ALL clauses match</span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own With Expression</h3>
          <p class="text-xs opacity-60 mb-4">
            Write a <code class="font-mono bg-base-300 px-1 rounded">with</code> expression to see how it works.
          </p>

          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <textarea
                name="code"
                rows="6"
                class="textarea textarea-bordered font-mono text-sm"
                placeholder={"with {:ok, a} <- {:ok, 1},\n     {:ok, b} <- {:ok, 2},\n     {:ok, c} <- {:ok, 3} do\n  a + b + c\nelse\n  {:error, reason} -> \"Failed: \#{reason}\"\nend"}
                autocomplete="off"
              ><%= @sandbox_code %></textarea>
            </div>
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
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
                <strong>with</strong> chains
                <code class="font-mono bg-base-100 px-1 rounded">&lt;-</code> clauses along the "happy path."
                Each clause must pattern-match for the next to run.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>
                <strong>Short-circuit</strong>: if any clause fails to match, execution stops
                immediately and the non-matching value is returned or handled by
                <code class="font-mono bg-base-100 px-1 rounded">else</code>.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>
                <strong>Variables carry forward</strong>: bindings from earlier clauses are available
                in later clauses and in the do block.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>
                The <strong>else block</strong> is optional. Without it, the unmatched value is
                returned directly. With it, you can pattern-match on failures.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>
                <strong>Replaces nested case</strong>: with flattens deeply nested
                case/if chains into a linear, readable pipeline.
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_scenario", %{"id" => id}, socket) do
    scenario = Enum.find(with_scenarios(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_scenario: scenario)
     |> assign(active_step: nil)
     |> assign(step_result: nil)}
  end

  def handle_event("simulate_with", %{"code" => code, "step" => step_str}, socket) do
    step = String.to_integer(step_str)
    scenario = socket.assigns.active_scenario
    total_clauses = length(scenario.clauses)

    success = step >= total_clauses

    result =
      if success do
        %{
          success: true,
          code: code,
          result: scenario.success_body,
          explanation: "All #{total_clauses} clauses matched. The do block executes.",
          else_match: nil
        }
      else
        failed_clause = Enum.at(scenario.clauses, step)
        else_match = find_else_match(scenario, step)

        %{
          success: false,
          code: code,
          result: else_match_body(scenario, else_match),
          explanation: "Step #{step + 1} failed: #{failed_clause.description}. Pattern #{failed_clause.pattern} did not match.",
          else_match: else_match
        }
      end

    {:noreply,
     socket
     |> assign(active_step: step)
     |> assign(step_result: result)}
  end

  def handle_event("toggle_refactoring", _params, socket) do
    {:noreply, assign(socket, show_refactoring: !socket.assigns.show_refactoring)}
  end

  def handle_event("toggle_else_detail", _params, socket) do
    {:noreply, assign(socket, show_else_detail: !socket.assigns.show_else_detail)}
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

  defp with_scenarios, do: @with_scenarios

  defp sandbox_examples do
    [
      {"all match", ~s|with {:ok, a} <- {:ok, 1},\n     {:ok, b} <- {:ok, 2},\n     {:ok, c} <- {:ok, 3} do\n  {:ok, a + b + c}\nend|},
      {"second fails", ~s|with {:ok, a} <- {:ok, 1},\n     {:ok, b} <- {:error, :oops},\n     {:ok, c} <- {:ok, 3} do\n  {:ok, a + b + c}\nend|},
      {"with else", ~s|with {:ok, a} <- {:ok, 10},\n     {:ok, b} <- {:error, :not_found} do\n  a + b\nelse\n  {:error, :not_found} -> "not found"\n  {:error, reason} -> "error: \#{reason}"\nend|},
      {"bare =", ~s|with {:ok, a} <- {:ok, 5},\n     b = a * 2,\n     {:ok, c} <- {:ok, b + 1} do\n  {a, b, c}\nend|},
      {"guards in with", ~s|with {:ok, n} when n > 0 <- {:ok, 42} do\n  "positive: \#{n}"\nelse\n  {:ok, n} -> "non-positive: \#{n}"\n  other -> "error: \#{inspect(other)}"\nend|}
    ]
  end

  defp find_else_match(scenario, _step) do
    case scenario.else_clauses do
      [_ | _] -> List.last(scenario.else_clauses) |> Map.get(:pattern)
      [] -> nil
    end
  end

  defp else_match_body(scenario, pattern) do
    case Enum.find(scenario.else_clauses, &(&1.pattern == pattern)) do
      nil -> "unhandled error"
      clause -> clause.body
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
