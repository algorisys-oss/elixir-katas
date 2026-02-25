defmodule ElixirKatasWeb.ElixirKata49ProtocolsLive do
  use ElixirKatasWeb, :live_component

  @protocol_examples [
    %{
      id: "define",
      title: "Defining a Protocol",
      code: ~s[defprotocol Displayable do\n  @doc "Returns a human-readable string"\n  def display(data)\nend],
      explanation: "A protocol defines a contract: any type that implements Displayable must provide a display/1 function."
    },
    %{
      id: "impl_struct",
      title: "Implementing for a Struct",
      code: "defmodule User do\n  defstruct [:name, :email]\nend\n\ndefimpl Displayable, for: User do\n  def display(user) do\n    \"\#{user.name} <\#{user.email}>\"\n  end\nend\n\nDisplayable.display(%User{name: \"Alice\", email: \"a@b.com\"})\n#=> \"Alice <a@b.com>\"",
      explanation: "defimpl provides the protocol implementation for a specific type. The BEAM dispatches to the correct implementation at runtime."
    },
    %{
      id: "impl_multi",
      title: "Multiple Implementations",
      code: "defmodule Product do\n  defstruct [:name, :price]\nend\n\ndefimpl Displayable, for: Product do\n  def display(product) do\n    \"\#{product.name} - $\#{product.price}\"\n  end\nend\n\ndefimpl Displayable, for: BitString do\n  def display(str), do: \"String: \#{str}\"\nend\n\ndefimpl Displayable, for: Integer do\n  def display(n), do: \"Number: \#{n}\"\nend",
      explanation: "Each type gets its own implementation. The protocol dispatches to the right one based on the argument's type."
    },
    %{
      id: "any",
      title: "Fallback with Any",
      code: ~s[defprotocol Describable do\n  @fallback_to_any true\n  def describe(data)\nend\n\ndefimpl Describable, for: Any do\n  def describe(data) do\n    "A \#{data.__struct__ |> Module.split() |> List.last()}"\n  end\nend],
      explanation: "@fallback_to_any true allows types without explicit implementations to use the Any fallback. Without it, calling on an unimplemented type raises Protocol.UndefinedError."
    },
    %{
      id: "derive",
      title: "Deriving Protocols",
      code: "defprotocol Serializable do\n  @fallback_to_any true\n  def serialize(data)\nend\n\ndefimpl Serializable, for: Any do\n  def serialize(data) do\n    data\n    |> Map.from_struct()\n    |> inspect()\n  end\nend\n\ndefmodule Order do\n  @derive [Serializable]\n  defstruct [:id, :total]\nend\n\n# Order automatically gets Serializable via Any",
      explanation: "@derive tells the compiler to implement the protocol using the Any implementation. This is opt-in, unlike @fallback_to_any which is a blanket fallback."
    }
  ]

  @dispatch_steps [
    %{step: 1, label: "Call", detail: "Displayable.display(%User&lbrace;name: \"Alice\"&rbrace;)"},
    %{step: 2, label: "Check type", detail: "data.__struct__ => User"},
    %{step: 3, label: "Lookup impl", detail: "Find Displayable.User module"},
    %{step: 4, label: "Dispatch", detail: "Displayable.User.display(data)"},
    %{step: 5, label: "Result", detail: ~s|"Alice <alice@example.com>"|}
  ]

  @type_options [
    %{id: "user", label: "User", value: ~s|%{__struct__: "User", name: "Alice", email: "alice@example.com"}|, display: ~s|"Alice <alice@example.com>"|},
    %{id: "product", label: "Product", value: ~s|%{__struct__: "Product", name: "Elixir Book", price: 29.99}|, display: ~s|"Elixir Book - $29.99"|},
    %{id: "integer", label: "Integer", value: "42", display: ~s|"Number: 42"|},
    %{id: "string", label: "String", value: ~s|"hello world"|, display: ~s|"String: hello world"|},
    %{id: "list", label: "List (no impl)", value: "[1, 2, 3]", display: "** (Protocol.UndefinedError)"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@protocol_examples) end)
     |> assign_new(:selected_type, fn -> hd(@type_options) end)
     |> assign_new(:show_dispatch, fn -> false end)
     |> assign_new(:dispatch_step, fn -> 0 end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Protocols</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>Protocols</strong> enable polymorphism in Elixir. They define a contract that
        different types can implement, allowing you to write code that works with any type
        that fulfills the contract -- without knowing the type in advance.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for example <- protocol_examples() do %>
          <button
            phx-click="select_example"
            phx-target={@myself}
            phx-value-id={example.id}
            class={"btn btn-sm " <> if(@active_example.id == example.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= example.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Example -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_example.title %></h3>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-3"><%= @active_example.code %></div>
          <div class="bg-info/10 border border-info/30 rounded-lg p-3">
            <div class="text-xs font-bold opacity-60 mb-1">How it works</div>
            <div class="text-sm"><%= @active_example.explanation %></div>
          </div>
        </div>
      </div>

      <!-- Protocol Dispatch Visualization -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">How Protocol Dispatch Works</h3>
            <button
              phx-click="toggle_dispatch"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_dispatch, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_dispatch do %>
            <!-- Type Selector -->
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for type_opt <- type_options() do %>
                <button
                  phx-click="select_type"
                  phx-target={@myself}
                  phx-value-id={type_opt.id}
                  class={"btn btn-xs " <> if(@selected_type.id == type_opt.id, do: "btn-accent", else: "btn-ghost")}
                >
                  <%= type_opt.label %>
                </button>
              <% end %>
            </div>

            <!-- Step Controls -->
            <div class="flex gap-2 mb-4">
              <button
                phx-click="dispatch_back"
                phx-target={@myself}
                disabled={@dispatch_step <= 0}
                class="btn btn-sm btn-outline"
              >
                &larr; Back
              </button>
              <button
                phx-click="dispatch_forward"
                phx-target={@myself}
                disabled={@dispatch_step >= length(dispatch_steps())}
                class="btn btn-sm btn-primary"
              >
                Next Step &rarr;
              </button>
              <button
                phx-click="dispatch_all"
                phx-target={@myself}
                class="btn btn-sm btn-accent"
              >
                Show All
              </button>
            </div>

            <!-- Dispatch Steps -->
            <div class="space-y-2">
              <%= for {step, idx} <- Enum.with_index(dispatch_steps()) do %>
                <%= if idx < @dispatch_step do %>
                  <div class={"flex items-center gap-3 p-3 rounded-lg transition-all " <> dispatch_step_class(step.step)}>
                    <div class="flex-shrink-0 w-8 h-8 rounded-full bg-primary text-primary-content flex items-center justify-center text-xs font-bold">
                      <%= step.step %>
                    </div>
                    <div>
                      <div class="font-bold text-sm"><%= step.label %></div>
                      <div class="font-mono text-xs"><%= step.detail %></div>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>

            <!-- Final Result -->
            <%= if @dispatch_step >= length(dispatch_steps()) do %>
              <div class={"mt-4 rounded-lg p-3 " <> if(@selected_type.id == "list", do: "bg-error/10 border border-error/30", else: "bg-success/10 border border-success/30")}>
                <div class="text-xs font-bold opacity-60 mb-1">Result for <%= @selected_type.label %></div>
                <div class={"font-mono text-sm font-bold " <> if(@selected_type.id == "list", do: "text-error", else: "text-success")}>
                  <%= @selected_type.display %>
                </div>
              </div>
            <% end %>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own Protocol -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Protocol Concepts</h3>
          <p class="text-xs opacity-60 mb-4">
            Experiment with protocol-related expressions. Try checking if a protocol is implemented for a type.
          </p>

          <form phx-submit="run_custom" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="code"
                value={@custom_code}
                placeholder={~s|String.Chars.impl_for(42)|}
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Run</button>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <%= for {label, code} <- quick_examples() do %>
              <button
                phx-click="quick_custom"
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

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>defprotocol</strong> defines a contract with one or more function signatures.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>defimpl</strong> provides the implementation for a specific type (struct, atom, integer, etc.).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Dispatch is based on the <strong>first argument's type</strong> -- the protocol checks the value and routes to the correct implementation.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>@fallback_to_any true</strong> provides a default implementation for types without explicit impls.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>@derive</strong> opts a struct into using the Any implementation at compile time.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    example = Enum.find(protocol_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_example: example)}
  end

  def handle_event("toggle_dispatch", _params, socket) do
    {:noreply,
     socket
     |> assign(show_dispatch: !socket.assigns.show_dispatch)
     |> assign(dispatch_step: 0)}
  end

  def handle_event("select_type", %{"id" => id}, socket) do
    type_opt = Enum.find(type_options(), &(&1.id == id))
    {:noreply,
     socket
     |> assign(selected_type: type_opt)
     |> assign(dispatch_step: 0)}
  end

  def handle_event("dispatch_forward", _params, socket) do
    new_step = min(socket.assigns.dispatch_step + 1, length(dispatch_steps()))
    {:noreply, assign(socket, dispatch_step: new_step)}
  end

  def handle_event("dispatch_back", _params, socket) do
    new_step = max(socket.assigns.dispatch_step - 1, 0)
    {:noreply, assign(socket, dispatch_step: new_step)}
  end

  def handle_event("dispatch_all", _params, socket) do
    {:noreply, assign(socket, dispatch_step: length(dispatch_steps()))}
  end

  def handle_event("run_custom", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))

    {:noreply,
     socket
     |> assign(custom_code: code)
     |> assign(custom_result: result)}
  end

  def handle_event("quick_custom", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(custom_code: code)
     |> assign(custom_result: result)}
  end

  # Helpers

  defp protocol_examples, do: @protocol_examples
  defp type_options, do: @type_options
  defp dispatch_steps, do: @dispatch_steps

  defp quick_examples do
    [
      {"impl_for integer", "String.Chars.impl_for(42)"},
      {"impl_for string", ~s|String.Chars.impl_for("hello")|},
      {"impl_for list", "String.Chars.impl_for([1,2,3])"},
      {"to_string atom", "to_string(:hello)"},
      {"to_string number", "to_string(3.14)"},
      {"protocol?", "Protocol.assert_protocol!(Enumerable)"}
    ]
  end

  defp dispatch_step_class(step) do
    case step do
      1 -> "bg-base-300"
      2 -> "bg-info/10"
      3 -> "bg-warning/10"
      4 -> "bg-primary/10"
      5 -> "bg-success/10"
      _ -> "bg-base-300"
    end
  end

  defp evaluate_code(code) do
    try do
      {result, _} = Code.eval_string(code)
      %{ok: true, input: code, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, input: code, output: "Error: #{Exception.message(e)}"}
    end
  end
end
