defmodule ElixirKatasWeb.ElixirKata17AnonymousFunctionsLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "basic",
      title: "Basic Anonymous Function",
      description: "The simplest fn: takes a name and returns a greeting.",
      code: "greet = fn name -> \"Hello, \#{name}!\" end",
      call_examples: [
        %{call: "greet.(\"Alice\")", result: "\"Hello, Alice!\""},
        %{call: "greet.(\"World\")", result: "\"Hello, World!\""}
      ],
      notes: "Anonymous functions use fn -> end syntax. Call them with the dot: fun.(args)"
    },
    %{
      id: "multi_arg",
      title: "Multiple Arguments",
      description: "Anonymous functions can take multiple arguments, separated by commas.",
      code: "add = fn a, b -> a + b end",
      call_examples: [
        %{call: "add.(3, 4)", result: "7"},
        %{call: "add.(10, 20)", result: "30"}
      ],
      notes: "Multiple args separated by commas, just like named functions."
    },
    %{
      id: "no_args",
      title: "Zero-Argument Function",
      description: "A function that takes no arguments. The parentheses are still required when calling.",
      code: "say_hi = fn -> \"Hi there!\" end",
      call_examples: [
        %{call: "say_hi.()", result: "\"Hi there!\""}
      ],
      notes: "Even with zero args, you must use the dot-parens syntax: fun.()"
    },
    %{
      id: "multi_clause",
      title: "Multi-Clause Anonymous Function",
      description: "Anonymous functions can have multiple clauses with pattern matching, just like named functions.",
      code: "status = fn\n  {:ok, val} -> \"Success: \#{val}\"\n  {:error, reason} -> \"Error: \#{reason}\"\n  _ -> \"Unknown\"\nend",
      call_examples: [
        %{call: "status.({:ok, 42})", result: "\"Success: 42\""},
        %{call: "status.({:error, \"not found\"})", result: "\"Error: not found\""},
        %{call: "status.(:something)", result: "\"Unknown\""}
      ],
      notes: "Each clause must have the same arity. Elixir tries clauses top-to-bottom (first match wins)."
    },
    %{
      id: "closure",
      title: "Closure (Capturing Variables)",
      description: "Anonymous functions capture variables from the surrounding scope. The captured value is frozen at definition time.",
      code: "multiplier = 3\ntriple = fn x -> x * multiplier end",
      call_examples: [
        %{call: "triple.(5)", result: "15"},
        %{call: "triple.(10)", result: "30"}
      ],
      notes: "The variable 'multiplier' is captured from the outer scope. Even if you rebind multiplier later, triple still uses 3."
    },
    %{
      id: "capture",
      title: "Capture Operator (&)",
      description: "The & operator provides shorthand for creating anonymous functions.",
      code: "double = &(&1 * 2)\nadd = &(&1 + &2)",
      call_examples: [
        %{call: "double.(5)", result: "10"},
        %{call: "add.(3, 7)", result: "10"}
      ],
      notes: "&1, &2, etc. refer to the first, second arguments. This is syntactic sugar for fn."
    }
  ]

  @closure_steps [
    %{
      step: 1,
      code: "x = 10",
      desc: "Bind x to 10 in the outer scope.",
      state: %{x: 10, f: nil},
      highlight: "outer"
    },
    %{
      step: 2,
      code: "doubler = fn -> x * 2 end",
      desc: "Define an anonymous function that captures x from the outer scope. The value of x (10) is 'closed over'.",
      state: %{x: 10, f: "fn -> x * 2 end (x=10)"},
      highlight: "capture"
    },
    %{
      step: 3,
      code: "doubler.()",
      desc: "Call the function. It uses the captured value of x (10), returning 20.",
      state: %{x: 10, f: "fn -> x * 2 end (x=10)", result: 20},
      highlight: "call"
    },
    %{
      step: 4,
      code: "x = 99",
      desc: "Rebind x to 99. But the closure still has the old value!",
      state: %{x: 99, f: "fn -> x * 2 end (x=10)"},
      highlight: "rebind"
    },
    %{
      step: 5,
      code: "doubler.()",
      desc: "Call again. Still returns 20! The closure captured x=10 at definition time. Rebinding x does NOT affect the closure.",
      state: %{x: 99, f: "fn -> x * 2 end (x=10)", result: 20},
      highlight: "frozen"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:selected_example, fn -> hd(@examples) end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:closure_step, fn -> 0 end)
     |> assign_new(:show_calling_syntax, fn -> false end)
     |> assign_new(:show_values_demo, fn -> false end)
     |> assign_new(:passed_fn, fn -> nil end)
     |> assign_new(:passed_fn_result, fn -> nil end)
     |> assign_new(:sandbox_input, fn -> "" end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Anonymous Functions</h2>
      <p class="text-sm opacity-70 mb-6">
        Anonymous functions in Elixir are first-class values created with
        <code class="font-mono bg-base-300 px-1 rounded">fn -&gt; end</code>.
        They can be stored in variables, passed as arguments, and returned from other functions.
        They also "close over" variables from their defining scope (closures).
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for ex <- examples() do %>
          <button
            phx-click="select_example"
            phx-target={@myself}
            phx-value-id={ex.id}
            class={"btn btn-sm " <> if(@selected_example.id == ex.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= ex.title %>
          </button>
        <% end %>
      </div>

      <!-- Selected Example Display -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm"><%= @selected_example.title %></h3>
            <span class="badge badge-info badge-sm"><%= length(@selected_example.call_examples) %> examples</span>
          </div>
          <p class="text-xs opacity-60 mb-4"><%= @selected_example.description %></p>

          <!-- Code Display -->
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4 whitespace-pre-wrap">
            <span class="opacity-50">iex&gt; </span><%= @selected_example.code %>
          </div>

          <!-- Call Examples -->
          <h4 class="text-xs font-bold opacity-60 mb-2">Calling the function:</h4>
          <div class="space-y-2 mb-4">
            <%= for call_ex <- @selected_example.call_examples do %>
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm flex items-center gap-3">
                <div class="flex-1">
                  <span class="opacity-50">iex&gt; </span><%= call_ex.call %>
                </div>
                <span class="opacity-30">&rArr;</span>
                <span class="text-success font-bold"><%= call_ex.result %></span>
              </div>
            <% end %>
          </div>

          <!-- Notes -->
          <div class="alert text-sm">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <span><%= @selected_example.notes %></span>
          </div>
        </div>
      </div>

      <!-- Calling Syntax: fn.() vs named -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Calling Syntax: fn.() vs Named Functions</h3>
            <button
              phx-click="toggle_calling_syntax"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_calling_syntax, do: "Hide", else: "Show Details" %>
            </button>
          </div>

          <%= if @show_calling_syntax do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Anonymous -->
              <div class="bg-primary/10 border border-primary/30 rounded-lg p-4">
                <h4 class="font-bold text-primary text-sm mb-2">Anonymous Function</h4>
                <div class="font-mono text-sm space-y-2">
                  <div class="bg-base-100 rounded p-2">
                    <div class="opacity-60"># Define</div>
                    <div>add = fn a, b -&gt; a + b end</div>
                  </div>
                  <div class="bg-base-100 rounded p-2">
                    <div class="opacity-60"># Call with dot notation</div>
                    <div>add<span class="text-primary font-bold">.</span>(3, 4)</div>
                    <div class="text-success"># =&gt; 7</div>
                  </div>
                </div>
                <p class="text-xs opacity-60 mt-2">
                  The <strong>dot</strong> is required to distinguish from a named function call.
                </p>
              </div>

              <!-- Named -->
              <div class="bg-secondary/10 border border-secondary/30 rounded-lg p-4">
                <h4 class="font-bold text-secondary text-sm mb-2">Named Function</h4>
                <div class="font-mono text-sm space-y-2">
                  <div class="bg-base-100 rounded p-2">
                    <div class="opacity-60"># Define in a module</div>
                    <div>def add(a, b), do: a + b</div>
                  </div>
                  <div class="bg-base-100 rounded p-2">
                    <div class="opacity-60"># Call without dot</div>
                    <div>add(3, 4)</div>
                    <div class="text-success"># =&gt; 7</div>
                  </div>
                </div>
                <p class="text-xs opacity-60 mt-2">
                  Named functions are called directly, no dot needed.
                </p>
              </div>
            </div>

            <div class="alert alert-warning text-sm mt-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-5 w-5" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
              <span>
                Common mistake: calling <code class="font-mono bg-base-100 px-1 rounded">add(3, 4)</code> when
                <code class="font-mono bg-base-100 px-1 rounded">add</code> is an anonymous function will fail with
                <code class="font-mono bg-base-100 px-1 rounded">CompileError</code>. Always use the dot!
              </span>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Closure Demo (Step-Through) -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Closure Behavior: Step-Through Demo</h3>
          <p class="text-xs opacity-60 mb-4">
            Anonymous functions capture variables from the scope where they are defined.
            Step through to see how closures freeze the captured value.
          </p>

          <!-- Steps -->
          <div class="space-y-2 mb-4">
            <%= for {step, idx} <- Enum.with_index(closure_steps()) do %>
              <div
                phx-click="closure_goto"
                phx-target={@myself}
                phx-value-step={idx}
                class={"rounded-lg p-3 border-2 cursor-pointer transition-all " <>
                  cond do
                    idx == @closure_step and step.highlight == "frozen" -> "border-warning bg-warning/10"
                    idx == @closure_step -> "border-primary bg-primary/10"
                    idx < @closure_step -> "border-base-300 bg-base-100 opacity-70"
                    true -> "border-base-300 bg-base-100 opacity-40"
                  end}
              >
                <div class="flex items-start gap-3">
                  <div class={"flex-shrink-0 w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold " <>
                    if(idx <= @closure_step, do: "bg-primary text-primary-content", else: "bg-base-300 text-base-content/50")}>
                    <%= step.step %>
                  </div>
                  <div class="flex-1 min-w-0">
                    <div class="font-mono text-sm whitespace-pre-wrap"><%= step.code %></div>
                    <%= if idx <= @closure_step do %>
                      <div class="mt-1 text-xs opacity-70"><%= step.desc %></div>
                      <%= if Map.has_key?(step.state, :result) do %>
                        <div class="mt-1 font-mono text-xs font-bold text-success">
                          &rArr; <%= step.state.result %>
                        </div>
                      <% end %>
                    <% end %>
                  </div>
                  <%= if idx <= @closure_step do %>
                    <span class={"badge badge-sm " <>
                      case step.highlight do
                        "frozen" -> "badge-warning"
                        "rebind" -> "badge-error"
                        "capture" -> "badge-info"
                        _ -> "badge-success"
                      end}>
                      <%= case step.highlight do
                        "outer" -> "bind"
                        "capture" -> "closure"
                        "call" -> "call"
                        "rebind" -> "rebind"
                        "frozen" -> "still 20!"
                        _ -> ""
                      end %>
                    </span>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Current State -->
          <% active_closure = Enum.at(closure_steps(), @closure_step) %>
          <div class="bg-base-300 rounded-lg p-3 mb-4">
            <h4 class="text-xs font-bold opacity-60 mb-2">Current Scope After Step <%= @closure_step + 1 %></h4>
            <div class="flex flex-wrap gap-3">
              <div class="flex items-center gap-1 bg-base-100 rounded-lg px-3 py-1.5 border border-base-300">
                <span class="font-mono text-sm text-info font-bold">x</span>
                <span class="opacity-30">=</span>
                <span class={"font-mono text-sm font-bold " <> if(active_closure.highlight == "rebind" or active_closure.highlight == "frozen", do: "text-warning", else: "text-success")}>
                  <%= active_closure.state.x %>
                </span>
              </div>
              <%= if active_closure.state.f do %>
                <div class="flex items-center gap-1 bg-base-100 rounded-lg px-3 py-1.5 border border-base-300">
                  <span class="font-mono text-sm text-info font-bold">doubler</span>
                  <span class="opacity-30">=</span>
                  <span class="font-mono text-xs text-accent"><%= active_closure.state.f %></span>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Navigation -->
          <div class="flex gap-2">
            <button
              phx-click="closure_prev"
              phx-target={@myself}
              disabled={@closure_step <= 0}
              class="btn btn-sm btn-outline"
            >
              &larr; Previous
            </button>
            <button
              phx-click="closure_next"
              phx-target={@myself}
              disabled={@closure_step >= length(closure_steps()) - 1}
              class="btn btn-sm btn-primary"
            >
              Next &rarr;
            </button>
            <button
              phx-click="closure_reset"
              phx-target={@myself}
              class="btn btn-sm btn-ghost"
            >
              Reset
            </button>
          </div>
        </div>
      </div>

      <!-- Functions Are Values Demo -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Functions Are Values</h3>
            <button
              phx-click="toggle_values_demo"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_values_demo, do: "Hide", else: "Show Demo" %>
            </button>
          </div>

          <%= if @show_values_demo do %>
            <p class="text-xs opacity-60 mb-4">
              Anonymous functions are values just like integers or strings. You can store them in
              variables, put them in lists, pass them to other functions, and return them.
            </p>

            <div class="space-y-4">
              <!-- Store in data structures -->
              <div class="bg-base-300 rounded-lg p-3">
                <h4 class="text-xs font-bold opacity-60 mb-2">Stored in a list</h4>
                <div class="font-mono text-sm space-y-1">
                  <div><span class="opacity-50">iex&gt; </span>ops = [fn a, b -&gt; a + b end, fn a, b -&gt; a * b end]</div>
                  <div><span class="opacity-50">iex&gt; </span>Enum.at(ops, 0).(3, 4)</div>
                  <div class="text-success"># =&gt; 7</div>
                  <div><span class="opacity-50">iex&gt; </span>Enum.at(ops, 1).(3, 4)</div>
                  <div class="text-success"># =&gt; 12</div>
                </div>
              </div>

              <!-- Pass to higher-order functions -->
              <div class="bg-base-300 rounded-lg p-3">
                <h4 class="text-xs font-bold opacity-60 mb-2">Passed to Enum.map</h4>
                <div class="font-mono text-sm space-y-1">
                  <div><span class="opacity-50">iex&gt; </span>double = fn x -&gt; x * 2 end</div>
                  <div><span class="opacity-50">iex&gt; </span>Enum.map([1, 2, 3], double)</div>
                  <div class="text-success"># =&gt; [2, 4, 6]</div>
                </div>
              </div>

              <!-- Interactive: choose a function to apply -->
              <div class="bg-primary/10 border border-primary/30 rounded-lg p-4">
                <h4 class="font-bold text-primary text-sm mb-2">Try It: Pass a Function</h4>
                <p class="text-xs opacity-60 mb-3">
                  Select a function to apply to the list [1, 2, 3, 4, 5] using Enum.map:
                </p>
                <div class="flex flex-wrap gap-2 mb-3">
                  <button
                    phx-click="apply_fn"
                    phx-target={@myself}
                    phx-value-fn="double"
                    class={"btn btn-sm " <> if(@passed_fn == "double", do: "btn-primary", else: "btn-outline")}
                  >
                    fn x -&gt; x * 2 end
                  </button>
                  <button
                    phx-click="apply_fn"
                    phx-target={@myself}
                    phx-value-fn="square"
                    class={"btn btn-sm " <> if(@passed_fn == "square", do: "btn-primary", else: "btn-outline")}
                  >
                    fn x -&gt; x * x end
                  </button>
                  <button
                    phx-click="apply_fn"
                    phx-target={@myself}
                    phx-value-fn="negate"
                    class={"btn btn-sm " <> if(@passed_fn == "negate", do: "btn-primary", else: "btn-outline")}
                  >
                    fn x -&gt; -x end
                  </button>
                  <button
                    phx-click="apply_fn"
                    phx-target={@myself}
                    phx-value-fn="to_string"
                    class={"btn btn-sm " <> if(@passed_fn == "to_string", do: "btn-primary", else: "btn-outline")}
                  >
                    fn x -&gt; to_string(x) end
                  </button>
                </div>

                <%= if @passed_fn_result do %>
                  <div class="bg-base-100 rounded-lg p-3 font-mono text-sm">
                    <div><span class="opacity-50">iex&gt; </span>Enum.map([1, 2, 3, 4, 5], <span class="text-info"><%= @passed_fn_result.fn_display %></span>)</div>
                    <div class="text-success font-bold mt-1">&rArr; <%= @passed_fn_result.result %></div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Interactive Sandbox -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive Sandbox</h3>
          <p class="text-xs opacity-60 mb-4">
            Try writing and calling your own anonymous functions. Enter any valid Elixir expression.
          </p>

          <form phx-submit="sandbox_eval" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Elixir Expression</span></label>
              <input
                type="text"
                name="code"
                value={@sandbox_input}
                placeholder="(fn x -> x * 2 end).(5)"
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Quick examples:</span>
            <button phx-click="sandbox_quick" phx-target={@myself} phx-value-code="(fn x -> x * 2 end).(5)" class="btn btn-xs btn-outline">
              (fn x -&gt; x * 2 end).(5)
            </button>
            <button phx-click="sandbox_quick" phx-target={@myself} phx-value-code="(fn x, y -> x + y end).(3, 7)" class="btn btn-xs btn-outline">
              (fn x, y -&gt; x + y end).(3, 7)
            </button>
            <button phx-click="sandbox_quick" phx-target={@myself} phx-value-code="(&(&1 * &1)).(6)" class="btn btn-xs btn-outline">
              (&amp;(&amp;1 * &amp;1)).(6)
            </button>
            <button phx-click="sandbox_quick" phx-target={@myself} phx-value-code="(fn {:ok, v} -> v; {:error, _} -> :fail end).({:ok, 42})" class="btn btn-xs btn-outline">
              multi-clause
            </button>
          </div>

          <!-- Result -->
          <%= if @sandbox_result do %>
            <div class={"alert text-sm " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @sandbox_result.code %></div>
                <div class="font-mono font-bold mt-1"><%= @sandbox_result.value %></div>
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
                <strong>Syntax:</strong>
                <code class="font-mono bg-base-100 px-1 rounded">fn args -&gt; body end</code> creates an anonymous function.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>
                <strong>Calling:</strong> Use the dot:
                <code class="font-mono bg-base-100 px-1 rounded">fun.(args)</code>. The dot distinguishes anonymous from named function calls.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>
                <strong>Closures:</strong> Anonymous functions capture variables from the enclosing scope.
                The captured value is frozen at definition time.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>
                <strong>Multi-clause:</strong> Use pattern matching with multiple clauses:
                <code class="font-mono bg-base-100 px-1 rounded">fn &lbrace;:ok, v&rbrace; -&gt; v; &lbrace;:error, _&rbrace; -&gt; nil end</code>
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>
                <strong>First-class values:</strong> Functions can be stored in variables, passed as arguments, put in lists/maps, and returned from other functions.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">6</span>
              <span>
                <strong>Capture operator:</strong>
                <code class="font-mono bg-base-100 px-1 rounded">&amp;(&amp;1 + &amp;2)</code> is shorthand for
                <code class="font-mono bg-base-100 px-1 rounded">fn a, b -&gt; a + b end</code>
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
    example = Enum.find(examples(), &(&1.id == id))
    {:noreply, assign(socket, selected_example: example)}
  end

  def handle_event("toggle_calling_syntax", _params, socket) do
    {:noreply, assign(socket, show_calling_syntax: !socket.assigns.show_calling_syntax)}
  end

  def handle_event("toggle_values_demo", _params, socket) do
    {:noreply, assign(socket, show_values_demo: !socket.assigns.show_values_demo)}
  end

  def handle_event("closure_goto", %{"step" => step_str}, socket) do
    step = String.to_integer(step_str)
    {:noreply, assign(socket, closure_step: step)}
  end

  def handle_event("closure_next", _params, socket) do
    max_step = length(closure_steps()) - 1
    new_step = min(socket.assigns.closure_step + 1, max_step)
    {:noreply, assign(socket, closure_step: new_step)}
  end

  def handle_event("closure_prev", _params, socket) do
    new_step = max(socket.assigns.closure_step - 1, 0)
    {:noreply, assign(socket, closure_step: new_step)}
  end

  def handle_event("closure_reset", _params, socket) do
    {:noreply, assign(socket, closure_step: 0)}
  end

  def handle_event("apply_fn", %{"fn" => fn_name}, socket) do
    list = [1, 2, 3, 4, 5]

    {fn_display, result} =
      case fn_name do
        "double" ->
          {"fn x -> x * 2 end", inspect(Enum.map(list, &(&1 * 2)))}

        "square" ->
          {"fn x -> x * x end", inspect(Enum.map(list, &(&1 * &1)))}

        "negate" ->
          {"fn x -> -x end", inspect(Enum.map(list, &(-&1)))}

        "to_string" ->
          {"fn x -> to_string(x) end", inspect(Enum.map(list, &to_string/1))}

        _ ->
          {"unknown", "error"}
      end

    {:noreply,
     socket
     |> assign(passed_fn: fn_name)
     |> assign(passed_fn_result: %{fn_display: fn_display, result: result})}
  end

  def handle_event("sandbox_eval", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(sandbox_input: code)
     |> assign(sandbox_result: result)}
  end

  def handle_event("sandbox_quick", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(sandbox_input: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp examples, do: @examples
  defp closure_steps, do: @closure_steps

  defp evaluate_code(code) do
    code = String.trim(code)

    if code == "" do
      nil
    else
      try do
        {result, _bindings} = Code.eval_string(code)
        %{ok: true, code: code, value: inspect(result)}
      rescue
        e ->
          %{ok: false, code: code, value: Exception.message(e)}
      end
    end
  end
end
