defmodule ElixirKatasWeb.ElixirKata05ComparisonLive do
  use ElixirKatasWeb, :live_component

  @type_defaults %{
    "integer" => "42",
    "float" => "3.14",
    "string" => "hello",
    "atom" => ":world",
    "boolean" => "true",
    "list" => "[1, 2, 3]",
    "tuple" => "{1, 2}",
    "map" => "%{a: 1}"
  }

  @type_options ["integer", "float", "string", "atom", "boolean", "list", "tuple", "map"]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:left_type, fn -> "integer" end)
     |> assign_new(:right_type, fn -> "float" end)
     |> assign_new(:left_value, fn -> "42" end)
     |> assign_new(:right_value, fn -> "42.0" end)
     |> compute_comparisons()}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Comparison & Ordering Explorer</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir can compare values of any type. Explore how operators work and discover the universal type ordering.
      </p>

      <!-- Input Controls -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-8">
        <!-- Left Value -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <h3 class="card-title text-sm">Left Value</h3>
            <form phx-change="change_left" phx-target={@myself}>
              <div class="form-control mb-2">
                <label class="label py-1">
                  <span class="label-text text-xs font-semibold">Type</span>
                </label>
                <select name="type" class="select select-bordered select-sm w-full">
                  <%= for t <- type_options() do %>
                    <option value={t} selected={t == @left_type}><%= t %></option>
                  <% end %>
                </select>
              </div>
              <div class="form-control">
                <label class="label py-1">
                  <span class="label-text text-xs font-semibold">Value</span>
                </label>
                <input
                  type="text"
                  name="value"
                  value={@left_value}
                  class="input input-bordered input-sm w-full font-mono"
                  autocomplete="off"
                />
              </div>
            </form>
            <div class="mt-2 text-xs opacity-60">
              Parsed as: <code class="font-mono bg-base-300 px-1 rounded"><%= @left_parsed_display %></code>
            </div>
          </div>
        </div>

        <!-- Right Value -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <h3 class="card-title text-sm">Right Value</h3>
            <form phx-change="change_right" phx-target={@myself}>
              <div class="form-control mb-2">
                <label class="label py-1">
                  <span class="label-text text-xs font-semibold">Type</span>
                </label>
                <select name="type" class="select select-bordered select-sm w-full">
                  <%= for t <- type_options() do %>
                    <option value={t} selected={t == @right_type}><%= t %></option>
                  <% end %>
                </select>
              </div>
              <div class="form-control">
                <label class="label py-1">
                  <span class="label-text text-xs font-semibold">Value</span>
                </label>
                <input
                  type="text"
                  name="value"
                  value={@right_value}
                  class="input input-bordered input-sm w-full font-mono"
                  autocomplete="off"
                />
              </div>
            </form>
            <div class="mt-2 text-xs opacity-60">
              Parsed as: <code class="font-mono bg-base-300 px-1 rounded"><%= @right_parsed_display %></code>
            </div>
          </div>
        </div>
      </div>

      <!-- Quick Presets -->
      <div class="mb-8">
        <h3 class="text-sm font-bold mb-2 opacity-70">Quick Presets</h3>
        <div class="flex flex-wrap gap-2">
          <button phx-click="preset" phx-target={@myself} phx-value-left_type="integer" phx-value-left_value="1" phx-value-right_type="float" phx-value-right_value="1.0" class="btn btn-xs btn-outline">1 vs 1.0</button>
          <button phx-click="preset" phx-target={@myself} phx-value-left_type="integer" phx-value-left_value="1" phx-value-right_type="integer" phx-value-right_value="2" class="btn btn-xs btn-outline">1 vs 2</button>
          <button phx-click="preset" phx-target={@myself} phx-value-left_type="boolean" phx-value-left_value="true" phx-value-right_type="atom" phx-value-right_value=":true" class="btn btn-xs btn-outline">true vs :true</button>
          <button phx-click="preset" phx-target={@myself} phx-value-left_type="string" phx-value-left_value="abc" phx-value-right_type="string" phx-value-right_value="abd" class="btn btn-xs btn-outline">"abc" vs "abd"</button>
          <button phx-click="preset" phx-target={@myself} phx-value-left_type="atom" phx-value-left_value=":hello" phx-value-right_type="string" phx-value-right_value="hello" class="btn btn-xs btn-outline">:hello vs "hello"</button>
          <button phx-click="preset" phx-target={@myself} phx-value-left_type="integer" phx-value-left_value="0" phx-value-right_type="atom" phx-value-right_value=":zero" class="btn btn-xs btn-outline">0 vs :zero</button>
          <button phx-click="preset" phx-target={@myself} phx-value-left_type="list" phx-value-left_value="[1, 2]" phx-value-right_type="tuple" phx-value-right_value={"{1, 2}"} class="btn btn-xs btn-outline">[1,2] vs &lbrace;1,2&rbrace;</button>
          <button phx-click="preset" phx-target={@myself} phx-value-left_type="boolean" phx-value-left_value="false" phx-value-right_type="atom" phx-value-right_value=":nil" class="btn btn-xs btn-outline">false vs nil</button>
        </div>
      </div>

      <!-- Comparison Results -->
      <div class="card bg-base-200 shadow-md mb-8">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Comparison Results</h3>
          <%= if @parse_error do %>
            <div class="alert alert-warning text-sm">
              <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-5 w-5" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
              <span><%= @parse_error %></span>
            </div>
          <% else %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th class="font-mono">Expression</th>
                    <th>Result</th>
                    <th>Description</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for {op, result, desc} <- @comparisons do %>
                    <tr>
                      <td class="font-mono text-sm">
                        <span class="text-info"><%= @left_parsed_display %></span>
                        <span class="font-bold text-warning"><%= op %></span>
                        <span class="text-secondary"><%= @right_parsed_display %></span>
                      </td>
                      <td>
                        <span class={"badge badge-sm " <> if(result, do: "badge-success", else: "badge-error")}>
                          <%= result %>
                        </span>
                      </td>
                      <td class="text-xs opacity-70"><%= desc %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <!-- Key Insight -->
            <div class="mt-4 p-3 bg-base-300 rounded-lg text-sm">
              <span class="font-bold text-warning">== vs ===</span>
              <p class="mt-1 opacity-80">
                <code class="font-mono">==</code> compares values with type coercion (1 == 1.0 is true).
                <code class="font-mono">===</code> is strict and checks type too (1 === 1.0 is false).
                This distinction only matters for integer vs float comparisons.
              </p>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Type Ordering Section -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Elixir Type Ordering</h3>
          <p class="text-sm opacity-70 mb-4">
            Elixir defines a total ordering over all types, so you can compare any two values.
            The ordering is:
          </p>
          <div class="flex flex-wrap items-center gap-1 text-sm font-mono mb-4">
            <%= for {type, idx} <- Enum.with_index(type_ordering()) do %>
              <span class={"badge " <> type_badge_color(type) <> " badge-md"}>
                <%= type %>
              </span>
              <%= if idx < length(type_ordering()) - 1 do %>
                <span class="text-warning font-bold">&lt;</span>
              <% end %>
            <% end %>
          </div>
          <div class="text-xs opacity-60 space-y-1">
            <p>This means <code class="font-mono">1 &lt; :hello</code> is <span class="badge badge-success badge-xs">true</span> because number &lt; atom.</p>
            <p>And <code class="font-mono">&lbrace;1, 2&rbrace; &lt; %&lbrace;&rbrace;</code> is <span class="badge badge-success badge-xs">true</span> because tuple &lt; map.</p>
            <p>Within the same type, values are compared by their natural ordering (e.g., alphabetical for strings).</p>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("change_left", %{"type" => type, "value" => value}, socket) do
    # If the type changed from what was previously selected, use the default value for the new type
    new_value =
      if type != socket.assigns.left_type,
        do: Map.get(@type_defaults, type, ""),
        else: value

    {:noreply,
     socket
     |> assign(left_type: type, left_value: new_value)
     |> compute_comparisons()}
  end

  def handle_event("change_right", %{"type" => type, "value" => value}, socket) do
    new_value =
      if type != socket.assigns.right_type,
        do: Map.get(@type_defaults, type, ""),
        else: value

    {:noreply,
     socket
     |> assign(right_type: type, right_value: new_value)
     |> compute_comparisons()}
  end

  def handle_event("preset", params, socket) do
    {:noreply,
     socket
     |> assign(
       left_type: params["left_type"],
       left_value: params["left_value"],
       right_type: params["right_type"],
       right_value: params["right_value"]
     )
     |> compute_comparisons()}
  end

  # Helpers

  defp compute_comparisons(socket) do
    left_type = socket.assigns.left_type
    right_type = socket.assigns.right_type
    left_raw = socket.assigns.left_value
    right_raw = socket.assigns.right_value

    with {:ok, left} <- parse_value(left_raw, left_type),
         {:ok, right} <- parse_value(right_raw, right_type) do
      comparisons = [
        {"==", left == right, "Equal (with type coercion)"},
        {"===", left === right, "Strict equal (no coercion)"},
        {"!=", left != right, "Not equal (with type coercion)"},
        {"!==", left !== right, "Strict not equal"},
        {"<", left < right, "Less than"},
        {">", left > right, "Greater than"},
        {"<=", left <= right, "Less than or equal"},
        {">=", left >= right, "Greater than or equal"}
      ]

      socket
      |> assign(comparisons: comparisons)
      |> assign(parse_error: nil)
      |> assign(left_parsed_display: inspect(left))
      |> assign(right_parsed_display: inspect(right))
    else
      {:error, msg} ->
        socket
        |> assign(comparisons: [])
        |> assign(parse_error: msg)
        |> assign(left_parsed_display: "?")
        |> assign(right_parsed_display: "?")
    end
  end

  defp parse_value(raw, "integer") do
    case Integer.parse(String.trim(raw)) do
      {n, ""} -> {:ok, n}
      _ -> {:error, "Could not parse '#{raw}' as integer. Try a whole number like 42."}
    end
  end

  defp parse_value(raw, "float") do
    trimmed = String.trim(raw)

    case Float.parse(trimmed) do
      {f, ""} ->
        {:ok, f}

      _ ->
        # Try integer parse and convert
        case Integer.parse(trimmed) do
          {n, ""} -> {:ok, n / 1}
          _ -> {:error, "Could not parse '#{raw}' as float. Try a number like 3.14."}
        end
    end
  end

  defp parse_value(raw, "string"), do: {:ok, String.trim(raw)}

  defp parse_value(raw, "atom") do
    trimmed = String.trim(raw)

    atom_name =
      if String.starts_with?(trimmed, ":"),
        do: String.slice(trimmed, 1..-1//1),
        else: trimmed

    if atom_name == "" do
      {:error, "Atom name cannot be empty. Try :hello or :world."}
    else
      {:ok, String.to_atom(atom_name)}
    end
  end

  defp parse_value(raw, "boolean") do
    case String.trim(raw) |> String.downcase() do
      "true" -> {:ok, true}
      "false" -> {:ok, false}
      _ -> {:error, "Boolean must be 'true' or 'false'."}
    end
  end

  defp parse_value(raw, "list") do
    trimmed = String.trim(raw)

    case Code.eval_string(trimmed) do
      {val, _} when is_list(val) -> {:ok, val}
      _ -> {:error, "Could not parse '#{raw}' as list. Try [1, 2, 3]."}
    end
  rescue
    _ -> {:error, "Could not parse '#{raw}' as list. Try [1, 2, 3]."}
  end

  defp parse_value(raw, "tuple") do
    trimmed = String.trim(raw)

    case Code.eval_string(trimmed) do
      {val, _} when is_tuple(val) -> {:ok, val}
      _ -> {:error, "Could not parse '#{raw}' as tuple. Try {1, 2}."}
    end
  rescue
    _ -> {:error, "Could not parse '#{raw}' as tuple. Try {1, 2}."}
  end

  defp parse_value(raw, "map") do
    trimmed = String.trim(raw)

    case Code.eval_string(trimmed) do
      {val, _} when is_map(val) -> {:ok, val}
      _ -> {:error, "Could not parse '#{raw}' as map. Try %{a: 1}."}
    end
  rescue
    _ -> {:error, "Could not parse '#{raw}' as map. Try %{a: 1}."}
  end

  defp parse_value(raw, _type), do: {:ok, raw}

  defp type_options, do: @type_options

  defp type_ordering do
    ["number", "atom", "reference", "function", "port", "pid", "tuple", "map", "list", "bitstring"]
  end

  defp type_badge_color("number"), do: "badge-primary"
  defp type_badge_color("atom"), do: "badge-secondary"
  defp type_badge_color("reference"), do: "badge-accent"
  defp type_badge_color("function"), do: "badge-info"
  defp type_badge_color("port"), do: "badge-warning"
  defp type_badge_color("pid"), do: "badge-error"
  defp type_badge_color("tuple"), do: "badge-primary"
  defp type_badge_color("map"), do: "badge-secondary"
  defp type_badge_color("list"), do: "badge-accent"
  defp type_badge_color("bitstring"), do: "badge-info"
  defp type_badge_color(_), do: "badge-ghost"
end
