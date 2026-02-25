defmodule ElixirKatasWeb.ElixirKata11ListMatchingLive do
  use ElixirKatasWeb, :live_component

  @preset_patterns [
    %{pattern: "[h | t]", description: "Head and tail"},
    %{pattern: "[a, b, c]", description: "Exact 3 elements"},
    %{pattern: "[h | _]", description: "Head only, discard tail"},
    %{pattern: "[_, second | _]", description: "Second element only"},
    %{pattern: "[_, _, third | _]", description: "Third element only"},
    %{pattern: "[a, b]", description: "Exact 2 elements"},
    %{pattern: "[a]", description: "Exact 1 element"},
    %{pattern: "[]", description: "Empty list"},
    %{pattern: "[1 | t]", description: "Head must be 1"},
    %{pattern: "[h, h]", description: "Two equal elements"},
    %{pattern: "[a, b, c, d, e]", description: "Exact 5 elements"}
  ]

  @preset_lists [
    %{label: "[1, 2, 3]", value: [1, 2, 3]},
    %{label: "[10, 20, 30, 40, 50]", value: [10, 20, 30, 40, 50]},
    %{label: "[42]", value: [42]},
    %{label: "[]", value: []},
    %{label: "[1, 1]", value: [1, 1]},
    %{label: "[\"a\", \"b\", \"c\"]", value: ["a", "b", "c"]},
    %{label: "[1, 2]", value: [1, 2]},
    %{label: "[[1, 2], [3, 4], [5, 6]]", value: [[1, 2], [3, 4], [5, 6]]}
  ]

  @nested_examples [
    %{pattern: "[[a | _] | _]", list: [[1, 2], [3, 4], [5, 6]],
      description: "First element of first sub-list",
      explanation: "Matches outer head [1, 2], then matches [a | _] to get a = 1"},
    %{pattern: "[_ , [_, b] | _]", list: [[1, 2], [3, 4], [5, 6]],
      description: "Second element of second sub-list",
      explanation: "Skips first sub-list, matches [_, b] on [3, 4] to get b = 4"},
    %{pattern: "[[_ | inner_tail] | outer_tail]", list: [[1, 2, 3], [4, 5]],
      description: "Inner tail and outer tail",
      explanation: "inner_tail = [2, 3], outer_tail = [[4, 5]]"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_tab, fn -> "matcher" end)
     |> assign_new(:selected_list, fn -> [1, 2, 3] end)
     |> assign_new(:selected_list_label, fn -> "[1, 2, 3]" end)
     |> assign_new(:pattern_input, fn -> "" end)
     |> assign_new(:match_result, fn -> nil end)
     |> assign_new(:custom_list_input, fn -> "" end)
     |> assign_new(:decomposition, fn -> nil end)
     |> assign_new(:recursion_steps, fn -> [] end)
     |> assign_new(:show_recursion, fn -> false end)
     |> assign_new(:nested_result, fn -> nil end)
     |> assign_new(:preset_patterns, fn -> @preset_patterns end)
     |> assign_new(:preset_lists, fn -> @preset_lists end)
     |> assign_new(:nested_examples, fn -> @nested_examples end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">List Matching</h2>
      <p class="text-sm opacity-70 mb-6">
        Lists in Elixir are linked lists. Pattern matching with <code class="font-mono">[head | tail]</code> is the
        fundamental tool for processing lists. Combined with recursion, it powers most list operations.
      </p>

      <!-- Tab Switcher -->
      <div class="tabs tabs-boxed mb-6 bg-base-200">
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="matcher"
          class={"tab " <> if(@active_tab == "matcher", do: "tab-active", else: "")}
        >
          Pattern Matcher
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="decomposition"
          class={"tab " <> if(@active_tab == "decomposition", do: "tab-active", else: "")}
        >
          Head/Tail Visual
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="nested"
          class={"tab " <> if(@active_tab == "nested", do: "tab-active", else: "")}
        >
          Nested Matching
        </button>
        <button
          phx-click="switch_tab"
          phx-target={@myself}
          phx-value-tab="recursion"
          class={"tab " <> if(@active_tab == "recursion", do: "tab-active", else: "")}
        >
          Recursion Visual
        </button>
      </div>

      <!-- Pattern Matcher Tab -->
      <%= if @active_tab == "matcher" do %>
        <div class="space-y-6">
          <!-- List Selection -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Choose a List</h3>
              <div class="flex flex-wrap gap-2 mb-3">
                <%= for preset <- @preset_lists do %>
                  <button
                    phx-click="select_list"
                    phx-target={@myself}
                    phx-value-label={preset.label}
                    class={"btn btn-sm " <> if(@selected_list_label == preset.label, do: "btn-primary", else: "btn-outline")}
                  >
                    <%= preset.label %>
                  </button>
                <% end %>
              </div>

              <form phx-submit="set_custom_list" phx-target={@myself} class="flex gap-2">
                <input
                  type="text"
                  name="list"
                  value={@custom_list_input}
                  placeholder="Custom list: e.g. 1, 2, 3"
                  class="input input-bordered input-sm flex-1 font-mono"
                  autocomplete="off"
                />
                <button type="submit" class="btn btn-accent btn-sm">Set Custom List</button>
              </form>

              <!-- Current List Display -->
              <div class="mt-3 bg-base-300 rounded-lg p-3">
                <div class="text-xs opacity-50 mb-1">Current list:</div>
                <div class="font-mono text-lg font-bold"><%= format_list(@selected_list) %></div>
                <div class="text-xs opacity-50 mt-1">length: <%= length(@selected_list) %></div>
              </div>
            </div>
          </div>

          <!-- Pattern Input -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Match a Pattern</h3>
              <form phx-submit="try_list_match" phx-target={@myself} class="flex gap-2 mb-3">
                <input
                  type="text"
                  name="pattern"
                  value={@pattern_input}
                  placeholder="e.g. [h | t]"
                  class="input input-bordered input-sm flex-1 font-mono"
                  autocomplete="off"
                />
                <button type="submit" class="btn btn-primary btn-sm">Match!</button>
              </form>

              <!-- Preset Patterns -->
              <div class="flex flex-wrap gap-2">
                <%= for preset <- @preset_patterns do %>
                  <button
                    phx-click="try_preset_pattern"
                    phx-target={@myself}
                    phx-value-pattern={preset.pattern}
                    class="btn btn-xs btn-ghost font-mono"
                    title={preset.description}
                  >
                    <%= preset.pattern %>
                  </button>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Match Result -->
          <%= if @match_result do %>
            <div class={"card shadow-md " <> if(@match_result.success, do: "bg-success/10 border border-success/30", else: "bg-error/10 border border-error/30")}>
              <div class="card-body p-4">
                <div class="flex items-center gap-2 mb-3">
                  <%= if @match_result.success do %>
                    <span class="badge badge-success">Match Succeeded</span>
                  <% else %>
                    <span class="badge badge-error">MatchError</span>
                  <% end %>
                  <span class="font-mono text-sm">
                    <%= @match_result.pattern %> = <%= format_list(@selected_list) %>
                  </span>
                </div>

                <%= if @match_result.success do %>
                  <!-- Visual Match -->
                  <div class="flex flex-wrap items-center gap-1 justify-center mb-4">
                    <span class="text-xl font-mono text-warning">[</span>
                    <%= for {seg, idx} <- Enum.with_index(@match_result.segments) do %>
                      <div class={"flex flex-col items-center px-3 py-2 rounded-lg border-2 " <>
                        cond do
                          seg.is_head -> "border-success bg-success/10 shadow-md"
                          seg.is_tail -> "border-info bg-info/10"
                          seg.bound -> "border-accent bg-accent/10"
                          true -> "border-base-300 bg-base-100"
                        end}>
                        <span class="text-xs opacity-50"><%= seg.label %></span>
                        <span class="font-mono font-bold text-sm"><%= seg.value %></span>
                        <%= if seg.bound do %>
                          <span class={"text-xs font-bold mt-1 " <>
                            cond do
                              seg.is_head -> "text-success"
                              seg.is_tail -> "text-info"
                              true -> "text-accent"
                            end}>
                            <%= seg.var %> = <%= seg.value %>
                          </span>
                        <% end %>
                      </div>
                      <%= if idx < length(@match_result.segments) - 1 and not seg.is_tail do %>
                        <%= if seg.has_pipe do %>
                          <span class="text-lg text-warning font-bold">|</span>
                        <% else %>
                          <span class="text-lg opacity-30">,</span>
                        <% end %>
                      <% end %>
                    <% end %>
                    <span class="text-xl font-mono text-warning">]</span>
                  </div>

                  <!-- Bindings Table -->
                  <%= if length(@match_result.bindings) > 0 do %>
                    <div class="overflow-x-auto">
                      <table class="table table-sm table-zebra">
                        <thead>
                          <tr>
                            <th>Variable</th>
                            <th>Bound Value</th>
                          </tr>
                        </thead>
                        <tbody>
                          <%= for {var, val} <- @match_result.bindings do %>
                            <tr>
                              <td class="font-mono text-info font-bold"><%= var %></td>
                              <td class="font-mono text-success"><%= val %></td>
                            </tr>
                          <% end %>
                        </tbody>
                      </table>
                    </div>
                  <% end %>
                <% else %>
                  <div class="font-mono text-sm bg-error/10 p-3 rounded">
                    ** (MatchError) no match of right hand side value: <%= format_list(@selected_list) %>
                    <div class="text-xs mt-2 opacity-70"><%= @match_result.explanation %></div>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>

      <!-- Head/Tail Decomposition Tab -->
      <%= if @active_tab == "decomposition" do %>
        <div class="space-y-6">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Head/Tail Decomposition</h3>
              <p class="text-xs opacity-60 mb-4">
                Every non-empty list can be decomposed into a head (first element) and a tail (the rest).
                Click a list to see its decomposition step by step.
              </p>

              <div class="flex flex-wrap gap-2 mb-4">
                <%= for preset <- @preset_lists do %>
                  <button
                    phx-click="decompose"
                    phx-target={@myself}
                    phx-value-label={preset.label}
                    class="btn btn-sm btn-outline font-mono"
                  >
                    <%= preset.label %>
                  </button>
                <% end %>
              </div>

              <%= if @decomposition do %>
                <div class="space-y-3">
                  <%= for {step, idx} <- Enum.with_index(@decomposition) do %>
                    <div class={"p-3 rounded-lg border-2 transition-all " <>
                      if(step.is_empty, do: "border-warning bg-warning/10", else: "border-base-300 bg-base-300")}>
                      <div class="flex items-center gap-2 mb-1">
                        <span class="badge badge-sm badge-primary">Step <%= idx + 1 %></span>
                      </div>
                      <%= if step.is_empty do %>
                        <div class="font-mono text-sm">
                          <span class="text-warning font-bold">[]</span>
                          <span class="opacity-50 ml-2">= empty list (base case)</span>
                        </div>
                      <% else %>
                        <div class="flex items-center gap-2 flex-wrap">
                          <span class="font-mono text-sm opacity-50">[</span>
                          <div class="px-3 py-1 rounded border-2 border-success bg-success/10">
                            <span class="text-xs opacity-50 block">head</span>
                            <span class="font-mono font-bold text-success"><%= step.head %></span>
                          </div>
                          <span class="font-mono font-bold text-warning">|</span>
                          <div class="px-3 py-1 rounded border-2 border-info bg-info/10">
                            <span class="text-xs opacity-50 block">tail</span>
                            <span class="font-mono font-bold text-info"><%= step.tail %></span>
                          </div>
                          <span class="font-mono text-sm opacity-50">]</span>
                          <span class="font-mono text-sm opacity-30 ml-2">= <%= step.full %></span>
                        </div>
                      <% end %>
                    </div>
                  <% end %>
                </div>
              <% end %>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Nested Matching Tab -->
      <%= if @active_tab == "nested" do %>
        <div class="space-y-6">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Nested List Matching</h3>
              <p class="text-xs opacity-60 mb-4">
                Pattern matching works on nested lists too. You can reach into sub-lists
                to extract exactly the data you need.
              </p>

              <div class="space-y-3">
                <%= for {example, idx} <- Enum.with_index(@nested_examples) do %>
                  <div class="bg-base-300 rounded-lg p-4">
                    <div class="flex items-center justify-between mb-2">
                      <span class="font-bold text-sm"><%= example.description %></span>
                      <button
                        phx-click="try_nested"
                        phx-target={@myself}
                        phx-value-index={idx}
                        class={"btn btn-xs " <> if(@nested_result && @nested_result.index == idx, do: "btn-primary", else: "btn-outline btn-primary")}
                      >
                        Try it
                      </button>
                    </div>

                    <div class="font-mono text-sm mb-2">
                      <span class="text-info"><%= example.pattern %></span>
                      <span class="text-warning"> = </span>
                      <span><%= inspect(example.list) %></span>
                    </div>

                    <%= if @nested_result && @nested_result.index == idx do %>
                      <div class="mt-3 p-3 bg-success/10 border border-success/30 rounded-lg">
                        <div class="text-sm text-success mb-2"><%= example.explanation %></div>
                        <div class="flex flex-wrap gap-2">
                          <%= for {var, val} <- @nested_result.bindings do %>
                            <div class="badge badge-lg badge-outline gap-1 font-mono">
                              <span class="text-info"><%= var %></span>
                              <span class="opacity-50">=</span>
                              <span class="text-success"><%= val %></span>
                            </div>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
            </div>
          </div>

          <!-- Nested Pattern Reference -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">Nested Pattern Reference</h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div class="bg-base-300 rounded-lg p-3">
                  <div class="font-mono text-xs space-y-2">
                    <div class="opacity-60"># Given: list = [[1, 2], [3, 4]]</div>
                    <div>[first | _] = list</div>
                    <div class="text-success">first = [1, 2]</div>
                  </div>
                </div>
                <div class="bg-base-300 rounded-lg p-3">
                  <div class="font-mono text-xs space-y-2">
                    <div class="opacity-60"># Reach into sub-list</div>
                    <div>[[a, b] | _] = list</div>
                    <div class="text-success">a = 1, b = 2</div>
                  </div>
                </div>
                <div class="bg-base-300 rounded-lg p-3">
                  <div class="font-mono text-xs space-y-2">
                    <div class="opacity-60"># Get head of first sub-list</div>
                    <div>[[h | _] | _] = list</div>
                    <div class="text-success">h = 1</div>
                  </div>
                </div>
                <div class="bg-base-300 rounded-lg p-3">
                  <div class="font-mono text-xs space-y-2">
                    <div class="opacity-60"># Both outer and inner</div>
                    <div>[[h | it] | ot] = list</div>
                    <div class="text-success">h = 1, it = [2], ot = [[3, 4]]</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      <% end %>

      <!-- Recursion Visual Tab -->
      <%= if @active_tab == "recursion" do %>
        <div class="space-y-6">
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-1">Pattern Matching Drives Recursion</h3>
              <p class="text-xs opacity-60 mb-4">
                List recursion works by matching [head | tail] and calling itself with the tail.
                Click a function to see how pattern matching guides each step.
              </p>

              <div class="flex flex-wrap gap-2 mb-4">
                <button
                  phx-click="show_recursion"
                  phx-target={@myself}
                  phx-value-func="sum"
                  class={"btn btn-sm " <> if(@show_recursion == "sum", do: "btn-primary", else: "btn-outline")}
                >
                  sum/1
                </button>
                <button
                  phx-click="show_recursion"
                  phx-target={@myself}
                  phx-value-func="length"
                  class={"btn btn-sm " <> if(@show_recursion == "length", do: "btn-primary", else: "btn-outline")}
                >
                  length/1
                </button>
                <button
                  phx-click="show_recursion"
                  phx-target={@myself}
                  phx-value-func="map"
                  class={"btn btn-sm " <> if(@show_recursion == "map", do: "btn-primary", else: "btn-outline")}
                >
                  map/2
                </button>
              </div>

              <!-- Function Definition -->
              <%= if @show_recursion do %>
                <div class="bg-base-300 rounded-lg p-4 font-mono text-xs mb-4">
                  <%= if @show_recursion == "sum" do %>
                    <div class="opacity-60 mb-1"># Sum all elements in a list</div>
                    <div>def sum([]), do: 0</div>
                    <div>def sum([<span class="text-success">h</span> | <span class="text-info">t</span>]), do: <span class="text-success">h</span> + sum(<span class="text-info">t</span>)</div>
                  <% end %>
                  <%= if @show_recursion == "length" do %>
                    <div class="opacity-60 mb-1"># Count elements in a list</div>
                    <div>def length([]), do: 0</div>
                    <div>def length([<span class="text-success">_</span> | <span class="text-info">t</span>]), do: 1 + length(<span class="text-info">t</span>)</div>
                  <% end %>
                  <%= if @show_recursion == "map" do %>
                    <div class="opacity-60 mb-1"># Apply function to each element</div>
                    <div>def map([], _func), do: []</div>
                    <div>def map([<span class="text-success">h</span> | <span class="text-info">t</span>], func), do: [func.(<span class="text-success">h</span>) | map(<span class="text-info">t</span>, func)]</div>
                  <% end %>
                </div>
              <% end %>

              <!-- Recursion Steps -->
              <%= if length(@recursion_steps) > 0 do %>
                <div class="space-y-2">
                  <%= for {step, idx} <- Enum.with_index(@recursion_steps) do %>
                    <div class={"p-3 rounded-lg border-l-4 " <>
                      if(step.is_base, do: "border-l-warning bg-warning/10", else: "border-l-primary bg-base-300")}
                      style={"margin-left: #{idx * 16}px"}>
                      <div class="flex items-center gap-2">
                        <span class="badge badge-xs badge-primary"><%= idx + 1 %></span>
                        <span class="font-mono text-xs">
                          <%= if step.is_base do %>
                            <span class="text-warning font-bold"><%= step.call %></span>
                            <span class="opacity-50"> matches </span>
                            <span class="text-warning">[]</span>
                            <span class="opacity-50"> =&gt; </span>
                            <span class="font-bold"><%= step.result %></span>
                          <% else %>
                            <span class="font-bold"><%= step.call %></span>
                            <span class="opacity-50"> matches [</span>
                            <span class="text-success font-bold"><%= step.head %></span>
                            <span class="text-warning"> | </span>
                            <span class="text-info"><%= step.tail %></span>
                            <span class="opacity-50">]</span>
                          <% end %>
                        </span>
                      </div>
                      <%= if not step.is_base do %>
                        <div class="font-mono text-xs mt-1 opacity-60 pl-6">
                          <%= step.computation %>
                        </div>
                      <% end %>
                    </div>
                  <% end %>

                  <!-- Final Result -->
                  <div class="mt-3 p-3 bg-primary/10 border border-primary/30 rounded-lg">
                    <div class="font-mono text-sm">
                      <span class="opacity-50">Result: </span>
                      <span class="font-bold text-primary"><%= List.last(@recursion_steps).final_result %></span>
                    </div>
                  </div>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Pattern Matching in Recursion Reference -->
          <div class="card bg-base-200 shadow-md">
            <div class="card-body p-4">
              <h3 class="card-title text-sm mb-3">How Pattern Matching Powers Recursion</h3>
              <div class="space-y-3 text-sm">
                <div class="flex items-start gap-3 p-3 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5">1</span>
                  <div>
                    <span class="font-bold">Base case</span>: Match the empty list <code class="font-mono">[]</code> to stop recursion.
                  </div>
                </div>
                <div class="flex items-start gap-3 p-3 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5">2</span>
                  <div>
                    <span class="font-bold">Recursive case</span>: Match <code class="font-mono">[head | tail]</code> to process one element.
                  </div>
                </div>
                <div class="flex items-start gap-3 p-3 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5">3</span>
                  <div>
                    <span class="font-bold">Recur</span>: Call the function again with <code class="font-mono">tail</code>,
                    which is one element shorter. Eventually reaches <code class="font-mono">[]</code>.
                  </div>
                </div>
              </div>

              <div class="mt-4 p-3 bg-base-300 rounded-lg">
                <span class="font-bold text-warning text-sm">Tip: Tail-call optimization</span>
                <div class="font-mono text-xs mt-2 space-y-1">
                  <div class="opacity-60"># Accumulator pattern (tail-recursive)</div>
                  <div>def sum(list), do: sum(list, 0)</div>
                  <div>def sum([], acc), do: acc</div>
                  <div>def sum([h | t], acc), do: sum(t, acc + h)</div>
                </div>
                <p class="text-xs opacity-70 mt-2">
                  Using an accumulator makes the recursive call the last operation,
                  allowing Elixir to optimize it into a loop (no stack growth).
                </p>
              </div>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  # Helpers used by template
  defp format_list(list), do: inspect(list)

  @nested_examples_attr @nested_examples
  defp nested_examples, do: @nested_examples_attr

  # Event Handlers

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_event("select_list", %{"label" => label}, socket) do
    preset = Enum.find(@preset_lists, fn p -> p.label == label end)

    if preset do
      {:noreply,
       socket
       |> assign(selected_list: preset.value)
       |> assign(selected_list_label: label)
       |> assign(match_result: nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("set_custom_list", %{"list" => input}, socket) do
    input = String.trim(input)

    if input != "" do
      elements =
        input
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))
        |> Enum.map(&parse_element/1)

      label = inspect(elements)

      {:noreply,
       socket
       |> assign(selected_list: elements)
       |> assign(selected_list_label: label)
       |> assign(custom_list_input: "")
       |> assign(match_result: nil)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("try_list_match", %{"pattern" => pattern}, socket) do
    pattern = String.trim(pattern)

    if pattern != "" do
      result = do_list_match(pattern, socket.assigns.selected_list)

      {:noreply,
       socket
       |> assign(match_result: result)
       |> assign(pattern_input: pattern)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("try_preset_pattern", %{"pattern" => pattern}, socket) do
    result = do_list_match(pattern, socket.assigns.selected_list)

    {:noreply,
     socket
     |> assign(match_result: result)
     |> assign(pattern_input: pattern)}
  end

  def handle_event("decompose", %{"label" => label}, socket) do
    preset = Enum.find(@preset_lists, fn p -> p.label == label end)

    if preset do
      steps = build_decomposition(preset.value)
      {:noreply, assign(socket, decomposition: steps)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("try_nested", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    example = Enum.at(nested_examples(), idx)

    if example do
      bindings = evaluate_nested(example.pattern, example.list)
      {:noreply, assign(socket, nested_result: %{index: idx, bindings: bindings})}
    else
      {:noreply, socket}
    end
  end

  def handle_event("show_recursion", %{"func" => func}, socket) do
    list = [1, 2, 3, 4, 5]
    steps = build_recursion_steps(func, list)

    {:noreply,
     socket
     |> assign(show_recursion: func)
     |> assign(recursion_steps: steps)}
  end

  # List match engine

  defp do_list_match(pattern, list) do
    pattern = String.trim(pattern)

    cond do
      # Empty list pattern
      pattern == "[]" ->
        if list == [] do
          %{success: true, pattern: pattern, segments: [], bindings: [],
            explanation: "Empty list matches empty list."}
        else
          %{success: false, pattern: pattern, segments: [], bindings: [],
            explanation: "Empty pattern [] does not match a list with #{length(list)} elements."}
        end

      # Head | Tail pattern
      String.starts_with?(pattern, "[") and String.ends_with?(pattern, "]") and
        String.contains?(pattern, "|") ->
        match_head_tail(pattern, list)

      # Fixed-length pattern
      String.starts_with?(pattern, "[") and String.ends_with?(pattern, "]") ->
        match_fixed_length(pattern, list)

      true ->
        %{success: false, pattern: pattern, segments: [], bindings: [],
          explanation: "Invalid list pattern."}
    end
  end

  defp match_head_tail(pattern, list) do
    inner = pattern |> String.trim_leading("[") |> String.trim_trailing("]") |> String.trim()
    [head_part, tail_part] = String.split(inner, "|", parts: 2)
    head_pats = head_part |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))
    tail_var = String.trim(tail_part)

    if list == [] do
      %{success: false, pattern: pattern, segments: [], bindings: [],
        explanation: "Cannot match [head | tail] against an empty list."}
    else
      needed = length(head_pats)

      if length(list) < needed do
        %{success: false, pattern: pattern, segments: [], bindings: [],
          explanation: "Need at least #{needed} elements, but list has #{length(list)}."}
      else
        head_vals = Enum.take(list, needed)
        tail_vals = Enum.drop(list, needed)

        # Check for literal matches
        {all_match, head_bindings, head_segments} =
          Enum.zip(head_pats, head_vals)
          |> Enum.reduce({true, [], []}, fn {pat, val}, {match_acc, bind_acc, seg_acc} ->
            val_str = inspect(val)

            cond do
              pat == "_" ->
                seg = %{label: "_", value: val_str, var: "_", bound: false, is_head: true, is_tail: false, has_pipe: false}
                {match_acc, bind_acc, seg_acc ++ [seg]}

              Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pat) ->
                # Check for duplicate variable (same var in pattern)
                existing = Enum.find(bind_acc, fn {v, _} -> v == pat end)
                if existing do
                  {_v, existing_val} = existing
                  if existing_val == val_str do
                    seg = %{label: pat, value: val_str, var: pat, bound: true, is_head: true, is_tail: false, has_pipe: false}
                    {match_acc, bind_acc, seg_acc ++ [seg]}
                  else
                    seg = %{label: pat, value: val_str, var: pat, bound: false, is_head: true, is_tail: false, has_pipe: false}
                    {false, bind_acc, seg_acc ++ [seg]}
                  end
                else
                  seg = %{label: pat, value: val_str, var: pat, bound: true, is_head: true, is_tail: false, has_pipe: false}
                  {match_acc, bind_acc ++ [{pat, val_str}], seg_acc ++ [seg]}
                end

              true ->
                # Literal match
                matches = pat == val_str
                seg = %{label: pat, value: val_str, var: nil, bound: false, is_head: true, is_tail: false, has_pipe: false}
                {match_acc and matches, bind_acc, seg_acc ++ [seg]}
            end
          end)

        if not all_match do
          %{success: false, pattern: pattern, segments: [], bindings: [],
            explanation: "Literal value in pattern does not match corresponding list element."}
        else
          # Add pipe indicator to last head segment
          head_segments =
            if length(head_segments) > 0 do
              List.update_at(head_segments, -1, fn seg -> %{seg | has_pipe: true} end)
            else
              head_segments
            end

          tail_str = inspect(tail_vals)
          tail_bindings =
            cond do
              tail_var == "_" -> []
              Regex.match?(~r/^[a-z_][a-z0-9_]*$/, tail_var) -> [{tail_var, tail_str}]
              true -> []
            end

          tail_seg = %{
            label: tail_var,
            value: tail_str,
            var: tail_var,
            bound: tail_var != "_" and Regex.match?(~r/^[a-z_][a-z0-9_]*$/, tail_var),
            is_head: false,
            is_tail: true,
            has_pipe: false
          }

          %{
            success: true,
            pattern: pattern,
            segments: head_segments ++ [tail_seg],
            bindings: head_bindings ++ tail_bindings,
            explanation: ""
          }
        end
      end
    end
  end

  defp match_fixed_length(pattern, list) do
    inner = pattern |> String.trim_leading("[") |> String.trim_trailing("]") |> String.trim()
    pats = inner |> String.split(",") |> Enum.map(&String.trim/1) |> Enum.reject(&(&1 == ""))

    if length(pats) != length(list) do
      %{success: false, pattern: pattern, segments: [], bindings: [],
        explanation: "Pattern has #{length(pats)} elements but list has #{length(list)} elements."}
    else
      {all_match, bindings, segments} =
        Enum.zip(pats, list)
        |> Enum.reduce({true, [], []}, fn {pat, val}, {match_acc, bind_acc, seg_acc} ->
          val_str = inspect(val)

          cond do
            pat == "_" ->
              seg = %{label: "_", value: val_str, var: "_", bound: false, is_head: false, is_tail: false, has_pipe: false}
              {match_acc, bind_acc, seg_acc ++ [seg]}

            Regex.match?(~r/^[a-z_][a-z0-9_]*$/, pat) ->
              existing = Enum.find(bind_acc, fn {v, _} -> v == pat end)
              if existing do
                {_v, existing_val} = existing
                if existing_val == val_str do
                  seg = %{label: pat, value: val_str, var: pat, bound: true, is_head: false, is_tail: false, has_pipe: false}
                  {match_acc, bind_acc, seg_acc ++ [seg]}
                else
                  seg = %{label: pat, value: val_str, var: pat, bound: false, is_head: false, is_tail: false, has_pipe: false}
                  {false, bind_acc, seg_acc ++ [seg]}
                end
              else
                seg = %{label: pat, value: val_str, var: pat, bound: true, is_head: false, is_tail: false, has_pipe: false}
                {match_acc, bind_acc ++ [{pat, val_str}], seg_acc ++ [seg]}
              end

            true ->
              matches = pat == val_str
              seg = %{label: pat, value: val_str, var: nil, bound: false, is_head: false, is_tail: false, has_pipe: false}
              {match_acc and matches, bind_acc, seg_acc ++ [seg]}
          end
        end)

      if all_match do
        %{success: true, pattern: pattern, segments: segments, bindings: bindings, explanation: ""}
      else
        %{success: false, pattern: pattern, segments: [], bindings: [],
          explanation: "One or more literal values in the pattern do not match."}
      end
    end
  end

  defp build_decomposition(list) do
    build_decomposition(list, [])
  end

  defp build_decomposition([], acc) do
    acc ++ [%{is_empty: true, head: nil, tail: nil, full: "[]"}]
  end

  defp build_decomposition([h | t], acc) do
    step = %{
      is_empty: false,
      head: inspect(h),
      tail: inspect(t),
      full: inspect([h | t])
    }

    build_decomposition(t, acc ++ [step])
  end

  defp evaluate_nested(pattern, list) do
    # Simplified nested pattern evaluation for the preset examples
    cond do
      pattern == "[[a | _] | _]" ->
        case list do
          [[a | _] | _] -> [{"a", inspect(a)}]
          _ -> []
        end

      pattern == "[_ , [_, b] | _]" ->
        case list do
          [_, [_, b] | _] -> [{"b", inspect(b)}]
          _ -> []
        end

      pattern == "[[_ | inner_tail] | outer_tail]" ->
        case list do
          [[_ | inner_tail] | outer_tail] ->
            [{"inner_tail", inspect(inner_tail)}, {"outer_tail", inspect(outer_tail)}]
          _ -> []
        end

      true ->
        []
    end
  end

  defp build_recursion_steps("sum", list) do
    build_sum_steps(list, [])
  end

  defp build_recursion_steps("length", list) do
    build_length_steps(list, [])
  end

  defp build_recursion_steps("map", list) do
    build_map_steps(list, [])
  end

  defp build_recursion_steps(_, _list), do: []

  defp build_sum_steps([], acc) do
    acc ++ [%{
      call: "sum([])",
      is_base: true,
      head: nil,
      tail: nil,
      computation: nil,
      result: "0",
      final_result: compute_final_sum(acc, 0)
    }]
  end

  defp build_sum_steps([h | t], acc) do
    step = %{
      call: "sum(#{inspect([h | t])})",
      is_base: false,
      head: inspect(h),
      tail: inspect(t),
      computation: "#{h} + sum(#{inspect(t)})",
      result: nil,
      final_result: nil
    }

    build_sum_steps(t, acc ++ [step])
  end

  defp compute_final_sum(steps, base) do
    heads = steps |> Enum.map(fn s -> s.head end) |> Enum.reject(&is_nil/1)
    total = heads |> Enum.map(&String.to_integer/1) |> Enum.sum()
    to_string(total + base)
  end

  defp build_length_steps([], acc) do
    acc ++ [%{
      call: "length([])",
      is_base: true,
      head: nil,
      tail: nil,
      computation: nil,
      result: "0",
      final_result: to_string(length(acc))
    }]
  end

  defp build_length_steps([h | t], acc) do
    step = %{
      call: "length(#{inspect([h | t])})",
      is_base: false,
      head: inspect(h),
      tail: inspect(t),
      computation: "1 + length(#{inspect(t)})",
      result: nil,
      final_result: nil
    }

    build_length_steps(t, acc ++ [step])
  end

  defp build_map_steps([], acc) do
    mapped = acc |> Enum.map(fn s -> s.head end) |> Enum.reject(&is_nil/1) |> Enum.map(fn h ->
      case Integer.parse(h) do
        {n, ""} -> n * 2
        _ -> h
      end
    end)

    acc ++ [%{
      call: "map([], &(&1 * 2))",
      is_base: true,
      head: nil,
      tail: nil,
      computation: nil,
      result: "[]",
      final_result: inspect(mapped)
    }]
  end

  defp build_map_steps([h | t], acc) do
    doubled = case h do
      n when is_integer(n) -> n * 2
      other -> other
    end

    step = %{
      call: "map(#{inspect([h | t])}, &(&1 * 2))",
      is_base: false,
      head: inspect(h),
      tail: inspect(t),
      computation: "[#{inspect(doubled)} | map(#{inspect(t)}, &(&1 * 2))]",
      result: nil,
      final_result: nil
    }

    build_map_steps(t, acc ++ [step])
  end

  defp parse_element(str) do
    case Integer.parse(str) do
      {n, ""} -> n
      _ ->
        case Float.parse(str) do
          {f, ""} -> f
          _ -> str
        end
    end
  end
end
