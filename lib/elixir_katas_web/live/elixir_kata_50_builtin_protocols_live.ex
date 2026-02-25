defmodule ElixirKatasWeb.ElixirKata50BuiltinProtocolsLive do
  use ElixirKatasWeb, :live_component

  @protocols [
    %{
      id: "string_chars",
      title: "String.Chars",
      description: "Converts a term to a string. Used by string interpolation and to_string/1.",
      define_code: ~s[# The protocol (built into Elixir):\ndefprotocol String.Chars do\n  def to_string(term)\nend],
      impl_code: "defmodule Temperature do\n  defstruct [:degrees, :unit]\nend\n\ndefimpl String.Chars, for: Temperature do\n  def to_string(%Temperature{degrees: d, unit: u}) do\n    \"\#{d}\#{unit_symbol(u)}\"\n  end\n\n  defp unit_symbol(:celsius), do: \"C\"\n  defp unit_symbol(:fahrenheit), do: \"F\"\n  defp unit_symbol(:kelvin), do: \"K\"\nend\n\ntemp = %Temperature{degrees: 100, unit: :celsius}\n\"Water boils at \#{temp}\"\n#=> \"Water boils at 100C\"",
      try_examples: [
        {"atom", ~s|to_string(:hello)|},
        {"integer", "to_string(42)"},
        {"float", "to_string(3.14)"},
        {"interpolation", ~s|x = 42; "The answer is \#{x}"|},
        {"list (fails)", "to_string([1,2,3])"}
      ]
    },
    %{
      id: "inspect",
      title: "Inspect",
      description: "Converts a term to an algebra document for pretty-printing. Used by inspect/1 and IO.inspect/1.",
      define_code: ~s[# The protocol (built into Elixir):\ndefprotocol Inspect do\n  def inspect(term, opts)\nend],
      impl_code: "defmodule SecretKey do\n  defstruct [:key, :name]\nend\n\ndefimpl Inspect, for: SecretKey do\n  def inspect(%SecretKey{name: name}, _opts) do\n    \"#SecretKey<\#{name}, key: [REDACTED]>\"\n  end\nend\n\nkey = %SecretKey{key: \"super-secret-123\", name: \"API Key\"}\ninspect(key)\n#=> \"#SecretKey<API Key, key: [REDACTED]>\"",
      try_examples: [
        {"map", ~s|inspect(%{a: 1, b: 2})|},
        {"tuple", "inspect({1, 2, 3})"},
        {"charlist", "inspect(~c\"hello\")"},
        {"limit", "inspect(Enum.to_list(1..100), limit: 5)"},
        {"pretty", "inspect(%{a: 1, b: %{c: 2, d: 3}}, pretty: true)"}
      ]
    },
    %{
      id: "enumerable",
      title: "Enumerable",
      description: "Makes a data type work with Enum and Stream functions. The most complex built-in protocol.",
      define_code: ~s[# The protocol (built into Elixir):\ndefprotocol Enumerable do\n  def count(enumerable)\n  def member?(enumerable, element)\n  def reduce(enumerable, acc, fun)\n  def slice(enumerable)\nend],
      impl_code: "defmodule Countdown do\n  defstruct [:from]\n\n  defimpl Enumerable do\n    def count(%Countdown{from: n}), do: {:ok, n + 1}\n\n    def member?(%Countdown{from: n}, elem),\n      do: {:ok, is_integer(elem) and elem >= 0 and elem <= n}\n\n    def reduce(%Countdown{from: n}, acc, fun) do\n      Enumerable.List.reduce(Enum.to_list(n..0//-1), acc, fun)\n    end\n\n    def slice(%Countdown{from: n}) do\n      {:ok, n + 1,\n        fn start, len, _step ->\n          Enum.to_list(n..0//-1) |> Enum.slice(start, len)\n        end}\n    end\n  end\nend\n\ncountdown = %Countdown{from: 5}\nEnum.to_list(countdown)\n#=> [5, 4, 3, 2, 1, 0]\n\nEnum.map(countdown, &(&1 * 10))\n#=> [50, 40, 30, 20, 10, 0]",
      try_examples: [
        {"map Enum", "Enum.map([1,2,3], &(&1 * 2))"},
        {"range Enum", "Enum.to_list(1..5)"},
        {"map reduce", "Enum.reduce(%{a: 1, b: 2}, 0, fn {_k, v}, acc -> acc + v end)"},
        {"Enumerable?", "Enumerable.impl_for([])"},
        {"Enumerable?", "Enumerable.impl_for(%{})"}
      ]
    }
  ]

  @comparison_data [
    %{protocol: "String.Chars", purpose: "to_string/1, interpolation", functions: "to_string/1", common_use: "Display to users"},
    %{protocol: "Inspect", purpose: "inspect/1, debugging", functions: "inspect/2", common_use: "Developer debugging"},
    %{protocol: "Enumerable", purpose: "Enum.*, Stream.*", functions: "count/1, member?/2, reduce/3, slice/1", common_use: "Iterating over data"},
    %{protocol: "Collectable", purpose: "Enum.into/2, for comprehensions", functions: "into/1", common_use: "Building collections"},
    %{protocol: "List.Chars", purpose: "to_charlist/1", functions: "to_charlist/1", common_use: "Erlang interop"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_protocol, fn -> hd(@protocols) end)
     |> assign_new(:show_impl, fn -> false end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)
     |> assign_new(:show_comparison, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Built-in Protocols</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir ships with several important protocols that you can implement for your own types.
        The most commonly used are <strong>String.Chars</strong>, <strong>Inspect</strong>,
        and <strong>Enumerable</strong>.
      </p>

      <!-- Protocol Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for protocol <- protocols() do %>
          <button
            phx-click="select_protocol"
            phx-target={@myself}
            phx-value-id={protocol.id}
            class={"btn btn-sm " <> if(@active_protocol.id == protocol.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= protocol.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Protocol -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_protocol.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @active_protocol.description %></p>

          <!-- Protocol Definition -->
          <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-4"><%= @active_protocol.define_code %></div>

          <!-- Implementation Toggle -->
          <div class="flex items-center justify-between mb-3">
            <span class="text-sm font-bold opacity-70">Custom Implementation Example</span>
            <button
              phx-click="toggle_impl"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_impl, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_impl do %>
            <div class="bg-base-100 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-4 border border-primary/20"><%= @active_protocol.impl_code %></div>
          <% end %>
        </div>
      </div>

      <!-- Try It -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try <%= @active_protocol.title %></h3>

          <form phx-submit="run_code" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="code"
                value={@custom_code}
                placeholder="to_string(:hello)"
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Run</button>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <%= for {label, code} <- @active_protocol.try_examples do %>
              <button
                phx-click="quick_code"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @custom_result do %>
            <div class={"alert text-sm mt-3 " <> if(@custom_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @custom_result.input %></div>
                <div class="font-mono font-bold mt-1"><%= @custom_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Protocol Comparison Table -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">All Built-in Protocols</h3>
            <button
              phx-click="toggle_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_comparison, do: "Hide", else: "Show Table" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Protocol</th>
                    <th>Purpose</th>
                    <th>Functions</th>
                    <th>Common Use</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for item <- comparison_data() do %>
                    <tr>
                      <td class="font-mono text-xs font-bold"><%= item.protocol %></td>
                      <td class="text-xs"><%= item.purpose %></td>
                      <td class="font-mono text-xs"><%= item.functions %></td>
                      <td class="text-xs"><%= item.common_use %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="mt-4 bg-warning/10 border border-warning/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Tip</div>
              <div class="text-sm">
                When you create a struct, consider implementing at least <strong>String.Chars</strong>
                (for user display) and <strong>Inspect</strong> (for debugging). These are the most
                commonly needed protocols.
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
              <span><strong>String.Chars</strong> powers <code class="font-mono bg-base-100 px-1 rounded">to_string/1</code> and string interpolation. Implement it for user-facing output.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Inspect</strong> powers <code class="font-mono bg-base-100 px-1 rounded">inspect/1</code> and <code class="font-mono bg-base-100 px-1 rounded">IO.inspect/1</code>. Use it to hide sensitive data or improve debug output.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Enumerable</strong> makes your type work with all <code class="font-mono bg-base-100 px-1 rounded">Enum</code> and <code class="font-mono bg-base-100 px-1 rounded">Stream</code> functions. Implement it for collection-like types.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Collectable</strong> is the inverse of Enumerable -- it lets you build your type using <code class="font-mono bg-base-100 px-1 rounded">Enum.into/2</code> and <code class="font-mono bg-base-100 px-1 rounded">for</code> comprehensions.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Implementing built-in protocols makes your custom types feel like <strong>first-class citizens</strong> in the Elixir ecosystem.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_protocol", %{"id" => id}, socket) do
    protocol = Enum.find(protocols(), &(&1.id == id))
    {:noreply,
     socket
     |> assign(active_protocol: protocol)
     |> assign(show_impl: false)
     |> assign(custom_code: "")
     |> assign(custom_result: nil)}
  end

  def handle_event("toggle_impl", _params, socket) do
    {:noreply, assign(socket, show_impl: !socket.assigns.show_impl)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  def handle_event("run_code", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))

    {:noreply,
     socket
     |> assign(custom_code: code)
     |> assign(custom_result: result)}
  end

  def handle_event("quick_code", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(custom_code: code)
     |> assign(custom_result: result)}
  end

  # Helpers

  defp protocols, do: @protocols
  defp comparison_data, do: @comparison_data

  defp evaluate_code(code) do
    try do
      {result, _} = Code.eval_string(code)
      %{ok: true, input: code, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, input: code, output: "Error: #{Exception.message(e)}"}
    end
  end
end
