defmodule ElixirKatasWeb.ElixirKata73MacrosLive do
  use ElixirKatasWeb, :live_component

  @macro_examples [
    %{
      id: "unless",
      title: "unless",
      description: "The unless macro is the opposite of if. It executes the body when the condition is falsy.",
      definition: "defmacro unless(condition, do: body) do\n  quote do\n    if !unquote(condition) do\n      unquote(body)\n    end\n  end\nend",
      usage: "unless false do\n  \"This runs!\"\nend",
      expansion: "if !false do\n  \"This runs!\"\nend",
      result: "\"This runs!\"",
      explanation: "unless is not a language keyword -- it's a macro that transforms into an if expression at compile time."
    },
    %{
      id: "log_debug",
      title: "debug logging",
      description: "A macro that can be completely eliminated at compile time in production.",
      definition: "defmacro debug(msg) do\n  if Application.get_env(:my_app, :debug) do\n    quote do\n      IO.puts(\"[DEBUG] \" <> unquote(msg))\n    end\n  else\n    # Return nil -- no code generated!\n    nil\n  end\nend",
      usage: ~s|debug("processing user \#{user_id}")|,
      expansion: "# In dev: IO.puts(\"[DEBUG] processing user 42\")\n# In prod: (nothing -- removed at compile time)",
      result: "nil (in production) or side-effect (in dev)",
      explanation: "The macro checks a compile-time config. In production, it generates no code at all -- zero runtime cost."
    },
    %{
      id: "defstruct_like",
      title: "attribute definition",
      description: "Macros can define module attributes and functions at compile time.",
      definition: "defmacro define_getter(name, default) do\n  quote do\n    def unquote(name)() do\n      unquote(default)\n    end\n  end\nend",
      usage: "defmodule Config do\n  import MyMacros\n  define_getter :timeout, 5000\n  define_getter :retries, 3\nend\n\nConfig.timeout()  # => 5000\nConfig.retries()  # => 3",
      expansion: "def timeout() do\n  5000\nend\n\ndef retries() do\n  3\nend",
      result: "Functions generated at compile time",
      explanation: "The macro generates function definitions. Each call to define_getter creates a new function in the module."
    },
    %{
      id: "pipe_debug",
      title: "pipe debugging",
      description: "A macro that inspects values mid-pipeline without changing the result.",
      definition: "defmacro pipe_inspect(value, label \\\\ \"\") do\n  quote do\n    result = unquote(value)\n    IO.inspect(result, label: unquote(label))\n    result\n  end\nend",
      usage: "[1, 2, 3]\n|> Enum.map(&(&1 * 2))\n|> pipe_inspect(\"after map\")\n|> Enum.filter(&(&1 > 3))\n|> pipe_inspect(\"after filter\")",
      expansion: "# Logs: after map: [2, 4, 6]\n# Logs: after filter: [4, 6]\n# Returns: [4, 6]",
      result: "[4, 6] (with debug output)",
      explanation: "The macro wraps the value, inspects it with a label, then returns it unchanged -- perfect for debugging pipelines."
    }
  ]

  @hygiene_demos [
    %{
      id: "hygienic",
      title: "Hygienic (Default)",
      description: "Variables defined inside a macro don't leak into the caller's scope.",
      code: "defmacro hygienic_example do\n  quote do\n    x = 42\n    x\n  end\nend\n\nx = 1\nhygienic_example()  # => 42\nx                    # => 1 (unchanged!)",
      explanation: "Elixir macros are hygienic by default. The x inside the macro is different from the x outside."
    },
    %{
      id: "var_override",
      title: "var! (Override Hygiene)",
      description: "Use var! to intentionally break hygiene and access the caller's variables.",
      code: "defmacro set_x(value) do\n  quote do\n    var!(x) = unquote(value)\n  end\nend\n\nx = 1\nset_x(42)\nx  # => 42 (modified!)",
      explanation: "var! explicitly reaches into the caller's scope. Use sparingly -- it makes code harder to reason about."
    }
  ]

  @builtin_macros [
    %{name: "if/unless", module: "Kernel", description: "Conditional branching"},
    %{name: "def/defp", module: "Kernel", description: "Define public/private functions"},
    %{name: "defmodule", module: "Kernel", description: "Define a module"},
    %{name: "defstruct", module: "Kernel", description: "Define a struct"},
    %{name: "use", module: "Kernel", description: "Invoke a module's __using__ macro"},
    %{name: "import", module: "Kernel", description: "Import functions from a module"},
    %{name: "alias", module: "Kernel", description: "Create module aliases"},
    %{name: "|>", module: "Kernel", description: "Pipe operator"},
    %{name: "for", module: "Kernel", description: "Comprehensions"},
    %{name: "with", module: "Kernel", description: "Special form for chaining matches"},
    %{name: "assert", module: "ExUnit.Assertions", description: "Test assertions"},
    %{name: "plug", module: "Plug.Builder", description: "Define request pipeline"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_macro, fn -> hd(@macro_examples) end)
     |> assign_new(:show_expansion, fn -> false end)
     |> assign_new(:active_hygiene, fn -> hd(@hygiene_demos) end)
     |> assign_new(:show_hygiene, fn -> false end)
     |> assign_new(:show_builtins, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Macros</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>Macros</strong> are compile-time code generators. They receive AST, transform it, and
        return new AST that replaces the macro call. Many Elixir features you use daily &mdash;
        <code class="font-mono bg-base-300 px-1 rounded">if</code>,
        <code class="font-mono bg-base-300 px-1 rounded">def</code>,
        <code class="font-mono bg-base-300 px-1 rounded">|&gt;</code> &mdash; are macros.
      </p>

      <!-- Macro Examples -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Macro Examples</h3>
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for example <- macro_examples() do %>
              <button
                phx-click="select_macro"
                phx-target={@myself}
                phx-value-id={example.id}
                class={"btn btn-sm " <> if(@active_macro.id == example.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= example.title %>
              </button>
            <% end %>
          </div>

          <p class="text-sm opacity-70 mb-4"><%= @active_macro.description %></p>

          <!-- Definition -->
          <div class="mb-4">
            <div class="text-xs font-bold opacity-60 mb-1">Macro Definition</div>
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_macro.definition %></div>
          </div>

          <!-- Usage -->
          <div class="mb-4">
            <div class="text-xs font-bold opacity-60 mb-1">Usage</div>
            <div class="bg-base-100 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap border border-base-300"><%= @active_macro.usage %></div>
          </div>

          <!-- Expansion Toggle -->
          <div class="mb-4">
            <button
              phx-click="toggle_expansion"
              phx-target={@myself}
              class="btn btn-sm btn-accent"
            >
              <%= if @show_expansion, do: "Hide Expansion", else: "Show Macro Expansion" %>
            </button>
          </div>

          <!-- Expansion -->
          <%= if @show_expansion do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
                <div class="text-xs font-bold opacity-60 mb-2">Compile-time Expansion</div>
                <div class="font-mono text-sm whitespace-pre-wrap"><%= @active_macro.expansion %></div>
              </div>
              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <div class="text-xs font-bold opacity-60 mb-2">Runtime Result</div>
                <div class="font-mono text-sm text-success"><%= @active_macro.result %></div>
              </div>
            </div>
          <% end %>

          <!-- Explanation -->
          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
            <%= @active_macro.explanation %>
          </div>
        </div>
      </div>

      <!-- Macro Hygiene -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Macro Hygiene</h3>
            <button
              phx-click="toggle_hygiene"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_hygiene, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_hygiene do %>
            <p class="text-xs opacity-60 mb-4">
              Elixir macros are <strong>hygienic</strong> &mdash; variables defined in a macro do not
              leak into the caller's scope. This prevents accidental name collisions.
            </p>

            <div class="flex flex-wrap gap-2 mb-4">
              <%= for demo <- hygiene_demos() do %>
                <button
                  phx-click="select_hygiene"
                  phx-target={@myself}
                  phx-value-id={demo.id}
                  class={"btn btn-sm " <> if(@active_hygiene.id == demo.id, do: "btn-accent", else: "btn-outline")}
                >
                  <%= demo.title %>
                </button>
              <% end %>
            </div>

            <p class="text-sm opacity-70 mb-3"><%= @active_hygiene.description %></p>
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_hygiene.code %></div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
              <%= @active_hygiene.explanation %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Built-in Macros -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Built-in Macros You Already Use</h3>
            <button
              phx-click="toggle_builtins"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_builtins, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_builtins do %>
            <p class="text-xs opacity-60 mb-4">
              Many fundamental Elixir constructs are macros, not special syntax. This is the power
              of homoiconicity &mdash; the language is built from itself.
            </p>

            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Macro</th>
                    <th>Module</th>
                    <th>Description</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for m <- builtin_macros() do %>
                    <tr>
                      <td class="font-mono text-primary font-bold"><%= m.name %></td>
                      <td class="font-mono text-xs opacity-60"><%= m.module %></td>
                      <td class="text-sm"><%= m.description %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="alert alert-warning text-sm mt-4">
              <div>
                <strong>Rule of thumb:</strong> Don't write a macro when a function will do.
                Macros add compile-time complexity and are harder to debug. Use them only when
                you need compile-time code generation or transformation.
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Macro Workflow -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Macro Workflow</h3>
          <div class="flex flex-wrap gap-2 items-center">
            <div class="bg-base-300 rounded-lg px-3 py-2 text-xs">
              <span class="font-bold text-primary">1.</span> Caller writes macro call
            </div>
            <span class="opacity-30">&rarr;</span>
            <div class="bg-base-300 rounded-lg px-3 py-2 text-xs">
              <span class="font-bold text-primary">2.</span> Arguments passed as AST
            </div>
            <span class="opacity-30">&rarr;</span>
            <div class="bg-base-300 rounded-lg px-3 py-2 text-xs">
              <span class="font-bold text-primary">3.</span> Macro transforms AST
            </div>
            <span class="opacity-30">&rarr;</span>
            <div class="bg-base-300 rounded-lg px-3 py-2 text-xs">
              <span class="font-bold text-primary">4.</span> Returns new AST
            </div>
            <span class="opacity-30">&rarr;</span>
            <div class="bg-base-300 rounded-lg px-3 py-2 text-xs">
              <span class="font-bold text-primary">5.</span> Compiler injects returned AST
            </div>
          </div>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try It</h3>
          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <textarea
              name="code"
              rows="5"
              class="textarea textarea-bordered font-mono text-sm w-full"
              placeholder={"# Expand a macro to see the generated code\nast = quote do\n  unless true, do: :never\nend\nMacro.expand_once(ast, __ENV__) |> Macro.to_string()"}
              autocomplete="off"
            ><%= @sandbox_code %></textarea>
            <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
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
            <div class={"alert text-sm mt-3 " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs"><%= @sandbox_result.output %></div>
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
              <span><strong>Macros</strong> are compile-time functions that receive AST and return AST. They generate code before runtime.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">defmacro</code> defines a macro. Use <code class="font-mono bg-base-100 px-1 rounded">quote</code> and <code class="font-mono bg-base-100 px-1 rounded">unquote</code> to build the returned AST.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Macro hygiene</strong> prevents variable leakage. Variables inside macros don't collide with the caller's scope.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>Many Elixir features (<code class="font-mono bg-base-100 px-1 rounded">if</code>, <code class="font-mono bg-base-100 px-1 rounded">def</code>, <code class="font-mono bg-base-100 px-1 rounded">|&gt;</code>) are macros &mdash; the language is built from itself.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Rule of thumb:</strong> Use functions first. Only reach for macros when you need compile-time code generation.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_macro", %{"id" => id}, socket) do
    example = Enum.find(macro_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_macro: example, show_expansion: false)}
  end

  def handle_event("toggle_expansion", _params, socket) do
    {:noreply, assign(socket, show_expansion: !socket.assigns.show_expansion)}
  end

  def handle_event("toggle_hygiene", _params, socket) do
    {:noreply, assign(socket, show_hygiene: !socket.assigns.show_hygiene)}
  end

  def handle_event("select_hygiene", %{"id" => id}, socket) do
    demo = Enum.find(hygiene_demos(), &(&1.id == id))
    {:noreply, assign(socket, active_hygiene: demo)}
  end

  def handle_event("toggle_builtins", _params, socket) do
    {:noreply, assign(socket, show_builtins: !socket.assigns.show_builtins)}
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

  defp macro_examples, do: @macro_examples
  defp hygiene_demos, do: @hygiene_demos
  defp builtin_macros, do: @builtin_macros

  defp sandbox_quick_examples do
    [
      {"expand unless", "ast = quote(do: unless(true, do: :nope))\nMacro.expand_once(ast, __ENV__) |> Macro.to_string()"},
      {"expand if", "ast = quote(do: if(x > 0, do: :pos, else: :neg))\nMacro.to_string(ast)"},
      {"is_macro?", "Kernel |> Module.__info__(:macros) |> Enum.take(10)"},
      {"quote + eval", "ast = quote(do: Enum.sum([1, 2, 3]))\nCode.eval_quoted(ast) |> elem(0)"}
    ]
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
