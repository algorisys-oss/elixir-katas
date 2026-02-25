defmodule ElixirKatasWeb.ElixirKata10TupleMatchingLive do
  use ElixirKatasWeb, :live_component

  @function_simulators [
    %{name: "File.read/1", description: "Read a file from disk",
      ok: {:ok, "Hello, Elixir!"}, error: {:error, :enoent}},
    %{name: "Map.fetch/2", description: "Fetch a key from a map",
      ok: {:ok, 42}, error: :error},
    %{name: "Integer.parse/1", description: "Parse a string to integer",
      ok: {42, ""}, error: :error},
    %{name: "GenServer.call/2", description: "Call a GenServer process",
      ok: {:ok, "response_data"}, error: {:error, :timeout}},
    %{name: "Ecto.Repo.insert/1", description: "Insert a database record",
      ok: {:ok, "%User{id: 1, name: \"Alice\"}"}, error: {:error, "%Changeset{errors: [name: \"can't be blank\"]}"}},
    %{name: "Jason.decode/1", description: "Decode a JSON string",
      ok: {:ok, "%{\"name\" => \"Elixir\"}"}, error: {:error, "%Jason.DecodeError{position: 0}"}}
  ]

  @preset_matches [
    %{pattern: "{:ok, val}", value: "{:ok, 42}",
      description: "Extract success value"},
    %{pattern: "{:error, reason}", value: "{:error, :enoent}",
      description: "Extract error reason"},
    %{pattern: "{:ok, val}", value: "{:error, :oops}",
      description: "Tag mismatch - fails!"},
    %{pattern: "{:reply, msg, state}", value: "{:reply, \"hello\", 42}",
      description: "3-element tagged tuple"},
    %{pattern: "{_, second}", value: "{:ignored, \"keep_me\"}",
      description: "Ignore first, keep second"},
    %{pattern: "{:ok, {nested, data}}", value: "{:ok, {1, 2}}",
      description: "Nested tuple destructuring"},
    %{pattern: "{a, a}", value: "{1, 1}",
      description: "Same variable = same value"},
    %{pattern: "{:error, %{message: msg}}", value: "{:error, %{message: \"not found\", code: 404}}",
      description: "Nested map in tuple"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_tab, fn -> "sandbox" end)
     |> assign_new(:selected_pattern, fn -> "" end)
     |> assign_new(:selected_value, fn -> "" end)
     |> assign_new(:match_result, fn -> nil end)
     |> assign_new(:bindings, fn -> %{} end)
     |> assign_new(:sim_result, fn -> nil end)
     |> assign_new(:sim_name, fn -> nil end)
     |> assign_new(:case_pattern, fn -> nil end)
     |> assign_new(:case_ok_body, fn -> "\"Got: \" <> inspect(val)" end)
     |> assign_new(:case_error_body, fn -> "\"Failed: \" <> inspect(reason)" end)
     |> assign_new(:case_result, fn -> nil end)
     |> assign_new(:presets, fn -> @preset_matches end)
     |> assign_new(:simulators, fn -> @function_simulators end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Tuple Matching</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir uses tagged tuples like <code class="font-mono">&lbrace;:ok, value&rbrace;</code> and
        <code class="font-mono">&lbrace;:error, reason&rbrace;</code> as a universal convention for function results.
        Pattern matching makes handling both cases clean and explicit.
      </p>

      <!-- Tab Switcher -->
      <div class="tabs tabs-boxed mb-6 bg-base-200">
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="sandbox"
          class={"tab " <> if(@active_tab == "sandbox", do: "tab-active", else: "")}
        >
          Pattern Sandbox
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="simulator"
          class={"tab " <> if(@active_tab == "simulator", do: "tab-active", else: "")}
        >
          Function Simulator
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="case_builder"
          class={"tab " <> if(@active_tab == "case_builder", do: "tab-active", else: "")}
        >
          Case Builder
        </button>
      </div>

      <!-- Pattern Sandbox Tab -->
      <%= if @active_tab == "sandbox" do %>
        <div class="space-y-6">
          <!-- Interactive Matcher -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Tuple Pattern Matcher</h3>
              <form phx-submit="try_tuple_match" phx-target={@myself}>
                <div class="flex flex-col md:flex-row gap-3 items-end">
                  <div class="form-control flex-1">
                    <label class="label py-0"><span class="label-text text-xs">Pattern (left side)</span></label>
                    <input
                      type="text"
                      name="pattern"
                      value={@selected_pattern}
                      placeholder="e.g. {:ok, val}"
                      class="input input-bordered input-sm font-mono"
                      autocomplete="off"
                    />
                  </div>
                  <span class="text-2xl font-bold text-warning self-center">=</span>
                  <div class="form-control flex-1">
                    <label class="label py-0"><span class="label-text text-xs">Value (right side)</span></label>
                    <input
                      type="text"
                      name="value"
                      value={@selected_value}
                      placeholder="e.g. {:ok, 42}"
                      class="input input-bordered input-sm font-mono"
                      autocomplete="off"
                    />
                  </div>
                  <button type="submit" class="btn btn-primary btn-sm">Match!</button>
                </div>
              </form>

              <!-- Result -->
              <%= if @match_result do %>
                <div class={"mt-4 rounded-lg border-2 overflow-hidden " <>
                  if(@match_result.success, do: "border-success", else: "border-error")}>
                  <!-- Header -->
                  <div class={"px-4 py-2 flex items-center gap-2 " <>
                    if(@match_result.success, do: "bg-success/20", else: "bg-error/20")}>
                    <%= if @match_result.success do %>
                      <span class="badge badge-success badge-sm">Match</span>
                    <% else %>
                      <span class="badge badge-error badge-sm">No Match</span>
                    <% end %>
                    <span class="font-mono text-sm">
                      <%= @match_result.pattern %> = <%= @match_result.value %>
                    </span>
                  </div>

                  <!-- Visual Matching -->
                  <div class="p-4">
                    <%= if @match_result.success and length(@match_result.elements) > 0 do %>
                      <div class="flex flex-wrap items-center gap-1 justify-center mb-3">
                        <span class="text-xl font-mono text-warning">&lbrace;</span>
                        <%= for {elem, idx} <- Enum.with_index(@match_result.elements) do %>
                          <div class={"flex flex-col items-center px-3 py-2 rounded-lg border-2 transition-all " <>
                            if(elem.bound, do: "border-success bg-success/10 shadow-md", else: "border-info bg-info/10")}>
                            <span class="text-xs opacity-50"><%= elem.pattern_part %></span>
                            <span class="font-mono font-bold"><%= elem.value_part %></span>
                            <%= if elem.bound do %>
                              <span class="text-xs text-success font-bold mt-1"><%= elem.var %> = <%= elem.value_part %></span>
                            <% end %>
                          </div>
                          <%= if idx < length(@match_result.elements) - 1 do %>
                            <span class="text-lg opacity-30">,</span>
                          <% end %>
                        <% end %>
                        <span class="text-xl font-mono text-warning">&rbrace;</span>
                      </div>
                    <% end %>

                    <div class="text-sm"><%= @match_result.explanation %></div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Variable Bindings -->
          <%= if map_size(@bindings) > 0 do %>
            <div class="card bg-base-200 shadow-md">
              <div class="card-body p-4">
                <div class="flex items-center justify-between mb-3">
                  <h3 class="card-title text-sm">Bound Variables</h3>
                  <button phx-click="clear_bindings" phx-target={@myself} class="btn btn-ghost btn-xs">Clear</button>
                </div>
                <div class="flex flex-wrap gap-2">
                  <%= for {var, val} <- @bindings do %>
                    <div class="badge badge-lg badge-outline gap-1 font-mono">
                      <span class="text-info"><%= var %></span>
                      <span class="opacity-50">=</span>
                      <span class="text-success"><%= val %></span>
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <!-- Preset Examples -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Try These Examples</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-2">
                <%= for {preset, idx} <- Enum.with_index(@presets) do %>
                  <button
                    phx-click="load_preset"
                    phx-target={@myself}
                    phx-value-index={idx}
                    class="btn btn-sm btn-ghost justify-start text-left h-auto py-2"
                  >
                    <div class="flex flex-col items-start">
                      <span class="font-mono text-xs"><%= preset.pattern %> = <%= preset.value %></span>
                      <span class="text-xs opacity-60"><%= preset.description %></span>
                    </div>
                  </button>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Function Simulator Tab -->
      <%= if @active_tab == "simulator" do %>
        <div class="space-y-6">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-1">Function Return Simulator</h3>
              <p class="text-xs opacity-60 mb-4">
                Click a button to simulate a function returning a success or error tuple.
                See how pattern matching extracts the relevant data.
              </p>

              <div class="space-y-3">
                <%= for sim <- @simulators do %>
                  <div class="bg-base-300 rounded-lg p-3">
                    <div class="flex items-center justify-between mb-2">
                      <div>
                        <span class="font-mono font-bold text-sm"><%= sim.name %></span>
                        <span class="text-xs opacity-60 ml-2"><%= sim.description %></span>
                      </div>
                    </div>
                    <div class="flex gap-2">
                      <button
                        phx-click="simulate"
                        phx-target={@myself}
                        phx-value-name={sim.name}
                        phx-value-outcome="ok"
                        class="btn btn-success btn-xs"
                      >
                        Success
                      </button>
                      <button
                        phx-click="simulate"
                        phx-target={@myself}
                        phx-value-name={sim.name}
                        phx-value-outcome="error"
                        class="btn btn-error btn-xs"
                      >
                        Error
                      </button>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Simulation Result -->
          <%= if @sim_result do %>
            <div class={"card shadow-md " <> if(@sim_result.is_ok, do: "bg-success/10 border border-success/30", else: "bg-error/10 border border-error/30")}>
              <div class="card-body p-4">
                <div class="flex items-center gap-2 mb-3">
                  <h3 class="card-title text-sm"><%= @sim_name %></h3>
                  <span class={"badge badge-sm " <> if(@sim_result.is_ok, do: "badge-success", else: "badge-error")}>
                    <%= if @sim_result.is_ok, do: "success", else: "error" %>
                  </span>
                </div>

                <!-- Return Value -->
                <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-3">
                  <div class="opacity-50 text-xs mb-1"># Function returned:</div>
                  <div class={"font-bold " <> if(@sim_result.is_ok, do: "text-success", else: "text-error")}>
                    <%= @sim_result.raw %>
                  </div>
                </div>

                <!-- Pattern Match -->
                <div class="bg-base-300 rounded-lg p-3 font-mono text-sm">
                  <div class="opacity-50 text-xs mb-1"># Pattern matching with case:</div>
                  <div>case <%= @sim_name %> do</div>
                  <div class={"pl-4 " <> if(@sim_result.is_ok, do: "text-success font-bold", else: "opacity-50")}>
                    &lbrace;:ok, value&rbrace; -&gt; "Success: #&lbrace;inspect(value)&rbrace;"
                  </div>
                  <div class={"pl-4 " <> if(!@sim_result.is_ok, do: "text-error font-bold", else: "opacity-50")}>
                    &lbrace;:error, reason&rbrace; -&gt; "Error: #&lbrace;inspect(reason)&rbrace;"
                  </div>
                  <%= if @sim_result.has_bare_error do %>
                    <div class={"pl-4 " <> if(!@sim_result.is_ok, do: "text-error font-bold", else: "opacity-50")}>
                      :error -&gt; "Operation failed"
                    </div>
                  <% end %>
                  <div>end</div>
                </div>

                <!-- Extracted Value -->
                <div class="mt-3 p-3 bg-base-100 rounded-lg">
                  <div class="text-sm">
                    <%= if @sim_result.is_ok do %>
                      <span class="font-bold text-success">value</span>
                      <span class="opacity-50"> = </span>
                      <span class="font-mono"><%= @sim_result.extracted %></span>
                    <% else %>
                      <span class="font-bold text-error">reason</span>
                      <span class="opacity-50"> = </span>
                      <span class="font-mono"><%= @sim_result.extracted %></span>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Case Builder Tab -->
      <%= if @active_tab == "case_builder" do %>
        <div class="space-y-6">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-1">Case Expression Builder</h3>
              <p class="text-xs opacity-60 mb-4">
                Build a case expression to handle ok/error tuples. Choose a function to simulate,
                then customize the handling for each branch.
              </p>

              <!-- Function Picker -->
              <div class="mb-4">
                <label class="label py-0 mb-1"><span class="label-text text-xs">Choose a function to match on:</span></label>
                <div class="flex flex-wrap gap-2">
                  <%= for sim <- @simulators do %>
                    <button
                      phx-click="set_case_pattern"
                      phx-target={@myself}
                      phx-value-name={sim.name}
                      class={"btn btn-xs " <> if(@case_pattern == sim.name, do: "btn-primary", else: "btn-outline")}
                    >
                      <%= sim.name %>
                    </button>
                  <% end %>
                </div>
              </div>

              <!-- Case Body Editor -->
              <%= if @case_pattern do %>
                <div class="bg-base-300 rounded-lg p-4 font-mono text-sm mb-4">
                  <div class="mb-2">case <span class="text-primary"><%= @case_pattern %></span> do</div>

                  <div class="pl-4 mb-2">
                    <div class="text-success mb-1">&lbrace;:ok, val&rbrace; -&gt;</div>
                    <form phx-change="update_case_ok" phx-target={@myself} class="pl-4">
                      <input
                        type="text"
                        name="body"
                        value={@case_ok_body}
                        class="input input-bordered input-xs font-mono w-full bg-success/10"
                        autocomplete="off"
                      />
                    </form>
                  </div>

                  <div class="pl-4 mb-2">
                    <div class="text-error mb-1">&lbrace;:error, reason&rbrace; -&gt;</div>
                    <form phx-change="update_case_error" phx-target={@myself} class="pl-4">
                      <input
                        type="text"
                        name="body"
                        value={@case_error_body}
                        class="input input-bordered input-xs font-mono w-full bg-error/10"
                        autocomplete="off"
                      />
                    </form>
                  </div>

                  <div>end</div>
                </div>

                <!-- Run it -->
                <div class="flex gap-2">
                  <button
                    phx-click="run_case"
                    phx-target={@myself}
                    phx-value-outcome="ok"
                    class="btn btn-success btn-sm"
                  >
                    Run with :ok result
                  </button>
                  <button
                    phx-click="run_case"
                    phx-target={@myself}
                    phx-value-outcome="error"
                    class="btn btn-error btn-sm"
                  >
                    Run with :error result
                  </button>
                </div>

                <!-- Case Result -->
                <%= if @case_result do %>
                  <div class={"mt-4 p-3 rounded-lg border " <>
                    if(@case_result.is_ok, do: "border-success bg-success/10", else: "border-error bg-error/10")}>
                    <div class="text-xs opacity-50 mb-1">Input:</div>
                    <div class="font-mono text-sm mb-2"><%= @case_result.input %></div>
                    <div class="text-xs opacity-50 mb-1">Matched branch:</div>
                    <div class={"font-mono text-sm font-bold " <>
                      if(@case_result.is_ok, do: "text-success", else: "text-error")}>
                      <%= @case_result.branch %>
                    </div>
                    <div class="text-xs opacity-50 mb-1 mt-2">Result:</div>
                    <div class="font-mono text-sm font-bold"><%= @case_result.output %></div>
                  </div>
                <% end %>
              <% end %>
            </div>
          </div>

          <!-- Common Patterns Reference -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Common Tuple Matching Patterns</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">with expression</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>with &lbrace;:ok, user&rbrace; &lt;- fetch_user(id),</div>
                    <div>     &lbrace;:ok, posts&rbrace; &lt;- fetch_posts(user) do</div>
                    <div>  &lbrace;:ok, %&lbrace;user: user, posts: posts&rbrace;&rbrace;</div>
                    <div>else</div>
                    <div>  &lbrace;:error, reason&rbrace; -&gt; &lbrace;:error, reason&rbrace;</div>
                    <div>end</div>
                  </div>
                </div>

                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">Function head matching</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>def handle(&lbrace;:ok, val&rbrace;) do</div>
                    <div>  IO.puts("Success: #&lbrace;val&rbrace;")</div>
                    <div>end</div>
                    <div class="mt-2">def handle(&lbrace;:error, reason&rbrace;) do</div>
                    <div>  IO.puts("Error: #&lbrace;reason&rbrace;")</div>
                    <div>end</div>
                  </div>
                </div>

                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">GenServer callbacks</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>def handle_call(:get, _from, state) do</div>
                    <div>  &lbrace;:reply, state, state&rbrace;</div>
                    <div>end</div>
                    <div class="mt-2">def handle_cast(&lbrace;:put, val&rbrace;, _state) do</div>
                    <div>  &lbrace;:noreply, val&rbrace;</div>
                    <div>end</div>
                  </div>
                </div>

                <div class="bg-base-300 rounded-lg p-3">
                  <h4 class="font-bold text-sm mb-2 text-info">Nested extraction</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div>&lbrace;:ok, %&lbrace;data: &lbrace;count, items&rbrace;&rbrace;&rbrace; =</div>
                    <div>  &lbrace;:ok, %&lbrace;data: &lbrace;3, ["a", "b", "c"]&rbrace;&rbrace;&rbrace;</div>
                    <div class="text-success mt-1">count = 3</div>
                    <div class="text-success">items = ["a", "b", "c"]</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Event Handlers

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("try_tuple_match", %{"pattern" => pattern, "value" => value}, socket) do
    pattern = String.trim(pattern)
    value = String.trim(value)

    if pattern != "" and value != "" do
      result = do_tuple_match(pattern, value)

      new_bindings =
        if result.success do
          result.elements
          |> Enum.filter(& &1.bound)
          |> Enum.reduce(socket.assigns.bindings, fn elem, acc ->
            Map.put(acc, elem.var, elem.value_part)
          end)
        else
          socket.assigns.bindings
        end

      {:noreply,
       socket
       |> assign(match_result: result)
       |> assign(selected_pattern: pattern)
       |> assign(selected_value: value)
       |> assign(bindings: new_bindings)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("load_preset", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    preset = Enum.at(@preset_matches, idx)

    result = do_tuple_match(preset.pattern, preset.value)

    new_bindings =
      if result.success do
        result.elements
        |> Enum.filter(& &1.bound)
        |> Enum.reduce(socket.assigns.bindings, fn elem, acc ->
          Map.put(acc, elem.var, elem.value_part)
        end)
      else
        socket.assigns.bindings
      end

    {:noreply,
     socket
     |> assign(match_result: result)
     |> assign(selected_pattern: preset.pattern)
     |> assign(selected_value: preset.value)
     |> assign(bindings: new_bindings)}
  end

  def handle_event("clear_bindings", _params, socket) do
    {:noreply, assign(socket, bindings: %{})}
  end

  def handle_event("simulate", %{"name" => name, "outcome" => outcome}, socket) do
    sim = Enum.find(@function_simulators, fn s -> s.name == name end)

    if sim do
      is_ok = outcome == "ok"
      raw_result = if is_ok, do: sim.ok, else: sim.error

      {raw_str, extracted, has_bare_error} = format_sim_result(raw_result, is_ok)

      {:noreply,
       socket
       |> assign(sim_result: %{
         is_ok: is_ok,
         raw: raw_str,
         extracted: extracted,
         has_bare_error: has_bare_error
       })
       |> assign(sim_name: name)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("set_case_pattern", %{"name" => name}, socket) do
    {:noreply,
     socket
     |> assign(case_pattern: name)
     |> assign(case_result: nil)}
  end

  def handle_event("update_case_ok", %{"body" => body}, socket) do
    {:noreply, assign(socket, case_ok_body: body)}
  end

  def handle_event("update_case_error", %{"body" => body}, socket) do
    {:noreply, assign(socket, case_error_body: body)}
  end

  def handle_event("run_case", %{"outcome" => outcome}, socket) do
    sim = Enum.find(@function_simulators, fn s -> s.name == socket.assigns.case_pattern end)

    if sim do
      is_ok = outcome == "ok"
      raw_result = if is_ok, do: sim.ok, else: sim.error
      {raw_str, extracted, _} = format_sim_result(raw_result, is_ok)

      branch =
        if is_ok do
          "{:ok, val} -> (val = #{extracted})"
        else
          "{:error, reason} -> (reason = #{extracted})"
        end

      body = if is_ok, do: socket.assigns.case_ok_body, else: socket.assigns.case_error_body
      output = String.replace(body, ~r/val|value/, extracted) |> String.replace(~r/reason/, extracted)

      {:noreply,
       assign(socket, case_result: %{
         is_ok: is_ok,
         input: raw_str,
         branch: branch,
         output: output
       })}
    else
      {:noreply, socket}
    end
  end

  # Match engine

  defp do_tuple_match(pattern, value) do
    pattern = String.trim(pattern)
    value = String.trim(value)

    cond do
      tuple_shaped?(pattern) and tuple_shaped?(value) ->
        pat_inner = unwrap_tuple(pattern)
        val_inner = unwrap_tuple(value)
        pat_parts = split_top_level(pat_inner)
        val_parts = split_top_level(val_inner)

        if length(pat_parts) == length(val_parts) do
          elements =
            Enum.zip(pat_parts, val_parts)
            |> Enum.map(fn {p, v} ->
              p = String.trim(p)
              v = String.trim(v)
              cond do
                p == "_" ->
                  %{pattern_part: p, value_part: v, bound: false, var: "_", matches: true}
                p == v ->
                  %{pattern_part: p, value_part: v, bound: false, var: nil, matches: true}
                String.starts_with?(p, ":") and String.starts_with?(v, ":") and p != v ->
                  %{pattern_part: p, value_part: v, bound: false, var: nil, matches: false}
                String.starts_with?(p, ":") and not String.starts_with?(v, ":") ->
                  %{pattern_part: p, value_part: v, bound: false, var: nil, matches: false}
                not String.starts_with?(p, ":") and String.starts_with?(v, ":") and
                  Regex.match?(~r/^[a-z_][a-z0-9_]*$/, p) ->
                  %{pattern_part: p, value_part: v, bound: true, var: p, matches: true}
                Regex.match?(~r/^[a-z_][a-z0-9_]*$/, p) ->
                  %{pattern_part: p, value_part: v, bound: true, var: p, matches: true}
                tuple_shaped?(p) and tuple_shaped?(v) ->
                  nested = do_tuple_match(p, v)
                  if nested.success do
                    bound_vars = nested.elements |> Enum.filter(& &1.bound)
                    var_name = case bound_vars do
                      [single] -> single.var
                      _ -> nil
                    end
                    %{pattern_part: p, value_part: v, bound: var_name != nil, var: var_name, matches: true}
                  else
                    %{pattern_part: p, value_part: v, bound: false, var: nil, matches: false}
                  end
                String.starts_with?(p, "%{") and String.starts_with?(v, "%{") ->
                  %{pattern_part: p, value_part: v, bound: true, var: "nested", matches: true}
                true ->
                  matches = p == v
                  %{pattern_part: p, value_part: v, bound: false, var: nil, matches: matches}
              end
            end)

          all_match = Enum.all?(elements, & &1.matches)

          if all_match do
            bound = elements |> Enum.filter(& &1.bound)
            explanation =
              if length(bound) > 0 do
                bindings_str = Enum.map_join(bound, ", ", fn e -> "#{e.var} = #{e.value_part}" end)
                "Match succeeded! Bound: #{bindings_str}"
              else
                "Match succeeded! All elements matched (no new bindings)."
              end
            %{success: true, pattern: pattern, value: value, elements: elements, explanation: explanation}
          else
            mismatched = Enum.find(elements, fn e -> !e.matches end)
            %{success: false, pattern: pattern, value: value, elements: elements,
              explanation: "Match failed: #{mismatched.pattern_part} does not match #{mismatched.value_part}."}
          end
        else
          %{success: false, pattern: pattern, value: value, elements: [],
            explanation: "Tuple size mismatch: pattern has #{length(pat_parts)} elements, value has #{length(val_parts)}."}
        end

      true ->
        if pattern == value do
          %{success: true, pattern: pattern, value: value, elements: [],
            explanation: "Literal match: #{pattern} equals #{value}."}
        else
          %{success: false, pattern: pattern, value: value, elements: [],
            explanation: "No match: #{pattern} does not equal #{value}."}
        end
    end
  end

  defp tuple_shaped?(str) do
    str = String.trim(str)
    String.starts_with?(str, "{") and String.ends_with?(str, "}")
  end

  defp unwrap_tuple(str) do
    str |> String.trim() |> String.trim_leading("{") |> String.trim_trailing("}") |> String.trim()
  end

  defp split_top_level(str) do
    do_split(str, 0, 0, 0, [], "")
  end

  defp do_split("", _p, _b, _m, acc, current) do
    current = String.trim(current)
    if current == "", do: acc, else: acc ++ [current]
  end

  defp do_split("," <> rest, 0, 0, 0, acc, current) do
    do_split(rest, 0, 0, 0, acc ++ [String.trim(current)], "")
  end

  defp do_split("{" <> rest, p, b, m, acc, current), do: do_split(rest, p + 1, b, m, acc, current <> "{")
  defp do_split("}" <> rest, p, b, m, acc, current), do: do_split(rest, max(p - 1, 0), b, m, acc, current <> "}")
  defp do_split("[" <> rest, p, b, m, acc, current), do: do_split(rest, p, b + 1, m, acc, current <> "[")
  defp do_split("]" <> rest, p, b, m, acc, current), do: do_split(rest, p, max(b - 1, 0), m, acc, current <> "]")
  defp do_split("%" <> rest, p, b, m, acc, current), do: do_split(rest, p, b, m, acc, current <> "%")
  defp do_split("\"" <> rest, p, b, m, acc, current) when m == 0, do: do_split(rest, p, b, 1, acc, current <> "\"")
  defp do_split("\"" <> rest, p, b, 1, acc, current), do: do_split(rest, p, b, 0, acc, current <> "\"")
  defp do_split(<<c::utf8, rest::binary>>, p, b, m, acc, current), do: do_split(rest, p, b, m, acc, current <> <<c::utf8>>)

  defp format_sim_result(result, is_ok) do
    case result do
      {:ok, val} ->
        {"{:ok, #{inspect(val)}}", inspect(val), false}

      {:error, reason} ->
        {"{:error, #{inspect(reason)}}", inspect(reason), false}

      {val, rest} when is_ok ->
        {"{#{inspect(val)}, #{inspect(rest)}}", inspect(val), false}

      :error ->
        {":error", ":error", true}

      other ->
        {inspect(other), inspect(other), false}
    end
  end
end
