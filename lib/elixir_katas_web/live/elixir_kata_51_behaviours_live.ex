defmodule ElixirKatasWeb.ElixirKata51BehavioursLive do
  use ElixirKatasWeb, :live_component

  @behaviour_examples [
    %{
      id: "define",
      title: "Defining a Behaviour",
      code: "defmodule Parser do\n  @doc \"Parses a string into structured data\"\n  @callback parse(input :: String.t()) :: {:ok, term()} | {:error, String.t()}\n\n  @doc \"Returns the file extensions this parser supports\"\n  @callback extensions() :: [String.t()]\nend",
      explanation: "A behaviour defines a set of @callback declarations. Any module using @behaviour Parser must implement all callbacks, or a compile-time warning is raised."
    },
    %{
      id: "implement",
      title: "Implementing a Behaviour",
      code: "defmodule JsonParser do\n  @behaviour Parser\n\n  @impl Parser\n  def parse(input) do\n    case Jason.decode(input) do\n      {:ok, data} -> {:ok, data}\n      {:error, _} -> {:error, \"invalid JSON\"}\n    end\n  end\n\n  @impl Parser\n  def extensions, do: [\".json\"]\nend\n\ndefmodule CsvParser do\n  @behaviour Parser\n\n  @impl Parser\n  def parse(input) do\n    rows = String.split(input, \"\\n\")\n    |> Enum.map(&String.split(&1, \",\"))\n    {:ok, rows}\n  end\n\n  @impl Parser\n  def extensions, do: [\".csv\"]\nend",
      explanation: "@behaviour Parser declares intent to implement all callbacks. @impl Parser marks which functions fulfill the contract. Missing callbacks trigger a compile warning."
    },
    %{
      id: "optional",
      title: "Optional Callbacks",
      code: ~s[defmodule EventHandler do\n  @callback handle_event(event :: term()) :: :ok | {:error, term()}\n  @callback init(opts :: keyword()) :: {:ok, term()}\n  @callback terminate(reason :: term(), state :: term()) :: :ok\n\n  @optional_callbacks terminate: 2\nend\n\ndefmodule MyHandler do\n  @behaviour EventHandler\n\n  @impl EventHandler\n  def init(opts), do: {:ok, opts}\n\n  @impl EventHandler\n  def handle_event(event) do\n    IO.inspect(event, label: "Event")\n    :ok\n  end\n\n  # terminate/2 is optional, so we can skip it\nend],
      explanation: "@optional_callbacks lets you mark certain callbacks as not required. Modules can implement them if needed, but won't get warnings if they don't."
    },
    %{
      id: "dispatch",
      title: "Dynamic Dispatch",
      code: "defmodule ParserRegistry do\n  @doc \"Select parser based on file extension\"\n  def parse_file(filename, content) do\n    ext = Path.extname(filename)\n    parser = find_parser(ext)\n\n    case parser do\n      nil -> {:error, \"no parser for \#{ext}\"}\n      mod -> mod.parse(content)\n    end\n  end\n\n  defp find_parser(ext) do\n    parsers = [JsonParser, CsvParser, YamlParser]\n\n    Enum.find(parsers, fn parser ->\n      ext in parser.extensions()\n    end)\n  end\nend\n\n# Usage:\nParserRegistry.parse_file(\"data.json\", ~s|{\"key\": \"value\"}|)\n#=> {:ok, %{\"key\" => \"value\"}}",
      explanation: "Behaviours shine when you need to select an implementation at runtime. Store module names and call behaviour functions dynamically."
    },
    %{
      id: "default",
      title: "Default Implementations with __using__",
      code: ~s[defmodule Serializer do\n  @callback serialize(term()) :: String.t()\n  @callback deserialize(String.t()) :: {:ok, term()} | {:error, term()}\n\n  defmacro __using__(_opts) do\n    quote do\n      @behaviour Serializer\n\n      # Default implementation using inspect\n      def serialize(term), do: inspect(term)\n\n      defoverridable serialize: 1\n    end\n  end\nend\n\ndefmodule MySerializer do\n  use Serializer\n\n  # serialize/1 has a default, we only need deserialize/1\n  @impl Serializer\n  def deserialize(str) do\n    {:ok, str}\n  end\nend],
      explanation: "Combining use with behaviours lets you provide default implementations. defoverridable marks functions that child modules can optionally replace."
    }
  ]

  @compile_checks [
    %{scenario: "Missing callback", code: ~s[defmodule Bad do\n  @behaviour Parser\n  # Forgot to implement parse/1 and extensions/0\nend], result: "warning: function parse/1 required by behaviour Parser is not implemented\nwarning: function extensions/0 required by behaviour Parser is not implemented", status: :warning},
    %{scenario: "Wrong return type", code: "defmodule AlsoBad do\n  @behaviour Parser\n\n  @impl Parser\n  def parse(_input), do: \"result\"  # Should return {:ok, _} or {:error, _}\n\n  @impl Parser\n  def extensions, do: [\".txt\"]\nend", result: "Compiles, but the @callback spec documents the expected return type. Dialyzer can catch type mismatches.", status: :note},
    %{scenario: "Correct implementation", code: "defmodule Good do\n  @behaviour Parser\n\n  @impl Parser\n  def parse(input), do: {:ok, input}\n\n  @impl Parser\n  def extensions, do: [\".txt\"]\nend", result: "Compiles cleanly with no warnings.", status: :ok}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@behaviour_examples) end)
     |> assign_new(:show_compile_checks, fn -> false end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Behaviours</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>Behaviours</strong> define a set of functions that a module must implement.
        They provide <em>compile-time</em> contract checking, ensuring modules conform to
        an expected interface. Think of them as Elixir's answer to interfaces.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for example <- behaviour_examples() do %>
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

      <!-- Compile-Time Checking -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Compile-Time Contract Checking</h3>
            <button
              phx-click="toggle_compile_checks"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_compile_checks, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_compile_checks do %>
            <div class="space-y-4">
              <%= for check <- compile_checks() do %>
                <div class={"rounded-lg p-4 border " <> compile_check_class(check.status)}>
                  <div class="flex items-center gap-2 mb-2">
                    <span class={"badge badge-sm " <> compile_check_badge(check.status)}>
                      <%= check.scenario %>
                    </span>
                  </div>
                  <div class="bg-base-100 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap mb-2"><%= check.code %></div>
                  <div class={"font-mono text-xs p-2 rounded " <> compile_check_result_class(check.status)}>
                    <%= check.result %>
                  </div>
                </div>
              <% end %>

              <div class="alert alert-info text-sm">
                <div>
                  <div class="font-bold">Why compile-time checks matter</div>
                  <span>Unlike protocols (which raise at runtime), behaviours catch missing
                    implementations at compile time. This means you discover errors before your
                    code ever runs, making your system more reliable.</span>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Explore Behaviours</h3>
          <p class="text-xs opacity-60 mb-4">
            Try behaviour-related expressions. Explore which modules implement common behaviours.
          </p>

          <form phx-submit="run_code" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="code"
                value={@custom_code}
                placeholder="GenServer.behaviour_info(:callbacks)"
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
                <div class="font-mono font-bold mt-1 whitespace-pre-wrap"><%= @custom_result.output %></div>
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
              <span><strong>@callback</strong> declares a function that implementing modules must define.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>@behaviour</strong> in a module declares intent to implement all required callbacks.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>@impl</strong> marks functions that fulfill a behaviour callback -- helps readability and catches typos.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>@optional_callbacks</strong> makes specific callbacks optional for implementing modules.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Behaviours enable <strong>dynamic dispatch</strong> by storing module names and calling callbacks at runtime.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    example = Enum.find(behaviour_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_example: example)}
  end

  def handle_event("toggle_compile_checks", _params, socket) do
    {:noreply, assign(socket, show_compile_checks: !socket.assigns.show_compile_checks)}
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

  defp behaviour_examples, do: @behaviour_examples
  defp compile_checks, do: @compile_checks

  defp quick_examples do
    [
      {"GenServer callbacks", "GenServer.behaviour_info(:callbacks)"},
      {"Supervisor callbacks", "Supervisor.behaviour_info(:callbacks)"},
      {"Application callbacks", "Application.behaviour_info(:callbacks)"},
      {"Optional callbacks", "GenServer.behaviour_info(:optional_callbacks)"},
      {"Module info", ":maps.module_info(:exports)"}
    ]
  end

  defp compile_check_class(:warning), do: "bg-warning/10 border-warning/30"
  defp compile_check_class(:ok), do: "bg-success/10 border-success/30"
  defp compile_check_class(:note), do: "bg-info/10 border-info/30"

  defp compile_check_badge(:warning), do: "badge-warning"
  defp compile_check_badge(:ok), do: "badge-success"
  defp compile_check_badge(:note), do: "badge-info"

  defp compile_check_result_class(:warning), do: "bg-warning/10 text-warning"
  defp compile_check_result_class(:ok), do: "bg-success/10 text-success"
  defp compile_check_result_class(:note), do: "bg-info/10 text-info"

  defp evaluate_code(code) do
    try do
      {result, _} = Code.eval_string(code)
      %{ok: true, input: code, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, input: code, output: "Error: #{Exception.message(e)}"}
    end
  end
end
