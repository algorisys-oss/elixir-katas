defmodule ElixirKatasWeb.ElixirKata47StructsLive do
  use ElixirKatasWeb, :live_component

  @struct_examples [
    %{
      id: "basic",
      title: "Defining a Struct",
      code: ~s|defmodule User do\n  defstruct [:name, :email, :age]\nend\n\n%User{name: "Alice", email: "alice@example.com", age: 30}|,
      result: ~s|%User{name: "Alice", email: "alice@example.com", age: 30}|,
      explanation: "defstruct defines a struct with the given fields. Fields default to nil if not provided."
    },
    %{
      id: "defaults",
      title: "Default Values",
      code: ~s|defmodule Config do\n  defstruct host: "localhost", port: 4000, ssl: false\nend\n\n%Config{}|,
      result: ~s|%Config{host: "localhost", port: 4000, ssl: false}|,
      explanation: "You can provide default values using keyword syntax. Unset fields get these defaults."
    },
    %{
      id: "enforce",
      title: "@enforce_keys",
      code: ~s|defmodule Order do\n  @enforce_keys [:product, :quantity]\n  defstruct [:product, :quantity, status: :pending]\nend\n\n# %Order{} would raise ArgumentError!\n%Order{product: "Book", quantity: 2}|,
      result: ~s|%Order{product: "Book", quantity: 2, status: :pending}|,
      explanation: "@enforce_keys ensures certain fields MUST be provided at creation time, or a compile-time error is raised."
    },
    %{
      id: "update",
      title: "Update Syntax",
      code: "user = %User{name: \"Alice\", email: \"alice@example.com\", age: 30}\n\n# Update with the | syntax\nupdated = %User{user | name: \"Bob\", age: 25}",
      result: "%User{name: \"Bob\", email: \"alice@example.com\", age: 25}",
      explanation: "The update syntax %Struct{struct | field: value} creates a new struct with the specified fields changed. The original is unchanged."
    },
    %{
      id: "pattern_match",
      title: "Pattern Matching",
      code: ~s|def greet(%User{name: name, age: age}) when age >= 18 do\n  "Hello, \#{name}! You are an adult."\nend\n\ndef greet(%User{name: name}) do\n  "Hi, \#{name}! You are a minor."\nend|,
      result: ~s|greet(%User{name: "Alice", age: 30}) => "Hello, Alice! You are an adult."|,
      explanation: "You can pattern match on structs just like maps. The struct name acts as an additional constraint."
    }
  ]

  @struct_vs_map [
    %{feature: "Type checking", struct: "Compile-time field checking", map: "No field restrictions"},
    %{feature: "Default values", struct: "defstruct supports defaults", map: "No built-in defaults"},
    %{feature: "Pattern matching", struct: "Matches on struct name + fields", map: "Matches on any key/value"},
    %{feature: "Unknown keys", struct: "Compile error for unknown keys", map: "Any key allowed"},
    %{feature: "Protocols", struct: "Can implement protocols", map: "Uses default implementations"},
    %{feature: "Underlying type", struct: "A map with __struct__ key", map: "Plain map"},
    %{feature: "Enumerable", struct: "Not enumerable by default", map: "Enumerable by default"}
  ]

  @builder_fields [
    %{name: "name", type: "text", label: "Name", placeholder: "Alice"},
    %{name: "email", type: "text", label: "Email", placeholder: "alice@example.com"},
    %{name: "age", type: "number", label: "Age", placeholder: "30"},
    %{name: "role", type: "select", label: "Role", options: ["user", "admin", "moderator"]}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@struct_examples) end)
     |> assign_new(:builder_name, fn -> "" end)
     |> assign_new(:builder_email, fn -> "" end)
     |> assign_new(:builder_age, fn -> "" end)
     |> assign_new(:builder_role, fn -> "user" end)
     |> assign_new(:built_struct, fn -> nil end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:match_input, fn -> "" end)
     |> assign_new(:match_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Structs</h2>
      <p class="text-sm opacity-70 mb-6">
        <strong>Structs</strong> are extensions built on top of maps that provide compile-time checks
        and default values. They are defined inside a module using <code class="font-mono bg-base-300 px-1 rounded">defstruct</code>.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for example <- struct_examples() do %>
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
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_example.code %></div>
          <div class="bg-success/10 border border-success/30 rounded-lg p-3 mb-3">
            <div class="text-xs font-bold opacity-60 mb-1">Result</div>
            <div class="font-mono text-sm text-success font-bold"><%= @active_example.result %></div>
          </div>
          <div class="bg-info/10 border border-info/30 rounded-lg p-3">
            <div class="text-xs font-bold opacity-60 mb-1">Explanation</div>
            <div class="text-sm"><%= @active_example.explanation %></div>
          </div>
        </div>
      </div>

      <!-- Interactive Struct Builder -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Struct Builder</h3>
          <p class="text-xs opacity-60 mb-4">
            Build a <code class="font-mono bg-base-300 px-1 rounded">%User&lbrace;&rbrace;</code> struct by filling in the fields below.
          </p>

          <form phx-submit="build_struct" phx-target={@myself} class="space-y-3">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <%= for field <- builder_fields() do %>
                <div class="form-control">
                  <label class="label py-0"><span class="label-text text-xs"><%= field.label %></span></label>
                  <%= if field.type == "select" do %>
                    <select name={field.name} class="select select-bordered select-sm">
                      <%= for opt <- field.options do %>
                        <option value={opt} selected={opt == @builder_role}><%= opt %></option>
                      <% end %>
                    </select>
                  <% else %>
                    <input
                      type={field.type}
                      name={field.name}
                      value={get_builder_value(assigns, field.name)}
                      placeholder={field.placeholder}
                      class="input input-bordered input-sm font-mono"
                      autocomplete="off"
                    />
                  <% end %>
                </div>
              <% end %>
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Build Struct</button>
          </form>

          <%= if @built_struct do %>
            <div class="mt-4 space-y-3">
              <div class="bg-base-300 rounded-lg p-3">
                <div class="text-xs font-bold opacity-60 mb-1">Struct Definition</div>
                <div class="font-mono text-sm whitespace-pre-wrap"><%= @built_struct.definition %></div>
              </div>
              <div class="bg-success/10 border border-success/30 rounded-lg p-3">
                <div class="text-xs font-bold opacity-60 mb-1">Created Struct</div>
                <div class="font-mono text-sm text-success font-bold"><%= @built_struct.result %></div>
              </div>
              <div class="bg-info/10 border border-info/30 rounded-lg p-3">
                <div class="text-xs font-bold opacity-60 mb-1">Underlying Map</div>
                <div class="font-mono text-sm text-info"><%= @built_struct.as_map %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Pattern Matching on Structs -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Pattern Matching on Structs</h3>
          <p class="text-xs opacity-60 mb-4">
            Try pattern matching expressions against a struct. The struct is:
            <code class="font-mono bg-base-300 px-1 rounded">%User&lbrace;name: "Alice", email: "alice@example.com", age: 30&rbrace;</code>
          </p>

          <form phx-submit="try_match" phx-target={@myself} class="flex gap-2 items-end mb-3">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Pattern</span></label>
              <input
                type="text"
                name="pattern"
                value={@match_input}
                placeholder="%User{name: name} = user"
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Match</button>
          </form>

          <!-- Quick match examples -->
          <div class="flex flex-wrap gap-2 mb-3">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <%= for {label, code} <- match_examples() do %>
              <button
                phx-click="quick_match"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @match_result do %>
            <div class={"alert text-sm " <> if(@match_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @match_result.input %></div>
                <div class="font-mono font-bold mt-1"><%= @match_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Struct vs Map Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Struct vs Map Comparison</h3>
            <button
              phx-click="toggle_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Feature</th>
                    <th class="text-primary">Struct</th>
                    <th class="text-secondary">Map</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for item <- struct_vs_map() do %>
                    <tr>
                      <td class="font-bold text-xs"><%= item.feature %></td>
                      <td class="text-xs"><%= item.struct %></td>
                      <td class="text-xs"><%= item.map %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="mt-4 bg-warning/10 border border-warning/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Key Insight</div>
              <div class="text-sm">
                A struct is just a map with a special <code class="font-mono bg-base-300 px-1 rounded">__struct__</code> key
                that holds the module name. This means <code class="font-mono bg-base-300 px-1 rounded">%User&lbrace;&rbrace;</code> is really
                <code class="font-mono bg-base-300 px-1 rounded">%&lbrace;__struct__: User, name: nil, ...&rbrace;</code>.
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
              <span><strong>Structs</strong> are maps with compile-time guarantees: you cannot set unknown fields.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>defstruct</strong> accepts a list of atoms (nil defaults) or a keyword list (with defaults).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>@enforce_keys</strong> ensures required fields must be provided at creation time.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>The <strong>update syntax</strong> <code class="font-mono bg-base-100 px-1 rounded">%User&lbrace;user | field: val&rbrace;</code> creates a new struct (immutability).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Structs do <strong>not implement Enumerable</strong> or Access by default -- they are not directly iterable.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    example = Enum.find(struct_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_example: example)}
  end

  def handle_event("build_struct", params, socket) do
    name = Map.get(params, "name", "")
    email = Map.get(params, "email", "")
    age_str = Map.get(params, "age", "")
    role = Map.get(params, "role", "user")

    age = case Integer.parse(age_str) do
      {n, _} -> n
      :error -> nil
    end

    name_val = if name == "", do: "nil", else: ~s|"#{name}"|
    email_val = if email == "", do: "nil", else: ~s|"#{email}"|
    age_val = if age, do: "#{age}", else: "nil"

    definition = "%User{\n  name: #{name_val},\n  email: #{email_val},\n  age: #{age_val},\n  role: :#{role}\n}"

    result = "%User{name: #{name_val}, email: #{email_val}, age: #{age_val}, role: :#{role}}"

    as_map = "%{__struct__: User, name: #{name_val}, email: #{email_val}, age: #{age_val}, role: :#{role}}"

    built = %{definition: definition, result: result, as_map: as_map}

    {:noreply,
     socket
     |> assign(builder_name: name)
     |> assign(builder_email: email)
     |> assign(builder_age: age_str)
     |> assign(builder_role: role)
     |> assign(built_struct: built)}
  end

  def handle_event("try_match", %{"pattern" => pattern}, socket) do
    result = evaluate_match(String.trim(pattern))

    {:noreply,
     socket
     |> assign(match_input: pattern)
     |> assign(match_result: result)}
  end

  def handle_event("quick_match", %{"code" => code}, socket) do
    result = evaluate_match(code)

    {:noreply,
     socket
     |> assign(match_input: code)
     |> assign(match_result: result)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  # Helpers

  defp struct_examples, do: @struct_examples
  defp struct_vs_map, do: @struct_vs_map
  defp builder_fields, do: @builder_fields

  defp get_builder_value(assigns, "name"), do: assigns.builder_name
  defp get_builder_value(assigns, "email"), do: assigns.builder_email
  defp get_builder_value(assigns, "age"), do: assigns.builder_age
  defp get_builder_value(assigns, "role"), do: assigns.builder_role
  defp get_builder_value(_assigns, _), do: ""

  defp match_examples do
    [
      {"Extract name", ~s|%{name: name} = %{__struct__: User, name: "Alice", email: "alice@example.com", age: 30}|},
      {"Check age", ~s|%{age: age} = %{__struct__: User, name: "Alice", email: "alice@example.com", age: 30}|},
      {"Destructure all", ~s|%{name: n, email: e, age: a} = %{__struct__: User, name: "Alice", email: "alice@example.com", age: 30}|},
      {"Guard match", ~s|match?(%{age: a} when a >= 18, %{name: "Alice", age: 30})|}
    ]
  end

  defp evaluate_match(code) do
    try do
      {result, bindings} = Code.eval_string(code)

      output =
        if length(bindings) > 0 do
          bindings_str = Enum.map_join(bindings, ", ", fn {k, v} -> "#{k} = #{inspect(v)}" end)
          "#{inspect(result, pretty: true)}\nBindings: #{bindings_str}"
        else
          inspect(result, pretty: true)
        end

      %{ok: true, input: code, output: output}
    rescue
      e -> %{ok: false, input: code, output: "Error: #{Exception.message(e)}"}
    end
  end
end
