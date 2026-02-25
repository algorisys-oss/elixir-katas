defmodule ElixirKatasWeb.ElixirKata53ModuleAttributesLive do
  use ElixirKatasWeb, :live_component

  @attribute_categories [
    %{
      id: "docs",
      title: "Documentation Attributes",
      description: "Elixir has first-class documentation support via module attributes.",
      examples: [
        %{
          id: "moduledoc",
          label: "@moduledoc",
          code: ~s[defmodule MyApp.Calculator do\n  @moduledoc """\n  A simple calculator module.\n\n  ## Examples\n\n      iex> Calculator.add(1, 2)\n      3\n  """\n\n  @doc "Adds two numbers together"\n  @spec add(number(), number()) :: number()\n  def add(a, b), do: a + b\nend],
          explanation: "@moduledoc describes the module itself. Supports Markdown formatting including code examples that can be tested with ExUnit (doctests)."
        },
        %{
          id: "doc",
          label: "@doc",
          code: "defmodule MyApp.User do\n  @doc \"\"\"\n  Creates a new user with the given name.\n\n  Returns `{:ok, user}` on success.\n\n  ## Parameters\n    - name: The user's full name (string)\n    - opts: Optional keyword list\n\n  ## Examples\n\n      iex> User.create(\"Alice\")\n      {:ok, %User{name: \"Alice\"}}\n  \"\"\"\n  def create(name, opts \\\\ []) do\n    # ...\n  end\n\n  @doc false\n  def internal_helper do\n    # @doc false hides this from documentation\n  end\nend",
          explanation: "@doc documents a single function. @doc false hides a function from generated docs. Documentation is accessible at runtime via Code.fetch_docs/1."
        }
      ]
    },
    %{
      id: "types",
      title: "Type Specifications",
      description: "Type specs serve as documentation and enable static analysis with Dialyzer.",
      examples: [
        %{
          id: "spec",
          label: "@spec",
          code: ~s[defmodule MyApp.Math do\n  @spec add(number(), number()) :: number()\n  def add(a, b), do: a + b\n\n  @spec divide(number(), number()) :: {:ok, float()} | {:error, String.t()}\n  def divide(_, 0), do: {:error, "division by zero"}\n  def divide(a, b), do: {:ok, a / b}\n\n  @spec factorial(non_neg_integer()) :: pos_integer()\n  def factorial(0), do: 1\n  def factorial(n) when n > 0, do: n * factorial(n - 1)\nend],
          explanation: "@spec declares the types of arguments and return values. Dialyzer uses these for static analysis. They also serve as excellent documentation."
        },
        %{
          id: "type",
          label: "@type / @typep / @opaque",
          code: "defmodule MyApp.User do\n  @type t :: %__MODULE__{\n    name: String.t(),\n    email: String.t(),\n    age: non_neg_integer()\n  }\n\n  @type role :: :admin | :user | :moderator\n\n  @typep internal_id :: pos_integer()\n\n  @opaque token :: String.t()\n\n  defstruct [:name, :email, :age]\n\n  @spec new(String.t(), String.t(), non_neg_integer()) :: t()\n  def new(name, email, age) do\n    %__MODULE__{name: name, email: email, age: age}\n  end\nend",
          explanation: "@type defines a public type. @typep is private. @opaque is public but internal structure is hidden. Convention: use t() for the module's main type."
        }
      ]
    },
    %{
      id: "constants",
      title: "Compile-Time Constants",
      description: "Module attributes as constants are evaluated at compile time and inlined into the code.",
      examples: [
        %{
          id: "constants",
          label: "Constants",
          code: "defmodule MyApp.Config do\n  @max_retries 3\n  @timeout_ms 5_000\n  @default_headers [{\"content-type\", \"application/json\"}]\n  @api_version \"v2\"\n\n  def fetch(url) do\n    # @max_retries is inlined at compile time\n    do_fetch(url, @max_retries)\n  end\n\n  defp do_fetch(_url, 0), do: {:error, :max_retries}\n  defp do_fetch(url, retries) do\n    case HTTPClient.get(url, @default_headers, timeout: @timeout_ms) do\n      {:ok, resp} -> {:ok, resp}\n      {:error, _} -> do_fetch(url, retries - 1)\n    end\n  end\nend",
          explanation: "Module attributes used as constants are replaced with their values at compile time. They cannot be changed at runtime -- they are truly constant."
        },
        %{
          id: "computed",
          label: "Computed at Compile Time",
          code: "defmodule MyApp.BuildInfo do\n  @compile_time DateTime.utc_now() |> DateTime.to_string()\n  @git_sha System.cmd(\"git\", [\"rev-parse\", \"HEAD\"])\n           |> elem(0) |> String.trim()\n  @env Mix.env()\n\n  def compile_time, do: @compile_time\n  def git_sha, do: @git_sha\n  def env, do: @env\n\n  # These values are fixed at compile time!\n  # Calling compile_time() always returns the\n  # same timestamp -- when the module was compiled.\nend",
          explanation: "Expressions in module attributes are evaluated at compile time. This is useful for embedding build information but means the value never changes at runtime."
        }
      ]
    },
    %{
      id: "accumulating",
      title: "Accumulating Attributes",
      description: "Module.register_attribute/3 with accumulate: true lets you build up a list during compilation.",
      examples: [
        %{
          id: "accumulate",
          label: "Accumulating",
          code: "defmodule MyApp.Router do\n  Module.register_attribute(__MODULE__, :routes, accumulate: true)\n\n  @routes {:get, \"/users\", :list_users}\n  @routes {:post, \"/users\", :create_user}\n  @routes {:get, \"/users/:id\", :get_user}\n  @routes {:delete, \"/users/:id\", :delete_user}\n\n  def routes, do: @routes\n  # => [{:delete, \"/users/:id\", :delete_user},\n  #     {:get, \"/users/:id\", :get_user},\n  #     {:post, \"/users\", :create_user},\n  #     {:get, \"/users\", :list_users}]",
          explanation: "With accumulate: true, each @routes assignment appends to a list instead of overriding. The list is in reverse order of declaration."
        },
        %{
          id: "before_compile",
          label: "Using with @before_compile",
          code: ~s[defmodule MyApp.EventRegistry do\n  Module.register_attribute(__MODULE__, :events, accumulate: true)\n\n  @events :user_created\n  @events :user_updated\n  @events :user_deleted\n\n  # Access accumulated attributes during compilation\n  @before_compile __MODULE__\n\n  defmacro __before_compile__(_env) do\n    quote do\n      def all_events, do: @events\n      def event_count, do: length(@events)\n    end\n  end\nend],
          explanation: "@before_compile runs a macro just before the module finishes compiling. This lets you generate functions based on accumulated attributes -- a powerful metaprogramming pattern."
        }
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_category, fn -> hd(@attribute_categories) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Module Attributes</h2>
      <p class="text-sm opacity-70 mb-6">
        Module attributes serve multiple purposes in Elixir: <strong>documentation</strong>,
        <strong>type specifications</strong>, <strong>compile-time constants</strong>, and
        <strong>temporary storage</strong> during compilation.
      </p>

      <!-- Category Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for category <- attribute_categories() do %>
          <button
            phx-click="select_category"
            phx-target={@myself}
            phx-value-id={category.id}
            class={"btn btn-sm " <> if(@active_category.id == category.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= category.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Category -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_category.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @active_category.description %></p>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(@active_category.examples) do %>
              <button
                phx-click="select_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"btn btn-xs " <> if(idx == @active_example_idx, do: "btn-accent", else: "btn-ghost")}
              >
                <%= example.label %>
              </button>
            <% end %>
          </div>

          <!-- Selected Example -->
          <% example = Enum.at(@active_category.examples, @active_example_idx) %>
          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap"><%= example.code %></div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Explanation</div>
              <div class="text-sm"><%= example.explanation %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Try It -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Explore Module Attributes</h3>
          <p class="text-xs opacity-60 mb-4">
            Try expressions related to module attributes, documentation, and type specs.
          </p>

          <form phx-submit="run_code" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="code"
                value={@custom_code}
                placeholder={~s|Code.fetch_docs(Enum)|}
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

      <!-- Quick Reference -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Module Attributes Reference</h3>
          <div class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Attribute</th>
                  <th>Purpose</th>
                  <th>Scope</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="font-mono text-xs font-bold">@moduledoc</td>
                  <td class="text-xs">Module documentation</td>
                  <td class="text-xs">Stored in BEAM file, accessible at runtime</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@doc</td>
                  <td class="text-xs">Function documentation</td>
                  <td class="text-xs">Stored in BEAM file, accessible at runtime</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@spec</td>
                  <td class="text-xs">Type specification</td>
                  <td class="text-xs">Used by Dialyzer for static analysis</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@type</td>
                  <td class="text-xs">Public type definition</td>
                  <td class="text-xs">Visible to other modules and Dialyzer</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@typep</td>
                  <td class="text-xs">Private type definition</td>
                  <td class="text-xs">Only visible within the module</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@opaque</td>
                  <td class="text-xs">Opaque type</td>
                  <td class="text-xs">Public name, hidden internal structure</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@behaviour</td>
                  <td class="text-xs">Declare behaviour implementation</td>
                  <td class="text-xs">Compile-time checking</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@callback</td>
                  <td class="text-xs">Behaviour callback definition</td>
                  <td class="text-xs">Compile-time contract</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@impl</td>
                  <td class="text-xs">Mark callback implementation</td>
                  <td class="text-xs">Compile-time validation</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@enforce_keys</td>
                  <td class="text-xs">Required struct fields</td>
                  <td class="text-xs">Compile-time checking</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs font-bold">@derive</td>
                  <td class="text-xs">Derive protocol implementation</td>
                  <td class="text-xs">Compile-time code generation</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>@moduledoc</strong> and <strong>@doc</strong> are stored in the compiled BEAM file and accessible at runtime via <code class="font-mono bg-base-100 px-1 rounded">Code.fetch_docs/1</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>@spec</strong> and <strong>@type</strong> enable static analysis with Dialyzer and serve as excellent documentation.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Custom attributes (e.g., <strong>@max_retries 3</strong>) are compile-time constants -- their values are inlined and cannot change at runtime.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Accumulating attributes</strong> with <code class="font-mono bg-base-100 px-1 rounded">accumulate: true</code> build lists during compilation for metaprogramming patterns.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Module attributes are <strong>not variables</strong> -- they are evaluated at compile time. Do not use them for runtime state.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_category", %{"id" => id}, socket) do
    category = Enum.find(attribute_categories(), &(&1.id == id))
    {:noreply,
     socket
     |> assign(active_category: category)
     |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, active_example_idx: idx)}
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

  defp attribute_categories, do: @attribute_categories

  defp quick_examples do
    [
      {"Enum module info", "Enum.module_info(:attributes)"},
      {"Map exports", ":maps.module_info(:exports) |> Enum.take(10)"},
      {"Module compiled?", "Code.ensure_loaded?(Enum)"},
      {"List types", "Kernel.Typespec.fetch_types(Enum) |> elem(1) |> length()"},
      {"Mix.env", "Mix.env()"}
    ]
  end

  defp evaluate_code(code) do
    try do
      {result, _} = Code.eval_string(code)
      %{ok: true, input: code, output: inspect(result, pretty: true, limit: 30)}
    rescue
      e -> %{ok: false, input: code, output: "Error: #{Exception.message(e)}"}
    end
  end
end
