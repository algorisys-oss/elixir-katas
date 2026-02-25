defmodule ElixirKatasWeb.ElixirKata19GuardsLive do
  use ElixirKatasWeb, :live_component

  @guard_functions [
    %{category: "Type checks", guards: [
      %{name: "is_integer/1", example: "is_integer(42)", description: "Checks if value is an integer", allowed: true},
      %{name: "is_float/1", example: "is_float(3.14)", description: "Checks if value is a float", allowed: true},
      %{name: "is_number/1", example: "is_number(42)", description: "Checks if value is integer or float", allowed: true},
      %{name: "is_binary/1", example: "is_binary(\"hi\")", description: "Checks if value is a binary (string)", allowed: true},
      %{name: "is_atom/1", example: "is_atom(:ok)", description: "Checks if value is an atom", allowed: true},
      %{name: "is_boolean/1", example: "is_boolean(true)", description: "Checks if value is true or false", allowed: true},
      %{name: "is_list/1", example: "is_list([1])", description: "Checks if value is a list", allowed: true},
      %{name: "is_map/1", example: "is_map(%{})", description: "Checks if value is a map", allowed: true},
      %{name: "is_tuple/1", example: "is_tuple({:ok})", description: "Checks if value is a tuple", allowed: true},
      %{name: "is_nil/1", example: "is_nil(nil)", description: "Checks if value is nil", allowed: true},
      %{name: "is_pid/1", example: "is_pid(self())", description: "Checks if value is a PID", allowed: true}
    ]},
    %{category: "Comparisons", guards: [
      %{name: "==/2", example: "x == 1", description: "Equal to", allowed: true},
      %{name: "!=/2", example: "x != 1", description: "Not equal to", allowed: true},
      %{name: "</2", example: "x < 10", description: "Less than", allowed: true},
      %{name: ">/2", example: "x > 0", description: "Greater than", allowed: true},
      %{name: "<=/2", example: "x <= 100", description: "Less than or equal", allowed: true},
      %{name: ">=/2", example: "x >= 0", description: "Greater than or equal", allowed: true}
    ]},
    %{category: "Arithmetic", guards: [
      %{name: "+/2", example: "x + 1", description: "Addition", allowed: true},
      %{name: "-/2", example: "x - 1", description: "Subtraction", allowed: true},
      %{name: "*/2", example: "x * 2", description: "Multiplication", allowed: true},
      %{name: "div/2", example: "div(x, 2)", description: "Integer division", allowed: true},
      %{name: "rem/2", example: "rem(x, 2)", description: "Remainder", allowed: true},
      %{name: "abs/1", example: "abs(x)", description: "Absolute value", allowed: true}
    ]},
    %{category: "Boolean", guards: [
      %{name: "and/2", example: "x > 0 and x < 10", description: "Logical AND", allowed: true},
      %{name: "or/2", example: "x == 0 or x == 1", description: "Logical OR", allowed: true},
      %{name: "not/1", example: "not is_nil(x)", description: "Logical NOT", allowed: true},
      %{name: "in/2", example: "x in [1, 2, 3]", description: "Membership (literal list only)", allowed: true}
    ]},
    %{category: "NOT allowed in guards", guards: [
      %{name: "String.length/1", example: "String.length(x)", description: "Module functions", allowed: false},
      %{name: "Enum.member?/2", example: "Enum.member?(list, x)", description: "Enum functions", allowed: false},
      %{name: "custom_fn.(x)", example: "my_fun.(x)", description: "Anonymous function calls", allowed: false},
      %{name: "send/receive", example: "send(pid, msg)", description: "Side effects", allowed: false},
      %{name: "try/rescue", example: "try do ... end", description: "Exception handling", allowed: false}
    ]}
  ]

  @test_scenarios [
    %{
      id: "classify_type",
      title: "Type Classifier",
      description: "Guards to classify values by type",
      clauses: [
        %{id: 0, head: "classify(x) when is_integer(x)", body: ":integer", guard: "is_integer(x)"},
        %{id: 1, head: "classify(x) when is_float(x)", body: ":float", guard: "is_float(x)"},
        %{id: 2, head: "classify(x) when is_binary(x)", body: ":string", guard: "is_binary(x)"},
        %{id: 3, head: "classify(x) when is_atom(x)", body: ":atom", guard: "is_atom(x)"},
        %{id: 4, head: "classify(x) when is_list(x)", body: ":list", guard: "is_list(x)"},
        %{id: 5, head: "classify(x) when is_map(x)", body: ":map", guard: "is_map(x)"},
        %{id: 6, head: "classify(_x)", body: ":other", guard: nil}
      ],
      test_values: [
        %{display: "42", code: "42"},
        %{display: "3.14", code: "3.14"},
        %{display: "\"hello\"", code: "\"hello\""},
        %{display: ":ok", code: ":ok"},
        %{display: "[1, 2]", code: "[1, 2]"},
        %{display: "%{}", code: "%{}"},
        %{display: "{:tuple}", code: "{:tuple}"}
      ]
    },
    %{
      id: "water_state",
      title: "Water State (Temperature)",
      description: "Guards with comparison operators for ranges",
      clauses: [
        %{id: 0, head: "water_state(temp) when temp <= 0", body: ":ice", guard: "temp <= 0"},
        %{id: 1, head: "water_state(temp) when temp < 100", body: ":liquid", guard: "temp < 100"},
        %{id: 2, head: "water_state(temp) when temp >= 100", body: ":steam", guard: "temp >= 100"}
      ],
      test_values: [
        %{display: "-10", code: "-10"},
        %{display: "0", code: "0"},
        %{display: "25", code: "25"},
        %{display: "99", code: "99"},
        %{display: "100", code: "100"},
        %{display: "200", code: "200"}
      ]
    },
    %{
      id: "ticket_price",
      title: "Ticket Price (Age)",
      description: "Multiple guard conditions for age-based pricing",
      clauses: [
        %{id: 0, head: "ticket(age) when age < 0", body: ":invalid", guard: "age < 0"},
        %{id: 1, head: "ticket(age) when age <= 3", body: ":free", guard: "age <= 3"},
        %{id: 2, head: "ticket(age) when age <= 12", body: ":child", guard: "age <= 12"},
        %{id: 3, head: "ticket(age) when age <= 64", body: ":adult", guard: "age <= 64"},
        %{id: 4, head: "ticket(age) when age >= 65", body: ":senior", guard: "age >= 65"}
      ],
      test_values: [
        %{display: "-1", code: "-1"},
        %{display: "2", code: "2"},
        %{display: "8", code: "8"},
        %{display: "30", code: "30"},
        %{display: "65", code: "65"},
        %{display: "80", code: "80"}
      ]
    },
    %{
      id: "fizzbuzz",
      title: "FizzBuzz with Guards",
      description: "Using rem/2 in guards for divisibility checks",
      clauses: [
        %{id: 0, head: "fizz(n) when rem(n, 15) == 0", body: "\"FizzBuzz\"", guard: "rem(n, 15) == 0"},
        %{id: 1, head: "fizz(n) when rem(n, 3) == 0", body: "\"Fizz\"", guard: "rem(n, 3) == 0"},
        %{id: 2, head: "fizz(n) when rem(n, 5) == 0", body: "\"Buzz\"", guard: "rem(n, 5) == 0"},
        %{id: 3, head: "fizz(n)", body: "n", guard: nil}
      ],
      test_values: [
        %{display: "1", code: "1"},
        %{display: "3", code: "3"},
        %{display: "5", code: "5"},
        %{display: "7", code: "7"},
        %{display: "15", code: "15"},
        %{display: "30", code: "30"}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:selected_scenario, fn -> hd(@test_scenarios) end)
     |> assign_new(:test_value, fn -> nil end)
     |> assign_new(:matched_clause, fn -> nil end)
     |> assign_new(:test_result, fn -> nil end)
     |> assign_new(:show_guard_table, fn -> true end)
     |> assign_new(:show_silent_fail, fn -> false end)
     |> assign_new(:show_case_guards, fn -> false end)
     |> assign_new(:show_defguard, fn -> false end)
     |> assign_new(:custom_input, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Guards</h2>
      <p class="text-sm opacity-70 mb-6">
        Guards are <code class="font-mono bg-base-300 px-1 rounded">when</code> clauses that add extra
        conditions to pattern matching. They let you refine which function clause matches based on
        the values of variables, not just their structure.
      </p>

      <!-- Interactive Guard Tester -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive Guard Tester</h3>
          <p class="text-xs opacity-60 mb-4">
            Select a scenario, then provide a value to see which guarded clause matches.
          </p>

          <!-- Scenario Selector -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for scenario <- scenarios() do %>
              <button
                phx-click="select_scenario"
                phx-target={@myself}
                phx-value-id={scenario.id}
                class={"btn btn-sm " <> if(@selected_scenario.id == scenario.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= scenario.title %>
              </button>
            <% end %>
          </div>

          <p class="text-xs opacity-60 mb-3"><%= @selected_scenario.description %></p>

          <!-- Clauses Display with Match Indicator -->
          <div class="flex items-start gap-3 mb-4">
            <div class="flex flex-col items-center">
              <span class="text-xs opacity-40 mb-1">try</span>
              <div class="w-0.5 bg-warning flex-1 min-h-[2rem]"></div>
              <span class="text-xs opacity-40 mt-1">&darr;</span>
            </div>

            <div class="flex-1 space-y-2">
              <%= for clause <- @selected_scenario.clauses do %>
                <div class={"rounded-lg p-3 border-2 transition-all " <>
                  cond do
                    @matched_clause == clause.id -> "border-success bg-success/15 shadow-lg"
                    @matched_clause != nil and clause.id < @matched_clause -> "border-base-300 bg-base-100 opacity-40"
                    @matched_clause != nil -> "border-base-300 bg-base-100 opacity-30"
                    true -> "border-base-300 bg-base-100"
                  end}>
                  <div class="flex items-center justify-between">
                    <div class="font-mono text-sm">
                      <span class="opacity-50">def </span>
                      <span class="font-bold"><%= clause.head %></span>
                      <span class="opacity-50"> do</span>
                      <span class="text-accent ml-2"><%= clause.body %></span>
                      <span class="opacity-50"> end</span>
                    </div>
                    <div class="flex items-center gap-2">
                      <%= if clause.guard do %>
                        <span class="badge badge-warning badge-xs">guard</span>
                      <% else %>
                        <span class="badge badge-ghost badge-xs">catch-all</span>
                      <% end %>
                      <%= if @matched_clause == clause.id do %>
                        <span class="badge badge-success badge-sm">MATCHED</span>
                      <% end %>
                      <%= if @matched_clause != nil and clause.id < @matched_clause do %>
                        <span class="badge badge-ghost badge-sm opacity-50">skipped</span>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Test Value Buttons -->
          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Test values:</span>
            <%= for tv <- @selected_scenario.test_values do %>
              <button
                phx-click="test_guard"
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
          <form phx-submit="test_custom_guard" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Custom value</span></label>
              <input
                type="text"
                name="value"
                value={@custom_input}
                placeholder="Enter any Elixir value..."
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
                <div class="font-mono text-xs opacity-60">
                  Input: <%= @test_value %>
                </div>
                <div class="font-mono font-bold mt-1">&rArr; <%= @test_result.value %></div>
                <%= if @test_result.guard_explain do %>
                  <div class="text-xs mt-1 opacity-70"><%= @test_result.guard_explain %></div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Guard Functions Reference Table -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Allowed Guard Expressions</h3>
            <button
              phx-click="toggle_guard_table"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_guard_table, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_guard_table do %>
            <p class="text-xs opacity-60 mb-4">
              Only a limited set of expressions is allowed in guards. This is because guards must be
              free of side effects and guaranteed to terminate.
            </p>

            <div class="space-y-4">
              <%= for category <- guard_functions() do %>
                <div>
                  <h4 class={"text-sm font-bold mb-2 " <> if(hd(category.guards).allowed, do: "text-success", else: "text-error")}>
                    <%= if hd(category.guards).allowed do %>
                      &#x2713;
                    <% else %>
                      &#x2717;
                    <% end %>
                    <%= category.category %>
                  </h4>
                  <div class="overflow-x-auto">
                    <table class="table table-sm">
                      <thead>
                        <tr>
                          <th>Expression</th>
                          <th>Example</th>
                          <th>Description</th>
                          <th>In Guards?</th>
                        </tr>
                      </thead>
                      <tbody>
                        <%= for guard <- category.guards do %>
                          <tr class="hover:bg-base-300">
                            <td class="font-mono text-sm font-bold"><%= guard.name %></td>
                            <td class="font-mono text-xs"><%= guard.example %></td>
                            <td class="text-xs opacity-70"><%= guard.description %></td>
                            <td>
                              <span class={"badge badge-xs " <> if(guard.allowed, do: "badge-success", else: "badge-error")}>
                                <%= if guard.allowed, do: "Yes", else: "No" %>
                              </span>
                            </td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Guards Fail Silently -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Guards Fail Silently</h3>
            <button
              phx-click="toggle_silent_fail"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_silent_fail, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_silent_fail do %>
            <p class="text-xs opacity-60 mb-4">
              If a guard expression raises an error, it does NOT crash. Instead, the guard simply
              returns <code class="font-mono bg-base-300 px-1 rounded">false</code> and Elixir moves
              to the next clause. This is called "failing silently."
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
                <h4 class="font-bold text-warning text-sm mb-2">Guard that fails silently</h4>
                <div class="font-mono text-sm space-y-2">
                  <div class="bg-base-100 rounded p-2">
                    <div class="opacity-60"># length/1 raises on non-lists</div>
                    <div>def check(x) when length(x) &gt; 0 do</div>
                    <div class="ml-4">"has elements"</div>
                    <div>end</div>
                    <div class="mt-1">def check(_x) do</div>
                    <div class="ml-4">"fallback"</div>
                    <div>end</div>
                  </div>
                  <div class="bg-base-100 rounded p-2">
                    <div><span class="opacity-50">iex&gt; </span>check("hello")</div>
                    <div class="text-success">"fallback"</div>
                    <div class="text-xs opacity-60 mt-1">
                      length("hello") raises ArgumentError, but the guard
                      silently returns false instead of crashing.
                    </div>
                  </div>
                </div>
              </div>

              <div class="bg-info/10 border border-info/30 rounded-lg p-4">
                <h4 class="font-bold text-info text-sm mb-2">Why this matters</h4>
                <div class="text-sm space-y-2">
                  <p>Guards are designed to be safe:</p>
                  <ul class="list-disc ml-4 space-y-1 text-xs">
                    <li>No side effects allowed</li>
                    <li>Errors become <code class="font-mono bg-base-100 px-1 rounded">false</code></li>
                    <li>Guarantees the program does not crash during pattern matching</li>
                    <li>Makes function dispatch predictable</li>
                  </ul>
                  <p class="text-xs opacity-60 mt-2">
                    This is different from <code class="font-mono bg-base-100 px-1 rounded">if</code> conditions,
                    where errors DO crash.
                  </p>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Guards in case / with -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Guards in case, cond, and with</h3>
            <button
              phx-click="toggle_case_guards"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_case_guards, do: "Hide", else: "Show Examples" %>
            </button>
          </div>

          <%= if @show_case_guards do %>
            <p class="text-xs opacity-60 mb-4">
              Guards are not limited to function heads. You can use them in
              <code class="font-mono bg-base-300 px-1 rounded">case</code>,
              <code class="font-mono bg-base-300 px-1 rounded">cond</code>, and
              <code class="font-mono bg-base-300 px-1 rounded">with</code> as well.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <!-- case -->
              <div class="bg-primary/10 border border-primary/30 rounded-lg p-4">
                <h4 class="font-bold text-primary text-sm mb-2">case with guards</h4>
                <div class="font-mono text-xs space-y-1">
                  <div>case value do</div>
                  <div class="ml-2">x when is_integer(x) and x &gt; 0 -&gt;</div>
                  <div class="ml-4 text-success">"positive integer"</div>
                  <div class="ml-2">x when is_integer(x) -&gt;</div>
                  <div class="ml-4 text-warning">"non-positive integer"</div>
                  <div class="ml-2">x when is_binary(x) -&gt;</div>
                  <div class="ml-4 text-info">"string"</div>
                  <div class="ml-2">_ -&gt;</div>
                  <div class="ml-4 text-error">"other"</div>
                  <div>end</div>
                </div>
              </div>

              <!-- with -->
              <div class="bg-secondary/10 border border-secondary/30 rounded-lg p-4">
                <h4 class="font-bold text-secondary text-sm mb-2">with guards</h4>
                <div class="font-mono text-xs space-y-1">
                  <div>with &lbrace;:ok, val&rbrace;</div>
                  <div class="ml-2">when is_integer(val) &lt;-</div>
                  <div class="ml-2">fetch_value() do</div>
                  <div class="ml-2 text-success">val * 2</div>
                  <div>end</div>
                </div>
                <p class="text-xs opacity-60 mt-2">
                  Guard ensures the matched value meets additional conditions.
                </p>
              </div>

              <!-- Function heads -->
              <div class="bg-accent/10 border border-accent/30 rounded-lg p-4">
                <h4 class="font-bold text-accent text-sm mb-2">Function heads</h4>
                <div class="font-mono text-xs space-y-1">
                  <div>def process(x)</div>
                  <div class="ml-2">when is_number(x)</div>
                  <div class="ml-2">and x &gt; 0 do</div>
                  <div class="ml-2 text-success"># positive number</div>
                  <div>end</div>
                </div>
                <p class="text-xs opacity-60 mt-2">
                  Most common place for guards.
                </p>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Custom Guard (defguard) -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Custom Guards with defguard</h3>
            <button
              phx-click="toggle_defguard"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_defguard, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_defguard do %>
            <p class="text-xs opacity-60 mb-4">
              You can define reusable guards with
              <code class="font-mono bg-base-300 px-1 rounded">defguard</code> and
              <code class="font-mono bg-base-300 px-1 rounded">defguardp</code>.
            </p>

            <div class="space-y-4">
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm">
                <div class="opacity-60"># Define a custom guard</div>
                <div>defmodule MyGuards do</div>
                <div class="ml-2">defguard is_positive(x) when is_number(x) and x &gt; 0</div>
                <div class="ml-2">defguard is_even(x) when is_integer(x) and rem(x, 2) == 0</div>
                <div class="ml-2">defguard is_adult(age) when is_integer(age) and age &gt;= 18</div>
                <div>end</div>
              </div>

              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm">
                <div class="opacity-60"># Use the custom guard</div>
                <div>import MyGuards</div>
                <div class="mt-1">def process(x) when is_positive(x) do</div>
                <div class="ml-2 text-success">"positive: &lbrace;&rbrace;#&lbrace;x&rbrace;"</div>
                <div>end</div>
              </div>

              <div class="alert alert-info text-sm">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                <div>
                  <div class="font-bold">defguard vs defguardp</div>
                  <span>
                    <code class="font-mono bg-base-100 px-1 rounded">defguard</code> is public (can be imported),
                    <code class="font-mono bg-base-100 px-1 rounded">defguardp</code> is private (module-only).
                    Custom guards can only use expressions that are allowed in regular guards.
                  </span>
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
              <span>
                <strong>Guards</strong> use <code class="font-mono bg-base-100 px-1 rounded">when</code>
                to add conditions beyond pattern matching:
                <code class="font-mono bg-base-100 px-1 rounded">def f(x) when is_integer(x)</code>
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>
                <strong>Limited expressions:</strong> Only a specific set of operators, type checks, and
                built-in functions are allowed. No custom functions or side effects.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>
                <strong>Silent failure:</strong> If a guard raises an error, it returns
                <code class="font-mono bg-base-100 px-1 rounded">false</code> instead of crashing.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>
                <strong>Multiple contexts:</strong> Guards work in function heads,
                <code class="font-mono bg-base-100 px-1 rounded">case</code>,
                <code class="font-mono bg-base-100 px-1 rounded">with</code>, and anonymous functions.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>
                <strong>Custom guards:</strong>
                <code class="font-mono bg-base-100 px-1 rounded">defguard is_positive(x) when is_number(x) and x &gt; 0</code>
                lets you define reusable guard macros.
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
    scenario = Enum.find(scenarios(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(selected_scenario: scenario)
     |> assign(test_value: nil)
     |> assign(matched_clause: nil)
     |> assign(test_result: nil)}
  end

  def handle_event("test_guard", %{"code" => code, "display" => display}, socket) do
    run_guard_test(socket, code, display)
  end

  def handle_event("test_custom_guard", %{"value" => value}, socket) do
    value = String.trim(value)

    if value == "" do
      {:noreply, socket}
    else
      run_guard_test(socket, value, value)
    end
  end

  def handle_event("toggle_guard_table", _params, socket) do
    {:noreply, assign(socket, show_guard_table: !socket.assigns.show_guard_table)}
  end

  def handle_event("toggle_silent_fail", _params, socket) do
    {:noreply, assign(socket, show_silent_fail: !socket.assigns.show_silent_fail)}
  end

  def handle_event("toggle_case_guards", _params, socket) do
    {:noreply, assign(socket, show_case_guards: !socket.assigns.show_case_guards)}
  end

  def handle_event("toggle_defguard", _params, socket) do
    {:noreply, assign(socket, show_defguard: !socket.assigns.show_defguard)}
  end

  # Helpers

  defp scenarios, do: @test_scenarios
  defp guard_functions, do: @guard_functions

  defp run_guard_test(socket, code, display) do
    scenario = socket.assigns.selected_scenario

    try do
      # Build the function clauses as an anonymous function
      clauses_code =
        scenario.clauses
        |> Enum.map(fn clause ->
          if clause.guard do
            "  x when #{clause.guard} -> {#{clause.id}, #{clause.body}}"
          else
            "  _x -> {#{clause.id}, #{clause.body}}"
          end
        end)
        |> Enum.join("\n")

      eval_code = "fn\n#{clauses_code}\nend.(#{code})"

      {result, _bindings} = Code.eval_string(eval_code)
      {clause_id, value} = result

      guard_explain =
        case Enum.at(scenario.clauses, clause_id) do
          %{guard: nil} -> "Matched the catch-all clause (no guard)."
          %{guard: guard} -> "Guard '#{guard}' evaluated to true for input #{display}."
        end

      {:noreply,
       socket
       |> assign(test_value: display)
       |> assign(matched_clause: clause_id)
       |> assign(custom_input: display)
       |> assign(test_result: %{ok: true, value: inspect(value), guard_explain: guard_explain})}
    rescue
      e ->
        {:noreply,
         socket
         |> assign(test_value: display)
         |> assign(matched_clause: nil)
         |> assign(custom_input: display)
         |> assign(test_result: %{ok: false, value: Exception.message(e), guard_explain: nil})}
    end
  end
end
