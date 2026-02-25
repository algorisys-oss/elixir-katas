defmodule ElixirKatasWeb.ElixirKata22RecursionLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "factorial",
      title: "Factorial",
      description: "n! = n * (n-1) * ... * 1",
      code: "def factorial(0), do: 1\ndef factorial(n), do: n * factorial(n - 1)",
      base_case: "factorial(0) = 1",
      recursive_case: "factorial(n) = n * factorial(n - 1)",
      default_input: "5",
      max_input: 12,
      enum_equivalent: "Enum.reduce(1..n, 1, &(&1 * &2))"
    },
    %{
      id: "fibonacci",
      title: "Fibonacci",
      description: "fib(n) = fib(n-1) + fib(n-2)",
      code: "def fib(0), do: 0\ndef fib(1), do: 1\ndef fib(n), do: fib(n - 1) + fib(n - 2)",
      base_case: "fib(0) = 0, fib(1) = 1",
      recursive_case: "fib(n) = fib(n-1) + fib(n-2)",
      default_input: "6",
      max_input: 10,
      enum_equivalent: "Enum.reduce(2..n, {0, 1}, fn _, {a, b} -> {b, a+b} end)"
    },
    %{
      id: "sum",
      title: "List Sum",
      description: "Sum all elements of a list",
      code: "def sum([]), do: 0\ndef sum([h | t]), do: h + sum(t)",
      base_case: "sum([]) = 0",
      recursive_case: "sum([h | t]) = h + sum(t)",
      default_input: "[1, 2, 3, 4, 5]",
      max_input: 99,
      enum_equivalent: "Enum.sum(list)"
    },
    %{
      id: "length",
      title: "List Length",
      description: "Count elements in a list",
      code: "def my_length([]), do: 0\ndef my_length([_ | t]), do: 1 + my_length(t)",
      base_case: "my_length([]) = 0",
      recursive_case: "my_length([_ | t]) = 1 + my_length(t)",
      default_input: "[10, 20, 30, 40]",
      max_input: 99,
      enum_equivalent: "Enum.count(list)"
    },
    %{
      id: "reverse",
      title: "List Reverse",
      description: "Reverse the order of a list",
      code: "def reverse([]), do: []\ndef reverse([h | t]), do: reverse(t) ++ [h]",
      base_case: "reverse([]) = []",
      recursive_case: "reverse([h | t]) = reverse(t) ++ [h]",
      default_input: "[1, 2, 3, 4]",
      max_input: 99,
      enum_equivalent: "Enum.reverse(list)"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:current_example, fn -> hd(@examples) end)
     |> assign_new(:user_input, fn -> hd(@examples).default_input end)
     |> assign_new(:call_stack, fn -> [] end)
     |> assign_new(:current_step, fn -> 0 end)
     |> assign_new(:is_playing, fn -> false end)
     |> assign_new(:final_result, fn -> nil end)
     |> assign_new(:show_fib_tree, fn -> false end)
     |> assign_new(:show_base_case_demo, fn -> false end)
     |> assign_new(:show_enum_comparison, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Recursion</h2>
      <p class="text-sm opacity-70 mb-6">
        Recursion is a function calling itself to solve a problem by breaking it into smaller pieces.
        Every recursive function needs a <strong>base case</strong> (when to stop) and a
        <strong>recursive case</strong> (how to break it down).
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

      <!-- Function Definition -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3"><%= @current_example.title %></h3>
          <p class="text-xs opacity-60 mb-4"><%= @current_example.description %></p>

          <!-- Code Display -->
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm mb-4 whitespace-pre-wrap"><%= @current_example.code %></div>

          <!-- Base + Recursive Case -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="flex items-center gap-2 mb-1">
                <span class="badge badge-success badge-sm">Base Case</span>
                <span class="text-xs opacity-60">When to stop</span>
              </div>
              <div class="font-mono text-sm text-success"><%= @current_example.base_case %></div>
            </div>

            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="flex items-center gap-2 mb-1">
                <span class="badge badge-info badge-sm">Recursive Case</span>
                <span class="text-xs opacity-60">Break it down</span>
              </div>
              <div class="font-mono text-sm text-info"><%= @current_example.recursive_case %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Interactive Call Stack Visualizer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Call Stack Visualizer</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter a value and step through the recursion to see the call stack build up and then unwind.
          </p>

          <!-- Input -->
          <form phx-submit="run_recursion" phx-target={@myself} class="flex gap-2 items-end mb-4">
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
            <button type="submit" class="btn btn-primary btn-sm">Build Stack</button>
            <button
              type="button"
              phx-click="reset_stack"
              phx-target={@myself}
              class="btn btn-ghost btn-sm"
            >
              Reset
            </button>
          </form>

          <!-- Step Controls -->
          <%= if length(@call_stack) > 0 do %>
            <div class="flex gap-2 mb-4">
              <button
                phx-click="step_back"
                phx-target={@myself}
                disabled={@current_step <= 0}
                class="btn btn-sm btn-outline"
              >
                &larr; Back
              </button>
              <span class="text-xs opacity-50 self-center">
                Step <%= @current_step %> / <%= length(@call_stack) %>
              </span>
              <button
                phx-click="step_forward"
                phx-target={@myself}
                disabled={@current_step >= length(@call_stack)}
                class="btn btn-sm btn-primary"
              >
                Forward &rarr;
              </button>
              <button
                phx-click="step_all"
                phx-target={@myself}
                class="btn btn-sm btn-accent"
              >
                Show All
              </button>
            </div>
          <% end %>

          <!-- Call Stack Display -->
          <%= if length(@call_stack) > 0 do %>
            <div class="space-y-1">
              <%= for {frame, idx} <- Enum.with_index(@call_stack) do %>
                <%= if idx < @current_step do %>
                  <div class={"flex items-center gap-2 rounded-lg p-2 transition-all " <> frame_style(frame, idx, @current_step, length(@call_stack))}>
                    <!-- Depth indicator -->
                    <div style={"margin-left: #{frame.depth * 1.5}rem"} class="flex items-center gap-2 flex-1">
                      <!-- Direction arrow -->
                      <%= if frame.phase == :call do %>
                        <span class="text-info">&#x25BC;</span>
                      <% else %>
                        <span class="text-success">&#x25B2;</span>
                      <% end %>

                      <!-- Stack frame badge -->
                      <span class={"badge badge-xs " <> if(frame.phase == :call, do: "badge-info", else: "badge-success")}>
                        <%= if frame.phase == :call, do: "call", else: "return" %>
                      </span>

                      <!-- Call expression -->
                      <span class="font-mono text-sm">
                        <%= frame.expression %>
                      </span>

                      <!-- Result if return phase -->
                      <%= if frame.phase == :return do %>
                        <span class="opacity-30">=&gt;</span>
                        <span class="font-mono text-sm text-success font-bold"><%= frame.result %></span>
                      <% end %>

                      <!-- Base case marker -->
                      <%= if frame.is_base do %>
                        <span class="badge badge-warning badge-xs">base case!</span>
                      <% end %>
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>

            <!-- Stack Depth Counter -->
            <div class="mt-4 flex items-center gap-4">
              <div class="badge badge-lg badge-info gap-2">
                Max Stack Depth: <%= max_depth(@call_stack, @current_step) %>
              </div>
              <%= if @current_step >= length(@call_stack) and @final_result do %>
                <div class="badge badge-lg badge-success gap-2">
                  Final Result: <%= @final_result %>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Fibonacci Tree Visualization -->
      <%= if @current_example.id == "fibonacci" do %>
        <div class="card bg-base-200 shadow-md mb-6">
          <div class="card-body p-4">
            <div class="flex items-center justify-between mb-3">
              <h3 class="card-title text-sm">Fibonacci: Duplicate Calculations</h3>
              <button
                phx-click="toggle_fib_tree"
                phx-target={@myself}
                class="btn btn-xs btn-ghost"
              >
                <%= if @show_fib_tree, do: "Hide", else: "Show Tree" %>
              </button>
            </div>

            <%= if @show_fib_tree do %>
              <p class="text-xs opacity-60 mb-4">
                Naive Fibonacci is exponentially slow because it recalculates the same values many times.
                Notice how fib(3) is calculated twice, fib(2) three times, etc.
              </p>

              <!-- fib(5) call tree -->
              <div class="bg-base-300 rounded-lg p-4 font-mono text-xs overflow-x-auto">
                <div class="min-w-[600px]">
                  <div class="text-center mb-2">
                    <span class="bg-primary/20 px-2 py-1 rounded font-bold">fib(5)</span>
                  </div>
                  <div class="flex justify-center gap-16 mb-2">
                    <span class="bg-info/20 px-2 py-1 rounded">fib(4)</span>
                    <span class="bg-warning/20 px-2 py-1 rounded">fib(3)</span>
                  </div>
                  <div class="flex justify-center gap-4 mb-2">
                    <span class="bg-info/20 px-2 py-1 rounded">fib(3)</span>
                    <span class="bg-success/20 px-2 py-1 rounded">fib(2)</span>
                    <span class="mx-4"></span>
                    <span class="bg-success/20 px-2 py-1 rounded">fib(2)</span>
                    <span class="bg-success/50 px-2 py-1 rounded">fib(1)=1</span>
                  </div>
                  <div class="flex justify-center gap-2 mb-2">
                    <span class="bg-success/20 px-2 py-1 rounded">fib(2)</span>
                    <span class="bg-success/50 px-2 py-1 rounded">fib(1)=1</span>
                    <span class="mx-1"></span>
                    <span class="bg-success/50 px-2 py-1 rounded">fib(1)=1</span>
                    <span class="bg-success/50 px-2 py-1 rounded">fib(0)=0</span>
                    <span class="mx-1"></span>
                    <span class="bg-success/50 px-2 py-1 rounded">fib(1)=1</span>
                    <span class="bg-success/50 px-2 py-1 rounded">fib(0)=0</span>
                  </div>
                  <div class="flex justify-center gap-2">
                    <span class="bg-success/50 px-2 py-1 rounded">fib(1)=1</span>
                    <span class="bg-success/50 px-2 py-1 rounded">fib(0)=0</span>
                  </div>
                </div>
              </div>

              <!-- Duplicate count -->
              <div class="mt-4 grid grid-cols-2 md:grid-cols-5 gap-2">
                <%= for {call, count} <- fib_duplicate_counts() do %>
                  <div class={"text-center p-2 rounded-lg text-xs font-mono " <> if(count > 1, do: "bg-warning/20 border border-warning/30", else: "bg-base-100")}>
                    <div class="font-bold"><%= call %></div>
                    <div class={"text-xs " <> if(count > 1, do: "text-warning font-bold", else: "opacity-50")}>
                      called <%= count %>x
                    </div>
                  </div>
                <% end %>
              </div>

              <div class="alert alert-warning text-sm mt-4">
                <div>
                  <div class="font-bold">Why naive Fibonacci is O(2^n)</div>
                  <span>Each call branches into 2 more calls. For fib(5), there are 15 function calls instead of just 5 steps.
                    This is why tail-recursive or Enum-based solutions are much better!</span>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Why Base Case is Critical -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Why the Base Case is Critical</h3>
            <button
              phx-click="toggle_base_case"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_base_case_demo, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_base_case_demo do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <!-- Without base case -->
              <div class="bg-error/10 border border-error/30 rounded-lg p-4">
                <h4 class="font-bold text-error text-sm mb-2">Without Base Case</h4>
                <div class="font-mono text-sm space-y-1">
                  <div><span class="opacity-50">def </span><span class="font-bold">forever(n)</span><span class="opacity-50"> do</span></div>
                  <div class="ml-4">n + forever(n - 1)</div>
                  <div class="opacity-50">end</div>
                </div>
                <div class="mt-3 bg-base-100 rounded p-2 font-mono text-xs">
                  <div>forever(3)</div>
                  <div class="ml-2 opacity-70">&rarr; 3 + forever(2)</div>
                  <div class="ml-4 opacity-70">&rarr; 3 + 2 + forever(1)</div>
                  <div class="ml-6 opacity-70">&rarr; 3 + 2 + 1 + forever(0)</div>
                  <div class="ml-8 opacity-70">&rarr; 3 + 2 + 1 + 0 + forever(-1)</div>
                  <div class="ml-10 text-error">&rarr; ... never stops!</div>
                </div>
                <div class="mt-2 text-xs text-error font-bold">
                  Stack overflow! The BEAM will eventually kill this process.
                </div>
              </div>

              <!-- With base case -->
              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <h4 class="font-bold text-success text-sm mb-2">With Base Case</h4>
                <div class="font-mono text-sm space-y-1">
                  <div><span class="opacity-50">def </span><span class="font-bold text-success">sum(0), do: 0</span> <span class="text-success"># stop here!</span></div>
                  <div><span class="opacity-50">def </span><span class="font-bold">sum(n)</span><span class="opacity-50"> do</span></div>
                  <div class="ml-4">n + sum(n - 1)</div>
                  <div class="opacity-50">end</div>
                </div>
                <div class="mt-3 bg-base-100 rounded p-2 font-mono text-xs">
                  <div>sum(3)</div>
                  <div class="ml-2 opacity-70">&rarr; 3 + sum(2)</div>
                  <div class="ml-4 opacity-70">&rarr; 3 + 2 + sum(1)</div>
                  <div class="ml-6 opacity-70">&rarr; 3 + 2 + 1 + sum(0)</div>
                  <div class="ml-8 text-success">&rarr; 3 + 2 + 1 + 0 = 6</div>
                </div>
                <div class="mt-2 text-xs text-success font-bold">
                  Terminates cleanly once it hits the base case!
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Recursive vs Enum -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Recursive vs Enum Solutions</h3>
            <button
              phx-click="toggle_enum_comparison"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_enum_comparison, do: "Hide", else: "Show Comparison" %>
            </button>
          </div>

          <%= if @show_enum_comparison do %>
            <p class="text-xs opacity-60 mb-4">
              Elixir provides the Enum module for common operations. While recursion is fundamental to understand,
              in practice you will often use Enum functions which are optimized and more readable.
            </p>

            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Operation</th>
                    <th>Recursive</th>
                    <th>Enum Equivalent</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for ex <- examples() do %>
                    <tr>
                      <td class="font-bold text-sm"><%= ex.title %></td>
                      <td class="font-mono text-xs"><%= ex.code |> String.split("\n") |> hd() %></td>
                      <td class="font-mono text-xs text-primary"><%= ex.enum_equivalent %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="alert alert-info text-sm mt-4">
              <div>
                <div class="font-bold">When to use explicit recursion</div>
                <span>Use Enum/Stream for standard operations. Use explicit recursion when you need
                  custom traversal logic, early termination with accumulators, or processing that
                  does not fit Enum's patterns (like tree walks or parsers).</span>
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
              <span><strong>Base case:</strong> The condition that stops the recursion. Without it, you get infinite recursion.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Recursive case:</strong> Breaks the problem into a smaller subproblem and calls itself.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Call stack:</strong> Each recursive call adds a frame to the stack. The stack unwinds when base case is reached.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Pattern matching</strong> makes Elixir recursion elegant - base cases are separate function clauses.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Naive recursion (like Fibonacci) can be exponentially slow due to <strong>duplicate calculations</strong>.</span>
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
     |> assign(call_stack: [])
     |> assign(current_step: 0)
     |> assign(final_result: nil)
     |> assign(show_fib_tree: false)}
  end

  def handle_event("run_recursion", %{"input" => input}, socket) do
    input = String.trim(input)
    example = socket.assigns.current_example

    {stack, result} = build_call_stack(example.id, input)

    {:noreply,
     socket
     |> assign(user_input: input)
     |> assign(call_stack: stack)
     |> assign(current_step: 0)
     |> assign(final_result: result)}
  end

  def handle_event("step_forward", _params, socket) do
    new_step = min(socket.assigns.current_step + 1, length(socket.assigns.call_stack))
    {:noreply, assign(socket, current_step: new_step)}
  end

  def handle_event("step_back", _params, socket) do
    new_step = max(socket.assigns.current_step - 1, 0)
    {:noreply, assign(socket, current_step: new_step)}
  end

  def handle_event("step_all", _params, socket) do
    {:noreply, assign(socket, current_step: length(socket.assigns.call_stack))}
  end

  def handle_event("reset_stack", _params, socket) do
    {:noreply,
     socket
     |> assign(call_stack: [])
     |> assign(current_step: 0)
     |> assign(final_result: nil)}
  end

  def handle_event("toggle_fib_tree", _params, socket) do
    {:noreply, assign(socket, show_fib_tree: !socket.assigns.show_fib_tree)}
  end

  def handle_event("toggle_base_case", _params, socket) do
    {:noreply, assign(socket, show_base_case_demo: !socket.assigns.show_base_case_demo)}
  end

  def handle_event("toggle_enum_comparison", _params, socket) do
    {:noreply, assign(socket, show_enum_comparison: !socket.assigns.show_enum_comparison)}
  end

  # Helpers

  defp examples, do: @examples

  defp build_call_stack("factorial", input) do
    case Integer.parse(input) do
      {n, _} when n >= 0 and n <= 12 ->
        {frames, result} = factorial_frames(n, 0)
        {frames, to_string(result)}

      _ ->
        {[], "Invalid input"}
    end
  end

  defp build_call_stack("fibonacci", input) do
    case Integer.parse(input) do
      {n, _} when n >= 0 and n <= 10 ->
        {frames, result} = fibonacci_frames(n, 0)
        {frames, to_string(result)}

      _ ->
        {[], "Invalid input"}
    end
  end

  defp build_call_stack("sum", input) do
    try do
      {list, _} = Code.eval_string(input)

      if is_list(list) and Enum.all?(list, &is_number/1) do
        {frames, result} = sum_frames(list, 0)
        {frames, to_string(result)}
      else
        {[], "Invalid input - provide a list of numbers"}
      end
    rescue
      _ -> {[], "Invalid input"}
    end
  end

  defp build_call_stack("length", input) do
    try do
      {list, _} = Code.eval_string(input)

      if is_list(list) do
        {frames, result} = length_frames(list, 0)
        {frames, to_string(result)}
      else
        {[], "Invalid input - provide a list"}
      end
    rescue
      _ -> {[], "Invalid input"}
    end
  end

  defp build_call_stack("reverse", input) do
    try do
      {list, _} = Code.eval_string(input)

      if is_list(list) do
        {frames, result} = reverse_frames(list, 0)
        {frames, inspect(result)}
      else
        {[], "Invalid input - provide a list"}
      end
    rescue
      _ -> {[], "Invalid input"}
    end
  end

  defp build_call_stack(_, _), do: {[], "Unknown example"}

  # Factorial frames
  defp factorial_frames(0, depth) do
    frames = [
      %{expression: "factorial(0)", phase: :call, depth: depth, result: nil, is_base: true},
      %{expression: "factorial(0)", phase: :return, depth: depth, result: "1", is_base: true}
    ]

    {frames, 1}
  end

  defp factorial_frames(n, depth) do
    call_frame = %{expression: "factorial(#{n})", phase: :call, depth: depth, result: nil, is_base: false}
    {sub_frames, sub_result} = factorial_frames(n - 1, depth + 1)
    result = n * sub_result
    return_frame = %{expression: "#{n} * factorial(#{n - 1})", phase: :return, depth: depth, result: "#{result}", is_base: false}

    {[call_frame | sub_frames] ++ [return_frame], result}
  end

  # Fibonacci frames
  defp fibonacci_frames(0, depth) do
    frames = [
      %{expression: "fib(0)", phase: :call, depth: depth, result: nil, is_base: true},
      %{expression: "fib(0)", phase: :return, depth: depth, result: "0", is_base: true}
    ]

    {frames, 0}
  end

  defp fibonacci_frames(1, depth) do
    frames = [
      %{expression: "fib(1)", phase: :call, depth: depth, result: nil, is_base: true},
      %{expression: "fib(1)", phase: :return, depth: depth, result: "1", is_base: true}
    ]

    {frames, 1}
  end

  defp fibonacci_frames(n, depth) do
    call_frame = %{expression: "fib(#{n})", phase: :call, depth: depth, result: nil, is_base: false}
    {left_frames, left_result} = fibonacci_frames(n - 1, depth + 1)
    {right_frames, right_result} = fibonacci_frames(n - 2, depth + 1)
    result = left_result + right_result
    return_frame = %{expression: "fib(#{n - 1}) + fib(#{n - 2})", phase: :return, depth: depth, result: "#{result}", is_base: false}

    {[call_frame | left_frames] ++ right_frames ++ [return_frame], result}
  end

  # Sum frames
  defp sum_frames([], depth) do
    frames = [
      %{expression: "sum([])", phase: :call, depth: depth, result: nil, is_base: true},
      %{expression: "sum([])", phase: :return, depth: depth, result: "0", is_base: true}
    ]

    {frames, 0}
  end

  defp sum_frames([h | t], depth) do
    call_frame = %{expression: "sum([#{Enum.join([h | t], ", ")}])", phase: :call, depth: depth, result: nil, is_base: false}
    {sub_frames, sub_result} = sum_frames(t, depth + 1)
    result = h + sub_result
    return_frame = %{expression: "#{h} + sum([#{Enum.join(t, ", ")}])", phase: :return, depth: depth, result: "#{result}", is_base: false}

    {[call_frame | sub_frames] ++ [return_frame], result}
  end

  # Length frames
  defp length_frames([], depth) do
    frames = [
      %{expression: "my_length([])", phase: :call, depth: depth, result: nil, is_base: true},
      %{expression: "my_length([])", phase: :return, depth: depth, result: "0", is_base: true}
    ]

    {frames, 0}
  end

  defp length_frames([h | t], depth) do
    list_str = inspect([h | t])
    call_frame = %{expression: "my_length(#{list_str})", phase: :call, depth: depth, result: nil, is_base: false}
    {sub_frames, sub_result} = length_frames(t, depth + 1)
    result = 1 + sub_result
    return_frame = %{expression: "1 + my_length(#{inspect(t)})", phase: :return, depth: depth, result: "#{result}", is_base: false}

    {[call_frame | sub_frames] ++ [return_frame], result}
  end

  # Reverse frames
  defp reverse_frames([], depth) do
    frames = [
      %{expression: "reverse([])", phase: :call, depth: depth, result: nil, is_base: true},
      %{expression: "reverse([])", phase: :return, depth: depth, result: "[]", is_base: true}
    ]

    {frames, []}
  end

  defp reverse_frames([h | t], depth) do
    call_frame = %{expression: "reverse(#{inspect([h | t])})", phase: :call, depth: depth, result: nil, is_base: false}
    {sub_frames, sub_result} = reverse_frames(t, depth + 1)
    result = sub_result ++ [h]
    return_frame = %{expression: "reverse(#{inspect(t)}) ++ [#{inspect(h)}]", phase: :return, depth: depth, result: inspect(result), is_base: false}

    {[call_frame | sub_frames] ++ [return_frame], result}
  end

  defp frame_style(frame, _idx, _current_step, _total) do
    case frame.phase do
      :call ->
        if frame.is_base do
          "bg-warning/15 border border-warning/30"
        else
          "bg-info/10 border border-info/20"
        end

      :return ->
        "bg-success/10 border border-success/20"
    end
  end

  defp max_depth(call_stack, current_step) do
    call_stack
    |> Enum.take(current_step)
    |> Enum.filter(&(&1.phase == :call))
    |> Enum.map(& &1.depth)
    |> Enum.max(fn -> 0 end)
    |> Kernel.+(1)
  end

  defp fib_duplicate_counts do
    [
      {"fib(5)", 1},
      {"fib(4)", 1},
      {"fib(3)", 2},
      {"fib(2)", 3},
      {"fib(1)", 5},
      {"fib(0)", 3}
    ]
  end
end
