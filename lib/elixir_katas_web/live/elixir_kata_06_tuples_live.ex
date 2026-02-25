defmodule ElixirKatasWeb.ElixirKata06TuplesLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:elements, fn -> ["hello", "42", "true"] end)
     |> assign_new(:new_element, fn -> "" end)
     |> assign_new(:selected_index, fn -> nil end)
     |> assign_new(:extracted_value, fn -> nil end)
     |> assign_new(:replace_index, fn -> "0" end)
     |> assign_new(:replace_value, fn -> "" end)
     |> assign_new(:old_tuple_display, fn -> nil end)
     |> assign_new(:result_examples, fn -> compute_result_examples() end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Tuple Explorer</h2>
      <p class="text-sm opacity-70 mb-6">
        Tuples store a fixed number of elements contiguously in memory. They are great for returning multiple values and pattern matching.
      </p>

      <!-- Current Tuple Display -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Current Tuple</h3>
            <span class="badge badge-primary">tuple_size: <%= length(@elements) %></span>
          </div>

          <!-- Visual Tuple Boxes -->
          <div class="flex flex-wrap items-center gap-1 mb-3">
            <span class="text-xl font-mono font-bold text-warning">&lbrace;</span>
            <%= for {elem, idx} <- Enum.with_index(@elements) do %>
              <button
                phx-click="select_elem"
                phx-target={@myself}
                phx-value-index={idx}
                class={"flex flex-col items-center px-3 py-2 rounded-lg border-2 cursor-pointer transition-all hover:scale-105 " <>
                  if(@selected_index == idx, do: "border-primary bg-primary/20 shadow-lg", else: "border-base-300 bg-base-100 hover:border-primary/50")}
              >
                <span class="text-xs opacity-50 mb-1">idx <%= idx %></span>
                <span class="font-mono font-bold"><%= elem %></span>
              </button>
              <%= if idx < length(@elements) - 1 do %>
                <span class="text-lg opacity-30">,</span>
              <% end %>
            <% end %>
            <span class="text-xl font-mono font-bold text-warning">&rbrace;</span>
          </div>

          <!-- Code Representation -->
          <div class="bg-base-300 rounded-lg p-2 font-mono text-sm">
            <span class="opacity-50">iex&gt;</span> my_tuple = &lbrace;<%= Enum.join(@elements, ", ") %>&rbrace;
          </div>

          <!-- Extracted Value -->
          <%= if @extracted_value do %>
            <div class="mt-3 alert alert-info text-sm">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" class="stroke-current shrink-0 w-5 h-5"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
              <span><code class="font-mono">elem(tuple, <%= @selected_index %>)</code> = <strong><%= @extracted_value %></strong></span>
            </div>
          <% end %>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
        <!-- Add Element -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <h3 class="card-title text-sm">Add Element</h3>
            <form phx-submit="add_element" phx-target={@myself} class="flex gap-2">
              <input
                type="text"
                name="value"
                value={@new_element}
                placeholder="Enter a value..."
                class="input input-bordered input-sm flex-1 font-mono"
                autocomplete="off"
              />
              <button type="submit" class="btn btn-primary btn-sm">Add</button>
            </form>
            <p class="text-xs opacity-50 mt-1">
              Adds to the end. In reality, Tuple.append/2 creates a new tuple (O(n)).
            </p>
          </div>
        </div>

        <!-- Replace Element (put_elem) -->
        <div class="card bg-base-200 shadow-md">
          <div class="card-body p-4">
            <h3 class="card-title text-sm">put_elem (Immutability Demo)</h3>
            <form phx-submit="replace_element" phx-target={@myself} class="space-y-2">
              <div class="flex gap-2">
                <div class="form-control flex-1">
                  <label class="label py-0">
                    <span class="label-text text-xs">Index</span>
                  </label>
                  <input
                    type="number"
                    name="index"
                    value={@replace_index}
                    min="0"
                    max={max(length(@elements) - 1, 0)}
                    class="input input-bordered input-sm font-mono"
                  />
                </div>
                <div class="form-control flex-1">
                  <label class="label py-0">
                    <span class="label-text text-xs">New Value</span>
                  </label>
                  <input
                    type="text"
                    name="value"
                    value={@replace_value}
                    placeholder="new value"
                    class="input input-bordered input-sm font-mono"
                    autocomplete="off"
                  />
                </div>
              </div>
              <button type="submit" class="btn btn-secondary btn-sm w-full">put_elem</button>
            </form>

            <!-- Immutability Visualization -->
            <%= if @old_tuple_display do %>
              <div class="mt-3 space-y-1 text-sm">
                <div class="flex items-center gap-2">
                  <span class="badge badge-ghost badge-sm">old</span>
                  <code class="font-mono opacity-50 line-through"><%= @old_tuple_display %></code>
                </div>
                <div class="flex items-center gap-2">
                  <span class="badge badge-success badge-sm">new</span>
                  <code class="font-mono font-bold">&lbrace;<%= Enum.join(@elements, ", ") %>&rbrace;</code>
                </div>
                <p class="text-xs text-warning mt-1">
                  The original tuple is unchanged! put_elem returns a new tuple.
                </p>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- elem() Buttons -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Extract with elem/2</h3>
          <p class="text-xs opacity-60 mb-3">Click a button to extract the element at that index. Access is O(1).</p>
          <div class="flex flex-wrap gap-2">
            <%= for idx <- 0..(max(length(@elements) - 1, 0)) do %>
              <button
                phx-click="extract_elem"
                phx-target={@myself}
                phx-value-index={idx}
                class={"btn btn-sm " <> if(@selected_index == idx, do: "btn-primary", else: "btn-outline")}
              >
                elem(tuple, <%= idx %>)
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Clear / Reset -->
      <div class="flex gap-2 mb-6">
        <button phx-click="clear_tuple" phx-target={@myself} class="btn btn-error btn-sm btn-outline">
          Clear Tuple
        </button>
        <button phx-click="reset_tuple" phx-target={@myself} class="btn btn-ghost btn-sm">
          Reset to Default
        </button>
      </div>

      <!-- ok/error Convention -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">The &lbrace;:ok, val&rbrace; / &lbrace;:error, reason&rbrace; Convention</h3>
          <p class="text-sm opacity-70 mb-4">
            Elixir uses two-element tuples as a universal convention for success/failure results.
            This pattern is used everywhere in the standard library.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Success Examples -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <h4 class="font-bold text-success text-sm mb-2">Success Pattern</h4>
              <div class="space-y-2 font-mono text-sm">
                <%= for {expr, result} <- @result_examples.ok do %>
                  <div class="bg-base-100 rounded p-2">
                    <div class="opacity-60 text-xs"><%= expr %></div>
                    <div class="text-success font-bold"><%= result %></div>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Error Examples -->
            <div class="bg-error/10 border border-error/30 rounded-lg p-3">
              <h4 class="font-bold text-error text-sm mb-2">Error Pattern</h4>
              <div class="space-y-2 font-mono text-sm">
                <%= for {expr, result} <- @result_examples.error do %>
                  <div class="bg-base-100 rounded p-2">
                    <div class="opacity-60 text-xs"><%= expr %></div>
                    <div class="text-error font-bold"><%= result %></div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <div class="mt-4 p-3 bg-base-300 rounded-lg text-sm">
            <span class="font-bold text-info">Pattern Matching with Tuples</span>
            <pre class="mt-2 font-mono text-xs opacity-80"><%= "case File.read(\"config.txt\") do\n  {:ok, contents} -> \"Got: \" <> contents\n  {:error, reason} -> \"Failed: \" <> to_string(reason)\nend" %></pre>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("add_element", %{"value" => value}, socket) do
    value = String.trim(value)

    if value != "" do
      {:noreply,
       socket
       |> assign(elements: socket.assigns.elements ++ [value])
       |> assign(new_element: "")
       |> assign(old_tuple_display: nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("select_elem", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    value = Enum.at(socket.assigns.elements, idx)

    {:noreply,
     socket
     |> assign(selected_index: idx)
     |> assign(extracted_value: value)}
  end

  def handle_event("extract_elem", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    value = Enum.at(socket.assigns.elements, idx)

    {:noreply,
     socket
     |> assign(selected_index: idx)
     |> assign(extracted_value: value)}
  end

  def handle_event("replace_element", %{"index" => idx_str, "value" => value}, socket) do
    idx = String.to_integer(idx_str)
    elements = socket.assigns.elements

    if idx >= 0 and idx < length(elements) and String.trim(value) != "" do
      old_display = "{#{Enum.join(elements, ", ")}}"
      new_elements = List.replace_at(elements, idx, String.trim(value))

      {:noreply,
       socket
       |> assign(elements: new_elements)
       |> assign(old_tuple_display: old_display)
       |> assign(replace_value: "")
       |> assign(selected_index: nil)
       |> assign(extracted_value: nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("clear_tuple", _params, socket) do
    {:noreply,
     socket
     |> assign(elements: [])
     |> assign(selected_index: nil)
     |> assign(extracted_value: nil)
     |> assign(old_tuple_display: nil)}
  end

  def handle_event("reset_tuple", _params, socket) do
    {:noreply,
     socket
     |> assign(elements: ["hello", "42", "true"])
     |> assign(selected_index: nil)
     |> assign(extracted_value: nil)
     |> assign(old_tuple_display: nil)
     |> assign(replace_index: "0")
     |> assign(replace_value: "")}
  end

  # Helpers

  defp compute_result_examples do
    %{
      ok: [
        {"Integer.parse(\"42\")", "{42, \"\"}"},
        {"Map.fetch(%{a: 1}, :a)", "{:ok, 1}"},
        {"File.read(\"existing.txt\")", "{:ok, \"contents...\"}"},
        {"Keyword.fetch([a: 1], :a)", "{:ok, 1}"}
      ],
      error: [
        {"Integer.parse(\"nope\")", ":error"},
        {"Map.fetch(%{a: 1}, :b)", ":error"},
        {"File.read(\"missing.txt\")", "{:error, :enoent}"},
        {"GenServer.call(pid, :x, 0)", "{:error, :timeout}"}
      ]
    }
  end
end
