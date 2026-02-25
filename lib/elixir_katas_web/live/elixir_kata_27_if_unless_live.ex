defmodule ElixirKatasWeb.ElixirKata27IfUnlessLive do
  use ElixirKatasWeb, :live_component

  @truthy_falsy_values [
    %{display: "true", code: "true", truthy: true, category: "boolean"},
    %{display: "false", code: "false", truthy: false, category: "boolean"},
    %{display: "nil", code: "nil", truthy: false, category: "nil"},
    %{display: "0", code: "0", truthy: true, category: "number"},
    %{display: "1", code: "1", truthy: true, category: "number"},
    %{display: "-1", code: "-1", truthy: true, category: "number"},
    %{display: ~s|""|, code: ~s|""|, truthy: true, category: "string"},
    %{display: ~s|"hello"|, code: ~s|"hello"|, truthy: true, category: "string"},
    %{display: "[]", code: "[]", truthy: true, category: "collection"},
    %{display: "[1, 2]", code: "[1, 2]", truthy: true, category: "collection"},
    %{display: "%{}", code: "%{}", truthy: true, category: "collection"},
    %{display: ":ok", code: ":ok", truthy: true, category: "atom"},
    %{display: ":false", code: ":false", truthy: false, category: "atom"}
  ]

  @if_forms [
    %{
      id: "multiline",
      title: "Multi-line if/else",
      code: "if condition do\n  \"truthy branch\"\nelse\n  \"falsy branch\"\nend",
      description: "Standard multi-line form, used when branches have multiple expressions."
    },
    %{
      id: "oneline",
      title: "One-line if",
      code: ~s|if condition, do: "truthy", else: "falsy"|,
      description: "Compact keyword-list form for simple expressions. Commas and colons are required."
    },
    %{
      id: "no_else",
      title: "if without else",
      code: "if condition do\n  perform_action()\nend",
      description: "When there is no else, the expression returns nil if the condition is falsy."
    },
    %{
      id: "unless",
      title: "unless",
      code: "unless condition do\n  \"condition was falsy\"\nend",
      description: "unless is the inverse of if. It executes when the condition is falsy. Avoid unless/else."
    },
    %{
      id: "return_value",
      title: "if returns a value",
      code: "status = if user.admin?, do: :admin, else: :user",
      description: "Everything in Elixir is an expression. if returns the value of the executed branch."
    }
  ]

  @decision_tree [
    %{
      question: "Are you matching on the structure of a value?",
      yes: "Use case",
      no: "next"
    },
    %{
      question: "Do you have multiple conditions to check?",
      yes: "Use cond",
      no: "next"
    },
    %{
      question: "Is it a simple true/false check?",
      yes: "Use if/unless",
      no: "next"
    },
    %{
      question: "Are you chaining multiple ok/error operations?",
      yes: "Use with (Kata 28)",
      no: "Use case as a general fallback"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:tested_value, fn -> nil end)
     |> assign_new(:truthy_result, fn -> nil end)
     |> assign_new(:custom_input, fn -> "" end)
     |> assign_new(:custom_truthy_result, fn -> nil end)
     |> assign_new(:active_form, fn -> hd(@if_forms) end)
     |> assign_new(:show_macro, fn -> false end)
     |> assign_new(:show_decision_tree, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">If / Unless</h2>
      <p class="text-sm opacity-70 mb-6">
        <code class="font-mono bg-base-300 px-1 rounded">if</code> and
        <code class="font-mono bg-base-300 px-1 rounded">unless</code> are simple conditionals for
        true/false branching. In Elixir, they are <strong>macros</strong>, not special forms &mdash;
        and only <code class="font-mono bg-base-300 px-1 rounded">nil</code> and
        <code class="font-mono bg-base-300 px-1 rounded">false</code> are falsy.
      </p>

      <!-- Truthy/Falsy Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Truthy / Falsy Explorer</h3>
          <p class="text-xs opacity-60 mb-4">
            In Elixir, only <strong>nil</strong> and <strong>false</strong> are falsy.
            Everything else &mdash; including 0, empty strings, and empty lists &mdash; is truthy.
            Click a value to test it.
          </p>

          <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 gap-2 mb-4">
            <%= for val <- truthy_falsy_values() do %>
              <button
                phx-click="test_truthy"
                phx-target={@myself}
                phx-value-code={val.code}
                phx-value-display={val.display}
                class={"btn btn-sm font-mono " <>
                  cond do
                    @tested_value == val.display and val.truthy -> "btn-success"
                    @tested_value == val.display and !val.truthy -> "btn-error"
                    true -> "btn-outline"
                  end}
              >
                <%= val.display %>
              </button>
            <% end %>
          </div>

          <!-- Custom Value Test -->
          <form phx-submit="test_custom_truthy" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Test a custom value</span></label>
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

          <%= if @truthy_result do %>
            <div class={"alert text-sm " <> if(@truthy_result.truthy, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono">
                  if <span class="font-bold"><%= @truthy_result.display %></span>,
                  do: <span class="text-success">"truthy"</span>,
                  else: <span class="text-error">"falsy"</span>
                </div>
                <div class="font-mono font-bold mt-1">
                  &rArr; <%= if @truthy_result.truthy, do: "\"truthy\"", else: "\"falsy\"" %>
                </div>
                <div class="text-xs mt-1 opacity-70">
                  <%= if @truthy_result.truthy do %>
                    This value is <strong>truthy</strong>. In Elixir, everything except nil and false is truthy.
                  <% else %>
                    This value is <strong>falsy</strong>. Only nil and false are falsy in Elixir.
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <%= if @custom_truthy_result do %>
            <div class={"alert text-sm mt-2 " <> if(@custom_truthy_result.ok, do: (if @custom_truthy_result.truthy, do: "alert-success", else: "alert-error"), else: "alert-error")}>
              <div>
                <%= if @custom_truthy_result.ok do %>
                  <div class="font-mono font-bold">
                    <%= @custom_truthy_result.display %> is <strong><%= if @custom_truthy_result.truthy, do: "truthy", else: "falsy" %></strong>
                  </div>
                <% else %>
                  <div class="font-mono font-bold">Error: <%= @custom_truthy_result.error %></div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- If/Unless Forms -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Forms of if / unless</h3>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for form <- if_forms() do %>
              <button
                phx-click="select_form"
                phx-target={@myself}
                phx-value-id={form.id}
                class={"btn btn-sm " <> if(@active_form.id == form.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= form.title %>
              </button>
            <% end %>
          </div>

          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_form.code %></div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-sm"><%= @active_form.description %></div>
            </div>
          </div>

          <!-- Special note about nil return -->
          <%= if @active_form.id == "no_else" do %>
            <div class="alert alert-warning text-sm mt-4">
              <div>
                <div class="font-bold">if without else returns nil</div>
                <span>
                  <code class="font-mono bg-base-100 px-1 rounded">if false, do: "hello"</code>
                  returns <code class="font-mono bg-base-100 px-1 rounded">nil</code>,
                  not an error. This is because the implicit else branch returns nil.
                </span>
              </div>
            </div>
          <% end %>

          <!-- Special note about unless -->
          <%= if @active_form.id == "unless" do %>
            <div class="alert alert-warning text-sm mt-4">
              <div>
                <div class="font-bold">Avoid unless/else</div>
                <span>
                  While <code class="font-mono bg-base-100 px-1 rounded">unless</code> with
                  <code class="font-mono bg-base-100 px-1 rounded">else</code> is valid Elixir,
                  it reads confusingly. Use <code class="font-mono bg-base-100 px-1 rounded">if</code> instead
                  when you need both branches.
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- if is a Macro -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">if / unless are Macros</h3>
            <button
              phx-click="toggle_macro"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_macro, do: "Hide", else: "Show Details" %>
            </button>
          </div>

          <%= if @show_macro do %>
            <p class="text-xs opacity-60 mb-4">
              Unlike most languages where <code class="font-mono bg-base-300 px-1 rounded">if</code>
              is a built-in keyword, in Elixir it is defined as a macro in the
              <code class="font-mono bg-base-300 px-1 rounded">Kernel</code> module.
            </p>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-primary/10 border border-primary/30 rounded-lg p-4">
                <h4 class="font-bold text-primary text-sm mb-2">What this means</h4>
                <div class="text-sm space-y-2">
                  <ul class="list-disc ml-4 space-y-1 text-xs">
                    <li><code class="font-mono bg-base-100 px-1 rounded">if</code> is defined in <code class="font-mono bg-base-100 px-1 rounded">Kernel</code> and auto-imported</li>
                    <li>It is transformed at compile time into a <code class="font-mono bg-base-100 px-1 rounded">case</code> expression</li>
                    <li>You could implement your own <code class="font-mono bg-base-100 px-1 rounded">if</code> with macros</li>
                    <li>The real special form underneath is <code class="font-mono bg-base-100 px-1 rounded">case</code></li>
                  </ul>
                </div>
              </div>

              <div class="bg-secondary/10 border border-secondary/30 rounded-lg p-4">
                <h4 class="font-bold text-secondary text-sm mb-2">Under the hood</h4>
                <div class="font-mono text-xs space-y-1 bg-base-100 rounded p-3">
                  <div class="opacity-60"># This:</div>
                  <div>if x &gt; 0, do: "pos", else: "neg"</div>
                  <div class="mt-2 opacity-60"># Becomes roughly:</div>
                  <div>case x &gt; 0 do</div>
                  <div class="ml-2">val when val in [false, nil] -&gt;</div>
                  <div class="ml-4">"neg"</div>
                  <div class="ml-2">_ -&gt;</div>
                  <div class="ml-4">"pos"</div>
                  <div>end</div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- When to Use What - Decision Tree -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">When to Use if vs case vs cond</h3>
            <button
              phx-click="toggle_decision_tree"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_decision_tree, do: "Hide", else: "Show Decision Tree" %>
            </button>
          </div>

          <%= if @show_decision_tree do %>
            <div class="space-y-3 mb-4">
              <%= for {node, idx} <- Enum.with_index(decision_tree()) do %>
                <div class="flex items-start gap-3 bg-base-100 rounded-lg p-3 border border-base-300">
                  <span class="badge badge-primary badge-sm mt-0.5"><%= idx + 1 %></span>
                  <div class="flex-1">
                    <div class="font-bold text-sm mb-2"><%= node.question %></div>
                    <div class="flex gap-4">
                      <div class="flex items-center gap-1">
                        <span class="badge badge-success badge-xs">Yes</span>
                        <span class="text-sm font-mono"><%= node.yes %></span>
                      </div>
                      <div class="flex items-center gap-1">
                        <span class="badge badge-ghost badge-xs">No</span>
                        <span class="text-sm font-mono"><%= node.no %></span>
                      </div>
                    </div>
                  </div>
                </div>
                <%= if idx < length(decision_tree()) - 1 do %>
                  <div class="flex justify-center">
                    <span class="text-xs opacity-30">&darr; No</span>
                  </div>
                <% end %>
              <% end %>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div class="bg-accent/10 border border-accent/30 rounded-lg p-3 text-xs">
                <div class="font-bold text-accent mb-1">if / unless</div>
                <span>Simple true/false branching. One condition, two paths.</span>
              </div>
              <div class="bg-primary/10 border border-primary/30 rounded-lg p-3 text-xs">
                <div class="font-bold text-primary mb-1">case</div>
                <span>Pattern matching on one value. Structural dispatch with guards.</span>
              </div>
              <div class="bg-secondary/10 border border-secondary/30 rounded-lg p-3 text-xs">
                <div class="font-bold text-secondary mb-1">cond</div>
                <span>Multiple boolean conditions. Range checks. Multi-variable logic.</span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own</h3>
          <p class="text-xs opacity-60 mb-4">
            Write any Elixir expression using
            <code class="font-mono bg-base-300 px-1 rounded">if</code> or
            <code class="font-mono bg-base-300 px-1 rounded">unless</code>.
          </p>

          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <textarea
                name="code"
                rows="4"
                class="textarea textarea-bordered font-mono text-sm"
                placeholder={"x = 42\nif x > 0, do: \"positive\", else: \"non-positive\""}
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
                <strong>Only nil and false are falsy.</strong> Everything else &mdash; including
                <code class="font-mono bg-base-100 px-1 rounded">0</code>,
                <code class="font-mono bg-base-100 px-1 rounded">""</code>, and
                <code class="font-mono bg-base-100 px-1 rounded">[]</code> &mdash; is truthy.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>
                <strong>if returns a value</strong> &mdash; everything in Elixir is an expression.
                <code class="font-mono bg-base-100 px-1 rounded">result = if cond, do: a, else: b</code>
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>
                <strong>if and unless are macros</strong> defined in Kernel, not special forms.
                Under the hood, they compile to <code class="font-mono bg-base-100 px-1 rounded">case</code>.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>
                <strong>unless</strong> is the inverse of if. Avoid
                <code class="font-mono bg-base-100 px-1 rounded">unless ... else</code> &mdash;
                use <code class="font-mono bg-base-100 px-1 rounded">if</code> instead for clarity.
              </span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>
                Prefer <code class="font-mono bg-base-100 px-1 rounded">case</code> or
                <code class="font-mono bg-base-100 px-1 rounded">cond</code> for anything beyond
                simple true/false checks. Elixir is pattern-matching first.
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("test_truthy", %{"code" => code, "display" => display}, socket) do
    truthy = evaluate_truthy(code)

    {:noreply,
     socket
     |> assign(tested_value: display)
     |> assign(truthy_result: %{display: display, truthy: truthy})
     |> assign(custom_truthy_result: nil)}
  end

  def handle_event("test_custom_truthy", %{"value" => value}, socket) do
    value = String.trim(value)

    if value == "" do
      {:noreply, socket}
    else
      try do
        {result, _} = Code.eval_string(value)
        truthy = result != nil and result != false

        {:noreply,
         socket
         |> assign(custom_input: value)
         |> assign(custom_truthy_result: %{ok: true, display: value, truthy: truthy})}
      rescue
        e ->
          {:noreply,
           socket
           |> assign(custom_input: value)
           |> assign(custom_truthy_result: %{ok: false, display: value, error: Exception.message(e)})}
      end
    end
  end

  def handle_event("select_form", %{"id" => id}, socket) do
    form = Enum.find(if_forms(), &(&1.id == id))
    {:noreply, assign(socket, active_form: form)}
  end

  def handle_event("toggle_macro", _params, socket) do
    {:noreply, assign(socket, show_macro: !socket.assigns.show_macro)}
  end

  def handle_event("toggle_decision_tree", _params, socket) do
    {:noreply, assign(socket, show_decision_tree: !socket.assigns.show_decision_tree)}
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

  defp truthy_falsy_values, do: @truthy_falsy_values
  defp if_forms, do: @if_forms
  defp decision_tree, do: @decision_tree

  defp sandbox_examples do
    [
      {"if/else", ~s|x = 10\nif x > 5, do: "big", else: "small"|},
      {"unless", ~s|logged_in = false\nunless logged_in, do: "Please log in"|},
      {"if returns nil", ~s|if false, do: "never seen"|},
      {"nested if", ~s|age = 25\nif age >= 18 do\n  if age >= 21, do: "can drink", else: "can vote"\nelse\n  "minor"\nend|},
      {"with assignment", ~s|status = if rem(42, 2) == 0, do: :even, else: :odd\n{42, status}|}
    ]
  end

  defp evaluate_truthy(code) do
    try do
      {result, _} = Code.eval_string(code)
      result != nil and result != false
    rescue
      _ -> false
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
