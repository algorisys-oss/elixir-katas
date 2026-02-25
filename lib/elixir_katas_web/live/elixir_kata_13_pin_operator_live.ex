defmodule ElixirKatasWeb.ElixirKata13PinOperatorLive do
  use ElixirKatasWeb, :live_component

  @presets [
    %{
      id: "basic_rebind",
      title: "Basic Rebinding",
      steps: [
        %{code: "x = 1", desc: "Bind x to 1", result: "x = 1", status: :ok, bindings: %{"x" => "1"}},
        %{code: "x = 2", desc: "Rebind x to 2 (no error!)", result: "x = 2", status: :ok, bindings: %{"x" => "2"}},
        %{code: "^x = 2", desc: "Pin: match x's current value (2) against 2", result: "2 = 2  (match!)", status: :ok, bindings: %{"x" => "2"}},
        %{code: "^x = 3", desc: "Pin: match x's current value (2) against 3", result: "** (MatchError) no match of right hand side value: 3", status: :error, bindings: %{"x" => "2"}}
      ]
    },
    %{
      id: "case_pin",
      title: "Pin in Case",
      steps: [
        %{code: "role = :admin", desc: "Bind role to :admin", result: "role = :admin", status: :ok, bindings: %{"role" => ":admin"}},
        %{code: "case {:ok, :admin} do\n  {:ok, ^role} -> \"matched!\"\n  _ -> \"nope\"\nend", desc: "Pin role inside case clause", result: "\"matched!\"", status: :ok, bindings: %{"role" => ":admin"}},
        %{code: "case {:ok, :user} do\n  {:ok, ^role} -> \"matched!\"\n  _ -> \"nope\"\nend", desc: "Pin role, but value is :user not :admin", result: "\"nope\"  (fell through to catch-all)", status: :warning, bindings: %{"role" => ":admin"}}
      ]
    },
    %{
      id: "fn_pin",
      title: "Pin in Function Args",
      steps: [
        %{code: "expected = \"hello\"", desc: "Bind expected to \"hello\"", result: "expected = \"hello\"", status: :ok, bindings: %{"expected" => "\"hello\""}},
        %{code: "check = fn\n  ^expected -> :match\n  _ -> :no_match\nend", desc: "Define fn that pins expected", result: "check = #Function<...>", status: :ok, bindings: %{"expected" => "\"hello\"", "check" => "#Function"}},
        %{code: "check.(\"hello\")", desc: "Call with \"hello\" - matches pinned value", result: ":match", status: :ok, bindings: %{"expected" => "\"hello\"", "check" => "#Function"}},
        %{code: "check.(\"world\")", desc: "Call with \"world\" - does not match", result: ":no_match", status: :warning, bindings: %{"expected" => "\"hello\"", "check" => "#Function"}}
      ]
    },
    %{
      id: "map_pin",
      title: "Pin with Map Keys",
      steps: [
        %{code: "key = :name", desc: "Bind key to :name", result: "key = :name", status: :ok, bindings: %{"key" => ":name"}},
        %{code: "%{^key => value} = %{name: \"Alice\", age: 30}", desc: "Pin key to match dynamic map key", result: "value = \"Alice\"", status: :ok, bindings: %{"key" => ":name", "value" => "\"Alice\""}},
        %{code: "key = :email", desc: "Rebind key to :email", result: "key = :email", status: :ok, bindings: %{"key" => ":email", "value" => "\"Alice\""}},
        %{code: "%{^key => value} = %{name: \"Alice\", age: 30}", desc: "Pin :email - not in map!", result: "** (MatchError) no match of right hand side value: %{name: \"Alice\", age: 30}", status: :error, bindings: %{"key" => ":email", "value" => "\"Alice\""}}
      ]
    },
    %{
      id: "list_pin",
      title: "Pin in List Patterns",
      steps: [
        %{code: "first = 1", desc: "Bind first to 1", result: "first = 1", status: :ok, bindings: %{"first" => "1"}},
        %{code: "[^first, second | rest] = [1, 2, 3, 4]", desc: "Pin first element, bind rest", result: "second = 2, rest = [3, 4]", status: :ok, bindings: %{"first" => "1", "second" => "2", "rest" => "[3, 4]"}},
        %{code: "[^first, second | rest] = [99, 2, 3]", desc: "Pin first=1 but list starts with 99", result: "** (MatchError) no match of right hand side value: [99, 2, 3]", status: :error, bindings: %{"first" => "1", "second" => "2", "rest" => "[3, 4]"}}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:current_preset, fn -> hd(@presets) end)
     |> assign_new(:current_step, fn -> 0 end)
     |> assign_new(:sandbox_var_name, fn -> "x" end)
     |> assign_new(:sandbox_var_value, fn -> "1" end)
     |> assign_new(:sandbox_match_expr, fn -> "^x = 1" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:sandbox_bindings, fn -> %{} end)
     |> assign_new(:sandbox_history, fn -> [] end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">The Pin Operator (^)</h2>
      <p class="text-sm opacity-70 mb-6">
        In Elixir, <code class="font-mono bg-base-300 px-1 rounded">=</code> is the match operator, not assignment.
        Without <code class="font-mono bg-base-300 px-1 rounded">^</code>, variables on the left side get rebound.
        The pin operator <code class="font-mono bg-base-300 px-1 rounded">^</code> forces matching against the existing value instead of rebinding.
      </p>

      <!-- Concept Diagram -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Rebind vs Pin: At a Glance</h3>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Rebind -->
            <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="text-2xl">&#x1f513;</span>
                <h4 class="font-bold text-warning text-sm">Without Pin (Rebind)</h4>
              </div>
              <div class="font-mono text-sm space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60 text-xs"># x gets a new value</div>
                  <div>x = 1</div>
                  <div>x = 2  <span class="text-warning"># rebinds x to 2</span></div>
                </div>
              </div>
              <p class="text-xs opacity-60 mt-2">Variable is "open" - always accepts a new binding.</p>
            </div>

            <!-- Pin -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="text-2xl">&#x1f4cc;</span>
                <h4 class="font-bold text-success text-sm">With Pin (Match)</h4>
              </div>
              <div class="font-mono text-sm space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60 text-xs"># ^x asserts the existing value</div>
                  <div>x = 2</div>
                  <div>^x = 2  <span class="text-success"># matches! (2 = 2)</span></div>
                  <div>^x = 3  <span class="text-error"># MatchError!</span></div>
                </div>
              </div>
              <p class="text-xs opacity-60 mt-2">Variable is "pinned" - value must match exactly.</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Step-Through Scenarios -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Step-Through Scenarios</h3>
          <p class="text-xs opacity-60 mb-4">Select a scenario and step through each line to see how the pin operator behaves.</p>

          <!-- Preset Selector -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for preset <- presets() do %>
              <button
                phx-click="select_preset"
                phx-target={@myself}
                phx-value-id={preset.id}
                class={"btn btn-sm " <> if(@current_preset.id == preset.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= preset.title %>
              </button>
            <% end %>
          </div>

          <!-- Steps Display -->
          <div class="space-y-2 mb-4">
            <%= for {step, idx} <- Enum.with_index(@current_preset.steps) do %>
              <div
                phx-click="go_to_step"
                phx-target={@myself}
                phx-value-step={idx}
                class={"rounded-lg p-3 border-2 cursor-pointer transition-all " <> step_style(idx, @current_step, step.status)}
              >
                <div class="flex items-start gap-3">
                  <!-- Step Number -->
                  <div class={"flex-shrink-0 w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold " <>
                    if(idx <= @current_step, do: "bg-primary text-primary-content", else: "bg-base-300 text-base-content/50")}>
                    <%= idx + 1 %>
                  </div>

                  <div class="flex-1 min-w-0">
                    <!-- Code -->
                    <div class="font-mono text-sm whitespace-pre-wrap"><%= step.code %></div>

                    <!-- Description & Result (shown when active or past) -->
                    <%= if idx <= @current_step do %>
                      <div class="mt-1 text-xs opacity-70"><%= step.desc %></div>
                      <div class={"mt-1 font-mono text-xs font-bold " <> result_color(step.status)}>
                        &rArr; <%= step.result %>
                      </div>
                    <% end %>
                  </div>

                  <!-- Status icon -->
                  <%= if idx <= @current_step do %>
                    <div class="flex-shrink-0">
                      <%= if step.status == :ok do %>
                        <span class="badge badge-success badge-sm">OK</span>
                      <% end %>
                      <%= if step.status == :error do %>
                        <span class="badge badge-error badge-sm">Error</span>
                      <% end %>
                      <%= if step.status == :warning do %>
                        <span class="badge badge-warning badge-sm">Miss</span>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>

          <!-- Binding Context -->
          <%= if @current_step >= 0 do %>
            <% active_step = Enum.at(@current_preset.steps, @current_step) %>
            <div class="bg-base-300 rounded-lg p-3 mb-4">
              <h4 class="text-xs font-bold opacity-60 mb-2">Current Bindings After Step <%= @current_step + 1 %></h4>
              <div class="flex flex-wrap gap-2">
                <%= for {var_name, var_val} <- active_step.bindings do %>
                  <div class="flex items-center gap-1 bg-base-100 rounded-lg px-3 py-1.5 border border-base-300">
                    <span class="text-xs opacity-50">&#x1f4cc;</span>
                    <span class="font-mono text-sm text-info font-bold"><%= var_name %></span>
                    <span class="opacity-30">=</span>
                    <span class="font-mono text-sm text-success"><%= var_val %></span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <!-- Navigation -->
          <div class="flex gap-2">
            <button
              phx-click="prev_step"
              phx-target={@myself}
              disabled={@current_step <= 0}
              class="btn btn-sm btn-outline"
            >
              &larr; Previous
            </button>
            <button
              phx-click="next_step"
              phx-target={@myself}
              disabled={@current_step >= length(@current_preset.steps) - 1}
              class="btn btn-sm btn-primary"
            >
              Next &rarr;
            </button>
            <button
              phx-click="reset_steps"
              phx-target={@myself}
              class="btn btn-sm btn-ghost"
            >
              Reset
            </button>
          </div>
        </div>
      </div>

      <!-- Interactive Sandbox -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive Pin Sandbox</h3>
          <p class="text-xs opacity-60 mb-4">Bind a variable, then test match expressions against it. See how ^ changes behavior.</p>

          <!-- Bind Variable -->
          <form phx-submit="sandbox_bind" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Variable</span></label>
              <input
                type="text"
                name="name"
                value={@sandbox_var_name}
                class="input input-bordered input-sm w-24 font-mono"
                autocomplete="off"
              />
            </div>
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Value</span></label>
              <input
                type="text"
                name="value"
                value={@sandbox_var_value}
                class="input input-bordered input-sm w-32 font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Bind</button>
          </form>

          <!-- Current Bindings -->
          <%= if map_size(@sandbox_bindings) > 0 do %>
            <div class="bg-base-300 rounded-lg p-3 mb-4">
              <h4 class="text-xs font-bold opacity-60 mb-2">Active Bindings</h4>
              <div class="flex flex-wrap gap-2">
                <%= for {name, val} <- @sandbox_bindings do %>
                  <div class="flex items-center gap-1 bg-base-100 rounded-lg px-3 py-1.5 border border-base-300">
                    <span class="font-mono text-sm text-info font-bold"><%= name %></span>
                    <span class="opacity-30">=</span>
                    <span class="font-mono text-sm text-success"><%= val %></span>
                    <button
                      phx-click="sandbox_unbind"
                      phx-target={@myself}
                      phx-value-name={name}
                      class="btn btn-ghost btn-xs text-error ml-1"
                    >
                      x
                    </button>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <!-- Test Expression -->
          <form phx-submit="sandbox_test" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Match Expression</span></label>
              <input
                type="text"
                name="expr"
                value={@sandbox_match_expr}
                placeholder="^x = 1 or x = 5"
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-accent btn-sm">Test Match</button>
          </form>

          <!-- Quick Test Buttons -->
          <%= if map_size(@sandbox_bindings) > 0 do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <span class="text-xs opacity-50 self-center">Quick tests:</span>
              <%= for {name, val} <- @sandbox_bindings do %>
                <button
                  phx-click="sandbox_quick"
                  phx-target={@myself}
                  phx-value-expr={"^#{name} = #{val}"}
                  class="btn btn-xs btn-outline btn-success"
                >
                  ^<%= name %> = <%= val %> (should match)
                </button>
                <button
                  phx-click="sandbox_quick"
                  phx-target={@myself}
                  phx-value-expr={"^#{name} = 999"}
                  class="btn btn-xs btn-outline btn-error"
                >
                  ^<%= name %> = 999 (should fail)
                </button>
                <button
                  phx-click="sandbox_quick"
                  phx-target={@myself}
                  phx-value-expr={"#{name} = 999"}
                  class="btn btn-xs btn-outline btn-warning"
                >
                  <%= name %> = 999 (rebind)
                </button>
              <% end %>
            </div>
          <% end %>

          <!-- Result -->
          <%= if @sandbox_result do %>
            <div class={"alert text-sm " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono font-bold"><%= @sandbox_result.expr %></div>
                <div class="mt-1"><%= @sandbox_result.message %></div>
              </div>
            </div>
          <% end %>

          <!-- History -->
          <%= if length(@sandbox_history) > 0 do %>
            <div class="mt-4">
              <h4 class="text-xs font-bold opacity-60 mb-2">History</h4>
              <div class="space-y-1">
                <%= for entry <- Enum.reverse(@sandbox_history) do %>
                  <div class={"font-mono text-xs p-1.5 rounded " <> if(entry.ok, do: "bg-success/10", else: "bg-error/10")}>
                    <span class="opacity-60">iex&gt;</span> <%= entry.expr %>
                    <span class={"ml-2 font-bold " <> if(entry.ok, do: "text-success", else: "text-error")}><%= entry.short %></span>
                  </div>
                <% end %>
              </div>
              <button phx-click="sandbox_clear_history" phx-target={@myself} class="btn btn-ghost btn-xs mt-2">
                Clear History
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Key Takeaways -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Takeaways</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">x = value</code> on the left side of <code class="font-mono">=</code> always rebinds the variable.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">^x = value</code> asserts that value matches the current binding of x.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Use <code class="font-mono bg-base-100 px-1 rounded">^</code> in <code class="font-mono">case</code>, <code class="font-mono">fn</code>, and <code class="font-mono">with</code> to match against known values.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">%&lbrace;^key =&gt; val&rbrace;</code> lets you use a variable as a dynamic map key in a pattern.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_preset", %{"id" => id}, socket) do
    preset = Enum.find(presets(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(current_preset: preset)
     |> assign(current_step: 0)}
  end

  def handle_event("next_step", _params, socket) do
    max_step = length(socket.assigns.current_preset.steps) - 1
    new_step = min(socket.assigns.current_step + 1, max_step)
    {:noreply, assign(socket, current_step: new_step)}
  end

  def handle_event("prev_step", _params, socket) do
    new_step = max(socket.assigns.current_step - 1, 0)
    {:noreply, assign(socket, current_step: new_step)}
  end

  def handle_event("go_to_step", %{"step" => step_str}, socket) do
    step = String.to_integer(step_str)
    {:noreply, assign(socket, current_step: step)}
  end

  def handle_event("reset_steps", _params, socket) do
    {:noreply, assign(socket, current_step: 0)}
  end

  def handle_event("sandbox_bind", %{"name" => name, "value" => value}, socket) do
    name = String.trim(name)
    value = String.trim(value)

    if name != "" and value != "" do
      new_bindings = Map.put(socket.assigns.sandbox_bindings, name, value)

      {:noreply,
       socket
       |> assign(sandbox_bindings: new_bindings)
       |> assign(sandbox_var_name: name)
       |> assign(sandbox_var_value: value)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("sandbox_unbind", %{"name" => name}, socket) do
    new_bindings = Map.delete(socket.assigns.sandbox_bindings, name)
    {:noreply, assign(socket, sandbox_bindings: new_bindings)}
  end

  def handle_event("sandbox_test", %{"expr" => expr}, socket) do
    result = evaluate_sandbox_expr(expr, socket.assigns.sandbox_bindings)

    new_bindings =
      if result.new_bindings do
        Map.merge(socket.assigns.sandbox_bindings, result.new_bindings)
      else
        socket.assigns.sandbox_bindings
      end

    history_entry = %{expr: expr, ok: result.ok, short: result.short}

    {:noreply,
     socket
     |> assign(sandbox_result: result)
     |> assign(sandbox_match_expr: expr)
     |> assign(sandbox_bindings: new_bindings)
     |> assign(sandbox_history: [history_entry | socket.assigns.sandbox_history])}
  end

  def handle_event("sandbox_quick", %{"expr" => expr}, socket) do
    result = evaluate_sandbox_expr(expr, socket.assigns.sandbox_bindings)

    new_bindings =
      if result.new_bindings do
        Map.merge(socket.assigns.sandbox_bindings, result.new_bindings)
      else
        socket.assigns.sandbox_bindings
      end

    history_entry = %{expr: expr, ok: result.ok, short: result.short}

    {:noreply,
     socket
     |> assign(sandbox_result: result)
     |> assign(sandbox_match_expr: expr)
     |> assign(sandbox_bindings: new_bindings)
     |> assign(sandbox_history: [history_entry | socket.assigns.sandbox_history])}
  end

  def handle_event("sandbox_clear_history", _params, socket) do
    {:noreply, assign(socket, sandbox_history: [])}
  end

  # Helpers

  defp presets, do: @presets

  defp evaluate_sandbox_expr(expr, bindings) do
    expr = String.trim(expr)

    cond do
      # Pin expression: ^var = value
      Regex.match?(~r/^\^(\w+)\s*=\s*(.+)$/, expr) ->
        [_, var_name, match_val] = Regex.run(~r/^\^(\w+)\s*=\s*(.+)$/, expr)
        match_val = String.trim(match_val)

        case Map.get(bindings, var_name) do
          nil ->
            %{ok: false, expr: expr, message: "Variable '#{var_name}' is not bound. Bind it first!", short: "unbound", new_bindings: nil}

          current_val ->
            if current_val == match_val do
              %{ok: true, expr: expr, message: "Match succeeded! #{current_val} = #{match_val}", short: "match!", new_bindings: nil}
            else
              %{ok: false, expr: expr, message: "MatchError: #{current_val} does not match #{match_val}", short: "MatchError", new_bindings: nil}
            end
        end

      # Rebind expression: var = value
      Regex.match?(~r/^(\w+)\s*=\s*(.+)$/, expr) ->
        [_, var_name, new_val] = Regex.run(~r/^(\w+)\s*=\s*(.+)$/, expr)
        new_val = String.trim(new_val)

        old_val = Map.get(bindings, var_name)
        msg = if old_val, do: "Rebound #{var_name} from #{old_val} to #{new_val}", else: "Bound #{var_name} to #{new_val}"

        %{ok: true, expr: expr, message: msg, short: "#{var_name} = #{new_val}", new_bindings: %{var_name => new_val}}

      true ->
        %{ok: false, expr: expr, message: "Could not parse expression. Try 'x = 1' or '^x = 1'.", short: "parse error", new_bindings: nil}
    end
  end

  defp step_style(idx, current_step, status) do
    cond do
      idx == current_step and status == :error ->
        "border-error bg-error/10"

      idx == current_step and status == :warning ->
        "border-warning bg-warning/10"

      idx == current_step ->
        "border-primary bg-primary/10"

      idx < current_step ->
        "border-base-300 bg-base-100 opacity-70"

      true ->
        "border-base-300 bg-base-100 opacity-40"
    end
  end

  defp result_color(:ok), do: "text-success"
  defp result_color(:error), do: "text-error"
  defp result_color(:warning), do: "text-warning"
end
