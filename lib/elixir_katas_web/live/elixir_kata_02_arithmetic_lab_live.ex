defmodule ElixirKatasWeb.ElixirKata02ArithmeticLabLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign(active_tab: "notes")
     |> assign(a: "10")
     |> assign(b: "3")
     |> assign(results: [])
     |> assign(last_op: nil)
     |> assign(error: nil)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="max-w-4xl mx-auto">
        <!-- Header -->
        <div class="text-center mb-8">
          <h2 class="text-3xl font-bold mb-2">Arithmetic Lab</h2>
          <p class="text-base-content/60">
            Explore Elixir arithmetic operators. Notice how <code>/</code> always returns a float
            while <code>div/2</code> returns an integer.
          </p>
        </div>

        <!-- Input Section -->
        <div class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <form phx-change="update_inputs" phx-target={@myself}>
              <div class="flex flex-col sm:flex-row gap-6 items-end">
                <div class="form-control flex-1">
                  <label class="label">
                    <span class="label-text font-bold text-lg">A</span>
                  </label>
                  <input
                    type="text"
                    name="a"
                    value={@a}
                    class="input input-bordered input-lg font-mono text-center text-2xl"
                    placeholder="Enter number A"
                  />
                </div>

                <div class="flex items-center justify-center">
                  <span class="text-3xl font-bold text-base-content/40">op</span>
                </div>

                <div class="form-control flex-1">
                  <label class="label">
                    <span class="label-text font-bold text-lg">B</span>
                  </label>
                  <input
                    type="text"
                    name="b"
                    value={@b}
                    class="input input-bordered input-lg font-mono text-center text-2xl"
                    placeholder="Enter number B"
                  />
                </div>
              </div>
            </form>

            <!-- Operator Buttons -->
            <div class="grid grid-cols-3 sm:grid-cols-6 gap-3 mt-6">
              <button
                phx-click="calculate"
                phx-target={@myself}
                phx-value-op="+"
                class={[
                  "btn btn-lg font-mono text-xl",
                  if(@last_op == "+", do: "btn-primary", else: "btn-outline btn-primary")
                ]}
              >
                +
              </button>
              <button
                phx-click="calculate"
                phx-target={@myself}
                phx-value-op="-"
                class={[
                  "btn btn-lg font-mono text-xl",
                  if(@last_op == "-", do: "btn-secondary", else: "btn-outline btn-secondary")
                ]}
              >
                -
              </button>
              <button
                phx-click="calculate"
                phx-target={@myself}
                phx-value-op="*"
                class={[
                  "btn btn-lg font-mono text-xl",
                  if(@last_op == "*", do: "btn-accent", else: "btn-outline btn-accent")
                ]}
              >
                *
              </button>
              <button
                phx-click="calculate"
                phx-target={@myself}
                phx-value-op="/"
                class={[
                  "btn btn-lg font-mono text-xl",
                  if(@last_op == "/", do: "btn-warning", else: "btn-outline btn-warning")
                ]}
              >
                /
              </button>
              <button
                phx-click="calculate"
                phx-target={@myself}
                phx-value-op="div"
                class={[
                  "btn btn-lg font-mono text-sm",
                  if(@last_op == "div", do: "btn-info", else: "btn-outline btn-info")
                ]}
              >
                div
              </button>
              <button
                phx-click="calculate"
                phx-target={@myself}
                phx-value-op="rem"
                class={[
                  "btn btn-lg font-mono text-sm",
                  if(@last_op == "rem", do: "btn-success", else: "btn-outline btn-success")
                ]}
              >
                rem
              </button>
            </div>

            <div class="text-center mt-4">
              <button phx-click="run_all" phx-target={@myself} class="btn btn-ghost btn-sm">
                Run All Operators
              </button>
              <button phx-click="clear_results" phx-target={@myself} class="btn btn-ghost btn-sm ml-2">
                Clear Results
              </button>
            </div>
          </div>
        </div>

        <!-- Error Display -->
        <div :if={@error} class="alert alert-error mb-6">
          <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-6 w-6" fill="none" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
          <span>{@error}</span>
        </div>

        <!-- Results Table -->
        <div :if={@results != []} class="card bg-base-200 shadow-xl mb-8">
          <div class="card-body">
            <h3 class="card-title text-xl mb-4">Results</h3>
            <div class="overflow-x-auto">
              <table class="table">
                <thead>
                  <tr>
                    <th>Expression</th>
                    <th>Result</th>
                    <th>Return Type</th>
                    <th>Code</th>
                  </tr>
                </thead>
                <tbody>
                  <tr :for={{op, expr, result, type, code} <- Enum.reverse(@results)} class="hover">
                    <td class="font-mono text-lg">{expr}</td>
                    <td>
                      <span class="font-mono text-lg font-bold text-primary">{result}</span>
                    </td>
                    <td>
                      <span class={[
                        "badge",
                        type_badge_color(type)
                      ]}>
                        {type}
                      </span>
                    </td>
                    <td>
                      <code class="text-xs bg-base-300 px-2 py-1 rounded">{code}</code>
                    </td>
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
              The <code>/</code> operator <strong>always</strong> returns a float: <code>10 / 2</code> gives <code>5.0</code>, not <code>5</code>.
              Use <code>div(a, b)</code> for integer division and <code>rem(a, b)</code> for the remainder.
              Both <code>div</code> and <code>rem</code> require integer arguments.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("update_inputs", %{"a" => a, "b" => b}, socket) do
    {:noreply, assign(socket, a: a, b: b, error: nil)}
  end

  def handle_event("calculate", %{"op" => op}, socket) do
    case compute(socket.assigns.a, socket.assigns.b, op) do
      {:ok, result_entry} ->
        {:noreply,
         socket
         |> assign(results: [result_entry | socket.assigns.results])
         |> assign(last_op: op)
         |> assign(error: nil)}

      {:error, message} ->
        {:noreply, assign(socket, error: message, last_op: op)}
    end
  end

  def handle_event("run_all", _params, socket) do
    ops = ["+", "-", "*", "/", "div", "rem"]

    {results, errors} =
      Enum.reduce(ops, {[], []}, fn op, {res, errs} ->
        case compute(socket.assigns.a, socket.assigns.b, op) do
          {:ok, entry} -> {[entry | res], errs}
          {:error, msg} -> {res, [msg | errs]}
        end
      end)

    error = if errors != [], do: Enum.join(Enum.reverse(errors), "; "), else: nil
    {:noreply, assign(socket, results: Enum.reverse(results), last_op: nil, error: error)}
  end

  def handle_event("clear_results", _params, socket) do
    {:noreply, assign(socket, results: [], last_op: nil, error: nil)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp compute(a_str, b_str, op) do
    with {a, ""} <- Integer.parse(a_str),
         {b, ""} <- Integer.parse(b_str) do
      compute_op(a, b, op)
    else
      _ ->
        with {a, ""} <- Float.parse(a_str),
             {b, ""} <- Float.parse(b_str) do
          compute_float_op(a, b, op)
        else
          _ -> {:error, "Both A and B must be valid numbers."}
        end
    end
  end

  defp compute_op(a, b, "+") do
    result = a + b
    {:ok, {"+", "#{a} + #{b}", inspect(result), type_name(result), "#{a} + #{b}"}}
  end

  defp compute_op(a, b, "-") do
    result = a - b
    {:ok, {"-", "#{a} - #{b}", inspect(result), type_name(result), "#{a} - #{b}"}}
  end

  defp compute_op(a, b, "*") do
    result = a * b
    {:ok, {"*", "#{a} * #{b}", inspect(result), type_name(result), "#{a} * #{b}"}}
  end

  defp compute_op(_a, 0, "/") do
    {:error, "Division by zero is not allowed for / operator."}
  end

  defp compute_op(a, b, "/") do
    result = a / b
    {:ok, {"/", "#{a} / #{b}", inspect(result), type_name(result), "#{a} / #{b}"}}
  end

  defp compute_op(_a, 0, "div") do
    {:error, "Division by zero is not allowed for div/2."}
  end

  defp compute_op(a, b, "div") do
    result = div(a, b)
    {:ok, {"div", "div(#{a}, #{b})", inspect(result), type_name(result), "div(#{a}, #{b})"}}
  end

  defp compute_op(_a, 0, "rem") do
    {:error, "Division by zero is not allowed for rem/2."}
  end

  defp compute_op(a, b, "rem") do
    result = rem(a, b)
    {:ok, {"rem", "rem(#{a}, #{b})", inspect(result), type_name(result), "rem(#{a}, #{b})"}}
  end

  defp compute_float_op(a, b, "+") do
    result = a + b
    {:ok, {"+", "#{a} + #{b}", inspect(result), type_name(result), "#{a} + #{b}"}}
  end

  defp compute_float_op(a, b, "-") do
    result = a - b
    {:ok, {"-", "#{a} - #{b}", inspect(result), type_name(result), "#{a} - #{b}"}}
  end

  defp compute_float_op(a, b, "*") do
    result = a * b
    {:ok, {"*", "#{a} * #{b}", inspect(result), type_name(result), "#{a} * #{b}"}}
  end

  defp compute_float_op(_a, b, "/") when b == 0.0 do
    {:error, "Division by zero is not allowed for / operator."}
  end

  defp compute_float_op(a, b, "/") do
    result = a / b
    {:ok, {"/", "#{a} / #{b}", inspect(result), type_name(result), "#{a} / #{b}"}}
  end

  defp compute_float_op(_a, _b, "div") do
    {:error, "div/2 requires integer arguments. Use / for float division."}
  end

  defp compute_float_op(_a, _b, "rem") do
    {:error, "rem/2 requires integer arguments."}
  end

  defp type_name(value) when is_integer(value), do: "integer"
  defp type_name(value) when is_float(value), do: "float"
  defp type_name(_), do: "other"

  defp type_badge_color("integer"), do: "badge-info"
  defp type_badge_color("float"), do: "badge-secondary"
  defp type_badge_color(_), do: "badge-ghost"
end
