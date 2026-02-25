defmodule ElixirKatasWeb.ElixirKata23TailCallLive do
  use ElixirKatasWeb, :live_component

  @comparisons [
    %{
      id: "sum",
      title: "Sum 1..n",
      naive: %{
        label: "Naive Recursion",
        code: "def sum(0), do: 0\ndef sum(n), do: n + sum(n - 1)",
        explanation: "The addition n + sum(n-1) happens AFTER the recursive call returns, so each frame must be kept on the stack."
      },
      tail: %{
        label: "Tail-Recursive",
        code: "def sum(n), do: sum(n, 0)\ndef sum(0, acc), do: acc\ndef sum(n, acc), do: sum(n - 1, acc + n)",
        explanation: "The recursive call sum(n-1, acc+n) is the LAST thing the function does. No work remains, so the current frame can be reused."
      },
      default_input: "5",
      max_input: 15
    },
    %{
      id: "factorial",
      title: "Factorial",
      naive: %{
        label: "Naive Recursion",
        code: "def fact(0), do: 1\ndef fact(n), do: n * fact(n - 1)",
        explanation: "Must keep n on the stack to multiply after fact(n-1) returns."
      },
      tail: %{
        label: "Tail-Recursive",
        code: "def fact(n), do: fact(n, 1)\ndef fact(0, acc), do: acc\ndef fact(n, acc), do: fact(n - 1, n * acc)",
        explanation: "The accumulator carries the running product. The recursive call is the last operation."
      },
      default_input: "5",
      max_input: 12
    },
    %{
      id: "reverse",
      title: "List Reverse",
      naive: %{
        label: "Naive Recursion",
        code: "def reverse([]), do: []\ndef reverse([h | t]), do: reverse(t) ++ [h]",
        explanation: "Must wait for reverse(t) to return, then append [h]. Also, ++ is O(n), making this O(n^2)!"
      },
      tail: %{
        label: "Tail-Recursive",
        code: "def reverse(list), do: reverse(list, [])\ndef reverse([], acc), do: acc\ndef reverse([h | t], acc), do: reverse(t, [h | acc])",
        explanation: "Prepending with [h | acc] is O(1). The recursive call is the last operation. O(n) total."
      },
      default_input: "[1, 2, 3, 4]",
      max_input: 99
    },
    %{
      id: "map",
      title: "List Map",
      naive: %{
        label: "Naive Recursion",
        code: "def my_map([], _f), do: []\ndef my_map([h | t], f), do: [f.(h) | my_map(t, f)]",
        explanation: "Constructs the list as the stack unwinds. Each frame holds the transformed head."
      },
      tail: %{
        label: "Tail-Recursive",
        code: "def my_map(list, f), do: do_map(list, f, [])\ndef do_map([], _f, acc), do: Enum.reverse(acc)\ndef do_map([h | t], f, acc), do: do_map(t, f, [f.(h) | acc])",
        explanation: "Builds the result in reverse using an accumulator, then reverses at the end. The recursive call is the last operation."
      },
      default_input: "[1, 2, 3, 4]",
      max_input: 99
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:current_comparison, fn -> hd(@comparisons) end)
     |> assign_new(:user_input, fn -> hd(@comparisons).default_input end)
     |> assign_new(:naive_stack, fn -> [] end)
     |> assign_new(:tail_stack, fn -> [] end)
     |> assign_new(:naive_step, fn -> 0 end)
     |> assign_new(:tail_step, fn -> 0 end)
     |> assign_new(:naive_result, fn -> nil end)
     |> assign_new(:tail_result, fn -> nil end)
     |> assign_new(:show_conversion_guide, fn -> false end)
     |> assign_new(:show_beam_explanation, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Tail Call Optimization</h2>
      <p class="text-sm opacity-70 mb-6">
        A function is <strong>tail-recursive</strong> when the recursive call is the very last operation.
        The BEAM VM optimizes tail calls into loops, meaning they use constant stack space
        regardless of input size. The trick is to use an <strong>accumulator</strong> parameter.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for comp <- comparisons() do %>
          <button
            phx-click="select_comparison"
            phx-target={@myself}
            phx-value-id={comp.id}
            class={"btn btn-sm " <> if(@current_comparison.id == comp.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= comp.title %>
          </button>
        <% end %>
      </div>

      <!-- Side-by-Side Code -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Naive vs Tail-Recursive: <%= @current_comparison.title %></h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <!-- Naive -->
            <div class="bg-error/10 border border-error/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-error badge-sm">Naive</span>
                <span class="text-xs opacity-60"><%= @current_comparison.naive.label %></span>
              </div>
              <div class="bg-base-100 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap mb-3"><%= @current_comparison.naive.code %></div>
              <p class="text-xs opacity-70"><%= @current_comparison.naive.explanation %></p>
              <div class="mt-2">
                <span class="badge badge-error badge-xs">Stack: O(n)</span>
              </div>
            </div>

            <!-- Tail-Recursive -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-success badge-sm">Tail-Recursive</span>
                <span class="text-xs opacity-60"><%= @current_comparison.tail.label %></span>
              </div>
              <div class="bg-base-100 rounded-lg p-3 font-mono text-sm whitespace-pre-wrap mb-3"><%= @current_comparison.tail.code %></div>
              <p class="text-xs opacity-70"><%= @current_comparison.tail.explanation %></p>
              <div class="mt-2">
                <span class="badge badge-success badge-xs">Stack: O(1)</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Interactive Stack Depth Comparison -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Stack Depth Comparison</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter a value and step through both versions side by side to see the difference in stack usage.
          </p>

          <!-- Input -->
          <form phx-submit="run_comparison" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Input</span></label>
              <input
                type="text"
                name="input"
                value={@user_input}
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Compare</button>
            <button
              type="button"
              phx-click="reset_comparison"
              phx-target={@myself}
              class="btn btn-ghost btn-sm"
            >
              Reset
            </button>
          </form>

          <%= if length(@naive_stack) > 0 or length(@tail_stack) > 0 do %>
            <!-- Step Controls -->
            <div class="flex gap-2 mb-4">
              <button
                phx-click="step_both_back"
                phx-target={@myself}
                disabled={@naive_step <= 0 and @tail_step <= 0}
                class="btn btn-sm btn-outline"
              >
                &larr; Back
              </button>
              <button
                phx-click="step_both_forward"
                phx-target={@myself}
                disabled={@naive_step >= length(@naive_stack) and @tail_step >= length(@tail_stack)}
                class="btn btn-sm btn-primary"
              >
                Forward &rarr;
              </button>
              <button
                phx-click="step_all_both"
                phx-target={@myself}
                class="btn btn-sm btn-accent"
              >
                Show All
              </button>
            </div>

            <!-- Side by Side Stacks -->
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Naive Stack -->
              <div>
                <div class="flex items-center justify-between mb-2">
                  <span class="font-bold text-sm text-error">Naive Stack</span>
                  <span class="badge badge-error badge-sm">
                    depth: <%= naive_current_depth(@naive_stack, @naive_step) %>
                  </span>
                </div>
                <div class="space-y-1 min-h-[4rem]">
                  <%= for {frame, idx} <- Enum.with_index(@naive_stack) do %>
                    <%= if idx < @naive_step do %>
                      <div class={"flex items-center gap-2 rounded p-1.5 text-xs font-mono transition-all " <> naive_frame_style(frame)}>
                        <div style={"margin-left: #{frame.depth * 0.75}rem"} class="flex items-center gap-1">
                          <%= if frame.phase == :call do %>
                            <span class="text-info">&#x25BC;</span>
                          <% else %>
                            <span class="text-success">&#x25B2;</span>
                          <% end %>
                          <span><%= frame.expression %></span>
                          <%= if frame.phase == :return do %>
                            <span class="text-success font-bold">= <%= frame.result %></span>
                          <% end %>
                          <%= if frame.is_base do %>
                            <span class="badge badge-warning" style="font-size: 0.6rem; padding: 0 4px;">base</span>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>

              <!-- Tail-Recursive Stack -->
              <div>
                <div class="flex items-center justify-between mb-2">
                  <span class="font-bold text-sm text-success">Tail-Recursive Stack</span>
                  <span class="badge badge-success badge-sm">
                    depth: <%= tail_current_depth(@tail_stack, @tail_step) %>
                  </span>
                </div>
                <div class="space-y-1 min-h-[4rem]">
                  <%= for {frame, idx} <- Enum.with_index(@tail_stack) do %>
                    <%= if idx < @tail_step do %>
                      <div class={"flex items-center gap-2 rounded p-1.5 text-xs font-mono transition-all " <> tail_frame_style(frame)}>
                        <div class="flex items-center gap-1">
                          <%= if frame.is_base do %>
                            <span class="text-success">&#x2713;</span>
                          <% else %>
                            <span class="text-info">&rarr;</span>
                          <% end %>
                          <span><%= frame.expression %></span>
                          <span class="opacity-50">acc=<%= frame.acc %></span>
                          <%= if frame.is_base do %>
                            <span class="badge badge-warning" style="font-size: 0.6rem; padding: 0 4px;">done</span>
                            <span class="text-success font-bold">= <%= frame.acc %></span>
                          <% end %>
                        </div>
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>

            <!-- Visual Stack Bar Chart -->
            <div class="mt-6 bg-base-300 rounded-lg p-4">
              <h4 class="text-xs font-bold opacity-60 mb-3">Stack Depth Over Time</h4>
              <div class="flex items-end gap-1 h-24">
                <!-- Naive bars -->
                <div class="flex-1 flex items-end gap-px">
                  <%= for {frame, idx} <- Enum.with_index(@naive_stack) do %>
                    <%= if idx < @naive_step do %>
                      <div
                        class={"flex-1 rounded-t transition-all " <> if(frame.phase == :call, do: "bg-error/60", else: "bg-error/30")}
                        style={"height: #{(frame.depth + 1) * 16}px; max-height: 96px"}
                        title={"Naive step #{idx + 1}: depth #{frame.depth + 1}"}
                      >
                      </div>
                    <% end %>
                  <% end %>
                </div>
                <!-- Divider -->
                <div class="w-px bg-base-content/20 h-full mx-2"></div>
                <!-- Tail bars -->
                <div class="flex-1 flex items-end gap-px">
                  <%= for {frame, idx} <- Enum.with_index(@tail_stack) do %>
                    <%= if idx < @tail_step do %>
                      <div
                        class="flex-1 bg-success/60 rounded-t transition-all"
                        style="height: 16px"
                        title={"Tail step #{idx + 1}: depth 1 (constant)"}
                      >
                      </div>
                    <% end %>
                  <% end %>
                </div>
              </div>
              <div class="flex justify-between mt-1">
                <span class="text-xs opacity-50 text-error">Naive (grows)</span>
                <span class="text-xs opacity-50 text-success">Tail (constant)</span>
              </div>
            </div>

            <!-- Results -->
            <div class="grid grid-cols-2 gap-4 mt-4">
              <%= if @naive_result do %>
                <div class="badge badge-lg badge-error gap-2">Naive result: <%= @naive_result %></div>
              <% end %>
              <%= if @tail_result do %>
                <div class="badge badge-lg badge-success gap-2">Tail result: <%= @tail_result %></div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- The Accumulator Pattern -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">How to Convert: The Accumulator Pattern</h3>
            <button
              phx-click="toggle_conversion_guide"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_conversion_guide, do: "Hide", else: "Show Guide" %>
            </button>
          </div>

          <%= if @show_conversion_guide do %>
            <div class="space-y-4">
              <p class="text-sm opacity-70">
                To convert naive recursion to tail-recursive, follow these steps:
              </p>

              <div class="space-y-3">
                <div class="flex items-start gap-3 p-3 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5">1</span>
                  <div>
                    <div class="font-bold text-sm">Add an accumulator parameter</div>
                    <div class="text-xs opacity-70 mt-1">The accumulator carries the intermediate result. Initialize it to the identity value for the operation (0 for sum, 1 for product, [] for lists).</div>
                    <div class="font-mono text-xs mt-2 bg-base-100 rounded p-2">
                      <div class="opacity-50"># Before: def sum(0), do: 0</div>
                      <div class="text-success"># After:  def sum(0, acc), do: acc</div>
                    </div>
                  </div>
                </div>

                <div class="flex items-start gap-3 p-3 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5">2</span>
                  <div>
                    <div class="font-bold text-sm">Move the work BEFORE the recursive call</div>
                    <div class="text-xs opacity-70 mt-1">Instead of doing work after the call returns, update the accumulator before making the next call.</div>
                    <div class="font-mono text-xs mt-2 bg-base-100 rounded p-2">
                      <div class="opacity-50"># Before: n + sum(n - 1)        <span class="text-error"># work AFTER call</span></div>
                      <div class="text-success"># After:  sum(n - 1, acc + n)   <span class="text-success"># work BEFORE call</span></div>
                    </div>
                  </div>
                </div>

                <div class="flex items-start gap-3 p-3 bg-base-300 rounded-lg">
                  <span class="badge badge-primary badge-sm mt-0.5">3</span>
                  <div>
                    <div class="font-bold text-sm">Add a public wrapper function</div>
                    <div class="text-xs opacity-70 mt-1">Hide the accumulator from callers with a wrapper that provides the initial value.</div>
                    <div class="font-mono text-xs mt-2 bg-base-100 rounded p-2">
                      <div class="text-success">def sum(n), do: sum(n, 0)  <span class="text-info"># public API</span></div>
                      <div class="opacity-50">defp sum(0, acc), do: acc  <span class="text-info"># private impl</span></div>
                      <div class="opacity-50">defp sum(n, acc), do: sum(n - 1, acc + n)</div>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Conversion table -->
              <div class="overflow-x-auto mt-4">
                <table class="table table-sm">
                  <thead>
                    <tr>
                      <th>Operation</th>
                      <th>Accumulator Init</th>
                      <th>Accumulator Update</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr>
                      <td class="font-bold">Sum</td>
                      <td class="font-mono text-xs">0</td>
                      <td class="font-mono text-xs">acc + n</td>
                    </tr>
                    <tr>
                      <td class="font-bold">Product / Factorial</td>
                      <td class="font-mono text-xs">1</td>
                      <td class="font-mono text-xs">acc * n</td>
                    </tr>
                    <tr>
                      <td class="font-bold">Reverse</td>
                      <td class="font-mono text-xs">[]</td>
                      <td class="font-mono text-xs">[h | acc]</td>
                    </tr>
                    <tr>
                      <td class="font-bold">Map</td>
                      <td class="font-mono text-xs">[]</td>
                      <td class="font-mono text-xs">[f.(h) | acc]  <span class="text-xs opacity-50">(then reverse)</span></td>
                    </tr>
                    <tr>
                      <td class="font-bold">Count / Length</td>
                      <td class="font-mono text-xs">0</td>
                      <td class="font-mono text-xs">acc + 1</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- BEAM TCO Explanation -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">How the BEAM Optimizes Tail Calls</h3>
            <button
              phx-click="toggle_beam_explanation"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_beam_explanation, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_beam_explanation do %>
            <div class="space-y-4">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <!-- Without TCO -->
                <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                  <h4 class="font-bold text-error text-sm mb-2">Without TCO (Naive)</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># Each call pushes a new frame</div>
                      <div>sum(5) <span class="text-error"># frame 1 - waiting</span></div>
                      <div class="ml-2">sum(4) <span class="text-error"># frame 2 - waiting</span></div>
                      <div class="ml-4">sum(3) <span class="text-error"># frame 3 - waiting</span></div>
                      <div class="ml-6">sum(2) <span class="text-error"># frame 4 - waiting</span></div>
                      <div class="ml-8">sum(1) <span class="text-error"># frame 5 - waiting</span></div>
                      <div class="ml-10">sum(0) <span class="text-success"># base case</span></div>
                    </div>
                  </div>
                  <div class="mt-2 text-xs text-error">All 6 frames exist simultaneously on the stack.</div>
                </div>

                <!-- With TCO -->
                <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                  <h4 class="font-bold text-success text-sm mb-2">With TCO (Tail-Recursive)</h4>
                  <div class="font-mono text-xs space-y-1">
                    <div class="bg-base-100 rounded p-2">
                      <div class="opacity-60"># BEAM reuses the same frame!</div>
                      <div>sum(5, 0)  <span class="text-success"># reuse frame</span></div>
                      <div>sum(4, 5)  <span class="text-success"># same frame, new args</span></div>
                      <div>sum(3, 9)  <span class="text-success"># same frame, new args</span></div>
                      <div>sum(2, 12) <span class="text-success"># same frame, new args</span></div>
                      <div>sum(1, 14) <span class="text-success"># same frame, new args</span></div>
                      <div>sum(0, 15) <span class="text-success"># base case, return 15</span></div>
                    </div>
                  </div>
                  <div class="mt-2 text-xs text-success">Only 1 frame ever exists. Equivalent to a loop!</div>
                </div>
              </div>

              <div class="alert alert-info text-sm">
                <div>
                  <div class="font-bold">Why does this work?</div>
                  <span>When the recursive call is the very last thing a function does, the current
                    stack frame has no more work to do. The BEAM detects this and instead of pushing a new
                    frame, it replaces the current one - effectively turning recursion into a loop.
                    This means tail-recursive functions can run forever without stack overflow.</span>
                </div>
              </div>

              <div class="alert alert-warning text-sm">
                <div>
                  <div class="font-bold">What makes a call NOT a tail call?</div>
                  <span>If there is ANY operation after the recursive call - even just adding a number
                    like <code class="font-mono bg-base-100 px-1 rounded">n + recurse(n-1)</code> - then it is NOT
                    a tail call because the function must return to perform the addition.</span>
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
              <span>A <strong>tail call</strong> is when the recursive call is the very last operation in the function.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>The BEAM optimizes tail calls into <strong>constant-space loops</strong>: no stack growth.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Use an <strong>accumulator</strong> parameter to carry intermediate results and move work before the call.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">n + recurse(n-1)</code> is NOT tail-recursive because + happens after the call.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>For list operations, build the result in reverse then call <code class="font-mono bg-base-100 px-1 rounded">Enum.reverse/1</code> at the end.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_comparison", %{"id" => id}, socket) do
    comparison = Enum.find(comparisons(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(current_comparison: comparison)
     |> assign(user_input: comparison.default_input)
     |> assign(naive_stack: [])
     |> assign(tail_stack: [])
     |> assign(naive_step: 0)
     |> assign(tail_step: 0)
     |> assign(naive_result: nil)
     |> assign(tail_result: nil)}
  end

  def handle_event("run_comparison", %{"input" => input}, socket) do
    input = String.trim(input)
    comparison = socket.assigns.current_comparison

    {naive, naive_result} = build_naive_stack(comparison.id, input)
    {tail, tail_result} = build_tail_stack(comparison.id, input)

    {:noreply,
     socket
     |> assign(user_input: input)
     |> assign(naive_stack: naive)
     |> assign(tail_stack: tail)
     |> assign(naive_step: 0)
     |> assign(tail_step: 0)
     |> assign(naive_result: naive_result)
     |> assign(tail_result: tail_result)}
  end

  def handle_event("step_both_forward", _params, socket) do
    new_naive = min(socket.assigns.naive_step + 1, length(socket.assigns.naive_stack))
    new_tail = min(socket.assigns.tail_step + 1, length(socket.assigns.tail_stack))

    {:noreply,
     socket
     |> assign(naive_step: new_naive)
     |> assign(tail_step: new_tail)}
  end

  def handle_event("step_both_back", _params, socket) do
    new_naive = max(socket.assigns.naive_step - 1, 0)
    new_tail = max(socket.assigns.tail_step - 1, 0)

    {:noreply,
     socket
     |> assign(naive_step: new_naive)
     |> assign(tail_step: new_tail)}
  end

  def handle_event("step_all_both", _params, socket) do
    {:noreply,
     socket
     |> assign(naive_step: length(socket.assigns.naive_stack))
     |> assign(tail_step: length(socket.assigns.tail_stack))}
  end

  def handle_event("reset_comparison", _params, socket) do
    {:noreply,
     socket
     |> assign(naive_stack: [])
     |> assign(tail_stack: [])
     |> assign(naive_step: 0)
     |> assign(tail_step: 0)
     |> assign(naive_result: nil)
     |> assign(tail_result: nil)}
  end

  def handle_event("toggle_conversion_guide", _params, socket) do
    {:noreply, assign(socket, show_conversion_guide: !socket.assigns.show_conversion_guide)}
  end

  def handle_event("toggle_beam_explanation", _params, socket) do
    {:noreply, assign(socket, show_beam_explanation: !socket.assigns.show_beam_explanation)}
  end

  # Helpers

  defp comparisons, do: @comparisons

  # Build naive stack frames
  defp build_naive_stack("sum", input) do
    case Integer.parse(input) do
      {n, _} when n >= 0 and n <= 15 -> naive_sum_frames(n, 0)
      _ -> {[], "Invalid"}
    end
  end

  defp build_naive_stack("factorial", input) do
    case Integer.parse(input) do
      {n, _} when n >= 0 and n <= 12 -> naive_fact_frames(n, 0)
      _ -> {[], "Invalid"}
    end
  end

  defp build_naive_stack("reverse", input) do
    try do
      {list, _} = Code.eval_string(input)
      if is_list(list), do: naive_reverse_frames(list, 0), else: {[], "Invalid"}
    rescue
      _ -> {[], "Invalid"}
    end
  end

  defp build_naive_stack("map", input) do
    try do
      {list, _} = Code.eval_string(input)
      if is_list(list), do: naive_map_frames(list, 0), else: {[], "Invalid"}
    rescue
      _ -> {[], "Invalid"}
    end
  end

  defp build_naive_stack(_, _), do: {[], "Unknown"}

  # Build tail-recursive stack frames
  defp build_tail_stack("sum", input) do
    case Integer.parse(input) do
      {n, _} when n >= 0 and n <= 15 -> tail_sum_frames(n, 0)
      _ -> {[], "Invalid"}
    end
  end

  defp build_tail_stack("factorial", input) do
    case Integer.parse(input) do
      {n, _} when n >= 0 and n <= 12 -> tail_fact_frames(n, 1)
      _ -> {[], "Invalid"}
    end
  end

  defp build_tail_stack("reverse", input) do
    try do
      {list, _} = Code.eval_string(input)
      if is_list(list), do: tail_reverse_frames(list, []), else: {[], "Invalid"}
    rescue
      _ -> {[], "Invalid"}
    end
  end

  defp build_tail_stack("map", input) do
    try do
      {list, _} = Code.eval_string(input)
      if is_list(list), do: tail_map_frames(list, []), else: {[], "Invalid"}
    rescue
      _ -> {[], "Invalid"}
    end
  end

  defp build_tail_stack(_, _), do: {[], "Unknown"}

  # Naive sum frames
  defp naive_sum_frames(0, depth) do
    {[
       %{expression: "sum(0)", phase: :call, depth: depth, result: nil, is_base: true},
       %{expression: "sum(0)", phase: :return, depth: depth, result: "0", is_base: true}
     ], "0"}
  end

  defp naive_sum_frames(n, depth) do
    call = %{expression: "sum(#{n})", phase: :call, depth: depth, result: nil, is_base: false}
    {sub, _} = naive_sum_frames(n - 1, depth + 1)
    result = div(n * (n + 1), 2)
    ret = %{expression: "#{n} + sum(#{n - 1})", phase: :return, depth: depth, result: "#{result}", is_base: false}
    {[call | sub] ++ [ret], "#{result}"}
  end

  # Naive factorial frames
  defp naive_fact_frames(0, depth) do
    {[
       %{expression: "fact(0)", phase: :call, depth: depth, result: nil, is_base: true},
       %{expression: "fact(0)", phase: :return, depth: depth, result: "1", is_base: true}
     ], "1"}
  end

  defp naive_fact_frames(n, depth) do
    call = %{expression: "fact(#{n})", phase: :call, depth: depth, result: nil, is_base: false}
    {sub, _} = naive_fact_frames(n - 1, depth + 1)
    result = Enum.reduce(1..n, 1, &(&1 * &2))
    ret = %{expression: "#{n} * fact(#{n - 1})", phase: :return, depth: depth, result: "#{result}", is_base: false}
    {[call | sub] ++ [ret], "#{result}"}
  end

  # Naive reverse frames
  defp naive_reverse_frames([], depth) do
    {[
       %{expression: "reverse([])", phase: :call, depth: depth, result: nil, is_base: true},
       %{expression: "reverse([])", phase: :return, depth: depth, result: "[]", is_base: true}
     ], inspect([])}
  end

  defp naive_reverse_frames([h | t], depth) do
    call = %{expression: "reverse(#{inspect([h | t])})", phase: :call, depth: depth, result: nil, is_base: false}
    {sub, _} = naive_reverse_frames(t, depth + 1)
    result = Enum.reverse([h | t])
    ret = %{expression: "reverse(#{inspect(t)}) ++ [#{inspect(h)}]", phase: :return, depth: depth, result: inspect(result), is_base: false}
    {[call | sub] ++ [ret], inspect(result)}
  end

  # Naive map frames
  defp naive_map_frames([], depth) do
    {[
       %{expression: "my_map([])", phase: :call, depth: depth, result: nil, is_base: true},
       %{expression: "my_map([])", phase: :return, depth: depth, result: "[]", is_base: true}
     ], inspect([])}
  end

  defp naive_map_frames([h | t], depth) do
    call = %{expression: "my_map(#{inspect([h | t])})", phase: :call, depth: depth, result: nil, is_base: false}
    {sub, _} = naive_map_frames(t, depth + 1)
    result = Enum.map([h | t], &(&1 * 2))
    ret = %{expression: "[f.(#{h}) | my_map(#{inspect(t)})]", phase: :return, depth: depth, result: inspect(result), is_base: false}
    {[call | sub] ++ [ret], inspect(result)}
  end

  # Tail-recursive sum frames
  defp tail_sum_frames(0, acc) do
    {[%{expression: "sum(0, #{acc})", acc: "#{acc}", is_base: true}], "#{acc}"}
  end

  defp tail_sum_frames(n, acc) do
    frame = %{expression: "sum(#{n}, #{acc})", acc: "#{acc}", is_base: false}
    new_acc = acc + n
    {rest, result} = tail_sum_frames(n - 1, new_acc)
    {[frame | rest], result}
  end

  # Tail-recursive factorial frames
  defp tail_fact_frames(0, acc) do
    {[%{expression: "fact(0, #{acc})", acc: "#{acc}", is_base: true}], "#{acc}"}
  end

  defp tail_fact_frames(n, acc) do
    frame = %{expression: "fact(#{n}, #{acc})", acc: "#{acc}", is_base: false}
    new_acc = n * acc
    {rest, result} = tail_fact_frames(n - 1, new_acc)
    {[frame | rest], result}
  end

  # Tail-recursive reverse frames
  defp tail_reverse_frames([], acc) do
    {[%{expression: "reverse([], #{inspect(acc)})", acc: inspect(acc), is_base: true}], inspect(acc)}
  end

  defp tail_reverse_frames([h | t], acc) do
    frame = %{expression: "reverse(#{inspect([h | t])}, ...)", acc: inspect(acc), is_base: false}
    new_acc = [h | acc]
    {rest, result} = tail_reverse_frames(t, new_acc)
    {[frame | rest], result}
  end

  # Tail-recursive map frames
  defp tail_map_frames([], acc) do
    result = Enum.reverse(acc)
    {[%{expression: "do_map([], ...) -> reverse", acc: inspect(result), is_base: true}], inspect(result)}
  end

  defp tail_map_frames([h | t], acc) do
    frame = %{expression: "do_map(#{inspect([h | t])}, ...)", acc: inspect(acc), is_base: false}
    new_acc = [h * 2 | acc]
    {rest, result} = tail_map_frames(t, new_acc)
    {[frame | rest], result}
  end

  defp naive_current_depth(stack, step) do
    stack
    |> Enum.take(step)
    |> Enum.filter(&(&1.phase == :call))
    |> Enum.map(& &1.depth)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp tail_current_depth(_stack, step) when step > 0, do: 1
  defp tail_current_depth(_stack, _step), do: 0

  defp naive_frame_style(frame) do
    case frame.phase do
      :call -> if frame.is_base, do: "bg-warning/15", else: "bg-error/10"
      :return -> "bg-success/10"
    end
  end

  defp tail_frame_style(frame) do
    if frame.is_base, do: "bg-success/20", else: "bg-success/10"
  end
end
