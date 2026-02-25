defmodule ElixirKatasWeb.ElixirKata54UseImportLive do
  use ElixirKatasWeb, :live_component

  @directives [
    %{
      id: "import",
      title: "import",
      color: "primary",
      description: "Brings functions from another module into the current scope so you can call them without the module prefix.",
      examples: [
        %{
          label: "Basic import",
          code: ~s[defmodule MyModule do\n  import Enum\n\n  def double_all(list) do\n    # Can call map/2 directly instead of Enum.map/2\n    map(list, &(&1 * 2))\n  end\nend],
          explanation: "import Enum brings all Enum functions into scope."
        },
        %{
          label: "Selective import",
          code: "defmodule MyModule do\n  # Only import specific functions\n  import Enum, only: [map: 2, filter: 2]\n\n  # Or exclude specific functions\n  import List, except: [flatten: 1]\n\n  # Import only macros\n  import Kernel, only: :macros\nend",
          explanation: "Use :only and :except to control which functions are imported. This avoids name collisions and makes dependencies explicit."
        }
      ],
      when_to_use: "When you call functions from another module frequently and want shorter code. Use :only to be explicit.",
      gotchas: ["Can cause name collisions with local functions", "Makes it harder to find where a function is defined", "Prefer qualified calls (Enum.map) in most code"]
    },
    %{
      id: "alias",
      title: "alias",
      color: "secondary",
      description: "Creates a shortcut for a module name. Does not import any functions -- just shortens the name.",
      examples: [
        %{
          label: "Basic alias",
          code: ~s[defmodule MyApp.Web.Controllers.UserController do\n  alias MyApp.Accounts.User\n  alias MyApp.Accounts.Permissions\n\n  def show(id) do\n    # Use User instead of MyApp.Accounts.User\n    User.get(id)\n  end\nend],
          explanation: "alias takes the last segment by default. MyApp.Accounts.User becomes just User."
        },
        %{
          label: "Custom alias & multi-alias",
          code: ~s[defmodule MyModule do\n  # Custom alias name\n  alias MyApp.Accounts.User, as: U\n\n  # Multi-alias (alias multiple modules at once)\n  alias MyApp.Accounts.{User, Permission, Role}\n\n  def example do\n    U.get(1)          # Using custom alias\n    User.create(...)  # Using multi-alias\n    Role.admin()      # Using multi-alias\n  end\nend],
          explanation: "Use :as for custom names. Multi-alias with curly braces aliases several modules from the same parent."
        }
      ],
      when_to_use: "Almost always when working with deeply nested module names. It is the most commonly used directive.",
      gotchas: ["Aliasing to a confusing name (as: X) hurts readability", "The last segment must be unique in scope"]
    },
    %{
      id: "require",
      title: "require",
      color: "accent",
      description: "Makes macros from another module available. Required before you can use a module's macros.",
      examples: [
        %{
          label: "Requiring for macros",
          code: ~s[defmodule MyModule do\n  require Logger\n\n  def process(data) do\n    # Logger.info is a macro, needs require\n    Logger.info("Processing: \#{inspect(data)}")\n\n    # Without require, you'd get:\n    # ** (CompileError) you must require Logger\n    #    before invoking the macro Logger.info/1\n  end\nend],
          explanation: "Macros are expanded at compile time. require ensures the module is compiled and its macros are available before they're used."
        },
        %{
          label: "require for guards",
          code: ~s[defmodule MyModule do\n  require Integer\n\n  def even?(n) when Integer.is_even(n), do: true\n  def even?(_), do: false\n\n  # Integer.is_even is a macro that expands to:\n  # rem(n, 2) == 0\nend],
          explanation: "Guard-compatible macros like Integer.is_even/1 also need require since they expand at compile time."
        }
      ],
      when_to_use: "When you need to use macros from another module. Logger is the most common example.",
      gotchas: ["Only needed for macros, not regular functions", "import automatically requires the module", "use automatically requires the module"]
    },
    %{
      id: "use",
      title: "use",
      color: "warning",
      description: "Invokes the __using__/1 macro from another module. This is the most powerful directive -- it can inject code, imports, aliases, and more into your module.",
      examples: [
        %{
          label: "How use works",
          code: "# When you write:\ndefmodule MyController do\n  use Phoenix.Controller\nend\n\n# It is equivalent to:\ndefmodule MyController do\n  require Phoenix.Controller\n  Phoenix.Controller.__using__([])\nend\n\n# The __using__ macro can inject anything:\ndefmodule Phoenix.Controller do\n  defmacro __using__(_opts) do\n    quote do\n      import Phoenix.Controller\n      import Plug.Conn\n      # ... more setup code\n    end\n  end\nend",
          explanation: "use Module is syntactic sugar for calling Module.__using__/1 macro. The macro can inject any code into your module -- imports, aliases, behaviour declarations, functions, etc."
        },
        %{
          label: "use with options",
          code: "# use can pass options to __using__\ndefmodule MySchema do\n  use Ecto.Schema, prefix: \"my_app\"\nend\n\ndefmodule MyGenServer do\n  use GenServer, restart: :temporary\nend\n\n# A custom example:\ndefmodule Validatable do\n  defmacro __using__(opts) do\n    fields = Keyword.get(opts, :fields, [])\n    quote do\n      @required_fields unquote(fields)\n\n      def validate(data) do\n        missing = Enum.filter(@required_fields, fn f ->\n          !Map.has_key?(data, f)\n        end)\n        if missing == [], do: :ok, else: {:error, missing}\n      end\n    end\n  end\nend\n\ndefmodule User do\n  use Validatable, fields: [:name, :email]\nend",
          explanation: "Options passed to use are forwarded to __using__/1. This lets the macro customize the injected code based on the caller's needs."
        }
      ],
      when_to_use: "When a library provides a __using__ macro for setup (GenServer, Phoenix.Controller, Ecto.Schema, etc.).",
      gotchas: ["use can inject a lot of hidden code -- read the docs to know what it does", "Prefer import/alias/require when use is not needed", "use is the least explicit directive -- be aware of what it injects"]
    }
  ]

  @summary_table [
    %{directive: "import", what: "Brings functions into scope", needs: "Nothing", example: "import Enum, only: [map: 2]"},
    %{directive: "alias", what: "Shortens module name", needs: "Nothing", example: "alias MyApp.User"},
    %{directive: "require", what: "Enables macro usage", needs: "Module compiled", example: "require Logger"},
    %{directive: "use", what: "Calls __using__ macro", needs: "__using__/1 defined", example: "use GenServer"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_directive, fn -> hd(@directives) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:show_summary, fn -> false end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Use, Import, Alias & Require</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir provides four directives for working with modules:
        <strong>import</strong>, <strong>alias</strong>, <strong>require</strong>, and <strong>use</strong>.
        Each serves a different purpose and understanding when to use each is key.
      </p>

      <!-- Directive Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for directive <- directives() do %>
          <button
            phx-click="select_directive"
            phx-target={@myself}
            phx-value-id={directive.id}
            class={"btn btn-sm " <> if(@active_directive.id == directive.id, do: "btn-#{directive.color}", else: "btn-outline")}
          >
            <%= directive.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Directive -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_directive.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @active_directive.description %></p>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(@active_directive.examples) do %>
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
          <% example = Enum.at(@active_directive.examples, @active_example_idx) %>
          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap"><%= example.code %></div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Explanation</div>
              <div class="text-sm"><%= example.explanation %></div>
            </div>
          </div>

          <!-- When to Use -->
          <div class="mt-4 bg-success/10 border border-success/30 rounded-lg p-3">
            <div class="text-xs font-bold text-success mb-1">When to use</div>
            <div class="text-sm"><%= @active_directive.when_to_use %></div>
          </div>

          <!-- Gotchas -->
          <div class="mt-3 bg-warning/10 border border-warning/30 rounded-lg p-3">
            <div class="text-xs font-bold text-warning mb-1">Watch out for</div>
            <ul class="space-y-1">
              <%= for gotcha <- @active_directive.gotchas do %>
                <li class="flex items-start gap-2 text-xs">
                  <span class="text-warning mt-0.5">!</span>
                  <span><%= gotcha %></span>
                </li>
              <% end %>
            </ul>
          </div>
        </div>
      </div>

      <!-- Try It -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Explore Directives</h3>
          <p class="text-xs opacity-60 mb-4">
            Try expressions to explore how import, alias, require, and use work.
          </p>

          <form phx-submit="run_code" phx-target={@myself} class="space-y-3">
            <div class="form-control">
              <input
                type="text"
                name="code"
                value={@custom_code}
                placeholder="Enum.module_info(:exports) |> length()"
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

      <!-- Summary Table -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Quick Reference</h3>
            <button
              phx-click="toggle_summary"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_summary, do: "Hide", else: "Show Table" %>
            </button>
          </div>

          <%= if @show_summary do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Directive</th>
                    <th>What it does</th>
                    <th>Requires</th>
                    <th>Example</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for item <- summary_table() do %>
                    <tr>
                      <td class="font-mono text-xs font-bold"><%= item.directive %></td>
                      <td class="text-xs"><%= item.what %></td>
                      <td class="text-xs"><%= item.needs %></td>
                      <td class="font-mono text-xs"><%= item.example %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="mt-4 bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Directive Hierarchy</div>
              <div class="text-sm font-mono">
                use = require + __using__ macro call<br/>
                import = require + bring functions into scope<br/>
                alias = just a name shortcut<br/>
                require = just enable macros
              </div>
            </div>

            <div class="mt-3 bg-warning/10 border border-warning/30 rounded-lg p-3">
              <div class="text-xs font-bold text-warning mb-1">Best Practice</div>
              <div class="text-sm">
                Prefer the <strong>least powerful</strong> directive that works:
                alias &gt; require &gt; import (with :only) &gt; use.
                This keeps your code explicit and easy to understand.
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
              <span><strong>alias</strong> shortens module names. Use it freely for deeply nested modules.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>import</strong> brings functions into scope. Always use <code class="font-mono bg-base-100 px-1 rounded">:only</code> to be explicit about what you import.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>require</strong> is needed before using macros. Logger is the most common example.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>use</strong> calls the <code class="font-mono bg-base-100 px-1 rounded">__using__/1</code> macro. It can inject any code -- read the docs to know what it does.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>All four directives are <strong>lexically scoped</strong> -- they only apply within the module (or function) where they appear.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_directive", %{"id" => id}, socket) do
    directive = Enum.find(directives(), &(&1.id == id))
    {:noreply,
     socket
     |> assign(active_directive: directive)
     |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, active_example_idx: idx)}
  end

  def handle_event("toggle_summary", _params, socket) do
    {:noreply, assign(socket, show_summary: !socket.assigns.show_summary)}
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

  defp directives, do: @directives
  defp summary_table, do: @summary_table

  defp quick_examples do
    [
      {"Enum exports count", "Enum.module_info(:exports) |> length()"},
      {"Logger loaded?", "Code.ensure_loaded?(Logger)"},
      {"Kernel macros", "Kernel.module_info(:exports) |> Enum.take(10)"},
      {"import test", "import Enum, only: [map: 2]; map([1,2,3], &(&1*2))"},
      {"alias test", "alias String, as: S; S.upcase(\"hello\")"}
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
