defmodule ElixirKatasWeb.ElixirKata52PolymorphismLive do
  use ElixirKatasWeb, :live_component

  @approaches [
    %{
      id: "protocols",
      title: "Protocols",
      color: "primary",
      when_to_use: "When you want to extend behavior for types you don't own",
      description: "Protocols dispatch on the first argument's type. They are open -- anyone can add implementations for new types without modifying the protocol or the type.",
      code: ~s[defprotocol Area do\n  def calculate(shape)\nend\n\ndefimpl Area, for: Circle do\n  def calculate(%Circle{radius: r}), do: :math.pi() * r * r\nend\n\ndefimpl Area, for: Rectangle do\n  def calculate(%Rectangle{w: w, h: h}), do: w * h\nend\n\n# Anyone can add new shapes without changing Area!],
      pros: [
        "Open for extension without modifying existing code",
        "Dispatch on any data type (structs, atoms, integers, etc.)",
        "Can be implemented by third-party libraries",
        "Used by the standard library (String.Chars, Inspect, Enumerable)"
      ],
      cons: [
        "Only dispatches on the first argument's type",
        "Runtime dispatch (slightly slower than direct calls)",
        "Error if no implementation exists (unless @fallback_to_any)",
        "Cannot share implementation logic between types easily"
      ]
    },
    %{
      id: "behaviours",
      title: "Behaviours",
      color: "secondary",
      when_to_use: "When you define a contract that multiple modules must implement",
      description: "Behaviours define a set of callbacks that implementing modules must provide. They are checked at compile time and enable dynamic dispatch via module names.",
      code: ~s[defmodule Storage do\n  @callback store(key :: String.t(), value :: term()) :: :ok\n  @callback fetch(key :: String.t()) :: {:ok, term()} | :error\nend\n\ndefmodule FileStorage do\n  @behaviour Storage\n  @impl Storage\n  def store(key, value), do: File.write!(key, :erlang.term_to_binary(value))\n  @impl Storage\n  def fetch(key), do: {:ok, File.read!(key) |> :erlang.binary_to_term()}\nend\n\ndefmodule S3Storage do\n  @behaviour Storage\n  @impl Storage\n  def store(key, value), do: # ... S3 logic\n  @impl Storage\n  def fetch(key), do: # ... S3 logic\nend\n\n# Dynamic dispatch via module name:\nstorage = Application.get_env(:app, :storage_backend)\nstorage.store("key", "value")],
      pros: [
        "Compile-time checking of required callbacks",
        "@impl tags improve readability and catch typos",
        "Can provide default implementations via __using__",
        "Dynamic dispatch via module names"
      ],
      cons: [
        "Closed -- new types must explicitly declare @behaviour",
        "No automatic dispatch based on data type",
        "Only works at the module level",
        "Cannot be implemented by external types you don't control"
      ]
    },
    %{
      id: "pattern_matching",
      title: "Pattern Matching",
      color: "accent",
      when_to_use: "When handling a fixed set of known types or shapes",
      description: "Multi-clause functions with pattern matching provide ad-hoc polymorphism. Simple, fast, and requires no ceremony -- but not extensible without modifying the function.",
      code: ~s[defmodule Formatter do\n  def format({:ok, value}), do: "Success: \#{inspect(value)}"\n  def format({:error, reason}), do: "Error: \#{reason}"\n  def format(:loading), do: "Loading..."\nend\n\ndefmodule Shape do\n  def area(%{type: :circle, radius: r}), do: :math.pi() * r * r\n  def area(%{type: :rect, w: w, h: h}), do: w * h\n  def area(%{type: :triangle, base: b, height: h}), do: 0.5 * b * h\nend],
      pros: [
        "Simplest approach -- no boilerplate",
        "Fast: compile-time dispatch, no runtime lookup",
        "Works with any data shape (tuples, maps, atoms, etc.)",
        "Guards add extra precision"
      ],
      cons: [
        "Closed: adding new types requires modifying the function",
        "All logic lives in one place -- can become large",
        "No compile-time contract checking",
        "Hard for third parties to extend"
      ]
    }
  ]

  @decision_tree [
    %{question: "Do external modules need to add implementations?", yes: "Use a Protocol", no: "next"},
    %{question: "Do you need compile-time checking of implementations?", yes: "Use a Behaviour", no: "next"},
    %{question: "Are you dispatching on a fixed set of known shapes?", yes: "Use Pattern Matching", no: "next"},
    %{question: "Do you need to dispatch on the data's type?", yes: "Use a Protocol", no: "Use a Behaviour or Pattern Matching"}
  ]

  @side_by_side [
    %{
      feature: "Extension",
      protocol: "Open (anyone can add impls)",
      behaviour: "Closed (must declare @behaviour)",
      pattern: "Closed (modify function)"
    },
    %{
      feature: "Dispatch",
      protocol: "First arg type at runtime",
      behaviour: "Module name at runtime",
      pattern: "Compile-time clause selection"
    },
    %{
      feature: "Checking",
      protocol: "Runtime (Protocol.UndefinedError)",
      behaviour: "Compile-time warnings",
      pattern: "Runtime (FunctionClauseError)"
    },
    %{
      feature: "Performance",
      protocol: "Dynamic lookup (cached)",
      behaviour: "Direct module call",
      pattern: "Fastest (compiled clauses)"
    },
    %{
      feature: "Use case",
      protocol: "Type-based polymorphism",
      behaviour: "Module-based contracts",
      pattern: "Value-based branching"
    },
    %{
      feature: "Erlang equiv.",
      protocol: "No direct equivalent",
      behaviour: "Erlang behaviours",
      pattern: "Pattern matching"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_approach, fn -> hd(@approaches) end)
     |> assign_new(:show_decision_tree, fn -> false end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:decision_step, fn -> 0 end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Polymorphism Patterns</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir offers three main ways to achieve polymorphism: <strong>Protocols</strong>,
        <strong>Behaviours</strong>, and <strong>Pattern Matching</strong>. Each has different
        trade-offs and is suited to different situations.
      </p>

      <!-- Approach Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for approach <- approaches() do %>
          <button
            phx-click="select_approach"
            phx-target={@myself}
            phx-value-id={approach.id}
            class={"btn btn-sm " <> if(@active_approach.id == approach.id, do: "btn-#{approach.color}", else: "btn-outline")}
          >
            <%= approach.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Approach -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center gap-2 mb-2">
            <h3 class="card-title text-sm"><%= @active_approach.title %></h3>
            <span class={"badge badge-sm badge-#{@active_approach.color}"}><%= @active_approach.when_to_use %></span>
          </div>
          <p class="text-xs opacity-60 mb-4"><%= @active_approach.description %></p>

          <!-- Code Example -->
          <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-4"><%= @active_approach.code %></div>

          <!-- Pros & Cons -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Pros -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold text-success mb-2">Advantages</div>
              <ul class="space-y-1">
                <%= for pro <- @active_approach.pros do %>
                  <li class="flex items-start gap-2 text-xs">
                    <span class="text-success mt-0.5">+</span>
                    <span><%= pro %></span>
                  </li>
                <% end %>
              </ul>
            </div>

            <!-- Cons -->
            <div class="bg-error/10 border border-error/30 rounded-lg p-3">
              <div class="text-xs font-bold text-error mb-2">Trade-offs</div>
              <ul class="space-y-1">
                <%= for con <- @active_approach.cons do %>
                  <li class="flex items-start gap-2 text-xs">
                    <span class="text-error mt-0.5">-</span>
                    <span><%= con %></span>
                  </li>
                <% end %>
              </ul>
            </div>
          </div>
        </div>
      </div>

      <!-- Decision Tree -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Decision Tree: Which to Use?</h3>
            <button
              phx-click="toggle_decision_tree"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_decision_tree, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_decision_tree do %>
            <div class="space-y-3">
              <%= for {node, idx} <- Enum.with_index(decision_tree()) do %>
                <div class={"rounded-lg p-3 transition-all " <> if(idx <= @decision_step, do: "bg-base-300", else: "bg-base-300/30 opacity-40")}>
                  <div class="flex items-start gap-3">
                    <div class="flex-shrink-0 w-7 h-7 rounded-full bg-primary text-primary-content flex items-center justify-center text-xs font-bold">
                      <%= idx + 1 %>
                    </div>
                    <div class="flex-1">
                      <div class="font-bold text-sm mb-2"><%= node.question %></div>
                      <div class="flex gap-2">
                        <button
                          phx-click="decision_answer"
                          phx-target={@myself}
                          phx-value-idx={idx}
                          phx-value-answer="yes"
                          class="btn btn-xs btn-success"
                          disabled={idx != @decision_step}
                        >
                          Yes &rarr; <%= node.yes %>
                        </button>
                        <button
                          phx-click="decision_answer"
                          phx-target={@myself}
                          phx-value-idx={idx}
                          phx-value-answer="no"
                          class="btn btn-xs btn-ghost"
                          disabled={idx != @decision_step}
                        >
                          No &darr;
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
              <% end %>

              <button
                phx-click="reset_decision"
                phx-target={@myself}
                class="btn btn-xs btn-ghost mt-2"
              >
                Start Over
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Side-by-Side Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Side-by-Side Comparison</h3>
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
                    <th>Feature</th>
                    <th class="text-primary">Protocol</th>
                    <th class="text-secondary">Behaviour</th>
                    <th class="text-accent">Pattern Match</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for item <- side_by_side() do %>
                    <tr>
                      <td class="font-bold text-xs"><%= item.feature %></td>
                      <td class="text-xs"><%= item.protocol %></td>
                      <td class="text-xs"><%= item.behaviour %></td>
                      <td class="text-xs"><%= item.pattern %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
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
              <span><strong>Protocols</strong> are best for type-based polymorphism that needs to be open for extension.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Behaviours</strong> are best for module-level contracts with compile-time checking.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Pattern matching</strong> is best for simple, closed, fast dispatch on known shapes.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>In practice, Elixir codebases use all three. Start with <strong>pattern matching</strong>, escalate to protocols or behaviours when extensibility is needed.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Phoenix itself uses all three: <strong>protocols</strong> (Phoenix.Param), <strong>behaviours</strong> (Phoenix.Controller), and <strong>pattern matching</strong> (router matching).</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_approach", %{"id" => id}, socket) do
    approach = Enum.find(approaches(), &(&1.id == id))
    {:noreply, assign(socket, active_approach: approach)}
  end

  def handle_event("toggle_decision_tree", _params, socket) do
    {:noreply,
     socket
     |> assign(show_decision_tree: !socket.assigns.show_decision_tree)
     |> assign(decision_step: 0)}
  end

  def handle_event("decision_answer", %{"idx" => idx_str, "answer" => answer}, socket) do
    idx = String.to_integer(idx_str)

    if answer == "no" and idx < length(decision_tree()) - 1 do
      {:noreply, assign(socket, decision_step: idx + 1)}
    else
      {:noreply, assign(socket, decision_step: idx)}
    end
  end

  def handle_event("reset_decision", _params, socket) do
    {:noreply, assign(socket, decision_step: 0)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  # Helpers

  defp approaches, do: @approaches
  defp decision_tree, do: @decision_tree
  defp side_by_side, do: @side_by_side
end
