defmodule ElixirKatasWeb.ElixirKata09MatchOperatorLive do
  use ElixirKatasWeb, :live_component

  @preset_examples [
    %{left: "x", right: "1", description: "Bind x to 1"},
    %{left: "1", right: "1", description: "Literal match succeeds"},
    %{left: "2", right: "1", description: "Literal mismatch - MatchError!"},
    %{left: "{a, b}", right: "{1, 2}", description: "Tuple destructuring"},
    %{left: "{:ok, val}", right: "{:ok, 42}", description: "Tagged tuple match"},
    %{left: "{:ok, val}", right: "{:error, \"oops\"}", description: "Tag mismatch - MatchError!"},
    %{left: "[h | t]", right: "[1, 2, 3]", description: "Head/tail list match"},
    %{left: "[a, b, c]", right: "[1, 2, 3]", description: "Fixed-length list match"},
    %{left: "[a, b]", right: "[1, 2, 3]", description: "Length mismatch - MatchError!"},
    %{left: "_", right: "anything", description: "Underscore matches anything"},
    %{left: "{_, second}", right: "{1, 2}", description: "Ignore first element"},
    %{left: "%{name: n}", right: "%{name: \"Elixir\", version: \"1.16\"}", description: "Partial map match"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:left_input, fn -> "" end)
     |> assign_new(:right_input, fn -> "" end)
     |> assign_new(:match_result, fn -> nil end)
     |> assign_new(:bindings, fn -> %{} end)
     |> assign_new(:history, fn -> [] end)
     |> assign_new(:step_index, fn -> 0 end)
     |> assign_new(:step_mode, fn -> false end)
     |> assign_new(:presets, fn -> @preset_examples end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">The Match Operator</h2>
      <p class="text-sm opacity-70 mb-6">
        In Elixir, <code class="font-mono font-bold">=</code> is the <strong>match operator</strong>, not assignment.
        It tries to make the left side match the right side, binding variables as needed.
        If the match fails, you get a <code class="font-mono text-error">MatchError</code>.
      </p>

      <!-- Match Sandbox -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Match Sandbox</h3>
          <form phx-submit="try_match" phx-target={@myself}>
            <div class="flex flex-col md:flex-row gap-3 items-end">
              <div class="form-control flex-1">
                <label class="label py-0"><span class="label-text text-xs">Left side (pattern)</span></label>
                <input
                  type="text"
                  name="left"
                  value={@left_input}
                  placeholder="e.g. {a, b}"
                  class="input input-bordered input-sm font-mono"
                  autocomplete="off"
                />
              </div>
              <span class="text-2xl font-bold text-warning self-center">=</span>
              <div class="form-control flex-1">
                <label class="label py-0"><span class="label-text text-xs">Right side (value)</span></label>
                <input
                  type="text"
                  name="right"
                  value={@right_input}
                  placeholder="e.g. {1, 2}"
                  class="input input-bordered input-sm font-mono"
                  autocomplete="off"
                />
              </div>
              <button type="submit" class="btn btn-primary btn-sm">Match!</button>
            </div>
          </form>

          <!-- Result Display -->
          <%= if @match_result do %>
            <div class={"mt-4 p-4 rounded-lg border-2 " <> if(@match_result.success, do: "border-success bg-success/10", else: "border-error bg-error/10")}>
              <div class="flex items-center gap-2 mb-2">
                <%= if @match_result.success do %>
                  <span class="badge badge-success">Match Succeeded</span>
                <% else %>
                  <span class="badge badge-error">MatchError</span>
                <% end %>
              </div>

              <div class="font-mono text-sm mb-2">
                <span class="opacity-60"><%= @match_result.left %></span>
                <span class="text-warning font-bold"> = </span>
                <span class="opacity-60"><%= @match_result.right %></span>
              </div>

              <%= if @match_result.success do %>
                <div class="text-sm text-success"><%= @match_result.explanation %></div>
              <% else %>
                <div class="text-sm text-error"><%= @match_result.explanation %></div>
                <div class="mt-2 font-mono text-xs bg-error/10 p-2 rounded">
                  ** (MatchError) no match of right hand side value: <%= @match_result.right %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Variable Binding Table -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Variable Bindings</h3>
            <div class="flex gap-2">
              <span class="badge badge-ghost"><%= map_size(@bindings) %> bound</span>
              <button phx-click="clear_bindings" phx-target={@myself} class="btn btn-ghost btn-xs">Clear All</button>
            </div>
          </div>

          <%= if map_size(@bindings) > 0 do %>
            <div class="overflow-x-auto">
              <table class="table table-sm table-zebra">
                <thead>
                  <tr>
                    <th>Variable</th>
                    <th>Bound Value</th>
                    <th>Re-match Test</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for {var, val} <- Enum.sort(@bindings) do %>
                    <tr>
                      <td class="font-mono text-info font-bold"><%= var %></td>
                      <td class="font-mono text-success"><%= val %></td>
                      <td class="flex gap-1">
                        <button
                          phx-click="test_rebind"
                          phx-target={@myself}
                          phx-value-var={var}
                          phx-value-val={val}
                          class="btn btn-success btn-xs btn-outline"
                          title={"Try: #{val} = #{var}"}
                        >
                          <%= val %> = <%= var %>
                        </button>
                        <button
                          phx-click="test_rebind_fail"
                          phx-target={@myself}
                          phx-value-var={var}
                          phx-value-val={val}
                          class="btn btn-error btn-xs btn-outline"
                          title={"Try: wrong_val = #{var}"}
                        >
                          other = <%= var %>
                        </button>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% else %>
            <div class="text-center py-4 opacity-50 text-sm">
              No variables bound yet. Try a match above!
            </div>
          <% end %>
        </div>
      </div>

      <!-- Preset Examples -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Preset Examples</h3>
            <div class="flex gap-2">
              <button
                phx-click="toggle_step_mode"
                phx-target={@myself}
                class={"btn btn-xs " <> if(@step_mode, do: "btn-accent", else: "btn-outline btn-accent")}
              >
                <%= if @step_mode, do: "Step Mode ON", else: "Step-Through Mode" %>
              </button>
              <%= if @step_mode do %>
                <button
                  phx-click="step_next"
                  phx-target={@myself}
                  class="btn btn-xs btn-primary"
                  disabled={@step_index >= length(@presets)}
                >
                  Next Step (<%= @step_index + 1 %>/<%= length(@presets) %>)
                </button>
                <button phx-click="step_reset" phx-target={@myself} class="btn btn-xs btn-ghost">Reset</button>
              <% end %>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-2">
            <%= for {preset, idx} <- Enum.with_index(@presets) do %>
              <button
                phx-click="load_preset"
                phx-target={@myself}
                phx-value-index={idx}
                class={"btn btn-sm justify-start text-left h-auto py-2 " <>
                  cond do
                    @step_mode and idx < @step_index -> "btn-ghost opacity-50"
                    @step_mode and idx == @step_index -> "btn-accent animate-pulse"
                    @step_mode and idx > @step_index -> "btn-disabled opacity-30"
                    true -> "btn-ghost hover:btn-outline"
                  end}
                disabled={@step_mode and idx != @step_index}
              >
                <div class="flex flex-col items-start">
                  <span class="font-mono text-xs">
                    <%= preset.left %> = <%= preset.right %>
                  </span>
                  <span class="text-xs opacity-60"><%= preset.description %></span>
                </div>
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Match History -->
      <%= if length(@history) > 0 do %>
        <div class="card bg-base-200 shadow-md mb-6">
          <div class="card-body p-4">
            <div class="flex items-center justify-between mb-3">
              <h3 class="card-title text-sm">Match History</h3>
              <button phx-click="clear_history" phx-target={@myself} class="btn btn-ghost btn-xs">Clear</button>
            </div>
            <div class="max-h-48 overflow-y-auto space-y-1">
              <%= for {entry, _idx} <- Enum.with_index(@history) do %>
                <div class={"font-mono text-xs p-2 rounded flex items-center gap-2 " <>
                  if(entry.success, do: "bg-success/10", else: "bg-error/10")}>
                  <span class={"badge badge-xs " <> if(entry.success, do: "badge-success", else: "badge-error")}>
                    <%= if entry.success, do: "ok", else: "err" %>
                  </span>
                  <span><%= entry.left %> = <%= entry.right %></span>
                  <%= if entry.success and map_size(entry.new_bindings) > 0 do %>
                    <span class="opacity-50">
                      binds: <%= Enum.map_join(entry.new_bindings, ", ", fn {k, v} -> "#{k}=#{v}" end) %>
                    </span>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div class="bg-info/10 border border-info/30 rounded-lg p-4">
              <h4 class="font-bold text-info text-sm mb-2">Binding</h4>
              <div class="font-mono text-xs space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Variable on left binds</div>
                  <div>x = 1</div>
                  <div class="text-success">x is now 1</div>
                </div>
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Rebinding is allowed</div>
                  <div>x = 2</div>
                  <div class="text-success">x is now 2</div>
                </div>
              </div>
            </div>

            <div class="bg-success/10 border border-success/30 rounded-lg p-4">
              <h4 class="font-bold text-success text-sm mb-2">Matching</h4>
              <div class="font-mono text-xs space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Literal on left must match</div>
                  <div>1 = 1</div>
                  <div class="text-success">Match succeeds!</div>
                </div>
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># After x = 1:</div>
                  <div>1 = x</div>
                  <div class="text-success">Succeeds (x is 1)</div>
                </div>
              </div>
            </div>

            <div class="bg-error/10 border border-error/30 rounded-lg p-4">
              <h4 class="font-bold text-error text-sm mb-2">MatchError</h4>
              <div class="font-mono text-xs space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Literals that don't match</div>
                  <div>2 = 1</div>
                  <div class="text-error">** (MatchError)</div>
                </div>
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Structure mismatch</div>
                  <div>&lbrace;a, b&rbrace; = &lbrace;1, 2, 3&rbrace;</div>
                  <div class="text-error">** (MatchError)</div>
                </div>
              </div>
            </div>
          </div>

          <div class="mt-4 p-3 bg-base-300 rounded-lg text-sm">
            <span class="font-bold text-warning">Pin Operator ^</span>
            <div class="font-mono text-xs mt-2 space-y-1">
              <div>x = 1          <span class="text-success"># binds x to 1</span></div>
              <div>^x = 1         <span class="text-success"># matches: x is already 1</span></div>
              <div>^x = 2         <span class="text-error"># MatchError: x is 1, not 2</span></div>
            </div>
            <p class="text-xs opacity-70 mt-2">
              The pin operator <code class="font-mono">^</code> prevents rebinding, forcing the existing value to be used in the match.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("try_match", %{"left" => left, "right" => right}, socket) do
    left = String.trim(left)
    right = String.trim(right)

    if left != "" and right != "" do
      {result, new_bindings} = evaluate_match(left, right, socket.assigns.bindings)

      updated_bindings =
        if result.success do
          Map.merge(socket.assigns.bindings, new_bindings)
        else
          socket.assigns.bindings
        end

      history_entry = Map.put(result, :new_bindings, new_bindings)

      {:noreply,
       socket
       |> assign(match_result: result)
       |> assign(bindings: updated_bindings)
       |> assign(left_input: left)
       |> assign(right_input: right)
       |> assign(history: [history_entry | socket.assigns.history] |> Enum.take(20))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("load_preset", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    preset = Enum.at(@preset_examples, idx)

    {result, new_bindings} = evaluate_match(preset.left, preset.right, socket.assigns.bindings)

    updated_bindings =
      if result.success do
        Map.merge(socket.assigns.bindings, new_bindings)
      else
        socket.assigns.bindings
      end

    history_entry = Map.put(result, :new_bindings, new_bindings)

    step_index =
      if socket.assigns.step_mode do
        max(socket.assigns.step_index, idx + 1)
      else
        socket.assigns.step_index
      end

    {:noreply,
     socket
     |> assign(left_input: preset.left)
     |> assign(right_input: preset.right)
     |> assign(match_result: result)
     |> assign(bindings: updated_bindings)
     |> assign(step_index: step_index)
     |> assign(history: [history_entry | socket.assigns.history] |> Enum.take(20))}
  end

  def handle_event("toggle_step_mode", _params, socket) do
    new_mode = !socket.assigns.step_mode

    {:noreply,
     socket
     |> assign(step_mode: new_mode)
     |> assign(step_index: 0)
     |> assign(bindings: %{})
     |> assign(match_result: nil)
     |> assign(history: [])}
  end

  def handle_event("step_next", _params, socket) do
    idx = socket.assigns.step_index

    if idx < length(@preset_examples) do
      preset = Enum.at(@preset_examples, idx)

      {result, new_bindings} = evaluate_match(preset.left, preset.right, socket.assigns.bindings)

      updated_bindings =
        if result.success do
          Map.merge(socket.assigns.bindings, new_bindings)
        else
          socket.assigns.bindings
        end

      history_entry = Map.put(result, :new_bindings, new_bindings)

      {:noreply,
       socket
       |> assign(left_input: preset.left)
       |> assign(right_input: preset.right)
       |> assign(match_result: result)
       |> assign(bindings: updated_bindings)
       |> assign(step_index: idx + 1)
       |> assign(history: [history_entry | socket.assigns.history] |> Enum.take(20))}
    else
      {:noreply, socket}
    end
  end

  def handle_event("step_reset", _params, socket) do
    {:noreply,
     socket
     |> assign(step_index: 0)
     |> assign(bindings: %{})
     |> assign(match_result: nil)
     |> assign(history: [])}
  end

  def handle_event("test_rebind", %{"var" => var, "val" => val}, socket) do
    result = %{
      left: val,
      right: var,
      success: true,
      explanation: "Match succeeds! The value of #{var} is #{val}, and #{val} = #{val} matches."
    }

    history_entry = Map.put(result, :new_bindings, %{})

    {:noreply,
     socket
     |> assign(match_result: result)
     |> assign(left_input: val)
     |> assign(right_input: var)
     |> assign(history: [history_entry | socket.assigns.history] |> Enum.take(20))}
  end

  def handle_event("test_rebind_fail", %{"var" => var, "val" => val}, socket) do
    wrong_val = generate_wrong_value(val)

    result = %{
      left: wrong_val,
      right: var,
      success: false,
      explanation: "MatchError! #{var} is bound to #{val}, but #{wrong_val} does not match #{val}."
    }

    history_entry = Map.put(result, :new_bindings, %{})

    {:noreply,
     socket
     |> assign(match_result: result)
     |> assign(left_input: wrong_val)
     |> assign(right_input: var)
     |> assign(history: [history_entry | socket.assigns.history] |> Enum.take(20))}
  end

  def handle_event("clear_bindings", _params, socket) do
    {:noreply, assign(socket, bindings: %{})}
  end

  def handle_event("clear_history", _params, socket) do
    {:noreply, assign(socket, history: [])}
  end

  # Match evaluation engine

  defp evaluate_match(left, right, existing_bindings) do
    try do
      right_val = parse_value(right, existing_bindings)
      match_pattern(left, right_val, existing_bindings)
    rescue
      _ ->
        {%{left: left, right: right, success: false,
           explanation: "Could not parse the expression. Check your syntax."}, %{}}
    end
  end

  defp match_pattern(pattern, value, existing_bindings) do
    pattern = String.trim(pattern)
    str_value = format_value(value)

    cond do
      # Underscore - matches anything
      pattern == "_" ->
        {%{left: pattern, right: str_value, success: true,
           explanation: "_ matches any value and discards it."}, %{}}

      # Pin operator
      String.starts_with?(pattern, "^") ->
        var_name = String.trim_leading(pattern, "^")
        case Map.fetch(existing_bindings, var_name) do
          {:ok, bound_val} ->
            if bound_val == str_value do
              {%{left: pattern, right: str_value, success: true,
                 explanation: "Pin match: ^#{var_name} is #{bound_val}, which matches #{str_value}."}, %{}}
            else
              {%{left: pattern, right: str_value, success: false,
                 explanation: "Pin match failed: ^#{var_name} is #{bound_val}, but right side is #{str_value}."}, %{}}
            end
          :error ->
            {%{left: pattern, right: str_value, success: false,
               explanation: "Cannot pin #{var_name}: it is not bound yet."}, %{}}
        end

      # Tuple pattern: {a, b} or {a, b, c}
      String.starts_with?(pattern, "{") and String.ends_with?(pattern, "}") ->
        match_tuple_pattern(pattern, value, str_value, existing_bindings)

      # List pattern: [h | t] or [a, b, c]
      String.starts_with?(pattern, "[") and String.ends_with?(pattern, "]") ->
        match_list_pattern(pattern, value, str_value, existing_bindings)

      # Map pattern: %{key: val}
      String.starts_with?(pattern, "%{") and String.ends_with?(pattern, "}") ->
        match_map_pattern(pattern, value, str_value, existing_bindings)

      # Simple variable name
      Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pattern) ->
        {%{left: pattern, right: str_value, success: true,
           explanation: "Variable #{pattern} is now bound to #{str_value}."}, %{pattern => str_value}}

      # Literal value
      true ->
        if pattern == str_value do
          {%{left: pattern, right: str_value, success: true,
             explanation: "Literal match: #{pattern} equals #{str_value}."}, %{}}
        else
          {%{left: pattern, right: str_value, success: false,
             explanation: "No match: #{pattern} does not equal #{str_value}."}, %{}}
        end
    end
  end

  defp match_tuple_pattern(pattern, value, str_value, _existing_bindings) do
    inner = pattern |> String.trim_leading("{") |> String.trim_trailing("}") |> String.trim()
    pat_elements = split_elements(inner)

    case value do
      {:tuple, elements} ->
        if length(pat_elements) == length(elements) do
          new_bindings =
            Enum.zip(pat_elements, elements)
            |> Enum.reduce(%{}, fn {pat, val}, acc ->
              pat = String.trim(pat)
              cond do
                pat == "_" -> acc
                String.starts_with?(pat, ":") -> acc
                Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pat) -> Map.put(acc, pat, format_value(val))
                true -> acc
              end
            end)

          tag_match =
            Enum.zip(pat_elements, elements)
            |> Enum.all?(fn {pat, val} ->
              pat = String.trim(pat)
              cond do
                pat == "_" -> true
                String.starts_with?(pat, ":") -> pat == format_value(val)
                Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pat) -> true
                true -> pat == format_value(val)
              end
            end)

          if tag_match do
            bindings_desc =
              if map_size(new_bindings) > 0 do
                " Bindings: " <> Enum.map_join(new_bindings, ", ", fn {k, v} -> "#{k} = #{v}" end)
              else
                ""
              end
            {%{left: pattern, right: str_value, success: true,
               explanation: "Tuple match succeeded!#{bindings_desc}"}, new_bindings}
          else
            {%{left: pattern, right: str_value, success: false,
               explanation: "Tuple elements do not match. Tags or literals differ."}, %{}}
          end
        else
          {%{left: pattern, right: str_value, success: false,
             explanation: "Tuple size mismatch: pattern has #{length(pat_elements)} elements, value has #{length(elements)}."}, %{}}
        end

      _ ->
        {%{left: pattern, right: str_value, success: false,
           explanation: "Cannot match tuple pattern against non-tuple value."}, %{}}
    end
  end

  defp match_list_pattern(pattern, value, str_value, _existing_bindings) do
    inner = pattern |> String.trim_leading("[") |> String.trim_trailing("]") |> String.trim()

    case value do
      {:list, elements} ->
        cond do
          # Empty pattern
          inner == "" ->
            if elements == [] do
              {%{left: pattern, right: str_value, success: true,
                 explanation: "Empty list matches empty list."}, %{}}
            else
              {%{left: pattern, right: str_value, success: false,
                 explanation: "Empty pattern does not match non-empty list."}, %{}}
            end

          # Head | Tail pattern
          String.contains?(inner, "|") ->
            [head_part, tail_part] = String.split(inner, "|", parts: 2)
            head_pats = head_part |> split_elements() |> Enum.map(&String.trim/1)
            tail_var = String.trim(tail_part)

            if length(elements) >= length(head_pats) do
              head_vals = Enum.take(elements, length(head_pats))
              tail_vals = Enum.drop(elements, length(head_pats))

              new_bindings =
                Enum.zip(head_pats, head_vals)
                |> Enum.reduce(%{}, fn {pat, val}, acc ->
                  cond do
                    pat == "_" -> acc
                    Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pat) -> Map.put(acc, pat, format_value(val))
                    true -> acc
                  end
                end)

              new_bindings =
                if tail_var != "_" and Regex.match?(~r/^[a-z_][a-z0-9_]*$/, tail_var) do
                  tail_str = "[" <> Enum.map_join(tail_vals, ", ", &format_value/1) <> "]"
                  Map.put(new_bindings, tail_var, tail_str)
                else
                  new_bindings
                end

              bindings_desc =
                if map_size(new_bindings) > 0 do
                  " Bindings: " <> Enum.map_join(new_bindings, ", ", fn {k, v} -> "#{k} = #{v}" end)
                else
                  ""
                end
              {%{left: pattern, right: str_value, success: true,
                 explanation: "List [head | tail] match succeeded!#{bindings_desc}"}, new_bindings}
            else
              {%{left: pattern, right: str_value, success: false,
                 explanation: "Not enough elements: need at least #{length(head_pats)}, got #{length(elements)}."}, %{}}
            end

          # Fixed-length pattern
          true ->
            pat_elements = split_elements(inner)

            if length(pat_elements) == length(elements) do
              new_bindings =
                Enum.zip(pat_elements, elements)
                |> Enum.reduce(%{}, fn {pat, val}, acc ->
                  pat = String.trim(pat)
                  cond do
                    pat == "_" -> acc
                    Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pat) -> Map.put(acc, pat, format_value(val))
                    true -> acc
                  end
                end)

              bindings_desc =
                if map_size(new_bindings) > 0 do
                  " Bindings: " <> Enum.map_join(new_bindings, ", ", fn {k, v} -> "#{k} = #{v}" end)
                else
                  ""
                end
              {%{left: pattern, right: str_value, success: true,
                 explanation: "Fixed-length list match succeeded!#{bindings_desc}"}, new_bindings}
            else
              {%{left: pattern, right: str_value, success: false,
                 explanation: "List length mismatch: pattern has #{length(pat_elements)} elements, value has #{length(elements)}."}, %{}}
            end
        end

      _ ->
        {%{left: pattern, right: str_value, success: false,
           explanation: "Cannot match list pattern against non-list value."}, %{}}
    end
  end

  defp match_map_pattern(pattern, value, str_value, _existing_bindings) do
    inner = pattern |> String.trim_leading("%{") |> String.trim_trailing("}") |> String.trim()
    pat_pairs = parse_map_pairs(inner)

    case value do
      {:map, map_data} ->
        {matched, bindings} =
          Enum.reduce(pat_pairs, {true, %{}}, fn {key, val_pat}, {still_match, acc} ->
            case Map.fetch(map_data, key) do
              {:ok, actual_val} ->
                val_pat = String.trim(val_pat)
                cond do
                  val_pat == "_" -> {still_match, acc}
                  Regex.match?(~r/^[a-z_][a-z0-9_]*$/, val_pat) ->
                    {still_match, Map.put(acc, val_pat, actual_val)}
                  true ->
                    if val_pat == actual_val, do: {still_match, acc}, else: {false, acc}
                end
              :error ->
                {false, acc}
            end
          end)

        if matched do
          bindings_desc =
            if map_size(bindings) > 0 do
              " Bindings: " <> Enum.map_join(bindings, ", ", fn {k, v} -> "#{k} = #{v}" end)
            else
              ""
            end
          {%{left: pattern, right: str_value, success: true,
             explanation: "Map match succeeded (partial match)!#{bindings_desc}"}, bindings}
        else
          {%{left: pattern, right: str_value, success: false,
             explanation: "Map match failed: required keys or values do not match."}, %{}}
        end

      _ ->
        {%{left: pattern, right: str_value, success: false,
           explanation: "Cannot match map pattern against non-map value."}, %{}}
    end
  end

  # Value parsing

  defp parse_value(str, bindings) do
    str = String.trim(str)

    cond do
      # Tuple
      String.starts_with?(str, "{") and String.ends_with?(str, "}") ->
        inner = str |> String.trim_leading("{") |> String.trim_trailing("}") |> String.trim()
        elements = split_elements(inner) |> Enum.map(fn s -> parse_value(String.trim(s), bindings) end)
        {:tuple, elements}

      # List
      String.starts_with?(str, "[") and String.ends_with?(str, "]") ->
        inner = str |> String.trim_leading("[") |> String.trim_trailing("]") |> String.trim()
        if inner == "" do
          {:list, []}
        else
          elements = split_elements(inner) |> Enum.map(fn s -> parse_value(String.trim(s), bindings) end)
          {:list, elements}
        end

      # Map
      String.starts_with?(str, "%{") and String.ends_with?(str, "}") ->
        inner = str |> String.trim_leading("%{") |> String.trim_trailing("}") |> String.trim()
        pairs = parse_map_pairs(inner)
        {:map, Map.new(pairs)}

      # Atom
      String.starts_with?(str, ":") ->
        {:atom, str}

      # String
      String.starts_with?(str, "\"") and String.ends_with?(str, "\"") ->
        {:string, String.trim(str, "\"")}

      # Variable reference
      Map.has_key?(bindings, str) ->
        {:literal, Map.get(bindings, str)}

      # Number
      true ->
        case Integer.parse(str) do
          {n, ""} -> {:number, n}
          _ ->
            case Float.parse(str) do
              {f, ""} -> {:number, f}
              _ -> {:literal, str}
            end
        end
    end
  end

  defp format_value({:tuple, elements}) do
    "{" <> Enum.map_join(elements, ", ", &format_value/1) <> "}"
  end

  defp format_value({:list, elements}) do
    "[" <> Enum.map_join(elements, ", ", &format_value/1) <> "]"
  end

  defp format_value({:map, map_data}) do
    pairs = Enum.map_join(map_data, ", ", fn {k, v} -> "#{k}: #{v}" end)
    "%{" <> pairs <> "}"
  end

  defp format_value({:atom, str}), do: str
  defp format_value({:string, str}), do: "\"#{str}\""
  defp format_value({:number, n}), do: to_string(n)
  defp format_value({:literal, str}), do: to_string(str)
  defp format_value(other), do: inspect(other)

  defp split_elements(str) do
    str
    |> String.trim()
    |> do_split_elements(0, 0, [], "")
  end

  defp do_split_elements("", _paren, _bracket, acc, current) do
    current = String.trim(current)
    if current == "", do: acc, else: acc ++ [current]
  end

  defp do_split_elements("," <> rest, 0, 0, acc, current) do
    do_split_elements(rest, 0, 0, acc ++ [String.trim(current)], "")
  end

  defp do_split_elements("{" <> rest, paren, bracket, acc, current) do
    do_split_elements(rest, paren + 1, bracket, acc, current <> "{")
  end

  defp do_split_elements("}" <> rest, paren, bracket, acc, current) do
    do_split_elements(rest, max(paren - 1, 0), bracket, acc, current <> "}")
  end

  defp do_split_elements("[" <> rest, paren, bracket, acc, current) do
    do_split_elements(rest, paren, bracket + 1, acc, current <> "[")
  end

  defp do_split_elements("]" <> rest, paren, bracket, acc, current) do
    do_split_elements(rest, paren, max(bracket - 1, 0), acc, current <> "]")
  end

  defp do_split_elements(<<c::utf8, rest::binary>>, paren, bracket, acc, current) do
    do_split_elements(rest, paren, bracket, acc, current <> <<c::utf8>>)
  end

  defp parse_map_pairs(str) do
    str
    |> split_elements()
    |> Enum.flat_map(fn pair ->
      cond do
        String.contains?(pair, ": ") ->
          [key, val] = String.split(pair, ": ", parts: 2)
          [{String.trim(key), String.trim(val)}]

        String.contains?(pair, " => ") ->
          [key, val] = String.split(pair, " => ", parts: 2)
          [{String.trim(key), String.trim(val)}]

        true ->
          []
      end
    end)
  end

  defp generate_wrong_value(val) do
    case Integer.parse(val) do
      {n, ""} -> to_string(n + 99)
      _ -> "wrong_value"
    end
  end
end
