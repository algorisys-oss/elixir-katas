defmodule ElixirKatasWeb.ElixirKata18NamedFunctionsLive do
  use ElixirKatasWeb, :live_component

  @modules [
    %{
      id: "greeter",
      name: "Greeter",
      moduledoc: "A module for greeting people in different ways.",
      functions: [
        %{
          id: "hello_1",
          name: "hello",
          arity: 1,
          visibility: :public,
          doc: "Greets a person by name.",
          head: "def hello(name)",
          body: "\"Hello, \#{name}!\"",
          clauses: [
            %{head: "hello(name)", body: "\"Hello, \#{name}!\"", guard: nil}
          ],
          test_inputs: ["\"Alice\"", "\"Bob\"", "\"World\""]
        },
        %{
          id: "hello_2",
          name: "hello",
          arity: 2,
          visibility: :public,
          doc: "Greets a person with a custom greeting.",
          head: "def hello(name, greeting)",
          body: "\"\#{greeting}, \#{name}!\"",
          clauses: [
            %{head: "hello(name, greeting)", body: "\"\#{greeting}, \#{name}!\"", guard: nil}
          ],
          test_inputs: ["\"Alice\", \"Hi\"", "\"Bob\", \"Hey\""]
        },
        %{
          id: "formal_1",
          name: "formal",
          arity: 1,
          visibility: :public,
          doc: "Provides a formal greeting.",
          head: "def formal(name)",
          body: "\"Good day, \#{capitalize(name)}\"",
          clauses: [
            %{head: "formal(name)", body: "\"Good day, \#{capitalize(name)}\"", guard: nil}
          ],
          test_inputs: ["\"alice\"", "\"bob\""]
        },
        %{
          id: "capitalize_1",
          name: "capitalize",
          arity: 1,
          visibility: :private,
          doc: "Capitalizes a name. Private helper, not callable from outside.",
          head: "defp capitalize(name)",
          body: "String.capitalize(name)",
          clauses: [
            %{head: "capitalize(name)", body: "String.capitalize(name)", guard: nil}
          ],
          test_inputs: ["\"alice\""]
        }
      ]
    },
    %{
      id: "math_utils",
      name: "MathUtils",
      moduledoc: "Basic math utilities showing arity and multi-clause functions.",
      functions: [
        %{
          id: "sum_1",
          name: "sum",
          arity: 1,
          visibility: :public,
          doc: "Sums all elements in a list.",
          head: "def sum(list)",
          body: "Enum.sum(list)",
          clauses: [
            %{head: "sum(list)", body: "Enum.sum(list)", guard: nil}
          ],
          test_inputs: ["[1, 2, 3]", "[10, 20, 30]"]
        },
        %{
          id: "sum_2",
          name: "sum",
          arity: 2,
          visibility: :public,
          doc: "Adds two numbers.",
          head: "def sum(a, b)",
          body: "a + b",
          clauses: [
            %{head: "sum(a, b)", body: "a + b", guard: nil}
          ],
          test_inputs: ["3, 4", "10, 20"]
        },
        %{
          id: "factorial_1",
          name: "factorial",
          arity: 1,
          visibility: :public,
          doc: "Computes factorial using multi-clause recursion with pattern matching.",
          head: "def factorial(n)",
          body: "(see clauses)",
          clauses: [
            %{head: "factorial(0)", body: "1", guard: nil},
            %{head: "factorial(n)", body: "n * factorial(n - 1)", guard: "n > 0"}
          ],
          test_inputs: ["0", "1", "5", "10"]
        },
        %{
          id: "clamp_3",
          name: "clamp",
          arity: 3,
          visibility: :private,
          doc: "Clamps a value between min and max. Private helper function.",
          head: "defp clamp(val, min_val, max_val)",
          body: "min(max(val, min_val), max_val)",
          clauses: [
            %{head: "clamp(val, min_val, max_val)", body: "min(max(val, min_val), max_val)", guard: nil}
          ],
          test_inputs: ["5, 1, 10", "15, 1, 10", "-3, 0, 100"]
        }
      ]
    },
    %{
      id: "shape",
      name: "Shape",
      moduledoc: "Demonstrates multi-clause named functions with pattern matching.",
      functions: [
        %{
          id: "area_1",
          name: "area",
          arity: 1,
          visibility: :public,
          doc: "Calculates area for different shapes using pattern matching on tuples.",
          head: "def area(shape)",
          body: "(see clauses)",
          clauses: [
            %{head: "area({:circle, r})", body: "3.14159 * r * r", guard: nil},
            %{head: "area({:rectangle, w, h})", body: "w * h", guard: nil},
            %{head: "area({:triangle, b, h})", body: "0.5 * b * h", guard: nil},
            %{head: "area(_)", body: "{:error, :unknown_shape}", guard: nil}
          ],
          test_inputs: ["{:circle, 5}", "{:rectangle, 4, 6}", "{:triangle, 3, 8}", "{:hexagon, 3}"]
        },
        %{
          id: "describe_1",
          name: "describe",
          arity: 1,
          visibility: :public,
          doc: "Returns a human-readable description of a shape.",
          head: "def describe(shape)",
          body: "(see clauses)",
          clauses: [
            %{head: "describe({:circle, r})", body: "\"Circle with radius \#{r}\"", guard: nil},
            %{head: "describe({:rectangle, w, h})", body: "\"Rectangle \#{w}x\#{h}\"", guard: nil},
            %{head: "describe(other)", body: "\"Unknown shape: \#{inspect(other)}\"", guard: nil}
          ],
          test_inputs: ["{:circle, 5}", "{:rectangle, 4, 6}", ":triangle"]
        },
        %{
          id: "valid_1",
          name: "valid?",
          arity: 1,
          visibility: :private,
          doc: "Checks if dimensions are positive. Private validation helper.",
          head: "defp valid?(shape)",
          body: "(see clauses)",
          clauses: [
            %{head: "valid?({:circle, r})", body: "r > 0", guard: "r > 0"},
            %{head: "valid?({:rectangle, w, h})", body: "w > 0 and h > 0", guard: nil},
            %{head: "valid?(_)", body: "false", guard: nil}
          ],
          test_inputs: ["{:circle, 5}", "{:circle, -1}", "{:rectangle, 3, 0}"]
        }
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:current_module, fn -> hd(@modules) end)
     |> assign_new(:selected_fn, fn -> hd(hd(@modules).functions) end)
     |> assign_new(:test_input, fn -> "" end)
     |> assign_new(:test_result, fn -> nil end)
     |> assign_new(:show_arity_explorer, fn -> false end)
     |> assign_new(:show_dispatch_demo, fn -> false end)
     |> assign_new(:dispatch_input, fn -> nil end)
     |> assign_new(:dispatch_matched, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Named Functions &amp; Modules</h2>
      <p class="text-sm opacity-70 mb-6">
        Named functions live inside modules, defined with
        <code class="font-mono bg-base-300 px-1 rounded">def</code> (public) or
        <code class="font-mono bg-base-300 px-1 rounded">defp</code> (private).
        Functions are identified by their name <em>and</em> arity (number of arguments).
        <code class="font-mono bg-base-300 px-1 rounded">hello/1</code> and
        <code class="font-mono bg-base-300 px-1 rounded">hello/2</code> are different functions.
      </p>

      <!-- Module Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for mod <- modules() do %>
          <button
            phx-click="select_module"
            phx-target={@myself}
            phx-value-id={mod.id}
            class={"btn btn-sm " <> if(@current_module.id == mod.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= mod.name %>
          </button>
        <% end %>
      </div>

      <!-- Module Display -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">
              defmodule <%= @current_module.name %>
            </h3>
            <div class="flex gap-2">
              <span class="badge badge-info badge-sm">
                <%= length(@current_module.functions) %> functions
              </span>
              <span class="badge badge-success badge-sm">
                <%= Enum.count(@current_module.functions, &(&1.visibility == :public)) %> public
              </span>
              <span class="badge badge-warning badge-sm">
                <%= Enum.count(@current_module.functions, &(&1.visibility == :private)) %> private
              </span>
            </div>
          </div>

          <!-- Module Doc -->
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <span class="opacity-50">@moduledoc """</span>
            <div class="ml-2 text-info"><%= @current_module.moduledoc %></div>
            <span class="opacity-50">"""</span>
          </div>

          <!-- Function List -->
          <div class="space-y-2">
            <%= for fun <- @current_module.functions do %>
              <div
                phx-click="select_fn"
                phx-target={@myself}
                phx-value-fn_id={fun.id}
                class={"rounded-lg p-3 border-2 cursor-pointer transition-all " <>
                  if(@selected_fn.id == fun.id, do: "border-primary bg-primary/10", else: "border-base-300 bg-base-100 hover:bg-base-300")}
              >
                <div class="flex items-center justify-between">
                  <div class="flex items-center gap-3">
                    <!-- Visibility Badge -->
                    <span class={"badge badge-sm " <> if(fun.visibility == :public, do: "badge-success", else: "badge-warning")}>
                      <%= if fun.visibility == :public, do: "def", else: "defp" %>
                    </span>
                    <!-- Function Signature -->
                    <span class="font-mono text-sm font-bold"><%= fun.name %>/<%= fun.arity %></span>
                  </div>
                  <span class="text-xs opacity-60"><%= fun.doc %></span>
                </div>

                <!-- Show clauses when selected -->
                <%= if @selected_fn.id == fun.id do %>
                  <div class="mt-3 space-y-1">
                    <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-2">
                      <div class="opacity-50 text-xs mb-1">@doc "<%= fun.doc %>"</div>
                      <%= for clause <- fun.clauses do %>
                        <div>
                          <span class={"opacity-50 " <> if(fun.visibility == :public, do: "text-success", else: "text-warning")}>
                            <%= if fun.visibility == :public, do: "def ", else: "defp " %>
                          </span>
                          <span class="font-bold"><%= clause.head %></span>
                          <%= if clause.guard do %>
                            <span class="text-warning"> when <%= clause.guard %></span>
                          <% end %>
                          <span class="opacity-50"> do</span>
                        </div>
                        <div class="ml-4 text-accent"><%= clause.body %></div>
                        <div class="opacity-50">end</div>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Test a Function -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">
            Test: <%= @current_module.name %>.<%= @selected_fn.name %>/<%= @selected_fn.arity %>
          </h3>

          <%= if @selected_fn.visibility == :private do %>
            <div class="alert alert-warning text-sm mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-5 w-5" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
              <span>
                This is a <strong>private</strong> function (<code class="font-mono">defp</code>).
                It can only be called from within the <%= @current_module.name %> module, not from outside.
                We will simulate calling it here for learning purposes.
              </span>
            </div>
          <% end %>

          <form phx-submit="test_fn" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0">
                <span class="label-text text-xs">Arguments</span>
              </label>
              <input
                type="text"
                name="input"
                value={@test_input}
                placeholder={"e.g. #{hd(@selected_fn.test_inputs)}"}
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Call</button>
          </form>

          <!-- Quick Inputs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <%= for input <- @selected_fn.test_inputs do %>
              <button
                phx-click="quick_test"
                phx-target={@myself}
                phx-value-input={input}
                class="btn btn-xs btn-outline"
              >
                <%= input %>
              </button>
            <% end %>
          </div>

          <!-- Result -->
          <%= if @test_result do %>
            <div class={"alert text-sm " <> if(@test_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60">
                  <%= @current_module.name %>.<%= @selected_fn.name %>(<%= @test_input %>)
                </div>
                <div class="font-mono font-bold mt-1">&rArr; <%= @test_result.value %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Arity Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Arity Explorer</h3>
            <button
              phx-click="toggle_arity"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_arity_explorer, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_arity_explorer do %>
            <p class="text-xs opacity-60 mb-4">
              In Elixir, the function name alone does not uniquely identify a function.
              The <strong>name/arity</strong> pair does. <code class="font-mono bg-base-300 px-1 rounded">hello/1</code> and
              <code class="font-mono bg-base-300 px-1 rounded">hello/2</code> are completely different functions.
            </p>

            <!-- Arity Table -->
            <div class="overflow-x-auto mb-4">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Name/Arity</th>
                    <th>Signature</th>
                    <th>Visibility</th>
                    <th>Description</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for fun <- @current_module.functions do %>
                    <tr class="hover:bg-base-300">
                      <td class="font-mono font-bold text-info"><%= fun.name %>/<%= fun.arity %></td>
                      <td class="font-mono text-sm"><%= fun.head %></td>
                      <td>
                        <span class={"badge badge-xs " <> if(fun.visibility == :public, do: "badge-success", else: "badge-warning")}>
                          <%= fun.visibility %>
                        </span>
                      </td>
                      <td class="text-xs opacity-70"><%= fun.doc %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <!-- Key insight -->
            <div class="alert alert-info text-sm">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              <div>
                <div class="font-bold">Name/Arity Notation</div>
                <span>
                  The notation <code class="font-mono bg-base-100 px-1 rounded">Module.function/arity</code> is used
                  throughout Elixir docs. For example,
                  <code class="font-mono bg-base-100 px-1 rounded">String.length/1</code>,
                  <code class="font-mono bg-base-100 px-1 rounded">Enum.map/2</code>,
                  <code class="font-mono bg-base-100 px-1 rounded">IO.puts/1</code>.
                </span>
              </div>
            </div>

            <!-- Same name, different arity highlight -->
            <% grouped = Enum.group_by(@current_module.functions, & &1.name) %>
            <% multi_arity = Enum.filter(grouped, fn {_name, fns} -> length(fns) > 1 end) %>
            <%= if length(multi_arity) > 0 do %>
              <div class="mt-4">
                <h4 class="text-xs font-bold opacity-60 mb-2">Same name, different arities:</h4>
                <div class="space-y-2">
                  <%= for {name, fns} <- multi_arity do %>
                    <div class="bg-primary/10 border border-primary/30 rounded-lg p-3">
                      <div class="font-mono text-sm font-bold text-primary mb-2"><%= name %></div>
                      <div class="space-y-1">
                        <%= for fun <- fns do %>
                          <div class="flex items-center gap-2">
                            <span class="badge badge-primary badge-xs"><%= fun.name %>/<%= fun.arity %></span>
                            <span class="font-mono text-xs"><%= fun.head %></span>
                            <span class="text-xs opacity-50">- <%= fun.doc %></span>
                          </div>
                        <% end %>
                      </div>
                      <p class="text-xs opacity-60 mt-2">
                        These are separate functions that happen to share a name. Elixir dispatches based on the number of arguments.
                      </p>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>

      <!-- Function Dispatch Demo -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Function Dispatch Visualizer</h3>
            <button
              phx-click="toggle_dispatch"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_dispatch_demo, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_dispatch_demo do %>
            <p class="text-xs opacity-60 mb-4">
              When you call a multi-clause function, Elixir tries each clause top-to-bottom.
              Select an input to see which clause matches.
            </p>

            <% multi_clause_fns = Enum.filter(@current_module.functions, fn f -> length(f.clauses) > 1 end) %>
            <%= if length(multi_clause_fns) > 0 do %>
              <% dispatch_fn = hd(multi_clause_fns) %>
              <div class="mb-4">
                <h4 class="text-sm font-bold mb-2">
                  <span class="font-mono text-info"><%= dispatch_fn.name %>/<%= dispatch_fn.arity %></span>
                </h4>

                <!-- Clause List with match indicator -->
                <div class="space-y-2 mb-4">
                  <%= for {clause, idx} <- Enum.with_index(dispatch_fn.clauses) do %>
                    <div class={"rounded-lg p-3 border-2 transition-all " <>
                      cond do
                        @dispatch_matched == idx -> "border-success bg-success/15 shadow-lg"
                        @dispatch_matched != nil and idx < @dispatch_matched -> "border-base-300 bg-base-100 opacity-40"
                        @dispatch_matched != nil -> "border-base-300 bg-base-100 opacity-30"
                        true -> "border-base-300 bg-base-100"
                      end}>
                      <div class="flex items-center justify-between">
                        <div class="font-mono text-sm">
                          <span class="opacity-50">def </span>
                          <span class="font-bold"><%= clause.head %></span>
                          <%= if clause.guard do %>
                            <span class="text-warning"> when <%= clause.guard %></span>
                          <% end %>
                          <span class="opacity-50"> do</span>
                          <span class="text-accent ml-2"><%= clause.body %></span>
                          <span class="opacity-50"> end</span>
                        </div>
                        <%= if @dispatch_matched == idx do %>
                          <span class="badge badge-success">MATCHED</span>
                        <% end %>
                        <%= if @dispatch_matched != nil and idx < @dispatch_matched do %>
                          <span class="badge badge-ghost badge-sm opacity-50">skipped</span>
                        <% end %>
                      </div>
                    </div>
                  <% end %>
                </div>

                <!-- Dispatch Test Buttons -->
                <div class="flex flex-wrap gap-2">
                  <span class="text-xs opacity-50 self-center">Test dispatch:</span>
                  <%= for input <- dispatch_fn.test_inputs do %>
                    <button
                      phx-click="test_dispatch"
                      phx-target={@myself}
                      phx-value-input={input}
                      class={"btn btn-sm " <> if(@dispatch_input == input, do: "btn-primary", else: "btn-outline")}
                    >
                      <%= dispatch_fn.name %>(<%= input %>)
                    </button>
                  <% end %>
                </div>
              </div>
            <% else %>
              <p class="text-sm opacity-50">
                Select a module with multi-clause functions (like Shape) to see the dispatch visualizer.
              </p>
            <% end %>
          <% end %>
        </div>
      </div>

      <!-- def vs defp Reference -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">def vs defp</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-success/10 border border-success/30 rounded-lg p-4">
              <h4 class="font-bold text-success text-sm mb-2">def - Public</h4>
              <div class="font-mono text-sm space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div>def hello(name) do</div>
                  <div class="ml-4">"Hello, &lbrace;&rbrace;#&lbrace;name&rbrace;!"</div>
                  <div>end</div>
                </div>
              </div>
              <p class="text-xs opacity-60 mt-2">
                Callable from anywhere: <code class="font-mono bg-base-100 px-1 rounded">Greeter.hello("Alice")</code>
              </p>
            </div>

            <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
              <h4 class="font-bold text-warning text-sm mb-2">defp - Private</h4>
              <div class="font-mono text-sm space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div>defp capitalize(name) do</div>
                  <div class="ml-4">String.capitalize(name)</div>
                  <div>end</div>
                </div>
              </div>
              <p class="text-xs opacity-60 mt-2">
                Only callable within the module. Calling from outside raises
                <code class="font-mono bg-base-100 px-1 rounded">UndefinedFunctionError</code>.
              </p>
            </div>
          </div>
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
                <strong>Modules</strong> are defined with <code class="font-mono bg-base-100 px-1 rounded">defmodule</code>.
                All named functions must live inside a module.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>
                <strong>def vs defp:</strong>
                <code class="font-mono bg-base-100 px-1 rounded">def</code> creates public functions,
                <code class="font-mono bg-base-100 px-1 rounded">defp</code> creates private ones.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>
                <strong>Arity</strong> is the number of arguments.
                <code class="font-mono bg-base-100 px-1 rounded">hello/1</code> and
                <code class="font-mono bg-base-100 px-1 rounded">hello/2</code> are distinct functions.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>
                <strong>Multi-clause:</strong> Named functions can have multiple clauses with pattern matching.
                Elixir tries them top-to-bottom (first match wins).
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>
                <strong>Documentation:</strong>
                <code class="font-mono bg-base-100 px-1 rounded">@moduledoc</code> documents the module,
                <code class="font-mono bg-base-100 px-1 rounded">@doc</code> documents individual functions.
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_module", %{"id" => id}, socket) do
    mod = Enum.find(modules(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(current_module: mod)
     |> assign(selected_fn: hd(mod.functions))
     |> assign(test_input: "")
     |> assign(test_result: nil)
     |> assign(dispatch_input: nil)
     |> assign(dispatch_matched: nil)}
  end

  def handle_event("select_fn", %{"fn_id" => fn_id}, socket) do
    fun = Enum.find(socket.assigns.current_module.functions, &(&1.id == fn_id))

    {:noreply,
     socket
     |> assign(selected_fn: fun)
     |> assign(test_input: "")
     |> assign(test_result: nil)}
  end

  def handle_event("test_fn", %{"input" => input}, socket) do
    input = String.trim(input)
    run_function_test(socket, input)
  end

  def handle_event("quick_test", %{"input" => input}, socket) do
    run_function_test(socket, input)
  end

  def handle_event("toggle_arity", _params, socket) do
    {:noreply, assign(socket, show_arity_explorer: !socket.assigns.show_arity_explorer)}
  end

  def handle_event("toggle_dispatch", _params, socket) do
    {:noreply, assign(socket, show_dispatch_demo: !socket.assigns.show_dispatch_demo)}
  end

  def handle_event("test_dispatch", %{"input" => input}, socket) do
    multi_clause_fns =
      Enum.filter(socket.assigns.current_module.functions, fn f -> length(f.clauses) > 1 end)

    if length(multi_clause_fns) > 0 do
      fun = hd(multi_clause_fns)

      case evaluate_fn(fun.id, input) do
        {:ok, _value} ->
          matched_idx = find_matching_clause(fun.clauses, input)

          {:noreply,
           socket
           |> assign(dispatch_input: input)
           |> assign(dispatch_matched: matched_idx)}

        {:error, _} ->
          {:noreply, assign(socket, dispatch_input: input, dispatch_matched: nil)}
      end
    else
      {:noreply, socket}
    end
  end

  # Helpers

  defp modules, do: @modules

  defp run_function_test(socket, input) do
    if input == "" do
      {:noreply, socket}
    else
      fun = socket.assigns.selected_fn

      case evaluate_fn(fun.id, input) do
        {:ok, value} ->
          {:noreply,
           socket
           |> assign(test_input: input)
           |> assign(test_result: %{ok: true, value: value})}

        {:error, msg} ->
          {:noreply,
           socket
           |> assign(test_input: input)
           |> assign(test_result: %{ok: false, value: msg})}
      end
    end
  end

  # Evaluation functions (named, not anonymous, to avoid module attribute restriction)

  defp evaluate_fn("hello_1", input) do
    name = String.trim(input, "\"")
    {:ok, "\"Hello, #{name}!\""}
  end

  defp evaluate_fn("hello_2", input) do
    parts = String.split(input, ",", parts: 2) |> Enum.map(&String.trim/1) |> Enum.map(&String.trim(&1, "\""))
    case parts do
      [name, greeting] -> {:ok, "\"#{greeting}, #{name}!\""}
      _ -> {:error, "Expected two arguments: name, greeting"}
    end
  end

  defp evaluate_fn("formal_1", input) do
    name = String.trim(input, "\"") |> String.capitalize()
    {:ok, "\"Good day, #{name}\""}
  end

  defp evaluate_fn("capitalize_1", input) do
    name = String.trim(input, "\"") |> String.capitalize()
    {:ok, "\"#{name}\""}
  end

  defp evaluate_fn("sum_1", input) do
    try do
      {result, _} = Code.eval_string("Enum.sum(#{input})")
      {:ok, inspect(result)}
    rescue
      _ -> {:error, "Invalid list"}
    end
  end

  defp evaluate_fn("sum_2", input) do
    try do
      {result, _} = Code.eval_string("(fn a, b -> a + b end).(#{input})")
      {:ok, inspect(result)}
    rescue
      _ -> {:error, "Invalid numbers"}
    end
  end

  defp evaluate_fn("factorial_1", input) do
    try do
      {n, _} = Integer.parse(String.trim(input))
      result = Enum.reduce(1..max(n, 1), 1, &(&1 * &2))
      result = if n == 0, do: 1, else: result
      {:ok, inspect(result)}
    rescue
      _ -> {:error, "Invalid number"}
    end
  end

  defp evaluate_fn("clamp_3", input) do
    try do
      {result, _} = Code.eval_string("(fn val, mn, mx -> min(max(val, mn), mx) end).(#{input})")
      {:ok, inspect(result)}
    rescue
      _ -> {:error, "Invalid arguments"}
    end
  end

  defp evaluate_fn("area_1", input) do
    try do
      {result, _} = Code.eval_string("""
      (fn
        {:circle, r} -> 3.14159 * r * r
        {:rectangle, w, h} -> w * h
        {:triangle, b, h} -> 0.5 * b * h
        _ -> {:error, :unknown_shape}
      end).(#{input})
      """)
      {:ok, inspect(result)}
    rescue
      _ -> {:error, "Invalid shape tuple"}
    end
  end

  defp evaluate_fn("describe_1", input) do
    try do
      {result, _} = Code.eval_string("""
      (fn
        {:circle, r} -> "Circle with radius \#{r}"
        {:rectangle, w, h} -> "Rectangle \#{w}x\#{h}"
        other -> "Unknown shape: \#{inspect(other)}"
      end).(#{input})
      """)
      {:ok, inspect(result)}
    rescue
      _ -> {:error, "Invalid shape"}
    end
  end

  defp evaluate_fn("valid_1", input) do
    try do
      {result, _} = Code.eval_string("""
      (fn
        {:circle, r} when r > 0 -> true
        {:rectangle, w, h} when w > 0 and h > 0 -> true
        _ -> false
      end).(#{input})
      """)
      {:ok, inspect(result)}
    rescue
      _ -> {:error, "Invalid input"}
    end
  end

  defp evaluate_fn(_, _input), do: {:error, "Unknown function"}

  defp find_matching_clause(clauses, input) do
    input_trimmed = String.trim(input)

    Enum.find_index(clauses, fn clause ->
      cond do
        String.contains?(clause.head, "{:circle") and String.starts_with?(input_trimmed, "{:circle") -> true
        String.contains?(clause.head, "{:rectangle") and String.starts_with?(input_trimmed, "{:rectangle") -> true
        String.contains?(clause.head, "{:triangle") and String.starts_with?(input_trimmed, "{:triangle") -> true
        String.contains?(clause.head, "{:square") and String.starts_with?(input_trimmed, "{:square") -> true
        String.contains?(clause.head, "(0)") and input_trimmed == "0" -> true
        String.contains?(clause.head, "(_)") or String.contains?(clause.head, "(other)") -> true
        clause.guard != nil and String.contains?(clause.guard, "> 0") ->
          case Integer.parse(input_trimmed) do
            {n, _} when n > 0 -> true
            _ -> false
          end
        true -> false
      end
    end)
  end
end
