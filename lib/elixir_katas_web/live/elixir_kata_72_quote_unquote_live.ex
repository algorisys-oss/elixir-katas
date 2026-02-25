defmodule ElixirKatasWeb.ElixirKata72QuoteUnquoteLive do
  use ElixirKatasWeb, :live_component

  @quote_examples [
    %{
      id: "literal",
      title: "Literals",
      description: "Atoms, numbers, strings, lists, and two-element tuples return themselves when quoted.",
      input: ":hello",
      code: "quote do\n  :hello\nend",
      result: ":hello",
      ast_explanation: "Literals are their own AST representation. No transformation needed."
    },
    %{
      id: "variable",
      title: "Variables",
      description: "Variables become 3-element tuples: {name, metadata, context}.",
      input: "x",
      code: "quote do\n  x\nend",
      result: "{:x, [], Elixir}",
      ast_explanation: "The tuple contains: the variable name (:x), metadata (line info, etc.), and the context module."
    },
    %{
      id: "function_call",
      title: "Function Calls",
      description: "Function calls become 3-element tuples: {function_name, metadata, arguments}.",
      input: "sum(1, 2, 3)",
      code: "quote do\n  sum(1, 2, 3)\nend",
      result: "{:sum, [], [1, 2, 3]}",
      ast_explanation: "The tuple contains: the function name (:sum), metadata, and a list of arguments."
    },
    %{
      id: "operator",
      title: "Operators",
      description: "Operators are function calls too. 1 + 2 becomes {:+, meta, [1, 2]}.",
      input: "1 + 2",
      code: "quote do\n  1 + 2\nend",
      result: "{:+, [], [1, 2]}",
      ast_explanation: "Operators are just functions with two arguments. The + operator becomes {:+, meta, [1, 2]}."
    },
    %{
      id: "nested",
      title: "Nested Expressions",
      description: "Complex expressions produce nested AST trees.",
      input: "1 + 2 * 3",
      code: "quote do\n  1 + 2 * 3\nend",
      result: "{:+, [], [1, {:*, [], [2, 3]}]}",
      ast_explanation: "The * binds tighter, so it appears deeper in the tree. The AST reflects operator precedence."
    },
    %{
      id: "block",
      title: "Blocks",
      description: "Multiple expressions become a :__block__ node.",
      input: "x = 1\nx + 2",
      code: "quote do\n  x = 1\n  x + 2\nend",
      result: "{:__block__, [], [{:=, [], [{:x, [], Elixir}, 1]}, {:+, [], [{:x, [], Elixir}, 2]}]}",
      ast_explanation: "A block groups multiple expressions. Each is a node in the arguments list."
    }
  ]

  @unquote_examples [
    %{
      id: "inject_value",
      title: "Injecting Values",
      description: "unquote injects an evaluated expression into the AST being built.",
      code: "x = 42\nquote do\n  1 + unquote(x)\nend",
      result: "{:+, [], [1, 42]}",
      explanation: "Without unquote, x would be quoted as {:x, [], Elixir}. With unquote, its value (42) is injected."
    },
    %{
      id: "inject_variable",
      title: "Injecting Variable References",
      description: "You can inject a quoted variable reference to build dynamic AST.",
      code: "name = :my_var\nquote do\n  unquote(Macro.var(name, nil)) = 10\nend",
      result: "{:=, [], [{:my_var, [], nil}, 10]}",
      explanation: "Macro.var/2 creates a variable AST node. unquote injects it into the quote block."
    },
    %{
      id: "splice",
      title: "Splicing Lists with unquote_splicing",
      description: "unquote_splicing injects a list's elements as individual arguments.",
      code: "args = [1, 2, 3]\nquote do\n  my_fun(unquote_splicing(args))\nend",
      result: "{:my_fun, [], [1, 2, 3]}",
      explanation: "unquote_splicing expands the list elements as individual arguments instead of inserting the list itself."
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_quote, fn -> hd(@quote_examples) end)
     |> assign_new(:active_unquote, fn -> hd(@unquote_examples) end)
     |> assign_new(:show_unquote, fn -> false end)
     |> assign_new(:show_homoiconicity, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Quote &amp; Unquote</h2>
      <p class="text-sm opacity-70 mb-6">
        <code class="font-mono bg-base-300 px-1 rounded">quote</code> converts Elixir code into its
        <strong>AST (Abstract Syntax Tree)</strong> representation. This is the foundation of Elixir's
        metaprogramming &mdash; code that writes code.
      </p>

      <!-- Quote Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Exploring quote</h3>
          <p class="text-xs opacity-60 mb-4">
            Select an expression to see how <code class="font-mono bg-base-300 px-1 rounded">quote</code>
            transforms it into AST.
          </p>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for example <- quote_examples() do %>
              <button
                phx-click="select_quote"
                phx-target={@myself}
                phx-value-id={example.id}
                class={"btn btn-sm " <> if(@active_quote.id == example.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= example.title %>
              </button>
            <% end %>
          </div>

          <p class="text-sm opacity-70 mb-3"><%= @active_quote.description %></p>

          <!-- Input -> AST transformation visual -->
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
            <!-- Source code -->
            <div class="bg-base-100 rounded-lg p-4 border border-base-300">
              <div class="text-xs font-bold opacity-60 mb-2">Source Code</div>
              <div class="font-mono text-sm text-info"><%= @active_quote.input %></div>
            </div>

            <!-- Arrow -->
            <div class="flex items-center justify-center">
              <div class="text-center">
                <div class="font-mono text-sm bg-base-300 rounded-lg px-3 py-2 whitespace-pre-wrap"><%= @active_quote.code %></div>
                <div class="text-xs opacity-40 mt-1">&darr;</div>
              </div>
            </div>

            <!-- AST output -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-4">
              <div class="text-xs font-bold opacity-60 mb-2">AST (Quoted Form)</div>
              <div class="font-mono text-sm text-success break-all"><%= @active_quote.result %></div>
            </div>
          </div>

          <!-- Explanation -->
          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
            <%= @active_quote.ast_explanation %>
          </div>
        </div>
      </div>

      <!-- AST Structure Card -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">AST Node Structure</h3>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm mb-4">
            <div class="text-accent">&lbrace;atom | tuple, keyword_list, list | atom&rbrace;</div>
            <div class="mt-2 text-xs opacity-70">
              <div>Element 1: function name or operator (atom) or nested AST (tuple)</div>
              <div>Element 2: metadata (line numbers, imports, etc.)</div>
              <div>Element 3: arguments list, or atom for variables</div>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm">
            <div class="bg-base-100 rounded-lg p-3 border border-base-300">
              <div class="font-bold text-accent mb-1">Literals</div>
              <div class="text-xs">Atoms, numbers, strings, lists, 2-tuples are their own AST</div>
            </div>
            <div class="bg-base-100 rounded-lg p-3 border border-base-300">
              <div class="font-bold text-accent mb-1">Variables</div>
              <div class="text-xs font-mono">&lbrace;:name, meta, context&rbrace;</div>
            </div>
            <div class="bg-base-100 rounded-lg p-3 border border-base-300">
              <div class="font-bold text-accent mb-1">Calls</div>
              <div class="text-xs font-mono">&lbrace;:fun, meta, [args]&rbrace;</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Unquote Section -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">unquote &amp; unquote_splicing</h3>
            <button
              phx-click="toggle_unquote"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_unquote, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_unquote do %>
            <p class="text-xs opacity-60 mb-4">
              <code class="font-mono bg-base-300 px-1 rounded">unquote</code> injects evaluated values
              into a <code class="font-mono bg-base-300 px-1 rounded">quote</code> block. Think of it like
              string interpolation, but for AST.
            </p>

            <div class="flex flex-wrap gap-2 mb-4">
              <%= for example <- unquote_examples() do %>
                <button
                  phx-click="select_unquote"
                  phx-target={@myself}
                  phx-value-id={example.id}
                  class={"btn btn-sm " <> if(@active_unquote.id == example.id, do: "btn-accent", else: "btn-outline")}
                >
                  <%= example.title %>
                </button>
              <% end %>
            </div>

            <p class="text-sm opacity-70 mb-3"><%= @active_unquote.description %></p>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_unquote.code %></div>

            <div class="bg-success/10 border border-success/30 rounded-lg p-3 mb-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success break-all"><%= @active_unquote.result %></div>
            </div>

            <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
              <%= @active_unquote.explanation %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Homoiconicity -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Homoiconicity</h3>
            <button
              phx-click="toggle_homoiconicity"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_homoiconicity, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_homoiconicity do %>
            <div class="space-y-4">
              <p class="text-sm opacity-70">
                Elixir is <strong>homoiconic</strong> &mdash; the language's own code can be represented
                using its own data structures (tuples and lists). This means code can manipulate other
                code as data.
              </p>

              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-base-100 rounded-lg p-4 border border-base-300">
                  <h4 class="font-bold text-sm mb-2">Code as Data</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div><span class="text-info">if x > 0, do: :positive</span></div>
                    <div class="opacity-40">&darr; quote &darr;</div>
                    <div><span class="text-success">&lbrace;:if, [], [&lbrace;:>, [], [&lbrace;:x, [], Elixir&rbrace;, 0]&rbrace;, ...]&rbrace;</span></div>
                  </div>
                  <p class="text-xs opacity-60 mt-2">Code becomes a nested tuple/list structure you can inspect and transform.</p>
                </div>
                <div class="bg-base-100 rounded-lg p-4 border border-base-300">
                  <h4 class="font-bold text-sm mb-2">Data as Code</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div><span class="text-success">&lbrace;:+, [], [1, 2]&rbrace;</span></div>
                    <div class="opacity-40">&darr; Code.eval_quoted &darr;</div>
                    <div><span class="text-info">3</span></div>
                  </div>
                  <p class="text-xs opacity-60 mt-2">AST data structures can be compiled and executed as code.</p>
                </div>
              </div>

              <div class="alert alert-warning text-sm">
                <div>
                  <strong>Why does this matter?</strong> Homoiconicity enables macros &mdash; functions that
                  receive code as data, transform it, and return new code. This is how Elixir implements
                  <code class="font-mono bg-base-100 px-1 rounded">if</code>,
                  <code class="font-mono bg-base-100 px-1 rounded">unless</code>,
                  <code class="font-mono bg-base-100 px-1 rounded">defmodule</code>, and more.
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try It</h3>
          <p class="text-xs opacity-60 mb-4">
            Use <code class="font-mono bg-base-300 px-1 rounded">quote do ... end</code> to see AST output, or evaluate any Elixir expression.
          </p>

          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <textarea
              name="code"
              rows="4"
              class="textarea textarea-bordered font-mono text-sm w-full"
              placeholder={"quote do\n  Enum.map([1, 2, 3], fn x -> x * 2 end)\nend"}
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
              <span><code class="font-mono bg-base-100 px-1 rounded">quote</code> converts Elixir code into its AST representation &mdash; nested tuples and lists.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>AST nodes are 3-tuples: <code class="font-mono bg-base-100 px-1 rounded">&lbrace;name, metadata, arguments&rbrace;</code>. Literals represent themselves.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">unquote</code> injects a value into a quoted expression, like string interpolation for AST.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">unquote_splicing</code> splices a list's elements as individual arguments.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Homoiconicity</strong> means code is data. This enables macros &mdash; the foundation of Elixir's extensibility.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_quote", %{"id" => id}, socket) do
    example = Enum.find(quote_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_quote: example)}
  end

  def handle_event("toggle_unquote", _params, socket) do
    {:noreply, assign(socket, show_unquote: !socket.assigns.show_unquote)}
  end

  def handle_event("select_unquote", %{"id" => id}, socket) do
    example = Enum.find(unquote_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_unquote: example)}
  end

  def handle_event("toggle_homoiconicity", _params, socket) do
    {:noreply, assign(socket, show_homoiconicity: !socket.assigns.show_homoiconicity)}
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

  defp quote_examples, do: @quote_examples
  defp unquote_examples, do: @unquote_examples

  defp sandbox_quick_examples do
    [
      {"quote variable", "quote do\n  x\nend"},
      {"quote if", "quote do\n  if true, do: :yes, else: :no\nend"},
      {"quote pipe", "quote do\n  [1, 2, 3] |> Enum.map(&(&1 * 2))\nend"},
      {"Macro.to_string", "quote(do: 1 + 2 * 3) |> Macro.to_string()"},
      {"eval_quoted", "ast = quote(do: 1 + 2)\nCode.eval_quoted(ast) |> elem(0)"}
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
