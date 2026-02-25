defmodule ElixirKatasWeb.ElixirKata15DestructuringLive do
  use ElixirKatasWeb, :live_component

  @structures [
    %{
      id: "user_profile",
      title: "Nested User Profile",
      data_display: "%{user: %{name: \"Alice\", age: 30, address: %{city: \"NYC\", zip: \"10001\"}}}",
      data: %{"user" => %{"name" => "Alice", "age" => 30, "address" => %{"city" => "NYC", "zip" => "10001"}}},
      tree: [
        %{key: "user", depth: 0, type: :map, value: nil},
        %{key: "name", depth: 1, type: :string, value: "\"Alice\""},
        %{key: "age", depth: 1, type: :integer, value: "30"},
        %{key: "address", depth: 1, type: :map, value: nil},
        %{key: "city", depth: 2, type: :string, value: "\"NYC\""},
        %{key: "zip", depth: 2, type: :string, value: "\"10001\""}
      ],
      challenges: [
        %{id: "c1", prompt: "Extract the user's name", answer: "name", target_path: "user.name", hint: "%{user: %{name: name}} = data", extracted_value: "\"Alice\""},
        %{id: "c2", prompt: "Extract the city", answer: "city", target_path: "user.address.city", hint: "%{user: %{address: %{city: city}}} = data", extracted_value: "\"NYC\""},
        %{id: "c3", prompt: "Extract both name and zip", answer: "name_and_zip", target_path: "user.name + user.address.zip", hint: "%{user: %{name: name, address: %{zip: zip}}} = data", extracted_value: "\"Alice\" and \"10001\""}
      ]
    },
    %{
      id: "api_response",
      title: "API Response",
      data_display: "{:ok, %{data: [%{id: 1, name: \"widget\"}, %{id: 2, name: \"gadget\"}], meta: %{total: 2, page: 1}}}",
      data: {:ok, %{"data" => [%{"id" => 1, "name" => "widget"}, %{"id" => 2, "name" => "gadget"}], "meta" => %{"total" => 2, "page" => 1}}},
      tree: [
        %{key: ":ok", depth: 0, type: :atom, value: ":ok"},
        %{key: "data", depth: 0, type: :list, value: nil},
        %{key: "[0]", depth: 1, type: :map, value: nil},
        %{key: "id", depth: 2, type: :integer, value: "1"},
        %{key: "name", depth: 2, type: :string, value: "\"widget\""},
        %{key: "[1]", depth: 1, type: :map, value: nil},
        %{key: "id", depth: 2, type: :integer, value: "2"},
        %{key: "name", depth: 2, type: :string, value: "\"gadget\""},
        %{key: "meta", depth: 0, type: :map, value: nil},
        %{key: "total", depth: 1, type: :integer, value: "2"},
        %{key: "page", depth: 1, type: :integer, value: "1"}
      ],
      challenges: [
        %{id: "c1", prompt: "Extract the :ok status and the data list", answer: "status_data", target_path: ":ok + data", hint: "{:ok, %{data: items}} = response", extracted_value: ":ok and [%{id: 1, ...}, ...]"},
        %{id: "c2", prompt: "Extract the first item's name", answer: "first_name", target_path: "data[0].name", hint: "{:ok, %{data: [%{name: name} | _]}} = response", extracted_value: "\"widget\""},
        %{id: "c3", prompt: "Extract total from meta", answer: "total", target_path: "meta.total", hint: "{:ok, %{meta: %{total: total}}} = response", extracted_value: "2"},
        %{id: "c4", prompt: "Extract first and second item names at once", answer: "both_names", target_path: "data[0].name + data[1].name", hint: "{:ok, %{data: [%{name: n1}, %{name: n2}]}} = response", extracted_value: "\"widget\" and \"gadget\""}
      ]
    },
    %{
      id: "config",
      title: "Application Config",
      data_display: "[app: [db: [host: \"localhost\", port: 5432], cache: [ttl: 3600]], env: :prod]",
      data: [app: [db: [host: "localhost", port: 5432], cache: [ttl: 3600]], env: :prod],
      tree: [
        %{key: "app", depth: 0, type: :keyword, value: nil},
        %{key: "db", depth: 1, type: :keyword, value: nil},
        %{key: "host", depth: 2, type: :string, value: "\"localhost\""},
        %{key: "port", depth: 2, type: :integer, value: "5432"},
        %{key: "cache", depth: 1, type: :keyword, value: nil},
        %{key: "ttl", depth: 2, type: :integer, value: "3600"},
        %{key: "env", depth: 0, type: :atom, value: ":prod"}
      ],
      challenges: [
        %{id: "c1", prompt: "Extract the env value", answer: "env", target_path: "env", hint: "[app: _, env: env] = config", extracted_value: ":prod"},
        %{id: "c2", prompt: "Extract the database host", answer: "host", target_path: "app.db.host", hint: "[app: [db: [host: host | _] | _] | _] = config", extracted_value: "\"localhost\""},
        %{id: "c3", prompt: "Extract the cache TTL", answer: "ttl", target_path: "app.cache.ttl", hint: "[app: [db: _, cache: [ttl: ttl]], env: _] = config", extracted_value: "3600"}
      ]
    },
    %{
      id: "event",
      title: "Event Payload",
      data_display: "%{event: \"purchase\", payload: %{user: %{id: 42, email: \"a@b.com\"}, items: [{:item, \"Book\", 29.99}, {:item, \"Pen\", 4.50}], total: 34.49}}",
      data: %{"event" => "purchase", "payload" => %{"user" => %{"id" => 42, "email" => "a@b.com"}, "items" => [{:item, "Book", 29.99}, {:item, "Pen", 4.50}], "total" => 34.49}},
      tree: [
        %{key: "event", depth: 0, type: :string, value: "\"purchase\""},
        %{key: "payload", depth: 0, type: :map, value: nil},
        %{key: "user", depth: 1, type: :map, value: nil},
        %{key: "id", depth: 2, type: :integer, value: "42"},
        %{key: "email", depth: 2, type: :string, value: "\"a@b.com\""},
        %{key: "items", depth: 1, type: :list, value: nil},
        %{key: "[0]", depth: 2, type: :tuple, value: "{:item, \"Book\", 29.99}"},
        %{key: "[1]", depth: 2, type: :tuple, value: "{:item, \"Pen\", 4.50}"},
        %{key: "total", depth: 1, type: :float, value: "34.49"}
      ],
      challenges: [
        %{id: "c1", prompt: "Extract the event name", answer: "event", target_path: "event", hint: "%{event: event} = data", extracted_value: "\"purchase\""},
        %{id: "c2", prompt: "Extract the user email", answer: "email", target_path: "payload.user.email", hint: "%{payload: %{user: %{email: email}}} = data", extracted_value: "\"a@b.com\""},
        %{id: "c3", prompt: "Extract the first item's name from the tuple", answer: "first_item", target_path: "payload.items[0] name", hint: "%{payload: %{items: [{:item, name, _price} | _]}} = data", extracted_value: "\"Book\""},
        %{id: "c4", prompt: "Extract user id and total together", answer: "id_total", target_path: "payload.user.id + payload.total", hint: "%{payload: %{user: %{id: id}, total: total}} = data", extracted_value: "42 and 34.49"}
      ]
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:current_structure, fn -> hd(@structures) end)
     |> assign_new(:active_challenge, fn -> nil end)
     |> assign_new(:show_hint, fn -> MapSet.new() end)
     |> assign_new(:completed_challenges, fn -> MapSet.new() end)
     |> assign_new(:highlighted_path, fn -> nil end)
     |> assign_new(:user_pattern, fn -> "" end)
     |> assign_new(:challenge_result, fn -> nil end)
     |> assign_new(:total_score, fn -> 0 end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Destructuring in Practice</h2>
      <p class="text-sm opacity-70 mb-6">
        Real-world Elixir code often involves deeply nested data structures. Destructuring lets you reach
        into complex structures and extract exactly what you need in a single pattern match.
      </p>

      <!-- Score Display -->
      <div class="flex items-center gap-4 mb-6">
        <div class="badge badge-lg badge-primary gap-2">
          Score: <%= @total_score %>
        </div>
        <div class="badge badge-lg badge-ghost gap-2">
          Completed: <%= MapSet.size(@completed_challenges) %> / <%= Enum.sum(Enum.map(structures(), fn s -> length(s.challenges) end)) %>
        </div>
      </div>

      <!-- Structure Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for structure <- structures() do %>
          <button
            phx-click="select_structure"
            phx-target={@myself}
            phx-value-id={structure.id}
            class={"btn btn-sm " <> if(@current_structure.id == structure.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= structure.title %>
            <span class={"badge badge-xs ml-1 " <> structure_progress_badge(structure, @completed_challenges)}>
              <%= structure_progress(structure, @completed_challenges) %>
            </span>
          </button>
        <% end %>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <!-- Data Structure Display -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <h3 class="card-title text-sm mb-3">Data Structure</h3>

            <!-- Code View -->
            <div class="bg-base-300 rounded-lg p-3 font-mono text-xs mb-4 whitespace-pre-wrap break-all">
              <span class="opacity-50">data = </span><%= @current_structure.data_display %>
            </div>

            <!-- Tree View -->
            <h4 class="text-xs font-bold opacity-60 mb-2">Structure Tree</h4>
            <div class="bg-base-100 rounded-lg p-3 space-y-1">
              <%= for node <- @current_structure.tree do %>
                <div
                  class={"flex items-center gap-2 py-0.5 rounded px-1 transition-all " <>
                    if(is_highlighted?(node, @highlighted_path), do: "bg-primary/20 font-bold", else: "")}
                  style={"padding-left: #{node.depth * 1.25}rem"}
                >
                  <!-- Connector -->
                  <%= if node.depth > 0 do %>
                    <span class="text-xs opacity-30">&lfloor;</span>
                  <% end %>

                  <!-- Type Badge -->
                  <span class={"badge badge-xs " <> type_badge(node.type)}><%= node.type %></span>

                  <!-- Key -->
                  <span class="font-mono text-sm text-info"><%= node.key %></span>

                  <!-- Value (if leaf) -->
                  <%= if node.value do %>
                    <span class="opacity-30">&rarr;</span>
                    <span class="font-mono text-sm text-success"><%= node.value %></span>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <!-- Challenges Panel -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <h3 class="card-title text-sm mb-3">Extraction Challenges</h3>

            <div class="space-y-3">
              <%= for challenge <- @current_structure.challenges do %>
                <% completed = MapSet.member?(@completed_challenges, "#{@current_structure.id}_#{challenge.id}") %>
                <div class={"rounded-lg p-3 border-2 transition-all " <>
                  cond do
                    completed -> "border-success bg-success/10"
                    @active_challenge && @active_challenge.id == challenge.id -> "border-primary bg-primary/10"
                    true -> "border-base-300 bg-base-100"
                  end}>
                  <div class="flex items-start justify-between gap-2">
                    <div class="flex-1">
                      <div class="flex items-center gap-2 mb-1">
                        <%= if completed do %>
                          <span class="text-success font-bold">&#x2713;</span>
                        <% else %>
                          <span class="opacity-30">&#x25cb;</span>
                        <% end %>
                        <span class="text-sm font-semibold"><%= challenge.prompt %></span>
                      </div>

                      <%= if completed do %>
                        <div class="font-mono text-xs text-success mt-1">
                          Extracted: <strong><%= challenge.extracted_value %></strong>
                        </div>
                      <% end %>
                    </div>

                    <div class="flex gap-1">
                      <%= if not completed do %>
                        <button
                          phx-click="select_challenge"
                          phx-target={@myself}
                          phx-value-challenge_id={challenge.id}
                          class={"btn btn-xs " <> if(@active_challenge && @active_challenge.id == challenge.id, do: "btn-primary", else: "btn-outline")}
                        >
                          Try
                        </button>
                      <% end %>
                      <button
                        phx-click="toggle_hint"
                        phx-target={@myself}
                        phx-value-key={"#{@current_structure.id}_#{challenge.id}"}
                        class="btn btn-xs btn-ghost"
                      >
                        Hint
                      </button>
                    </div>
                  </div>

                  <!-- Hint -->
                  <%= if MapSet.member?(@show_hint, "#{@current_structure.id}_#{challenge.id}") do %>
                    <div class="mt-2 bg-base-300 rounded p-2 font-mono text-xs text-warning">
                      <span class="opacity-60">Pattern: </span><%= challenge.hint %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- Active Challenge Input -->
      <%= if @active_challenge do %>
        <div class="card bg-base-200 shadow-md mb-6">
          <div class="card-body p-4">
            <h3 class="card-title text-sm mb-2">
              Challenge: <%= @active_challenge.prompt %>
            </h3>
            <p class="text-xs opacity-60 mb-3">
              Write a pattern that would appear on the left side of <code class="font-mono bg-base-300 px-1 rounded">=</code> to extract the requested value(s).
            </p>

            <form phx-submit="check_answer" phx-target={@myself} class="space-y-3">
              <div class="form-control">
                <div class="flex gap-2">
                  <div class="flex-1 font-mono text-sm bg-base-300 rounded-lg p-3 flex items-center gap-2">
                    <input
                      type="text"
                      name="pattern"
                      value={@user_pattern}
                      placeholder="Your pattern here..."
                      class="input input-bordered input-sm font-mono flex-1"
                      autocomplete="off"
                    />
                    <span class="opacity-50">= data</span>
                  </div>
                </div>
              </div>

              <div class="flex gap-2">
                <button type="submit" class="btn btn-primary btn-sm">Check Answer</button>
                <button
                  type="button"
                  phx-click="show_solution"
                  phx-target={@myself}
                  class="btn btn-ghost btn-sm"
                >
                  Show Solution
                </button>
              </div>
            </form>

            <!-- Result -->
            <%= if @challenge_result do %>
              <div class={"alert text-sm mt-3 " <> if(@challenge_result.correct, do: "alert-success", else: "alert-warning")}>
                <div>
                  <div class="font-bold"><%= @challenge_result.message %></div>
                  <%= if @challenge_result.pattern do %>
                    <div class="font-mono text-xs mt-1">
                      Pattern: <code><%= @challenge_result.pattern %></code>
                    </div>
                  <% end %>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Destructuring Patterns Reference -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Destructuring Patterns Reference</h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Map -->
            <div class="bg-primary/10 border border-primary/30 rounded-lg p-3">
              <h4 class="font-bold text-primary text-sm mb-2">Map Destructuring</h4>
              <div class="font-mono text-xs space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Extract one key</div>
                  <div>%&lbrace;name: name&rbrace; = %&lbrace;name: "Alice", age: 30&rbrace;</div>
                  <div class="text-success">name = "Alice"</div>
                </div>
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Nested maps</div>
                  <div>%&lbrace;a: %&lbrace;b: val&rbrace;&rbrace; = %&lbrace;a: %&lbrace;b: 42&rbrace;&rbrace;</div>
                  <div class="text-success">val = 42</div>
                </div>
              </div>
            </div>

            <!-- Tuple -->
            <div class="bg-secondary/10 border border-secondary/30 rounded-lg p-3">
              <h4 class="font-bold text-secondary text-sm mb-2">Tuple Destructuring</h4>
              <div class="font-mono text-xs space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Tagged tuples</div>
                  <div>&lbrace;:ok, value&rbrace; = &lbrace;:ok, 42&rbrace;</div>
                  <div class="text-success">value = 42</div>
                </div>
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Nested in maps</div>
                  <div>&lbrace;:ok, %&lbrace;data: items&rbrace;&rbrace; = resp</div>
                  <div class="text-success">items = [...]</div>
                </div>
              </div>
            </div>

            <!-- List -->
            <div class="bg-accent/10 border border-accent/30 rounded-lg p-3">
              <h4 class="font-bold text-accent text-sm mb-2">List Destructuring</h4>
              <div class="font-mono text-xs space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Head and tail</div>
                  <div>[head | tail] = [1, 2, 3]</div>
                  <div class="text-success">head = 1, tail = [2, 3]</div>
                </div>
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># First two elements</div>
                  <div>[a, b | _rest] = [1, 2, 3, 4]</div>
                  <div class="text-success">a = 1, b = 2</div>
                </div>
              </div>
            </div>

            <!-- Keyword -->
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <h4 class="font-bold text-info text-sm mb-2">Keyword Destructuring</h4>
              <div class="font-mono text-xs space-y-2">
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Access with Keyword module</div>
                  <div>config = [port: 4000, env: :dev]</div>
                  <div>Keyword.get(config, :port)</div>
                  <div class="text-success">4000</div>
                </div>
                <div class="bg-base-100 rounded p-2">
                  <div class="opacity-60"># Pattern match (order-sensitive!)</div>
                  <div>[port: p, env: e] = [port: 4000, env: :dev]</div>
                  <div class="text-success">p = 4000, e = :dev</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Tips -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Destructuring Tips</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span>You only need to match the keys you care about - extra keys are ignored in maps.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>Use <code class="font-mono bg-base-100 px-1 rounded">_</code> to ignore values you do not need.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Nest patterns to reach deep values: <code class="font-mono bg-base-100 px-1 rounded">%&lbrace;a: %&lbrace;b: %&lbrace;c: val&rbrace;&rbrace;&rbrace;</code></span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>Combine list head/tail with map patterns: <code class="font-mono bg-base-100 px-1 rounded">[%&lbrace;name: n&rbrace; | _]</code></span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Tagged tuples plus destructuring is idiomatic: <code class="font-mono bg-base-100 px-1 rounded">&lbrace;:ok, %&lbrace;data: items&rbrace;&rbrace;</code></span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_structure", %{"id" => id}, socket) do
    structure = Enum.find(structures(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(current_structure: structure)
     |> assign(active_challenge: nil)
     |> assign(challenge_result: nil)
     |> assign(highlighted_path: nil)
     |> assign(user_pattern: "")}
  end

  def handle_event("select_challenge", %{"challenge_id" => challenge_id}, socket) do
    challenge = Enum.find(socket.assigns.current_structure.challenges, &(&1.id == challenge_id))

    {:noreply,
     socket
     |> assign(active_challenge: challenge)
     |> assign(challenge_result: nil)
     |> assign(highlighted_path: challenge.target_path)
     |> assign(user_pattern: "")}
  end

  def handle_event("toggle_hint", %{"key" => key}, socket) do
    show_hint = socket.assigns.show_hint

    new_hints =
      if MapSet.member?(show_hint, key) do
        MapSet.delete(show_hint, key)
      else
        MapSet.put(show_hint, key)
      end

    {:noreply, assign(socket, show_hint: new_hints)}
  end

  def handle_event("check_answer", %{"pattern" => pattern}, socket) do
    challenge = socket.assigns.active_challenge
    structure = socket.assigns.current_structure
    pattern = String.trim(pattern)

    if challenge == nil or pattern == "" do
      {:noreply, socket}
    else
      {correct, message} = validate_pattern(pattern, challenge, structure)

      challenge_key = "#{structure.id}_#{challenge.id}"

      new_completed =
        if correct do
          MapSet.put(socket.assigns.completed_challenges, challenge_key)
        else
          socket.assigns.completed_challenges
        end

      new_score =
        if correct and not MapSet.member?(socket.assigns.completed_challenges, challenge_key) do
          socket.assigns.total_score + 10
        else
          socket.assigns.total_score
        end

      {:noreply,
       socket
       |> assign(user_pattern: pattern)
       |> assign(challenge_result: %{correct: correct, message: message, pattern: nil})
       |> assign(completed_challenges: new_completed)
       |> assign(total_score: new_score)}
    end
  end

  def handle_event("show_solution", _params, socket) do
    challenge = socket.assigns.active_challenge

    if challenge do
      {:noreply,
       socket
       |> assign(challenge_result: %{
         correct: false,
         message: "Solution revealed (no points awarded):",
         pattern: challenge.hint
       })}
    else
      {:noreply, socket}
    end
  end

  # Helpers

  defp structures, do: @structures

  defp validate_pattern(pattern, challenge, structure) do
    normalized = pattern |> String.replace(~r/\s+/, "") |> String.downcase()
    hint_normalized = challenge.hint |> String.replace(~r/\s+/, "") |> String.downcase()

    # Try to actually evaluate the pattern against the data
    code = "#{pattern} = #{structure.data_display}"

    try do
      {_result, bindings} = Code.eval_string(code)

      if length(bindings) > 0 do
        # Check if the pattern extracts meaningful values related to the challenge
        bound_values = Enum.map(bindings, fn {_k, v} -> inspect(v) end)
        expected = challenge.extracted_value

        # Simple heuristic: check if expected values appear in bindings
        values_match =
          Enum.any?(bound_values, fn bv ->
            String.contains?(expected, String.replace(bv, "\"", ""))
          end)

        if values_match or normalized == hint_normalized do
          {true, "Correct! Extracted: #{inspect(bindings |> Enum.map(fn {k, v} -> "#{k} = #{inspect(v)}" end) |> Enum.join(", "))}."}
        else
          {false, "Your pattern matched but did not extract the right values. Expected to get: #{expected}. Got bindings: #{inspect(bindings)}"}
        end
      else
        {false, "Pattern matched but no variables were bound. Use variable names to capture values."}
      end
    rescue
      e in MatchError ->
        {false, "MatchError - the pattern does not match the data structure. Check your nesting. #{Exception.message(e)}"}

      e in CompileError ->
        {false, "Syntax error in pattern: #{Exception.message(e)}"}

      e ->
        {false, "Error: #{Exception.message(e)}"}
    end
  end

  defp is_highlighted?(_node, nil), do: false

  defp is_highlighted?(node, path) do
    parts = String.split(path, ~r/[\.\+]/) |> Enum.map(&String.trim/1)
    node.key in parts
  end

  defp type_badge(:map), do: "badge-primary"
  defp type_badge(:string), do: "badge-success"
  defp type_badge(:integer), do: "badge-info"
  defp type_badge(:float), do: "badge-info"
  defp type_badge(:atom), do: "badge-secondary"
  defp type_badge(:list), do: "badge-accent"
  defp type_badge(:tuple), do: "badge-warning"
  defp type_badge(:keyword), do: "badge-error"
  defp type_badge(_), do: "badge-ghost"

  defp structure_progress(structure, completed) do
    done =
      Enum.count(structure.challenges, fn c ->
        MapSet.member?(completed, "#{structure.id}_#{c.id}")
      end)

    "#{done}/#{length(structure.challenges)}"
  end

  defp structure_progress_badge(structure, completed) do
    done =
      Enum.count(structure.challenges, fn c ->
        MapSet.member?(completed, "#{structure.id}_#{c.id}")
      end)

    cond do
      done == length(structure.challenges) -> "badge-success"
      done > 0 -> "badge-warning"
      true -> "badge-ghost"
    end
  end
end
