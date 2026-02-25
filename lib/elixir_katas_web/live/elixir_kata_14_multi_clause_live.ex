defmodule ElixirKatasWeb.ElixirKata14MultiClauseLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "fizzbuzz",
      title: "FizzBuzz",
      description: "Classic FizzBuzz using multi-clause functions with guards",
      clauses: [
        %{id: 0, head: "fizzbuzz(n) when rem(n, 15) == 0", body: "\"FizzBuzz\"", guard: "rem(n, 15) == 0"},
        %{id: 1, head: "fizzbuzz(n) when rem(n, 3) == 0", body: "\"Fizz\"", guard: "rem(n, 3) == 0"},
        %{id: 2, head: "fizzbuzz(n) when rem(n, 5) == 0", body: "\"Buzz\"", guard: "rem(n, 5) == 0"},
        %{id: 3, head: "fizzbuzz(n)", body: "n", guard: nil}
      ],
      input_type: "integer",
      input_label: "Enter a number",
      default_input: "15",
      evaluate: &__MODULE__.eval_fizzbuzz/1
    },
    %{
      id: "greeting",
      title: "Greeting by Language",
      description: "Pattern match on atoms to select a greeting",
      clauses: [
        %{id: 0, head: "greet(:english)", body: "\"Hello!\"", guard: nil},
        %{id: 1, head: "greet(:spanish)", body: "\"Hola!\"", guard: nil},
        %{id: 2, head: "greet(:japanese)", body: "\"Konnichiwa!\"", guard: nil},
        %{id: 3, head: "greet(:french)", body: "\"Bonjour!\"", guard: nil},
        %{id: 4, head: "greet(_lang)", body: "\"Hi! (unknown language)\"", guard: nil}
      ],
      input_type: "select",
      input_label: "Select a language",
      options: [":english", ":spanish", ":japanese", ":french", ":german", ":unknown"],
      default_input: ":english",
      evaluate: &__MODULE__.eval_greeting/1
    },
    %{
      id: "shape_area",
      title: "Shape Area Calculator",
      description: "Destructure tuples to calculate areas of different shapes",
      clauses: [
        %{id: 0, head: "area({:circle, r})", body: "3.14159 * r * r", guard: nil},
        %{id: 1, head: "area({:rectangle, w, h})", body: "w * h", guard: nil},
        %{id: 2, head: "area({:triangle, b, h})", body: "0.5 * b * h", guard: nil},
        %{id: 3, head: "area({:square, s})", body: "s * s", guard: nil},
        %{id: 4, head: "area(_shape)", body: "{:error, :unknown_shape}", guard: nil}
      ],
      input_type: "select",
      input_label: "Select a shape",
      options: ["{:circle, 5}", "{:rectangle, 4, 6}", "{:triangle, 3, 8}", "{:square, 7}", "{:hexagon, 3}"],
      default_input: "{:circle, 5}",
      evaluate: &__MODULE__.eval_shape_area/1
    },
    %{
      id: "status",
      title: "HTTP Status Handler",
      description: "Match on status codes with guards for ranges",
      clauses: [
        %{id: 0, head: "handle(200)", body: "\"OK - Success\"", guard: nil},
        %{id: 1, head: "handle(201)", body: "\"Created\"", guard: nil},
        %{id: 2, head: "handle(301)", body: "\"Moved Permanently\"", guard: nil},
        %{id: 3, head: "handle(404)", body: "\"Not Found\"", guard: nil},
        %{id: 4, head: "handle(code) when code >= 500", body: "\"Server Error: \#{code}\"", guard: "code >= 500"},
        %{id: 5, head: "handle(code) when code >= 400", body: "\"Client Error: \#{code}\"", guard: "code >= 400"},
        %{id: 6, head: "handle(code)", body: "\"Other: \#{code}\"", guard: nil}
      ],
      input_type: "integer",
      input_label: "Enter HTTP status code",
      default_input: "404",
      evaluate: &__MODULE__.eval_status/1
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:current_example, fn -> hd(@examples) end)
     |> assign_new(:user_input, fn -> hd(@examples).default_input end)
     |> assign_new(:match_result, fn -> nil end)
     |> assign_new(:matched_clause_id, fn -> nil end)
     |> assign_new(:clause_order, fn -> Enum.map(hd(@examples).clauses, & &1.id) end)
     |> assign_new(:reorder_mode, fn -> false end)
     |> assign_new(:show_unreachable_demo, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Multi-Clause Functions</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir lets you define multiple clauses of the same function. When called, Elixir tries each clause
        top-to-bottom and uses the first one that matches. This is "first match wins."
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for ex <- examples() do %>
          <button
            phx-click="select_example"
            phx-target={@myself}
            phx-value-id={ex.id}
            class={"btn btn-sm " <> if(@current_example.id == ex.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= ex.title %>
          </button>
        <% end %>
      </div>

      <!-- Function Clauses Display -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm"><%= @current_example.title %></h3>
            <div class="flex gap-2">
              <span class="badge badge-info badge-sm"><%= length(@current_example.clauses) %> clauses</span>
              <button
                phx-click="toggle_reorder"
                phx-target={@myself}
                class={"btn btn-xs " <> if(@reorder_mode, do: "btn-warning", else: "btn-ghost")}
              >
                <%= if @reorder_mode, do: "Done Reordering", else: "Reorder Clauses" %>
              </button>
            </div>
          </div>
          <p class="text-xs opacity-60 mb-4"><%= @current_example.description %></p>

          <!-- First Match Wins Arrow -->
          <div class="flex items-start gap-3">
            <div class="flex flex-col items-center">
              <span class="text-xs opacity-40 mb-1">try</span>
              <div class="w-0.5 bg-warning flex-1 min-h-[2rem]"></div>
              <span class="text-xs opacity-40 mt-1">&darr;</span>
            </div>

            <div class="flex-1 space-y-2">
              <% ordered_clauses = get_ordered_clauses(@current_example.clauses, @clause_order) %>
              <%= for {clause, idx} <- Enum.with_index(ordered_clauses) do %>
                <div class={"rounded-lg p-3 border-2 transition-all " <> clause_style(clause.id, @matched_clause_id, idx, @match_result)}>
                  <div class="flex items-center justify-between">
                    <div class="flex-1">
                      <div class="font-mono text-sm">
                        <span class="opacity-50">def </span>
                        <span class="font-bold"><%= clause.head %></span>
                        <span class="opacity-50"> do</span>
                      </div>
                      <div class="font-mono text-sm ml-4 text-accent">
                        <%= clause.body %>
                      </div>
                      <div class="font-mono text-sm opacity-50">end</div>
                      <%= if clause.guard do %>
                        <div class="mt-1">
                          <span class="badge badge-warning badge-xs">guard: <%= clause.guard %></span>
                        </div>
                      <% end %>
                    </div>

                    <!-- Match indicator -->
                    <div class="flex items-center gap-2">
                      <%= if @matched_clause_id != nil do %>
                        <%= if clause.id == @matched_clause_id do %>
                          <span class="badge badge-success">MATCHED</span>
                        <% else %>
                          <%= if is_before_match?(clause.id, @matched_clause_id, @clause_order) do %>
                            <span class="badge badge-ghost badge-sm opacity-50">skipped</span>
                          <% else %>
                            <span class="badge badge-ghost badge-sm opacity-30">not reached</span>
                          <% end %>
                        <% end %>
                      <% end %>

                      <!-- Reorder buttons -->
                      <%= if @reorder_mode do %>
                        <div class="flex flex-col gap-0.5">
                          <button
                            phx-click="move_clause"
                            phx-target={@myself}
                            phx-value-clause_id={clause.id}
                            phx-value-direction="up"
                            disabled={idx == 0}
                            class="btn btn-xs btn-ghost"
                          >&uarr;</button>
                          <button
                            phx-click="move_clause"
                            phx-target={@myself}
                            phx-value-clause_id={clause.id}
                            phx-value-direction="down"
                            disabled={idx == length(ordered_clauses) - 1}
                            class="btn btn-xs btn-ghost"
                          >&darr;</button>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      </div>

      <!-- Input & Test -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Test an Input</h3>

          <form phx-submit="test_input" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs"><%= @current_example.input_label %></span></label>
              <%= if @current_example.input_type == "select" do %>
                <select name="input" class="select select-bordered select-sm font-mono">
                  <%= for opt <- @current_example.options do %>
                    <option value={opt} selected={opt == @user_input}><%= opt %></option>
                  <% end %>
                </select>
              <% else %>
                <input
                  type="text"
                  name="input"
                  value={@user_input}
                  class="input input-bordered input-sm font-mono"
                  autocomplete="off"
                />
              <% end %>
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Call Function</button>
          </form>

          <!-- Result -->
          <%= if @match_result do %>
            <div class={"alert text-sm " <> if(@match_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono font-bold">
                  <%= @current_example.title |> String.downcase() |> String.replace(" ", "_") %>(<%= @user_input %>)
                </div>
                <div class="mt-1">
                  <%= if @match_result.ok do %>
                    &rArr; <span class="font-mono font-bold"><%= @match_result.value %></span>
                    <span class="opacity-60 ml-2">(clause #<%= @match_result.clause_index + 1 %>)</span>
                  <% else %>
                    <span class="font-mono"><%= @match_result.value %></span>
                  <% end %>
                </div>
              </div>
            </div>
          <% end %>

          <!-- Quick Tests -->
          <%= if @current_example.input_type == "integer" do %>
            <div class="flex flex-wrap gap-2 mt-4">
              <span class="text-xs opacity-50 self-center">Quick tests:</span>
              <%= for val <- quick_test_values(@current_example.id) do %>
                <button
                  phx-click="quick_test"
                  phx-target={@myself}
                  phx-value-input={val}
                  class="btn btn-xs btn-outline"
                >
                  <%= val %>
                </button>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Reorder Warning -->
      <%= if @reorder_mode do %>
        <div class="alert alert-warning mb-6 text-sm">
          <svg xmlns="http://www.w3.org/2000/svg" class="stroke-current shrink-0 h-5 w-5" fill="none" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
          <div>
            <div class="font-bold">Reorder Mode Active</div>
            <span>Move clauses up/down to see how order affects matching. Try putting the catch-all clause first!</span>
          </div>
        </div>
      <% end %>

      <!-- Unreachable Clauses Demo -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Unreachable Clauses Warning</h3>
            <button
              phx-click="toggle_unreachable"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_unreachable_demo, do: "Hide", else: "Show Example" %>
            </button>
          </div>

          <%= if @show_unreachable_demo do %>
            <div class="space-y-3">
              <p class="text-sm opacity-70">
                If a broad clause appears before a specific one, the specific clause can never be reached.
                Elixir warns about this at compile time.
              </p>

              <!-- Bad Example -->
              <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                <h4 class="font-bold text-error text-sm mb-2">Bad: Catch-all First</h4>
                <div class="font-mono text-sm space-y-1">
                  <div>
                    <span class="opacity-50">def </span>
                    <span class="font-bold">greet(_lang)</span>
                    <span class="text-error ml-2"># catches everything!</span>
                  </div>
                  <div class="opacity-30">
                    <span class="opacity-50">def </span>
                    <span class="font-bold line-through">greet(:english)</span>
                    <span class="text-error ml-2"># never reached!</span>
                  </div>
                  <div class="opacity-30">
                    <span class="opacity-50">def </span>
                    <span class="font-bold line-through">greet(:spanish)</span>
                    <span class="text-error ml-2"># never reached!</span>
                  </div>
                </div>
                <div class="mt-2 text-xs text-error font-mono">
                  warning: this clause for greet/1 cannot match because a previous clause always matches
                </div>
              </div>

              <!-- Good Example -->
              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <h4 class="font-bold text-success text-sm mb-2">Good: Specific First, Catch-all Last</h4>
                <div class="font-mono text-sm space-y-1">
                  <div>
                    <span class="opacity-50">def </span>
                    <span class="font-bold">greet(:english)</span>
                    <span class="text-success ml-2"># specific</span>
                  </div>
                  <div>
                    <span class="opacity-50">def </span>
                    <span class="font-bold">greet(:spanish)</span>
                    <span class="text-success ml-2"># specific</span>
                  </div>
                  <div>
                    <span class="opacity-50">def </span>
                    <span class="font-bold">greet(_lang)</span>
                    <span class="text-warning ml-2"># catch-all last</span>
                  </div>
                </div>
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
              <span><strong>First match wins</strong> - Elixir tries clauses top-to-bottom and uses the first match.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Guards</strong> refine matching: <code class="font-mono bg-base-100 px-1 rounded">when is_integer(x)</code>, <code class="font-mono bg-base-100 px-1 rounded">when x &gt; 0</code></span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Catch-all</strong> <code class="font-mono bg-base-100 px-1 rounded">_</code> should always be the <em>last</em> clause.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Clause ordering</strong> matters! Elixir warns about unreachable clauses at compile time.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    example = Enum.find(examples(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(current_example: example)
     |> assign(user_input: example.default_input)
     |> assign(match_result: nil)
     |> assign(matched_clause_id: nil)
     |> assign(clause_order: Enum.map(example.clauses, & &1.id))
     |> assign(reorder_mode: false)}
  end

  def handle_event("test_input", %{"input" => input}, socket) do
    run_match(socket, input)
  end

  def handle_event("quick_test", %{"input" => input}, socket) do
    run_match(socket, input)
  end

  def handle_event("toggle_reorder", _params, socket) do
    {:noreply, assign(socket, reorder_mode: !socket.assigns.reorder_mode)}
  end

  def handle_event("move_clause", %{"clause_id" => clause_id_str, "direction" => direction}, socket) do
    clause_id = String.to_integer(clause_id_str)
    order = socket.assigns.clause_order
    idx = Enum.find_index(order, &(&1 == clause_id))

    new_order =
      case direction do
        "up" when idx > 0 ->
          order |> List.delete_at(idx) |> List.insert_at(idx - 1, clause_id)

        "down" when idx < length(order) - 1 ->
          order |> List.delete_at(idx) |> List.insert_at(idx + 1, clause_id)

        _ ->
          order
      end

    {:noreply,
     socket
     |> assign(clause_order: new_order)
     |> assign(match_result: nil)
     |> assign(matched_clause_id: nil)}
  end

  def handle_event("toggle_unreachable", _params, socket) do
    {:noreply, assign(socket, show_unreachable_demo: !socket.assigns.show_unreachable_demo)}
  end

  # Evaluation functions (public for function capture)

  def eval_fizzbuzz(n) when is_integer(n) do
    cond do
      rem(n, 15) == 0 -> {0, "\"FizzBuzz\""}
      rem(n, 3) == 0 -> {1, "\"Fizz\""}
      rem(n, 5) == 0 -> {2, "\"Buzz\""}
      true -> {3, "#{n}"}
    end
  end

  def eval_greeting(input) do
    case input do
      ":english" -> {0, "\"Hello!\""}
      ":spanish" -> {1, "\"Hola!\""}
      ":japanese" -> {2, "\"Konnichiwa!\""}
      ":french" -> {3, "\"Bonjour!\""}
      _ -> {4, "\"Hi! (unknown language)\""}
    end
  end

  def eval_shape_area(input) do
    case input do
      "{:circle, 5}" -> {0, "78.54"}
      "{:rectangle, 4, 6}" -> {1, "24"}
      "{:triangle, 3, 8}" -> {2, "12.0"}
      "{:square, 7}" -> {3, "49"}
      _ -> {4, "{:error, :unknown_shape}"}
    end
  end

  def eval_status(code) when is_integer(code) do
    case code do
      200 -> {0, "\"OK - Success\""}
      201 -> {1, "\"Created\""}
      301 -> {2, "\"Moved Permanently\""}
      404 -> {3, "\"Not Found\""}
      c when c >= 500 -> {4, "\"Server Error: #{c}\""}
      c when c >= 400 -> {5, "\"Client Error: #{c}\""}
      c -> {6, "\"Other: #{c}\""}
    end
  end

  # Helpers

  defp examples, do: @examples

  defp run_match(socket, input) do
    input = String.trim(input)
    example = socket.assigns.current_example
    order = socket.assigns.clause_order

    try do
      # Get the natural match result
      {natural_clause_id, value} =
        case example.input_type do
          "integer" ->
            case Integer.parse(input) do
              {n, _} -> example.evaluate.(n)
              :error -> raise "Invalid integer"
            end

          _ ->
            example.evaluate.(input)
        end

      # Now check: in the current order, which clause would actually match?
      # For simplicity, we use the natural clause id but show its position in current order
      matched_id = find_first_match_in_order(natural_clause_id, order, example)
      clause_index = Enum.find_index(order, &(&1 == matched_id))

      # Re-evaluate with the actual matched clause's result
      actual_value =
        if matched_id == natural_clause_id do
          value
        else
          # A broader clause matched first in reordered list
          matched_clause = Enum.find(example.clauses, &(&1.id == matched_id))
          matched_clause.body
        end

      {:noreply,
       socket
       |> assign(user_input: input)
       |> assign(matched_clause_id: matched_id)
       |> assign(match_result: %{ok: true, value: actual_value, clause_index: clause_index})}
    rescue
      _ ->
        {:noreply,
         socket
         |> assign(user_input: input)
         |> assign(matched_clause_id: nil)
         |> assign(match_result: %{ok: false, value: "Could not parse input. Check the format."})}
    end
  end

  defp find_first_match_in_order(natural_clause_id, order, example) do
    # Find if any catch-all or broader clause appears before the natural match
    natural_idx_in_order = Enum.find_index(order, &(&1 == natural_clause_id))

    # Check clauses before the natural match in current order
    clauses_before =
      order
      |> Enum.take(natural_idx_in_order)

    # A catch-all clause (one with no guard and underscore/variable in pattern) would match first
    catch_all =
      Enum.find(clauses_before, fn clause_id ->
        clause = Enum.find(example.clauses, &(&1.id == clause_id))
        is_catch_all?(clause)
      end)

    catch_all || natural_clause_id
  end

  defp is_catch_all?(clause) do
    clause.guard == nil and
      (String.contains?(clause.head, "(_") or
         Regex.match?(~r/\(\w+\)$/, clause.head))
  end

  defp get_ordered_clauses(clauses, order) do
    Enum.map(order, fn id ->
      Enum.find(clauses, &(&1.id == id))
    end)
  end

  defp clause_style(clause_id, matched_id, _idx, _result) when clause_id == matched_id do
    "border-success bg-success/15 shadow-lg"
  end

  defp clause_style(_clause_id, nil, _idx, _result) do
    "border-base-300 bg-base-100"
  end

  defp clause_style(_clause_id, _matched_id, _idx, _result) do
    "border-base-300 bg-base-100 opacity-40"
  end

  defp is_before_match?(clause_id, matched_id, order) do
    clause_idx = Enum.find_index(order, &(&1 == clause_id))
    matched_idx = Enum.find_index(order, &(&1 == matched_id))
    clause_idx != nil and matched_idx != nil and clause_idx < matched_idx
  end

  defp quick_test_values("fizzbuzz"), do: ["1", "3", "5", "7", "9", "10", "15", "30", "45"]
  defp quick_test_values("status"), do: ["200", "201", "301", "404", "403", "418", "500", "503"]
  defp quick_test_values(_), do: []
end
