defmodule ElixirKatasWeb.ElixirKata04AtomsBooleanLive do
  use ElixirKatasWeb, :live_component

  @value_options [
    {"true", true},
    {"false", false},
    {"nil", nil},
    {":ok", :ok},
    {":error", :error},
    {"0", 0},
    {"1", 1},
    {"\"\"", ""},
    {"\"hello\"", "hello"},
    {"[]", []}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign(active_tab: "notes")
     |> assign(left_value: "true")
     |> assign(right_value: "false")
     |> assign(value_options: @value_options)
     |> assign(results: compute_results("true", "false"))
     |> assign(truthiness: compute_truthiness())}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="max-w-4xl mx-auto">
        <!-- Header -->
        <div class="text-center mb-8">
          <h2 class="text-3xl font-bold mb-2">Atoms & Boolean Logic</h2>
          <p class="text-base-content/60">
            Explore the difference between strict boolean operators (<code>and</code>/<code>or</code>/<code>not</code>)
            and truthy operators (<code>&&</code>/<code>||</code>/<code>!</code>).
          </p>
        </div>

        <!-- Truthiness Reference -->
        <div class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <h3 class="card-title text-xl mb-4">Truthiness in Elixir</h3>
            <p class="text-sm text-base-content/60 mb-4">
              In Elixir, only <code>false</code> and <code>nil</code> are falsy.
              <strong>Everything else is truthy</strong>, including <code>0</code>, <code>""</code>, and <code>[]</code>.
            </p>
            <div class="grid grid-cols-2 sm:grid-cols-5 gap-3">
              <div
                :for={{label, value} <- @truthiness}
                class={[
                  "flex flex-col items-center p-3 rounded-lg border-2 transition-all",
                  if(truthy?(value), do: "border-success bg-success/10", else: "border-error bg-error/10")
                ]}
              >
                <code class="font-bold text-sm">{label}</code>
                <span class={[
                  "badge badge-sm mt-1",
                  if(truthy?(value), do: "badge-success", else: "badge-error")
                ]}>
                  {if truthy?(value), do: "truthy", else: "falsy"}
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Truth Table Builder -->
        <div class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <h3 class="card-title text-xl mb-4">Truth Table Builder</h3>
            <p class="text-sm text-base-content/60 mb-4">
              Select two values and see how each operator evaluates them.
            </p>

            <!-- Value Selectors -->
            <form phx-change="update_values" phx-target={@myself}>
              <div class="flex flex-col sm:flex-row gap-6 items-end mb-6">
                <div class="form-control flex-1">
                  <label class="label">
                    <span class="label-text font-bold text-lg">Left Value</span>
                  </label>
                  <select name="left" class="select select-bordered select-lg font-mono w-full">
                    <option
                      :for={{label, _val} <- @value_options}
                      value={label}
                      selected={label == @left_value}
                    >
                      {label}
                    </option>
                  </select>
                </div>

                <div class="flex items-center">
                  <span class="text-2xl font-bold text-base-content/40">op</span>
                </div>

                <div class="form-control flex-1">
                  <label class="label">
                    <span class="label-text font-bold text-lg">Right Value</span>
                  </label>
                  <select name="right" class="select select-bordered select-lg font-mono w-full">
                    <option
                      :for={{label, _val} <- @value_options}
                      value={label}
                      selected={label == @right_value}
                    >
                      {label}
                    </option>
                  </select>
                </div>
              </div>
            </form>

            <!-- Results Table -->
            <div class="overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>Category</th>
                    <th>Expression</th>
                    <th>Result</th>
                    <th>Notes</th>
                  </tr>
                </thead>
                <tbody>
                  <!-- Strict Boolean Operators -->
                  <tr class="bg-blue-500/5">
                    <td rowspan="2" class="font-bold text-blue-500 align-middle">
                      Strict Boolean
                      <div class="text-xs font-normal text-base-content/50 mt-1">
                        Requires boolean left operand
                      </div>
                    </td>
                    <td class="font-mono text-sm">{@left_value} and {@right_value}</td>
                    <td>
                      {render_result(@results[:and])}
                    </td>
                    <td class="text-xs text-base-content/60">
                      {if @results[:and_error], do: @results[:and_error], else: "Returns right if left is true"}
                    </td>
                  </tr>
                  <tr class="bg-blue-500/5">
                    <td class="font-mono text-sm">{@left_value} or {@right_value}</td>
                    <td>
                      {render_result(@results[:or])}
                    </td>
                    <td class="text-xs text-base-content/60">
                      {if @results[:or_error], do: @results[:or_error], else: "Returns left if truthy, else right"}
                    </td>
                  </tr>

                  <!-- Truthy Operators -->
                  <tr class="bg-green-500/5">
                    <td rowspan="2" class="font-bold text-green-500 align-middle">
                      Truthy (Relaxed)
                      <div class="text-xs font-normal text-base-content/50 mt-1">
                        Accepts any type
                      </div>
                    </td>
                    <td class="font-mono text-sm">{@left_value} && {@right_value}</td>
                    <td>
                      {render_result(@results[:amp_amp])}
                    </td>
                    <td class="text-xs text-base-content/60">
                      Returns right if left is truthy, else returns left
                    </td>
                  </tr>
                  <tr class="bg-green-500/5">
                    <td class="font-mono text-sm">{@left_value} || {@right_value}</td>
                    <td>
                      {render_result(@results[:pipe_pipe])}
                    </td>
                    <td class="text-xs text-base-content/60">
                      Returns left if truthy, else returns right
                    </td>
                  </tr>

                  <!-- Not Operators -->
                  <tr class="bg-amber-500/5">
                    <td rowspan="2" class="font-bold text-amber-500 align-middle">
                      Negation
                    </td>
                    <td class="font-mono text-sm">not {@left_value}</td>
                    <td>
                      {render_result(@results[:not_left])}
                    </td>
                    <td class="text-xs text-base-content/60">
                      {if @results[:not_left_error], do: @results[:not_left_error], else: "Strict: requires boolean"}
                    </td>
                  </tr>
                  <tr class="bg-amber-500/5">
                    <td class="font-mono text-sm">!{@left_value}</td>
                    <td>
                      {render_result(@results[:bang_left])}
                    </td>
                    <td class="text-xs text-base-content/60">
                      Truthy: works with any value, always returns boolean
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Atoms Section -->
        <div class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <h3 class="card-title text-xl mb-4">Atoms Are Constants</h3>
            <p class="text-sm text-base-content/60 mb-4">
              Atoms are constants whose name is their value. They are commonly used as message identifiers,
              keys, and status indicators in Elixir.
            </p>
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div class="bg-base-300 rounded-lg p-4">
                <h4 class="font-bold mb-2">Common Atoms</h4>
                <div class="space-y-2 font-mono text-sm">
                  <div class="flex justify-between">
                    <code>:ok</code>
                    <span class="text-base-content/50">Success status</span>
                  </div>
                  <div class="flex justify-between">
                    <code>:error</code>
                    <span class="text-base-content/50">Failure status</span>
                  </div>
                  <div class="flex justify-between">
                    <code>true</code>
                    <span class="text-base-content/50">Same as :true</span>
                  </div>
                  <div class="flex justify-between">
                    <code>false</code>
                    <span class="text-base-content/50">Same as :false</span>
                  </div>
                  <div class="flex justify-between">
                    <code>nil</code>
                    <span class="text-base-content/50">Same as :nil</span>
                  </div>
                </div>
              </div>
              <div class="bg-base-300 rounded-lg p-4">
                <h4 class="font-bold mb-2">Atom Identity</h4>
                <div class="space-y-2 font-mono text-sm">
                  <div class="flex justify-between">
                    <code>true == :true</code>
                    <span class="badge badge-success badge-sm">true</span>
                  </div>
                  <div class="flex justify-between">
                    <code>false == :false</code>
                    <span class="badge badge-success badge-sm">true</span>
                  </div>
                  <div class="flex justify-between">
                    <code>nil == :nil</code>
                    <span class="badge badge-success badge-sm">true</span>
                  </div>
                  <div class="flex justify-between">
                    <code>is_atom(true)</code>
                    <span class="badge badge-success badge-sm">true</span>
                  </div>
                  <div class="flex justify-between">
                    <code>is_atom(nil)</code>
                    <span class="badge badge-success badge-sm">true</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- Comparison Quick Reference -->
        <div class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <h3 class="card-title text-xl mb-4">Operator Quick Reference</h3>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Operator</th>
                    <th>Type</th>
                    <th>Left Operand</th>
                    <th>Short-circuits?</th>
                    <th>Returns</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="font-mono font-bold text-blue-500">and</td>
                    <td>Strict</td>
                    <td>Must be boolean</td>
                    <td><span class="badge badge-success badge-xs">Yes</span></td>
                    <td>Second value or false</td>
                  </tr>
                  <tr>
                    <td class="font-mono font-bold text-blue-500">or</td>
                    <td>Strict</td>
                    <td>Must be boolean</td>
                    <td><span class="badge badge-success badge-xs">Yes</span></td>
                    <td>First truthy or second value</td>
                  </tr>
                  <tr>
                    <td class="font-mono font-bold text-blue-500">not</td>
                    <td>Strict</td>
                    <td>Must be boolean</td>
                    <td>N/A</td>
                    <td>Boolean</td>
                  </tr>
                  <tr>
                    <td class="font-mono font-bold text-green-500">&&</td>
                    <td>Truthy</td>
                    <td>Any value</td>
                    <td><span class="badge badge-success badge-xs">Yes</span></td>
                    <td>Second value or first falsy</td>
                  </tr>
                  <tr>
                    <td class="font-mono font-bold text-green-500">||</td>
                    <td>Truthy</td>
                    <td>Any value</td>
                    <td><span class="badge badge-success badge-xs">Yes</span></td>
                    <td>First truthy or second value</td>
                  </tr>
                  <tr>
                    <td class="font-mono font-bold text-green-500">!</td>
                    <td>Truthy</td>
                    <td>Any value</td>
                    <td>N/A</td>
                    <td>Boolean (always)</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>

        <!-- Key Insight -->
        <div class="alert alert-info">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <div>
            <h4 class="font-bold">Key Insight</h4>
            <p class="text-sm">
              <code>and</code>/<code>or</code>/<code>not</code> require a boolean as the first argument and will
              raise <code>BadBooleanError</code> otherwise. Use <code>&&</code>/<code>||</code>/<code>!</code>
              when working with non-boolean values. In practice, <code>&&</code> and <code>||</code> are
              more commonly used because they are more flexible.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("update_values", %{"left" => left, "right" => right}, socket) do
    results = compute_results(left, right)

    {:noreply,
     socket
     |> assign(left_value: left)
     |> assign(right_value: right)
     |> assign(results: results)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp compute_results(left_key, right_key) do
    left = resolve_value(left_key)
    right = resolve_value(right_key)

    # Truthy operators (always work)
    amp_amp_result = left && right
    pipe_pipe_result = left || right
    bang_left_result = !left

    # Strict boolean operators (may raise)
    {and_result, and_error} = safe_strict_op(left, right, :and)
    {or_result, or_error} = safe_strict_op(left, right, :or)
    {not_left_result, not_left_error} = safe_not(left)

    %{
      and: and_result,
      and_error: and_error,
      or: or_result,
      or_error: or_error,
      amp_amp: amp_amp_result,
      pipe_pipe: pipe_pipe_result,
      not_left: not_left_result,
      not_left_error: not_left_error,
      bang_left: bang_left_result
    }
  end

  defp safe_strict_op(left, right, :and) when is_boolean(left), do: {left and right, nil}
  defp safe_strict_op(left, _right, :and), do: {nil, "BadBooleanError: #{inspect(left)} is not boolean"}

  defp safe_strict_op(left, right, :or) when is_boolean(left), do: {left or right, nil}
  defp safe_strict_op(left, _right, :or), do: {nil, "BadBooleanError: #{inspect(left)} is not boolean"}

  defp safe_not(value) when is_boolean(value), do: {not value, nil}
  defp safe_not(value), do: {nil, "ArgumentError: not #{inspect(value)} is not boolean"}

  defp resolve_value("true"), do: true
  defp resolve_value("false"), do: false
  defp resolve_value("nil"), do: nil
  defp resolve_value(":ok"), do: :ok
  defp resolve_value(":error"), do: :error
  defp resolve_value("0"), do: 0
  defp resolve_value("1"), do: 1
  defp resolve_value("\"\""), do: ""
  defp resolve_value("\"hello\""), do: "hello"
  defp resolve_value("[]"), do: []
  defp resolve_value(other), do: other

  defp truthy?(false), do: false
  defp truthy?(nil), do: false
  defp truthy?(_), do: true

  defp compute_truthiness do
    Enum.map(@value_options, fn {label, value} -> {label, value} end)
  end

  defp render_result(nil) do
    assigns = %{}

    ~H"""
    <span class="badge badge-error badge-sm">ERROR</span>
    """
  end

  defp render_result(value) do
    assigns = %{value: value, class: result_badge_class(value)}

    ~H"""
    <span class={"badge badge-lg font-mono font-bold #{@class}"}>{inspect(@value)}</span>
    """
  end

  defp result_badge_class(true), do: "badge-success"
  defp result_badge_class(false), do: "badge-error"
  defp result_badge_class(nil), do: "badge-warning"
  defp result_badge_class(_), do: "badge-info"
end
