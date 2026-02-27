defmodule ElixirKatasWeb.PhoenixApiKata03ParamsAndJsonLive do
  use ElixirKatasWeb, :live_component

  @sample_bodies %{
    "create_user" => ~s|{"user": {"name": "Alice", "email": "alice@example.com", "age": 30}}|,
    "update_post" => ~s|{"post": {"title": "Updated Title", "published": true}}|,
    "nested" => ~s|{"order": {"items": [{"product_id": 1, "qty": 2}, {"product_id": 5, "qty": 1}], "coupon": "SAVE10"}}|,
    "simple" => ~s|{"message": "Hello, World!"}|
  }

  def phoenix_source do
    """
    # Params & JSON Encoding in Phoenix APIs
    #
    # Phoenix automatically parses JSON request bodies into Elixir maps.
    # All params (path, query, body) are merged into a single map.

    # How params arrive in your controller:
    #
    # Request:
    #   PUT /api/users/42?admin=true
    #   Content-Type: application/json
    #   {"user": {"name": "Alice", "email": "alice@example.com"}}
    #
    # Params map (all merged):
    #   %{
    #     "id" => "42",               # from path /users/:id
    #     "admin" => "true",           # from query string
    #     "user" => %{                 # from JSON body
    #       "name" => "Alice",
    #       "email" => "alice@example.com"
    #     }
    #   }

    defmodule MyAppWeb.Api.UserController do
      use MyAppWeb, :controller

      # Pattern match to extract exactly what you need
      def update(conn, %{"id" => id, "user" => user_params}) do
        user = Accounts.get_user!(id)

        case Accounts.update_user(user, user_params) do
          {:ok, user} -> json(conn, %{data: user})
          {:error, cs} -> # handle error
        end
      end

      # Or grab all params
      def create(conn, params) do
        IO.inspect(params, label: "All params")
        # %{"user" => %{"name" => "Alice", ...}}
      end
    end

    # config/config.exs — Jason is the default JSON library
    config :phoenix, :json_library, Jason

    # Jason.encode! converts Elixir → JSON
    # Jason.decode! converts JSON → Elixir
    Jason.encode!(%{name: "Alice", age: 30})
    # => ~s|{"age":30,"name":"Alice"}|

    Jason.decode!(~s|{"name": "Alice", "age": 30}|)
    # => %{"name" => "Alice", "age" => 30}
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    default_body = @sample_bodies["create_user"]
    {parsed, parse_error} = try_parse(default_body)
    re_encoded = if parsed, do: try_encode(parsed), else: nil

    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(json_input: default_body)
     |> assign(parsed_map: parsed)
     |> assign(parse_error: parse_error)
     |> assign(re_encoded: re_encoded)
     |> assign(selected_sample: "create_user")
     |> assign(path_param: "42")
     |> assign(query_string: "admin=true&page=1")
     |> assign(show_merged: false)
     |> assign(samples: @sample_bodies)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">Params & JSON Encoding</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Enter JSON and see how Phoenix parses it into an Elixir map, then re-encodes it back.
        Explore how path params, query params, and body params get merged.
      </p>

      <!-- Sample Picker -->
      <div>
        <h3 class="text-sm font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">Load a Sample</h3>
        <div class="flex flex-wrap gap-2">
          <%= for {key, _body} <- @samples do %>
            <button
              phx-click="load_sample"
              phx-value-key={key}
              phx-target={@myself}
              class={["px-3 py-1.5 rounded-lg text-sm font-medium transition-colors cursor-pointer",
                if(@selected_sample == key,
                  do: "bg-rose-600 text-white",
                  else: "bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-rose-100 dark:hover:bg-rose-900/30")
              ]}
            >
              {format_sample_name(key)}
            </button>
          <% end %>
        </div>
      </div>

      <!-- JSON Input/Output -->
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-4">
        <!-- Input -->
        <div>
          <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">
            JSON Input <span class="text-gray-400 font-normal">(request body)</span>
          </label>
          <form phx-change="update_json" phx-target={@myself}>
            <textarea
              name="json_body"
              rows="8"
              class="w-full font-mono text-sm bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-700 rounded-lg p-3 text-gray-900 dark:text-white focus:ring-rose-500 focus:border-rose-500"
              phx-debounce="300"
            ><%= @json_input %></textarea>
          </form>
        </div>

        <!-- Arrow + Parsed -->
        <div>
          <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">
            Elixir Map <span class="text-gray-400 font-normal">(Jason.decode!)</span>
          </label>
          <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm h-[calc(8*1.5rem+1.5rem)] overflow-auto">
            <%= if @parse_error do %>
              <div class="text-red-400"># Parse error!</div>
              <div class="text-red-300">{@parse_error}</div>
            <% else %>
              <div class="text-gray-500"># Jason.decode!(json_string)</div>
              <pre class="text-emerald-400 whitespace-pre-wrap"><%= inspect(@parsed_map, pretty: true) %></pre>
            <% end %>
          </div>
        </div>

        <!-- Re-encoded -->
        <div>
          <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">
            Re-encoded JSON <span class="text-gray-400 font-normal">(Jason.encode!)</span>
          </label>
          <div class="bg-gray-900 rounded-lg p-3 font-mono text-sm h-[calc(8*1.5rem+1.5rem)] overflow-auto">
            <%= if @re_encoded do %>
              <div class="text-gray-500"># Jason.encode!(elixir_map, pretty: true)</div>
              <pre class="text-cyan-400 whitespace-pre-wrap"><%= @re_encoded %></pre>
            <% else %>
              <div class="text-gray-500"># Fix the JSON input to see output</div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Key Insight: String Keys</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          JSON keys become <strong>string keys</strong> in Elixir, not atoms.
          <code>{"~s(%{\"name\" => \"Alice\"})"}</code>, not <code>{"~s(%{name: \"Alice\"})"}</code>.
          This is intentional — user input should never create atoms (atoms are not garbage collected).
        </p>
      </div>

      <!-- Params Merging Simulator -->
      <div class="border-t border-gray-200 dark:border-gray-700 pt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Params Merging Simulator</h3>
        <p class="text-sm text-gray-600 dark:text-gray-300 mb-4">
          Phoenix merges path params, query params, and body params into a single map.
          Edit the fields below and see the merged result.
        </p>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
          <!-- Path Params -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Path Param <span class="text-gray-400 font-normal">(/users/:id)</span>
            </label>
            <div class="flex items-center gap-2">
              <span class="text-gray-500 font-mono text-sm">/api/users/</span>
              <form phx-change="update_path_param" phx-target={@myself} class="flex-1">
                <input
                  type="text"
                  name="path_id"
                  value={@path_param}
                  class="w-full font-mono text-sm bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-700 rounded px-2 py-1 text-gray-900 dark:text-white focus:ring-rose-500 focus:border-rose-500"
                  phx-debounce="300"
                />
              </form>
            </div>
            <div class="mt-1 text-xs font-mono text-blue-600 dark:text-blue-400">{"%{\"id\" => \"#{@path_param}\"}"}</div>
          </div>

          <!-- Query Params -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Query String
            </label>
            <form phx-change="update_query" phx-target={@myself}>
              <input
                type="text"
                name="query"
                value={@query_string}
                class="w-full font-mono text-sm bg-gray-50 dark:bg-gray-900 border border-gray-300 dark:border-gray-700 rounded px-2 py-1 text-gray-900 dark:text-white focus:ring-rose-500 focus:border-rose-500"
                phx-debounce="300"
              />
            </form>
            <div class="mt-1 text-xs font-mono text-purple-600 dark:text-purple-400">
              <%= inspect(parse_query_string(@query_string)) %>
            </div>
          </div>

          <!-- Body Params -->
          <div>
            <label class="block text-sm font-semibold text-gray-700 dark:text-gray-300 mb-1">
              Body Params <span class="text-gray-400 font-normal">(from JSON above)</span>
            </label>
            <div class="text-xs font-mono text-emerald-600 dark:text-emerald-400">
              <%= if @parsed_map, do: inspect(@parsed_map, pretty: true, limit: 3), else: "(invalid JSON)" %>
            </div>
          </div>
        </div>

        <button
          phx-click="show_merged"
          phx-target={@myself}
          class="px-4 py-2 bg-rose-600 hover:bg-rose-700 text-white rounded-lg font-medium transition-colors cursor-pointer text-sm"
        >
          Merge All Params
        </button>

        <%= if @show_merged do %>
          <div class="mt-4 bg-gray-900 rounded-lg p-4 font-mono text-sm">
            <div class="text-gray-500 mb-2"># What your controller action receives as `params`:</div>
            <div class="text-gray-500"># PUT /api/users/{@path_param}?{@query_string}</div>
            <div class="text-gray-500 mb-2"># Body: (your JSON input above)</div>
            <pre class="text-yellow-400 whitespace-pre-wrap"><%= inspect(merged_params(@path_param, @query_string, @parsed_map), pretty: true) %></pre>
            <div class="mt-3 text-gray-500"># Pattern match in your controller:</div>
            <div class="text-white">{"def update(conn, %{\"id\" => id, \"user\" => user_params}) do"}</div>
            <div class="text-green-400 ml-4">{"# id => \"#{@path_param}\""}</div>
            <div class="text-green-400 ml-4">{"# user_params => (body \"user\" key value)"}</div>
            <div class="text-white">end</div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp format_sample_name(key) do
    key
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  defp try_parse(json_string) do
    case Jason.decode(json_string) do
      {:ok, map} -> {map, nil}
      {:error, %Jason.DecodeError{} = err} -> {nil, Exception.message(err)}
    end
  end

  defp try_encode(map) do
    case Jason.encode(map, pretty: true) do
      {:ok, json} -> json
      {:error, _} -> nil
    end
  end

  defp parse_query_string(qs) do
    qs
    |> String.split("&", trim: true)
    |> Enum.reduce(%{}, fn pair, acc ->
      case String.split(pair, "=", parts: 2) do
        [key, val] -> Map.put(acc, key, val)
        [key] -> Map.put(acc, key, "")
        _ -> acc
      end
    end)
  end

  defp merged_params(path_id, query_string, body_map) do
    path = %{"id" => path_id}
    query = parse_query_string(query_string)
    body = body_map || %{}

    Map.merge(path, query) |> Map.merge(body)
  end

  def handle_event("load_sample", %{"key" => key}, socket) do
    body = Map.get(@sample_bodies, key, "{}")
    {parsed, parse_error} = try_parse(body)
    re_encoded = if parsed, do: try_encode(parsed), else: nil

    {:noreply,
     socket
     |> assign(json_input: body)
     |> assign(parsed_map: parsed)
     |> assign(parse_error: parse_error)
     |> assign(re_encoded: re_encoded)
     |> assign(selected_sample: key)
     |> assign(show_merged: false)
    }
  end

  def handle_event("update_json", %{"json_body" => body}, socket) do
    {parsed, parse_error} = try_parse(body)
    re_encoded = if parsed, do: try_encode(parsed), else: nil

    {:noreply,
     socket
     |> assign(json_input: body)
     |> assign(parsed_map: parsed)
     |> assign(parse_error: parse_error)
     |> assign(re_encoded: re_encoded)
     |> assign(show_merged: false)
    }
  end

  def handle_event("update_path_param", %{"path_id" => id}, socket) do
    {:noreply, assign(socket, path_param: id, show_merged: false)}
  end

  def handle_event("update_query", %{"query" => qs}, socket) do
    {:noreply, assign(socket, query_string: qs, show_merged: false)}
  end

  def handle_event("show_merged", _params, socket) do
    {:noreply, assign(socket, show_merged: true)}
  end
end
