defmodule ElixirKatasWeb.ElixirKata16MatchingChallengesLive do
  use ElixirKatasWeb, :live_component

  @challenges [
    %{
      id: 1,
      difficulty: :easy,
      title: "Extract First Element",
      description: "Given a list, write a pattern that extracts the first element into a variable called `first`.",
      data_display: "[10, 20, 30, 40]",
      data_code: "[10, 20, 30, 40]",
      expected_var: "first",
      expected_value: "10",
      hint: "Use [first | _rest] to get the head of a list.",
      solution: "[first | _] = [10, 20, 30, 40]"
    },
    %{
      id: 2,
      difficulty: :easy,
      title: "Extract :ok Value",
      description: "Extract the value from a tagged :ok tuple into a variable called `val`.",
      data_display: "{:ok, \"success\"}",
      data_code: "{:ok, \"success\"}",
      expected_var: "val",
      expected_value: "\"success\"",
      hint: "Match the tuple structure: {:ok, val}",
      solution: "{:ok, val} = {:ok, \"success\"}"
    },
    %{
      id: 3,
      difficulty: :easy,
      title: "Match Map Keys",
      description: "Extract the `name` value from a map into a variable called `name`.",
      data_display: "%{name: \"Bob\", age: 25, role: :admin}",
      data_code: "%{name: \"Bob\", age: 25, role: :admin}",
      expected_var: "name",
      expected_value: "\"Bob\"",
      hint: "You only need to match the key you want: %{name: name}",
      solution: "%{name: name} = %{name: \"Bob\", age: 25, role: :admin}"
    },
    %{
      id: 4,
      difficulty: :medium,
      title: "Pin Operator",
      description: "The variable `expected` is bound to :ok. Write a pattern using the pin operator to assert the first element of the tuple is :ok, and extract the second into `msg`.",
      data_display: "{:ok, \"all good\"}",
      data_code: "{:ok, \"all good\"}",
      expected_var: "msg",
      expected_value: "\"all good\"",
      hint: "Use ^expected to pin: {^expected, msg}. The variable `expected` is already bound to :ok.",
      solution: "{^expected, msg} = {:ok, \"all good\"}",
      setup: "expected = :ok"
    },
    %{
      id: 5,
      difficulty: :medium,
      title: "Nested Map Destructuring",
      description: "Extract the city from a nested user map into a variable called `city`.",
      data_display: "%{user: %{name: \"Alice\", address: %{city: \"Portland\", state: \"OR\"}}}",
      data_code: "%{user: %{name: \"Alice\", address: %{city: \"Portland\", state: \"OR\"}}}",
      expected_var: "city",
      expected_value: "\"Portland\"",
      hint: "Nest map patterns: %{user: %{address: %{city: city}}}",
      solution: "%{user: %{address: %{city: city}}} = %{user: %{name: \"Alice\", address: %{city: \"Portland\", state: \"OR\"}}}"
    },
    %{
      id: 6,
      difficulty: :medium,
      title: "Head, Second, Ignore Rest",
      description: "Extract the first element into `a` and the second into `b`, ignoring the rest.",
      data_display: "[1, 2, 3, 4, 5]",
      data_code: "[1, 2, 3, 4, 5]",
      expected_var: "a",
      expected_value: "1",
      secondary_var: "b",
      secondary_value: "2",
      hint: "Use [a, b | _] to match first two and ignore the tail.",
      solution: "[a, b | _] = [1, 2, 3, 4, 5]"
    },
    %{
      id: 7,
      difficulty: :hard,
      title: "Extract from Keyword List",
      description: "Given a keyword list, extract the value associated with :port into `port`. (Hint: keyword lists are just lists of two-element tuples.)",
      data_display: "[host: \"localhost\", port: 5432, db: \"myapp\"]",
      data_code: "[host: \"localhost\", port: 5432, db: \"myapp\"]",
      expected_var: "port",
      expected_value: "5432",
      hint: "A keyword list [port: 5432] is really [{:port, 5432}]. Match with [{:host, _}, {:port, port} | _]",
      solution: "[host: _, port: port, db: _] = [host: \"localhost\", port: 5432, db: \"myapp\"]"
    },
    %{
      id: 8,
      difficulty: :hard,
      title: "Complex Nested Pattern",
      description: "Extract the first item's name into `item_name` from this API-style response.",
      data_display: "{:ok, %{data: [%{id: 1, name: \"Elixir\"}, %{id: 2, name: \"Phoenix\"}], status: 200}}",
      data_code: "{:ok, %{data: [%{id: 1, name: \"Elixir\"}, %{id: 2, name: \"Phoenix\"}], status: 200}}",
      expected_var: "item_name",
      expected_value: "\"Elixir\"",
      hint: "Combine tuple, map, and list patterns: {:ok, %{data: [%{name: item_name} | _]}}",
      solution: "{:ok, %{data: [%{name: item_name} | _]}} = {:ok, %{data: [%{id: 1, name: \"Elixir\"}, %{id: 2, name: \"Phoenix\"}], status: 200}}"
    },
    %{
      id: 9,
      difficulty: :hard,
      title: "Struct-like Map Match",
      description: "Match a map with a :__struct__ key equal to User (the atom), and extract the :email into `email`.",
      data_display: "%{__struct__: User, name: \"Eve\", email: \"eve@example.com\"}",
      data_code: "%{__struct__: User, name: \"Eve\", email: \"eve@example.com\"}",
      expected_var: "email",
      expected_value: "\"eve@example.com\"",
      hint: "Match the struct key and email: %{__struct__: User, email: email}",
      solution: "%{__struct__: User, email: email} = %{__struct__: User, name: \"Eve\", email: \"eve@example.com\"}"
    },
    %{
      id: 10,
      difficulty: :expert,
      title: "Multi-layer Extraction",
      description: "Extract both the status atom (:ok) into `status`, the first item's id into `first_id`, and the total from meta into `total`.",
      data_display: "{:ok, %{items: [%{id: 42, label: \"A\"}, %{id: 99, label: \"B\"}], meta: %{total: 2}}}",
      data_code: "{:ok, %{items: [%{id: 42, label: \"A\"}, %{id: 99, label: \"B\"}], meta: %{total: 2}}}",
      expected_var: "status",
      expected_value: ":ok",
      secondary_var: "first_id",
      secondary_value: "42",
      tertiary_var: "total",
      tertiary_value: "2",
      hint: "{status, %{items: [%{id: first_id} | _], meta: %{total: total}}}",
      solution: "{status, %{items: [%{id: first_id} | _], meta: %{total: total}}} = {:ok, %{items: [%{id: 42, label: \"A\"}, %{id: 99, label: \"B\"}], meta: %{total: 2}}}"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:challenges, fn -> @challenges end)
     |> assign_new(:current_challenge_id, fn -> 1 end)
     |> assign_new(:user_answers, fn -> %{} end)
     |> assign_new(:results, fn -> %{} end)
     |> assign_new(:show_hints, fn -> %{} end)
     |> assign_new(:show_solutions, fn -> %{} end)
     |> assign_new(:user_input, fn -> "" end)
     |> assign_new(:score, fn -> 0 end)
     |> assign_new(:attempts, fn -> %{} end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Pattern Matching Challenges</h2>
      <p class="text-sm opacity-70 mb-6">
        Test your pattern matching skills! Write patterns to extract the requested variables from each value.
        Challenges increase in difficulty from easy to expert.
      </p>

      <!-- Progress & Score Bar -->
      <div class="flex items-center justify-between mb-6">
        <div class="flex items-center gap-4">
          <div class="badge badge-lg badge-primary gap-2">
            Score: <%= @score %> / <%= length(@challenges) * 10 %>
          </div>
          <div class="badge badge-lg badge-ghost gap-2">
            <%= "#{Enum.count(@results, fn {_, v} -> v.correct end)}/#{length(@challenges)} solved" %>
          </div>
        </div>
      </div>

      <!-- Progress Tracker -->
      <div class="flex flex-wrap gap-1.5 mb-6">
        <%= for challenge <- @challenges do %>
          <% result = Map.get(@results, challenge.id) %>
          <button
            phx-click="go_to_challenge"
            phx-target={@myself}
            phx-value-id={challenge.id}
            class={"w-9 h-9 rounded-lg flex items-center justify-center font-bold text-sm transition-all cursor-pointer border-2 " <>
              cond do
                result && result.correct -> "border-success bg-success text-success-content"
                result && not result.correct -> "border-warning bg-warning/20 text-warning-content"
                challenge.id == @current_challenge_id -> "border-primary bg-primary/20"
                true -> "border-base-300 bg-base-100"
              end}
          >
            <%= if result && result.correct do %>
              &#x2713;
            <% else %>
              <%= challenge.id %>
            <% end %>
          </button>
        <% end %>
      </div>

      <!-- Current Challenge -->
      <% current = Enum.find(@challenges, &(&1.id == @current_challenge_id)) %>
      <% current_result = Map.get(@results, @current_challenge_id) %>

      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <!-- Header -->
          <div class="flex items-center justify-between mb-3">
            <div class="flex items-center gap-3">
              <h3 class="card-title text-sm">
                Challenge #<%= current.id %>: <%= current.title %>
              </h3>
              <span class={"badge badge-sm " <> difficulty_badge(current.difficulty)}>
                <%= current.difficulty %>
              </span>
            </div>
            <div class="flex gap-1">
              <button
                phx-click="prev_challenge"
                phx-target={@myself}
                disabled={@current_challenge_id <= 1}
                class="btn btn-xs btn-ghost"
              >
                &larr;
              </button>
              <span class="text-xs opacity-50 self-center"><%= @current_challenge_id %>/<%= length(@challenges) %></span>
              <button
                phx-click="next_challenge"
                phx-target={@myself}
                disabled={@current_challenge_id >= length(@challenges)}
                class="btn btn-xs btn-ghost"
              >
                &rarr;
              </button>
            </div>
          </div>

          <!-- Description -->
          <p class="text-sm mb-4"><%= current.description %></p>

          <!-- Data Display -->
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm mb-4">
            <span class="opacity-50">iex&gt; data = </span><%= current.data_display %>
          </div>

          <!-- Setup code if any -->
          <%= if Map.has_key?(current, :setup) do %>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3 font-mono text-sm mb-4">
              <span class="opacity-50"># Pre-bound variable:</span>
              <div><%= current.setup %></div>
            </div>
          <% end %>

          <!-- Expected extraction -->
          <div class="bg-base-300 rounded-lg p-3 mb-4">
            <h4 class="text-xs font-bold opacity-60 mb-2">Extract these variable(s):</h4>
            <div class="flex flex-wrap gap-3">
              <div class="flex items-center gap-2">
                <span class="badge badge-info badge-sm">target</span>
                <code class="font-mono text-sm"><%= current.expected_var %></code>
                <span class="opacity-30">=&gt;</span>
                <code class="font-mono text-sm text-success"><%= current.expected_value %></code>
              </div>
              <%= if Map.has_key?(current, :secondary_var) do %>
                <div class="flex items-center gap-2">
                  <span class="badge badge-info badge-sm">target</span>
                  <code class="font-mono text-sm"><%= current.secondary_var %></code>
                  <span class="opacity-30">=&gt;</span>
                  <code class="font-mono text-sm text-success"><%= current.secondary_value %></code>
                </div>
              <% end %>
              <%= if Map.has_key?(current, :tertiary_var) do %>
                <div class="flex items-center gap-2">
                  <span class="badge badge-info badge-sm">target</span>
                  <code class="font-mono text-sm"><%= current.tertiary_var %></code>
                  <span class="opacity-30">=&gt;</span>
                  <code class="font-mono text-sm text-success"><%= current.tertiary_value %></code>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Answer Input -->
          <form phx-submit="check_answer" phx-target={@myself} class="mb-4">
            <div class="flex gap-2">
              <div class="flex-1 font-mono text-sm bg-base-300 rounded-lg p-3 flex items-center gap-2">
                <input
                  type="text"
                  name="pattern"
                  value={Map.get(@user_answers, @current_challenge_id, "")}
                  placeholder="Your pattern here..."
                  class="input input-bordered input-sm font-mono flex-1"
                  autocomplete="off"
                  disabled={current_result && current_result.correct}
                />
                <span class="opacity-50">= data</span>
              </div>
            </div>

            <div class="flex gap-2 mt-3">
              <%= if !(current_result && current_result.correct) do %>
                <button type="submit" class="btn btn-primary btn-sm">
                  Check Answer
                </button>
              <% end %>
              <button
                type="button"
                phx-click="toggle_hint"
                phx-target={@myself}
                phx-value-id={current.id}
                class="btn btn-ghost btn-sm"
              >
                <%= if Map.has_key?(@show_hints, current.id), do: "Hide Hint", else: "Show Hint" %>
              </button>
              <%= if !(current_result && current_result.correct) do %>
                <button
                  type="button"
                  phx-click="show_solution"
                  phx-target={@myself}
                  phx-value-id={current.id}
                  class="btn btn-ghost btn-sm text-warning"
                >
                  Reveal Solution
                </button>
              <% end %>
            </div>
          </form>

          <!-- Hint -->
          <%= if Map.has_key?(@show_hints, current.id) do %>
            <div class="alert alert-info text-sm mb-4">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              <span><%= current.hint %></span>
            </div>
          <% end %>

          <!-- Solution -->
          <%= if Map.has_key?(@show_solutions, current.id) do %>
            <div class="alert alert-warning text-sm mb-4">
              <div>
                <div class="font-bold text-xs mb-1">Solution (no points):</div>
                <code class="font-mono text-xs"><%= current.solution %></code>
              </div>
            </div>
          <% end %>

          <!-- Result -->
          <%= if current_result do %>
            <div class={"alert text-sm " <> if(current_result.correct, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-bold"><%= current_result.message %></div>
                <%= if current_result.details do %>
                  <div class="font-mono text-xs mt-1"><%= current_result.details %></div>
                <% end %>
              </div>
            </div>
          <% end %>

          <!-- Attempt counter -->
          <% attempt_count = Map.get(@attempts, current.id, 0) %>
          <%= if attempt_count > 0 and !(current_result && current_result.correct) do %>
            <div class="text-xs opacity-50 mt-2">
              Attempts: <%= attempt_count %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- All Challenges Overview -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">All Challenges</h3>
          <div class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>#</th>
                  <th>Challenge</th>
                  <th>Difficulty</th>
                  <th>Status</th>
                  <th>Points</th>
                </tr>
              </thead>
              <tbody>
                <%= for challenge <- @challenges do %>
                  <% result = Map.get(@results, challenge.id) %>
                  <tr
                    phx-click="go_to_challenge"
                    phx-target={@myself}
                    phx-value-id={challenge.id}
                    class={"cursor-pointer hover:bg-base-300 " <> if(challenge.id == @current_challenge_id, do: "bg-primary/10", else: "")}
                  >
                    <td class="font-bold"><%= challenge.id %></td>
                    <td><%= challenge.title %></td>
                    <td>
                      <span class={"badge badge-xs " <> difficulty_badge(challenge.difficulty)}>
                        <%= challenge.difficulty %>
                      </span>
                    </td>
                    <td>
                      <%= if result && result.correct do %>
                        <span class="text-success font-bold">&#x2713; Solved</span>
                      <% else %>
                        <%= if result do %>
                          <span class="text-warning">Attempted</span>
                        <% else %>
                          <span class="opacity-30">Not started</span>
                        <% end %>
                      <% end %>
                    </td>
                    <td>
                      <%= if result && result.correct do %>
                        <span class="text-success font-bold">10</span>
                      <% else %>
                        <span class="opacity-30">-</span>
                      <% end %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("go_to_challenge", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)

    {:noreply,
     socket
     |> assign(current_challenge_id: id)
     |> assign(user_input: Map.get(socket.assigns.user_answers, id, ""))}
  end

  def handle_event("prev_challenge", _params, socket) do
    new_id = max(socket.assigns.current_challenge_id - 1, 1)

    {:noreply,
     socket
     |> assign(current_challenge_id: new_id)
     |> assign(user_input: Map.get(socket.assigns.user_answers, new_id, ""))}
  end

  def handle_event("next_challenge", _params, socket) do
    new_id = min(socket.assigns.current_challenge_id + 1, length(socket.assigns.challenges))

    {:noreply,
     socket
     |> assign(current_challenge_id: new_id)
     |> assign(user_input: Map.get(socket.assigns.user_answers, new_id, ""))}
  end

  def handle_event("check_answer", %{"pattern" => pattern}, socket) do
    pattern = String.trim(pattern)
    challenge_id = socket.assigns.current_challenge_id
    challenge = Enum.find(socket.assigns.challenges, &(&1.id == challenge_id))

    # Don't re-check already solved challenges
    existing_result = Map.get(socket.assigns.results, challenge_id)

    if existing_result && existing_result.correct do
      {:noreply, socket}
    else
      if pattern == "" do
        {:noreply, socket}
      else
        {correct, message, details} = evaluate_answer(pattern, challenge)

        new_attempts = Map.update(socket.assigns.attempts, challenge_id, 1, &(&1 + 1))

        new_score =
          if correct and !(existing_result && existing_result.correct) do
            socket.assigns.score + 10
          else
            socket.assigns.score
          end

        {:noreply,
         socket
         |> assign(user_answers: Map.put(socket.assigns.user_answers, challenge_id, pattern))
         |> assign(results: Map.put(socket.assigns.results, challenge_id, %{correct: correct, message: message, details: details}))
         |> assign(attempts: new_attempts)
         |> assign(score: new_score)}
      end
    end
  end

  def handle_event("toggle_hint", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    hints = socket.assigns.show_hints

    new_hints =
      if Map.has_key?(hints, id) do
        Map.delete(hints, id)
      else
        Map.put(hints, id, true)
      end

    {:noreply, assign(socket, show_hints: new_hints)}
  end

  def handle_event("show_solution", %{"id" => id_str}, socket) do
    id = String.to_integer(id_str)
    {:noreply, assign(socket, show_solutions: Map.put(socket.assigns.show_solutions, id, true))}
  end

  # Helpers

  defp evaluate_answer(pattern, challenge) do
    # Build the code to evaluate
    setup = Map.get(challenge, :setup, "")
    code = if setup != "", do: "#{setup}\n#{pattern} = #{challenge.data_code}", else: "#{pattern} = #{challenge.data_code}"

    try do
      {_result, bindings} = Code.eval_string(code)
      bindings_map = Map.new(bindings)

      # Check primary expected variable
      primary_var = String.to_atom(challenge.expected_var)
      primary_ok = check_binding(bindings_map, primary_var, challenge.expected_value)

      # Check secondary if exists
      secondary_ok =
        if Map.has_key?(challenge, :secondary_var) do
          sec_var = String.to_atom(challenge.secondary_var)
          check_binding(bindings_map, sec_var, challenge.secondary_value)
        else
          true
        end

      # Check tertiary if exists
      tertiary_ok =
        if Map.has_key?(challenge, :tertiary_var) do
          ter_var = String.to_atom(challenge.tertiary_var)
          check_binding(bindings_map, ter_var, challenge.tertiary_value)
        else
          true
        end

      if primary_ok and secondary_ok and tertiary_ok do
        bound_str =
          bindings
          |> Enum.map(fn {k, v} -> "#{k} = #{inspect(v)}" end)
          |> Enum.join(", ")

        {true, "Correct! Well done!", "Bindings: #{bound_str}"}
      else
        missing_vars = []

        missing_vars =
          if not primary_ok,
            do: missing_vars ++ ["#{challenge.expected_var} should be #{challenge.expected_value}"],
            else: missing_vars

        missing_vars =
          if Map.has_key?(challenge, :secondary_var) and not secondary_ok,
            do: missing_vars ++ ["#{challenge.secondary_var} should be #{challenge.secondary_value}"],
            else: missing_vars

        missing_vars =
          if Map.has_key?(challenge, :tertiary_var) and not tertiary_ok,
            do: missing_vars ++ ["#{challenge.tertiary_var} should be #{challenge.tertiary_value}"],
            else: missing_vars

        bound_str =
          bindings
          |> Enum.map(fn {k, v} -> "#{k} = #{inspect(v)}" end)
          |> Enum.join(", ")

        {false, "Pattern matched but wrong bindings.", "Got: #{bound_str}. Missing: #{Enum.join(missing_vars, ", ")}"}
      end
    rescue
      e in MatchError ->
        {false, "MatchError - your pattern does not match the data.", Exception.message(e)}

      e in CompileError ->
        {false, "Syntax error in your pattern.", Exception.message(e)}

      e ->
        {false, "Error evaluating pattern.", Exception.message(e)}
    end
  end

  defp check_binding(bindings_map, var_atom, expected_str) do
    case Map.get(bindings_map, var_atom) do
      nil -> false
      value -> inspect(value) == expected_str or to_string(value) == expected_str
    end
  end

  defp difficulty_badge(:easy), do: "badge-success"
  defp difficulty_badge(:medium), do: "badge-warning"
  defp difficulty_badge(:hard), do: "badge-error"
  defp difficulty_badge(:expert), do: "badge-primary"
  defp difficulty_badge(_), do: "badge-ghost"
end
