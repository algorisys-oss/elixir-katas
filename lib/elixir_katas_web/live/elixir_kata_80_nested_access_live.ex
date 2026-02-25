defmodule ElixirKatasWeb.ElixirKata80NestedAccessLive do
  use ElixirKatasWeb, :live_component

  @sample_data %{
    users: [
      %{name: "Alice", address: %{city: "Portland", zip: "97201"}, roles: [:admin, :user]},
      %{name: "Bob", address: %{city: "Seattle", zip: "98101"}, roles: [:user]}
    ],
    settings: %{theme: "dark", notifications: %{email: true, sms: false}}
  }

  @access_functions [
    %{
      id: "get_in",
      title: "get_in/2",
      description: "Retrieves a value from a nested structure using a list of keys.",
      examples: [
        %{
          label: "Get nested map value",
          code: ~s|data = %{users: [%{name: "Alice", address: %{city: "Portland"}}], settings: %{theme: "dark"}}\nget_in(data, [:settings, :theme])|,
          note: "Follows the key path [:settings, :theme] into the nested map."
        },
        %{
          label: "Get with Access.all",
          code: ~s|data = %{users: [%{name: "Alice"}, %{name: "Bob"}]}\nget_in(data, [:users, Access.all(), :name])|,
          note: "Access.all() traverses every element in the list."
        },
        %{
          label: "Get with Access.at",
          code: ~s|data = %{users: [%{name: "Alice"}, %{name: "Bob"}]}\nget_in(data, [:users, Access.at(1), :name])|,
          note: "Access.at(1) gets the element at index 1."
        },
        %{
          label: "Missing key returns nil",
          code: ~s|data = %{settings: %{theme: "dark"}}\nget_in(data, [:settings, :language])|,
          note: "Returns nil for missing keys instead of raising."
        }
      ]
    },
    %{
      id: "put_in",
      title: "put_in/3",
      description: "Puts a value into a nested structure at the given path.",
      examples: [
        %{
          label: "Update nested value",
          code: ~s|data = %{settings: %{theme: "dark", notifications: %{email: true}}}\nput_in(data, [:settings, :theme], "light")|,
          note: "Replaces the value at the specified path."
        },
        %{
          label: "Put with Access.at",
          code: ~s|data = %{users: [%{name: "Alice"}, %{name: "Bob"}]}\nput_in(data, [:users, Access.at(0), :name], "Alicia")|,
          note: "Updates a specific element in a nested list."
        },
        %{
          label: "Put with Access.all",
          code: ~s|data = %{users: [%{name: "Alice"}, %{name: "Bob"}]}\nput_in(data, [:users, Access.all(), :active], true)|,
          note: "Sets :active on every user via Access.all()."
        }
      ]
    },
    %{
      id: "update_in",
      title: "update_in/3",
      description: "Updates a value in a nested structure by applying a function.",
      examples: [
        %{
          label: "Transform nested value",
          code: ~s|data = %{settings: %{theme: "dark"}}\nupdate_in(data, [:settings, :theme], &String.upcase/1)|,
          note: "Applies the function to the value at the path."
        },
        %{
          label: "Increment counter",
          code: ~s|data = %{stats: %{views: 10, likes: 5}}\nupdate_in(data, [:stats, :views], &(&1 + 1))|,
          note: "Functions receive the current value and return the new one."
        },
        %{
          label: "Update all elements",
          code: ~s|data = %{scores: [10, 20, 30]}\nupdate_in(data, [:scores, Access.all()], &(&1 * 2))|,
          note: "Doubles every score using Access.all()."
        }
      ]
    },
    %{
      id: "pop_in",
      title: "pop_in/2",
      description: "Removes a key from a nested structure and returns both the value and the updated structure.",
      examples: [
        %{
          label: "Pop a nested key",
          code: ~s|data = %{settings: %{theme: "dark", lang: "en"}}\npop_in(data, [:settings, :lang])|,
          note: "Returns {popped_value, updated_structure}."
        },
        %{
          label: "Pop from list with Access.at",
          code: ~s|data = %{items: ["a", "b", "c"]}\npop_in(data, [:items, Access.at(1)])|,
          note: "Removes the element at index 1 and returns it."
        }
      ]
    }
  ]

  @access_module_fns [
    %{
      id: "key",
      title: "Access.key/2",
      code: ~s|data = %{user: %{name: "Alice", age: 30}}\nget_in(data, [Access.key(:user), Access.key(:name)])|,
      note: "Like using atom keys directly, but explicit. Optional second arg is a default."
    },
    %{
      id: "key!",
      title: "Access.key!/1",
      code: ~s|data = %{user: %{name: "Alice"}}\ntry do\n  get_in(data, [Access.key!(:user), Access.key!(:missing)])\nrescue\n  e -> "Error: " <> Exception.message(e)\nend|,
      note: "Raises KeyError if the key is missing. Use for required keys."
    },
    %{
      id: "elem",
      title: "Access.elem/1",
      code: ~s|data = %{pair: {:ok, "hello"}}\nget_in(data, [:pair, Access.elem(1)])|,
      note: "Accesses a tuple element by index."
    },
    %{
      id: "at",
      title: "Access.at/1",
      code: ~s|data = %{items: ["a", "b", "c", "d"]}\n{get_in(data, [:items, Access.at(0)]), get_in(data, [:items, Access.at(-1)])}|,
      note: "Accesses a list element by index. Supports negative indices."
    },
    %{
      id: "all",
      title: "Access.all/0",
      code: ~s|data = %{users: [%{name: "Alice", active: true}, %{name: "Bob", active: false}]}\nget_in(data, [:users, Access.all(), :name])|,
      note: "Traverses ALL elements in a list. Returns a list of results."
    },
    %{
      id: "filter",
      title: "Access.filter/1",
      code: ~s|data = %{users: [%{name: "Alice", active: true}, %{name: "Bob", active: false}, %{name: "Carol", active: true}]}\nget_in(data, [:users, Access.filter(& &1.active), :name])|,
      note: "Filters list elements by a predicate, then continues the access path."
    }
  ]

  @path_builder_paths [
    %{id: "city_first", label: "First user's city", path: "[:users, Access.at(0), :address, :city]", code: ~s|data = %{\n  users: [\n    %{name: "Alice", address: %{city: "Portland", zip: "97201"}, roles: [:admin, :user]},\n    %{name: "Bob", address: %{city: "Seattle", zip: "98101"}, roles: [:user]}\n  ],\n  settings: %{theme: "dark", notifications: %{email: true, sms: false}}\n}\nget_in(data, [:users, Access.at(0), :address, :city])|},
    %{id: "all_names", label: "All user names", path: "[:users, Access.all(), :name]", code: ~s|data = %{\n  users: [\n    %{name: "Alice", address: %{city: "Portland", zip: "97201"}, roles: [:admin, :user]},\n    %{name: "Bob", address: %{city: "Seattle", zip: "98101"}, roles: [:user]}\n  ],\n  settings: %{theme: "dark", notifications: %{email: true, sms: false}}\n}\nget_in(data, [:users, Access.all(), :name])|},
    %{id: "email_setting", label: "Email notification setting", path: "[:settings, :notifications, :email]", code: ~s|data = %{\n  users: [\n    %{name: "Alice", address: %{city: "Portland", zip: "97201"}, roles: [:admin, :user]},\n    %{name: "Bob", address: %{city: "Seattle", zip: "98101"}, roles: [:user]}\n  ],\n  settings: %{theme: "dark", notifications: %{email: true, sms: false}}\n}\nget_in(data, [:settings, :notifications, :email])|},
    %{id: "admin_roles", label: "First user's first role", path: "[:users, Access.at(0), :roles, Access.at(0)]", code: ~s|data = %{\n  users: [\n    %{name: "Alice", address: %{city: "Portland", zip: "97201"}, roles: [:admin, :user]},\n    %{name: "Bob", address: %{city: "Seattle", zip: "98101"}, roles: [:user]}\n  ],\n  settings: %{theme: "dark", notifications: %{email: true, sms: false}}\n}\nget_in(data, [:users, Access.at(0), :roles, Access.at(0)])|},
    %{id: "all_cities", label: "All cities", path: "[:users, Access.all(), :address, :city]", code: ~s|data = %{\n  users: [\n    %{name: "Alice", address: %{city: "Portland", zip: "97201"}, roles: [:admin, :user]},\n    %{name: "Bob", address: %{city: "Seattle", zip: "98101"}, roles: [:user]}\n  ],\n  settings: %{theme: "dark", notifications: %{email: true, sms: false}}\n}\nget_in(data, [:users, Access.all(), :address, :city])|},
    %{id: "update_theme", label: "Update theme to light", path: "[:settings, :theme]", code: ~s|data = %{\n  users: [\n    %{name: "Alice", address: %{city: "Portland", zip: "97201"}, roles: [:admin, :user]},\n    %{name: "Bob", address: %{city: "Seattle", zip: "98101"}, roles: [:user]}\n  ],\n  settings: %{theme: "dark", notifications: %{email: true, sms: false}}\n}\nput_in(data, [:settings, :theme], "light")|}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_fn, fn -> hd(@access_functions) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:fn_result, fn -> nil end)
     |> assign_new(:active_access_fn, fn -> hd(@access_module_fns) end)
     |> assign_new(:access_result, fn -> nil end)
     |> assign_new(:active_path, fn -> hd(@path_builder_paths) end)
     |> assign_new(:path_result, fn -> nil end)
     |> assign_new(:show_comparison, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Nested Data Access</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir provides powerful tools for working with <strong>deeply nested data structures</strong>.
        The <code class="font-mono bg-base-300 px-1 rounded">get_in</code>,
        <code class="font-mono bg-base-300 px-1 rounded">put_in</code>,
        <code class="font-mono bg-base-300 px-1 rounded">update_in</code>, and
        <code class="font-mono bg-base-300 px-1 rounded">pop_in</code> functions combined with the
        <code class="font-mono bg-base-300 px-1 rounded">Access</code> module let you navigate and
        transform nested maps, lists, and tuples with ease.
      </p>

      <!-- Section 1: Access Functions Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Access Functions Explorer</h3>

          <!-- Function Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for func <- access_functions() do %>
              <button
                phx-click="select_fn"
                phx-target={@myself}
                phx-value-id={func.id}
                class={"btn btn-sm " <> if(@active_fn.id == func.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= func.title %>
              </button>
            <% end %>
          </div>

          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm mb-4">
            <%= @active_fn.description %>
          </div>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-3">
            <%= for {ex, idx} <- Enum.with_index(@active_fn.examples) do %>
              <button
                phx-click="select_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"btn btn-xs " <> if(@active_example_idx == idx, do: "btn-accent", else: "btn-ghost")}
              >
                <%= ex.label %>
              </button>
            <% end %>
          </div>

          <% example = Enum.at(@active_fn.examples, @active_example_idx) %>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= example.code %></div>
          <div class="text-xs opacity-70 mb-3"><%= example.note %></div>

          <button
            phx-click="run_fn_example"
            phx-target={@myself}
            class="btn btn-primary btn-sm"
          >
            Run Example
          </button>

          <%= if @fn_result do %>
            <div class={"alert text-sm mt-3 " <> if(@fn_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= @fn_result.output %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 2: Access Module -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Access Module</h3>
          <p class="text-xs opacity-70 mb-4">
            The <code class="font-mono bg-base-300 px-1 rounded">Access</code> module provides
            functions that act as dynamic accessors in nested paths.
          </p>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for afn <- access_module_fns() do %>
              <button
                phx-click="select_access_fn"
                phx-target={@myself}
                phx-value-id={afn.id}
                class={"btn btn-sm " <> if(@active_access_fn.id == afn.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= afn.title %>
              </button>
            <% end %>
          </div>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_access_fn.code %></div>
          <div class="text-xs opacity-70 mb-3"><%= @active_access_fn.note %></div>

          <button
            phx-click="run_access_example"
            phx-target={@myself}
            class="btn btn-primary btn-sm"
          >
            Run Example
          </button>

          <%= if @access_result do %>
            <div class={"alert text-sm mt-3 " <> if(@access_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= @access_result.output %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 3: Interactive Path Builder -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Interactive Path Builder</h3>
          <p class="text-xs opacity-70 mb-3">
            Explore the nested data structure by selecting a path and seeing the result.
          </p>

          <!-- Data Structure Display -->
          <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-4"><%= sample_data_string() %></div>

          <!-- Path Buttons -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for p <- path_builder_paths() do %>
              <button
                phx-click="select_path"
                phx-target={@myself}
                phx-value-id={p.id}
                class={"btn btn-sm " <> if(@active_path.id == p.id, do: "btn-accent", else: "btn-outline")}
              >
                <%= p.label %>
              </button>
            <% end %>
          </div>

          <div class="bg-base-100 border border-base-300 rounded-lg p-3 mb-3">
            <div class="text-xs opacity-60 mb-1">Path:</div>
            <div class="font-mono text-sm text-primary"><%= @active_path.path %></div>
          </div>

          <button
            phx-click="run_path"
            phx-target={@myself}
            class="btn btn-primary btn-sm"
          >
            Execute Path
          </button>

          <%= if @path_result do %>
            <div class={"alert text-sm mt-3 " <> if(@path_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= @path_result.output %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 4: Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Pattern Matching vs get_in/put_in</h3>
            <button
              phx-click="toggle_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_comparison, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_comparison do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
              <div>
                <div class="text-xs font-bold text-warning mb-2">Manual Pattern Matching</div>
                <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><%= comparison_manual() %></div>
              </div>
              <div>
                <div class="text-xs font-bold text-success mb-2">Using get_in / put_in</div>
                <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><%= comparison_access() %></div>
              </div>
            </div>

            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Aspect</th>
                    <th>Pattern Matching</th>
                    <th>get_in / put_in</th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td class="font-bold">Readability</td>
                    <td class="text-warning">Verbose for deep nesting</td>
                    <td class="text-success">Concise path syntax</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Dynamic paths</td>
                    <td class="text-error">Not possible</td>
                    <td class="text-success">Paths are just lists</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Missing keys</td>
                    <td class="text-warning">MatchError / need defaults</td>
                    <td class="text-success">Returns nil gracefully</td>
                  </tr>
                  <tr>
                    <td class="font-bold">Compile-time checks</td>
                    <td class="text-success">Pattern validated</td>
                    <td class="text-warning">Runtime only</td>
                  </tr>
                  <tr>
                    <td class="font-bold">List traversal</td>
                    <td class="text-error">Manual Enum required</td>
                    <td class="text-success">Access.all() / Access.filter()</td>
                  </tr>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 5: Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try It</h3>
          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <textarea
              name="code"
              rows="6"
              class="textarea textarea-bordered font-mono text-sm w-full"
              placeholder={sandbox_placeholder()}
              autocomplete="off"
            ><%= @sandbox_code %></textarea>
            <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
          </form>

          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, code} <- sandbox_examples() do %>
              <button
                phx-click="quick_sandbox"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @sandbox_result do %>
            <div class={"alert text-sm mt-3 " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono text-xs whitespace-pre-wrap"><%= @sandbox_result.output %></div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 6: Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>get_in/2, put_in/3, update_in/3, pop_in/2</strong> let you navigate nested structures with a list of keys, avoiding deeply nested pattern matches.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Access.all()</strong> and <strong>Access.filter/1</strong> traverse and filter list elements inside nested paths, returning lists of results.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Access.key!/1</strong> raises on missing keys while <strong>Access.key/2</strong> returns a default. Choose based on whether the key is required or optional.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Paths are just lists</strong>, so they can be built dynamically at runtime &mdash; something pattern matching cannot do.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Access.elem/1</strong> and <strong>Access.at/1</strong> extend nested access to tuples and list indices, making the entire Access system work across all common data types.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_fn", %{"id" => id}, socket) do
    func = Enum.find(access_functions(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_fn: func)
     |> assign(active_example_idx: 0)
     |> assign(fn_result: nil)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, active_example_idx: idx, fn_result: nil)}
  end

  def handle_event("run_fn_example", _params, socket) do
    example = Enum.at(socket.assigns.active_fn.examples, socket.assigns.active_example_idx)
    result = evaluate_code(example.code)
    {:noreply, assign(socket, fn_result: result)}
  end

  def handle_event("select_access_fn", %{"id" => id}, socket) do
    afn = Enum.find(access_module_fns(), &(&1.id == id))
    {:noreply, assign(socket, active_access_fn: afn, access_result: nil)}
  end

  def handle_event("run_access_example", _params, socket) do
    result = evaluate_code(socket.assigns.active_access_fn.code)
    {:noreply, assign(socket, access_result: result)}
  end

  def handle_event("select_path", %{"id" => id}, socket) do
    p = Enum.find(path_builder_paths(), &(&1.id == id))
    {:noreply, assign(socket, active_path: p, path_result: nil)}
  end

  def handle_event("run_path", _params, socket) do
    result = evaluate_code(socket.assigns.active_path.code)
    {:noreply, assign(socket, path_result: result)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end

  def handle_event("run_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))
    {:noreply, assign(socket, sandbox_code: code, sandbox_result: result)}
  end

  def handle_event("quick_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(code)
    {:noreply, assign(socket, sandbox_code: code, sandbox_result: result)}
  end

  # Helpers

  defp access_functions, do: @access_functions
  defp access_module_fns, do: @access_module_fns
  defp path_builder_paths, do: @path_builder_paths

  defp sample_data_string do
    inspect(@sample_data, pretty: true, limit: :infinity)
  end

  defp comparison_manual do
    """
    # Get a deeply nested value
    %{users: [first | _]} = data
    %{address: %{city: city}} = first
    # city => "Portland"

    # Update a deeply nested value
    %{users: [first | rest]} = data
    updated_first = put_in(first.address.city, "Eugene")
    %{data | users: [updated_first | rest]}\
    """
  end

  defp comparison_access do
    """
    # Get a deeply nested value
    city = get_in(data, [:users, Access.at(0), :address, :city])
    # city => "Portland"

    # Update a deeply nested value
    put_in(data, [:users, Access.at(0), :address, :city], "Eugene")\
    """
  end

  defp sandbox_placeholder do
    "data = %{users: [%{name: \"Alice\"}, %{name: \"Bob\"}]}\nget_in(data, [:users, Access.all(), :name])"
  end

  defp sandbox_examples do
    [
      {"get_in basics",
       ~s|data = %{a: %{b: %{c: 42}}}\nget_in(data, [:a, :b, :c])|},
      {"Access.filter",
       ~s|data = %{items: [%{name: "a", price: 10}, %{name: "b", price: 50}, %{name: "c", price: 30}]}\nget_in(data, [:items, Access.filter(&(&1.price > 20)), :name])|},
      {"update_in + all",
       ~s|data = %{users: [%{name: "alice"}, %{name: "bob"}]}\nupdate_in(data, [:users, Access.all(), :name], &String.capitalize/1)|},
      {"dynamic path",
       ~s|data = %{a: %{b: %{c: "found!"}}}\npath = [:a, :b, :c]\nget_in(data, path)|}
    ]
  end

  defp evaluate_code(code) do
    try do
      {result, _bindings} = Code.eval_string(code)
      %{ok: true, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, output: "Error: #{Exception.message(e)}"}
    end
  end
end
