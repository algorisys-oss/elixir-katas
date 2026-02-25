defmodule ElixirKatasWeb.ElixirKata25CaseExpressionsLive do
  use ElixirKatasWeb, :live_component

  @case_examples [
    %{
      id: "tuples",
      title: "Matching Tuples",
      description: "case is commonly used to match on tagged tuples like {:ok, value} and {:error, reason}.",
      code: ~s|case File.read("hello.txt") do\n  {:ok, content} -> "Got: \#{content}"\n  {:error, reason} -> "Failed: \#{reason}"\nend|,
      clauses: [
        %{id: 0, pattern: ~s|{:ok, content}|, body: ~s|"Got: \#{content}"|, guard: nil},
        %{id: 1, pattern: ~s|{:error, reason}|, body: ~s|"Failed: \#{reason}"|, guard: nil}
      ],
      test_values: [
        %{display: ~s|{:ok, "hello"}|, code: ~s|{:ok, "hello"}|},
        %{display: ~s|{:error, :enoent}|, code: ~s|{:error, :enoent}|},
        %{display: ~s|{:ok, ""}|, code: ~s|{:ok, ""}|},
        %{display: ~s|{:error, :eacces}|, code: ~s|{:error, :eacces}|}
      ]
    },
    %{
      id: "lists",
      title: "Matching Lists",
      description: "Pattern match on lists to handle empty, single-element, and multi-element cases.",
      code: "case my_list do\n  [] -> \"empty\"\n  [x] -> \"single: \#{x}\"\n  [h | _t] -> \"first: \#{h}\"\nend",
      clauses: [
        %{id: 0, pattern: "[]", body: ~s|"empty"|, guard: nil},
        %{id: 1, pattern: "[x]", body: ~s|"single: \#{x}"|, guard: nil},
        %{id: 2, pattern: "[h | _t]", body: ~s|"first: \#{h}"|, guard: nil}
      ],
      test_values: [
        %{display: "[]", code: "[]"},
        %{display: "[42]", code: "[42]"},
        %{display: "[1, 2, 3]", code: "[1, 2, 3]"},
        %{display: ~s|["a", "b"]|, code: ~s|["a", "b"]|}
      ]
    },
    %{
      id: "atoms",
      title: "Matching Atoms",
      description: "Atoms are commonly used as status values, and case makes dispatching on them easy.",
      code: "case status do\n  :ok -> \"All good!\"\n  :warning -> \"Be careful\"\n  :error -> \"Something broke\"\n  _ -> \"Unknown status\"\nend",
      clauses: [
        %{id: 0, pattern: ":ok", body: ~s|"All good!"|, guard: nil},
        %{id: 1, pattern: ":warning", body: ~s|"Be careful"|, guard: nil},
        %{id: 2, pattern: ":error", body: ~s|"Something broke"|, guard: nil},
        %{id: 3, pattern: "_", body: ~s|"Unknown status"|, guard: nil}
      ],
      test_values: [
        %{display: ":ok", code: ":ok"},
        %{display: ":warning", code: ":warning"},
        %{display: ":error", code: ":error"},
        %{display: ":info", code: ":info"},
        %{display: ":debug", code: ":debug"}
      ]
    },
    %{
      id: "guards",
      title: "Case with Guards",
      description: "Guards in case clauses let you add conditions beyond structural matching.",
      code: "case value do\n  x when is_integer(x) and x > 0 -> \"positive int\"\n  x when is_integer(x) -> \"non-positive int\"\n  x when is_binary(x) -> \"string\"\n  _ -> \"other\"\nend",
      clauses: [
        %{id: 0, pattern: "x", body: ~s|"positive int"|, guard: "is_integer(x) and x > 0"},
        %{id: 1, pattern: "x", body: ~s|"non-positive int"|, guard: "is_integer(x)"},
        %{id: 2, pattern: "x", body: ~s|"string"|, guard: "is_binary(x)"},
        %{id: 3, pattern: "_", body: ~s|"other"|, guard: nil}
      ],
      test_values: [
        %{display: "42", code: "42"},
        %{display: "0", code: "0"},
        %{display: "-5", code: "-5"},
        %{display: ~s|"hello"|, code: ~s|"hello"|},
        %{display: ":atom", code: ":atom"},
        %{display: "[1, 2]", code: "[1, 2]"}
      ]
    },
    %{
      id: "maps",
      title: "Matching Maps",
      description: "Partial map matching in case extracts values and matches on specific keys.",
      code: ~s|case user do\n  %{role: :admin, name: name} -> "Admin: \#{name}"\n  %{role: :mod, name: name} -> "Mod: \#{name}"\n  %{name: name} -> "User: \#{name}"\n  _ -> "Unknown"\nend|,
      clauses: [
        %{id: 0, pattern: ~s|%{role: :admin, name: name}|, body: ~s|"Admin: \#{name}"|, guard: nil},
        %{id: 1, pattern: ~s|%{role: :mod, name: name}|, body: ~s|"Mod: \#{name}"|, guard: nil},
        %{id: 2, pattern: ~s|%{name: name}|, body: ~s|"User: \#{name}"|, guard: nil},
        %{id: 3, pattern: "_", body: ~s|"Unknown"|, guard: nil}
      ],
      test_values: [
        %{display: ~s|%{role: :admin, name: "Alice"}|, code: ~s|%{role: :admin, name: "Alice"}|},
        %{display: ~s|%{role: :mod, name: "Bob"}|, code: ~s|%{role: :mod, name: "Bob"}|},
        %{display: ~s|%{name: "Charlie"}|, code: ~s|%{name: "Charlie"}|},
        %{display: "%{}", code: "%{}"},
        %{display: ~s|%{role: :user, name: "Dana"}|, code: ~s|%{role: :user, name: "Dana"}|}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@case_examples) end)
     |> assign_new(:test_value, fn -> nil end)
     |> assign_new(:matched_clause, fn -> nil end)
     |> assign_new(:test_result, fn -> nil end)
     |> assign_new(:custom_input, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:show_first_match, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Case Expressions</h2>
      <p class="text-sm opacity-70 mb-6">
        <code class="font-mono bg-base-300 px-1 rounded">case</code> matches a value against a series of
        patterns. The first pattern that matches wins. You can add
        <code class="font-mono bg-base-300 px-1 rounded">when</code> guards for extra conditions.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for example <- case_examples() do %>
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

      <!-- Interactive Case Tester -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_example.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @active_example.description %></p>

          <!-- Clauses Display with Match Highlighting -->
          <div class="flex items-start gap-3 mb-4">
            <div class="flex flex-col items-center">
              <span class="text-xs opacity-40 mb-1">match</span>
              <div class="w-0.5 bg-warning flex-1 min-h-[2rem]"></div>
              <span class="text-xs opacity-40 mt-1">&darr;</span>
            </div>

            <div class="flex-1 space-y-2">
              <div class="font-mono text-sm bg-base-300 rounded-lg p-2 opacity-60">
                case <span class="text-info"><%= if @test_value, do: @test_value, else: "value" %></span> do
              </div>
              <%= for clause <- @active_example.clauses do %>
                <div class={"rounded-lg p-3 border-2 transition-all " <>
                  cond do
                    @matched_clause == clause.id -> "border-success bg-success/15 shadow-lg"
                    @matched_clause != nil and clause.id < @matched_clause -> "border-base-300 bg-base-100 opacity-40"
                    @matched_clause != nil -> "border-base-300 bg-base-100 opacity-30"
                    true -> "border-base-300 bg-base-100"
                  end}>
                  <div class="flex items-center justify-between">
                    <div class="font-mono text-sm">
                      <span class="font-bold text-accent"><%= clause.pattern %></span>
                      <%= if clause.guard do %>
                        <span class="opacity-50"> when </span>
                        <span class="text-warning"><%= clause.guard %></span>
                      <% end %>
                      <span class="opacity-50"> -&gt; </span>
                      <span><%= clause.body %></span>
                    </div>
                    <div class="flex items-center gap-2">
                      <%= if clause.guard do %>
                        <span class="badge badge-warning badge-xs">guard</span>
                      <% end %>
                      <%= if clause.pattern == "_" do %>
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
              <div class="font-mono text-sm bg-base-300 rounded-lg p-2 opacity-60">end</div>
            </div>
          </div>

          <!-- Test Value Buttons -->
          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Test values:</span>
            <%= for tv <- @active_example.test_values do %>
              <button
                phx-click="test_case"
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
          <form phx-submit="test_custom_case" phx-target={@myself} class="flex gap-2 items-end mb-4">
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
                <div class="font-mono text-xs opacity-60">Input: <%= @test_value %></div>
                <div class="font-mono font-bold mt-1">&rArr; <%= @test_result.value %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- First-Match-Wins Demonstration -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">First-Match-Wins Behavior</h3>
            <button
              phx-click="toggle_first_match"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_first_match, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_first_match do %>
            <p class="text-xs opacity-60 mb-4">
              Elixir tries each clause top-to-bottom and uses the <strong>first</strong> one that matches.
              Clause order matters! More specific patterns should come before general ones.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <h4 class="font-bold text-success text-sm mb-2">Correct ordering</h4>
                <div class="font-mono text-sm space-y-1 bg-base-100 rounded p-3">
                  <div>case list do</div>
                  <div class="ml-2">[] -&gt; <span class="text-success">"empty"</span></div>
                  <div class="ml-2">[x] -&gt; <span class="text-success">"one: &lbrace;&rbrace;#&lbrace;x&rbrace;"</span></div>
                  <div class="ml-2">[_h | _t] -&gt; <span class="text-success">"many"</span></div>
                  <div>end</div>
                </div>
                <p class="text-xs mt-2 opacity-70">
                  Specific patterns first, catch-all last. Each pattern gets a chance to match.
                </p>
              </div>

              <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                <h4 class="font-bold text-error text-sm mb-2">Wrong ordering</h4>
                <div class="font-mono text-sm space-y-1 bg-base-100 rounded p-3">
                  <div>case list do</div>
                  <div class="ml-2">[_h | _t] -&gt; <span class="text-warning">"many"</span>
                    <span class="text-error text-xs ml-2">&larr; matches EVERYTHING</span>
                  </div>
                  <div class="ml-2 opacity-30">[] -&gt; "empty"</div>
                  <div class="ml-2 opacity-30">[x] -&gt; "one"</div>
                  <div>end</div>
                </div>
                <p class="text-xs mt-2 opacity-70">
                  The general pattern [_h | _t] matches any non-empty list, so [x] never runs.
                  The compiler will warn about unreachable clauses.
                </p>
              </div>
            </div>

            <div class="alert alert-info text-sm mt-4">
              <div>
                <div class="font-bold">Compiler warnings help!</div>
                <span>
                  Elixir warns you when a clause can never be reached due to a
                  more general pattern above it. Always pay attention to these warnings.
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own Case Expression</h3>
          <p class="text-xs opacity-60 mb-4">
            Write a complete <code class="font-mono bg-base-300 px-1 rounded">case</code> expression.
          </p>

          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <textarea
                name="code"
                rows="5"
                class="textarea textarea-bordered font-mono text-sm"
                placeholder={"case {:ok, 42} do\n  {:ok, n} when n > 0 -> \"positive: \#{n}\"\n  {:ok, n} -> \"non-positive: \#{n}\"\n  {:error, _} -> \"error\"\nend"}
                autocomplete="off"
              ><%= @sandbox_code %></textarea>
            </div>
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
              <span class="text-xs opacity-50 self-center">Write any case expression to see the result</span>
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
                <strong>case</strong> matches a value against patterns, executing the body of the
                <strong>first</strong> matching clause.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>
                Patterns in case use the same rules as the
                <code class="font-mono bg-base-100 px-1 rounded">=</code> match operator:
                tuples, lists, maps, literals, pins, and variables all work.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>
                Add <code class="font-mono bg-base-100 px-1 rounded">when</code> guards to clauses
                for extra conditions:
                <code class="font-mono bg-base-100 px-1 rounded">x when is_integer(x) and x &gt; 0</code>
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>
                <strong>Order matters</strong> &mdash; put specific patterns before general ones.
                Always include a <code class="font-mono bg-base-100 px-1 rounded">_</code> catch-all
                to avoid MatchError.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>
                <code class="font-mono bg-base-100 px-1 rounded">case</code> returns a value &mdash;
                you can bind the result:
                <code class="font-mono bg-base-100 px-1 rounded">result = case ... end</code>
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
    example = Enum.find(case_examples(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_example: example)
     |> assign(test_value: nil)
     |> assign(matched_clause: nil)
     |> assign(test_result: nil)}
  end

  def handle_event("test_case", %{"code" => code, "display" => display}, socket) do
    run_case_test(socket, code, display)
  end

  def handle_event("test_custom_case", %{"value" => value}, socket) do
    value = String.trim(value)

    if value == "" do
      {:noreply, socket}
    else
      run_case_test(socket, value, value)
    end
  end

  def handle_event("toggle_first_match", _params, socket) do
    {:noreply, assign(socket, show_first_match: !socket.assigns.show_first_match)}
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

  defp case_examples, do: @case_examples

  defp sandbox_examples do
    [
      {"tagged tuple", ~s|case {:ok, 42} do\n  {:ok, n} when n > 0 -> "positive: \#{n}"\n  {:ok, n} -> "got: \#{n}"\n  {:error, _} -> "error"\nend|},
      {"http status", ~s|case 404 do\n  200 -> "OK"\n  301 -> "Moved"\n  404 -> "Not Found"\n  500 -> "Server Error"\n  _ -> "Other"\nend|},
      {"nested match", ~s|case {:user, %{name: "Alice", age: 30}} do\n  {:user, %{name: name, age: age}} when age >= 18 -> "\#{name} is an adult"\n  {:user, %{name: name}} -> "\#{name} is a minor"\n  _ -> "unknown"\nend|}
    ]
  end

  defp run_case_test(socket, code, display) do
    example = socket.assigns.active_example

    clauses_code =
      example.clauses
      |> Enum.map(fn clause ->
        if clause.guard do
          "  #{clause.pattern} when #{clause.guard} -> {#{clause.id}, #{clause.body}}"
        else
          "  #{clause.pattern} -> {#{clause.id}, #{clause.body}}"
        end
      end)
      |> Enum.join("\n")

    eval_code = "case #{code} do\n#{clauses_code}\nend"

    try do
      {result, _bindings} = Code.eval_string(eval_code)
      {clause_id, value} = result

      {:noreply,
       socket
       |> assign(test_value: display)
       |> assign(matched_clause: clause_id)
       |> assign(custom_input: display)
       |> assign(test_result: %{ok: true, value: inspect(value)})}
    rescue
      e ->
        {:noreply,
         socket
         |> assign(test_value: display)
         |> assign(matched_clause: nil)
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
