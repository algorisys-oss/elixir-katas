defmodule ElixirKatasWeb.ElixirKata01TypeExplorerLive do
  use ElixirKatasWeb, :live_component

  @type_cards [
    %{
      type: :integer,
      label: "Integer",
      color: "bg-blue-500",
      text_color: "text-blue-500",
      border: "border-blue-500",
      description: "Whole numbers with no size limit. Supports hex (0xFF), octal (0o77), and binary (0b1010).",
      example: "42"
    },
    %{
      type: :float,
      label: "Float",
      color: "bg-purple-500",
      text_color: "text-purple-500",
      border: "border-purple-500",
      description: "64-bit double precision. Must have a decimal point with at least one digit on each side.",
      example: "3.14"
    },
    %{
      type: :string,
      label: "String (Binary)",
      color: "bg-green-500",
      text_color: "text-green-500",
      border: "border-green-500",
      description: "UTF-8 encoded binaries delimited by double quotes. Checked with is_binary/1.",
      example: "\"hello\""
    },
    %{
      type: :atom,
      label: "Atom",
      color: "bg-amber-500",
      text_color: "text-amber-500",
      border: "border-amber-500",
      description: "Constants whose name is their value. Prefixed with a colon. Atoms are not garbage collected.",
      example: ":ok"
    },
    %{
      type: :boolean,
      label: "Boolean",
      color: "bg-rose-500",
      text_color: "text-rose-500",
      border: "border-rose-500",
      description: "true and false are atoms. is_boolean(:true) returns true. Booleans are atoms!",
      example: "true"
    },
    %{
      type: :nil,
      label: "Nil",
      color: "bg-gray-500",
      text_color: "text-gray-500",
      border: "border-gray-500",
      description: "nil is also an atom. It represents the absence of a value. nil == :nil is true.",
      example: "nil"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign(active_tab: "notes")
     |> assign(selected_type: nil)
     |> assign(generated_value: nil)
     |> assign(input_value: "")
     |> assign(detected_type: nil)
     |> assign(type_cards: @type_cards)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="max-w-4xl mx-auto">
        <!-- Header -->
        <div class="text-center mb-8">
          <h2 class="text-3xl font-bold mb-2">Elixir Type Explorer</h2>
          <p class="text-base-content/60">
            Explore the basic types in Elixir. Click on a type card or use the detector below.
          </p>
        </div>

        <!-- Type Cards Grid -->
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mb-8">
          <div
            :for={card <- @type_cards}
            class={[
              "card border-2 cursor-pointer transition-all duration-200 hover:shadow-lg hover:scale-[1.02]",
              if(@selected_type == card.type, do: "#{card.border} shadow-lg scale-[1.02]", else: "border-base-300")
            ]}
            phx-click="select_type"
            phx-target={@myself}
            phx-value-type={card.type}
          >
            <div class="card-body p-4">
              <div class="flex items-center justify-between">
                <h3 class={"card-title text-base #{card.text_color}"}>{card.label}</h3>
                <div class={"badge badge-sm #{card.color} text-white"}>{card.type}</div>
              </div>
              <p class="text-sm text-base-content/60 mt-1">{card.description}</p>
              <div class="mt-3 flex items-center justify-between">
                <code class="bg-base-200 px-3 py-1 rounded text-sm font-mono">{card.example}</code>
                <button
                  class={"btn btn-xs #{card.color} text-white"}
                  phx-click="generate"
                  phx-target={@myself}
                  phx-value-type={card.type}
                >
                  Generate
                </button>
              </div>
            </div>
          </div>
        </div>

        <!-- Generated Value Display -->
        <div :if={@generated_value} class="alert shadow-lg mb-8">
          <div>
            <span class="font-semibold">Generated value:</span>
            <code class="ml-2 bg-base-200 px-3 py-1 rounded font-mono text-lg">{@generated_value}</code>
          </div>
        </div>

        <!-- Type Detector -->
        <div class="card bg-base-200 shadow-xl">
          <div class="card-body">
            <h3 class="card-title text-xl mb-4">Type Detector</h3>
            <p class="text-sm text-base-content/60 mb-4">
              Type a value below and see which Elixir guard functions match it.
              The detector parses your input and runs <code>is_integer/1</code>, <code>is_float/1</code>,
              <code>is_binary/1</code>, <code>is_atom/1</code>, <code>is_boolean/1</code>, and <code>is_nil/1</code>.
            </p>

            <form phx-change="detect_type" phx-target={@myself} class="flex gap-4 items-end">
              <div class="form-control flex-1">
                <label class="label">
                  <span class="label-text font-semibold">Enter a value</span>
                </label>
                <input
                  type="text"
                  name="value"
                  value={@input_value}
                  placeholder={~s(Try: 42, 3.14, "hello", :ok, true, nil)}
                  class="input input-bordered w-full font-mono"
                />
              </div>
            </form>

            <div :if={@detected_type} class="mt-6">
              <div class="overflow-x-auto">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Guard Function</th>
                      <th>Result</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr :for={{guard, result} <- @detected_type}>
                      <td class="font-mono text-sm">{guard}</td>
                      <td>
                        <span class={[
                          "badge",
                          if(result, do: "badge-success", else: "badge-ghost")
                        ]}>
                          {inspect(result)}
                        </span>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div :if={@detected_type} class="mt-4 p-4 bg-base-300 rounded-lg">
              <span class="font-semibold">Detected type: </span>
              <span class="font-mono text-primary text-lg font-bold">{primary_type(@detected_type)}</span>
            </div>
          </div>
        </div>

        <!-- Key Insight -->
        <div class="alert alert-info mt-8">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
          </svg>
          <div>
            <h4 class="font-bold">Key Insight</h4>
            <p class="text-sm">
              In Elixir, <code>true</code>, <code>false</code>, and <code>nil</code> are all atoms.
              So <code>is_atom(true)</code> returns <code>true</code>, and <code>is_atom(nil)</code> returns <code>true</code>.
              Booleans pass both <code>is_boolean/1</code> and <code>is_atom/1</code>.
            </p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("select_type", %{"type" => type}, socket) do
    type_atom = String.to_existing_atom(type)
    {:noreply, assign(socket, selected_type: type_atom, generated_value: generate_example(type_atom))}
  end

  def handle_event("generate", %{"type" => type}, socket) do
    type_atom = String.to_existing_atom(type)
    {:noreply, assign(socket, selected_type: type_atom, generated_value: generate_example(type_atom))}
  end

  def handle_event("detect_type", %{"value" => value}, socket) do
    parsed = parse_value(value)
    checks = detect_checks(parsed)
    {:noreply, assign(socket, input_value: value, detected_type: checks)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp generate_example(:integer) do
    examples = [42, -17, 1_000_000, 0xFF, 255, 0, 100, -99, 12345]
    inspect(Enum.random(examples))
  end

  defp generate_example(:float) do
    examples = [3.14, 2.718, -0.5, 1.0e10, 99.99, 0.001, 1.618]
    inspect(Enum.random(examples))
  end

  defp generate_example(:string) do
    examples = ["hello", "Elixir", "world", "foo bar", "LiveView rocks", "42 is a string now"]
    inspect(Enum.random(examples))
  end

  defp generate_example(:atom) do
    examples = [:ok, :error, :hello, :elixir, :world, :foo, :bar]
    inspect(Enum.random(examples))
  end

  defp generate_example(:boolean) do
    inspect(Enum.random([true, false]))
  end

  defp generate_example(:nil) do
    "nil"
  end

  defp parse_value("nil"), do: nil
  defp parse_value("true"), do: true
  defp parse_value("false"), do: false

  defp parse_value(":" <> rest) do
    try do
      String.to_existing_atom(rest)
    rescue
      _ -> String.to_atom(rest)
    end
  end

  defp parse_value(value) do
    cond do
      match?({_int, ""}, Integer.parse(value)) ->
        {int, ""} = Integer.parse(value)
        int

      match?({_float, ""}, Float.parse(value)) ->
        {float, ""} = Float.parse(value)
        float

      true ->
        value
    end
  end

  defp detect_checks(value) do
    [
      {"is_integer(#{inspect(value)})", is_integer(value)},
      {"is_float(#{inspect(value)})", is_float(value)},
      {"is_number(#{inspect(value)})", is_number(value)},
      {"is_binary(#{inspect(value)})", is_binary(value)},
      {"is_atom(#{inspect(value)})", is_atom(value)},
      {"is_boolean(#{inspect(value)})", is_boolean(value)},
      {"is_nil(#{inspect(value)})", is_nil(value)}
    ]
  end

  defp primary_type(checks) do
    cond do
      check_result(checks, "is_nil") -> "nil (also an atom)"
      check_result(checks, "is_boolean") -> "boolean (also an atom)"
      check_result(checks, "is_integer") -> "integer"
      check_result(checks, "is_float") -> "float"
      check_result(checks, "is_binary") -> "string (binary)"
      check_result(checks, "is_atom") -> "atom"
      true -> "unknown"
    end
  end

  defp check_result(checks, prefix) do
    Enum.any?(checks, fn {guard, result} -> String.starts_with?(guard, prefix) and result end)
  end
end
