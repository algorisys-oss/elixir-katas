defmodule ElixirKatasWeb.ElixirKata75ElixirToolboxLive do
  use ElixirKatasWeb, :live_component

  @quiz_questions [
    %{
      id: 1,
      question: "You need to store user settings as key-value pairs. The keys are known at compile time and fixed. What do you use?",
      options: [
        %{id: "a", label: "Map", correct: false, explanation: "Maps work but don't enforce structure. Structs are better for fixed, known keys."},
        %{id: "b", label: "Keyword List", correct: false, explanation: "Keyword lists allow duplicate keys and only support atom keys. Not ideal for structured data."},
        %{id: "c", label: "Struct", correct: true, explanation: "Structs provide compile-time key validation, default values, and clear documentation of the expected shape."},
        %{id: "d", label: "ETS Table", correct: false, explanation: "ETS is for shared mutable state across processes. Overkill for simple structured data."}
      ],
      category: "data_structures"
    },
    %{
      id: 2,
      question: "You need to pass options to a function where order matters and duplicates are possible. What do you use?",
      options: [
        %{id: "a", label: "Map", correct: false, explanation: "Maps don't preserve insertion order and don't allow duplicate keys."},
        %{id: "b", label: "Keyword List", correct: true, explanation: "Keyword lists preserve order, allow duplicate keys, and are the convention for function options in Elixir."},
        %{id: "c", label: "Struct", correct: false, explanation: "Structs require a module definition and don't support arbitrary keys."},
        %{id: "d", label: "Tuple", correct: false, explanation: "Tuples are for fixed-size collections, not for named key-value options."}
      ],
      category: "data_structures"
    },
    %{
      id: 3,
      question: "You need a shared cache that many processes read from frequently but write to rarely. What do you use?",
      options: [
        %{id: "a", label: "GenServer", correct: false, explanation: "GenServer serializes all access through one process. Fine for writes, but a bottleneck for reads."},
        %{id: "b", label: "Agent", correct: false, explanation: "Agent is a simplified GenServer -- still serializes access. Not ideal for read-heavy workloads."},
        %{id: "c", label: "ETS", correct: true, explanation: "ETS provides concurrent, lock-free reads from multiple processes. Perfect for read-heavy shared data."},
        %{id: "d", label: "Process Dictionary", correct: false, explanation: "Process dictionaries are per-process and not shared. Can't be read by other processes."}
      ],
      category: "concurrency"
    },
    %{
      id: 4,
      question: "You need to run a one-off computation concurrently and wait for the result. What do you use?",
      options: [
        %{id: "a", label: "GenServer", correct: false, explanation: "GenServer is for long-running stateful processes. Overkill for a one-off computation."},
        %{id: "b", label: "Task", correct: true, explanation: "Task is designed for one-off concurrent work. Use Task.async/1 + Task.await/1 to run and collect results."},
        %{id: "c", label: "spawn/1", correct: false, explanation: "spawn creates a process but doesn't provide easy result collection or error handling."},
        %{id: "d", label: "Agent", correct: false, explanation: "Agent is for simple shared state, not for concurrent computations."}
      ],
      category: "concurrency"
    },
    %{
      id: 5,
      question: "You need a long-running process that maintains state and handles requests sequentially. What do you use?",
      options: [
        %{id: "a", label: "GenServer", correct: true, explanation: "GenServer is the standard abstraction for stateful, long-running processes that handle synchronous and asynchronous messages."},
        %{id: "b", label: "Task", correct: false, explanation: "Tasks are for short-lived, one-off work. They don't maintain state across requests."},
        %{id: "c", label: "Agent", correct: false, explanation: "Agent works for simple get/update state but lacks the full request handling of GenServer (handle_info, custom protocols, etc)."},
        %{id: "d", label: "ETS", correct: false, explanation: "ETS is a data store, not a process. It doesn't handle requests or run logic."}
      ],
      category: "concurrency"
    },
    %{
      id: 6,
      question: "You need to look up a process by a user-defined name (like a user ID) instead of by PID. What do you use?",
      options: [
        %{id: "a", label: "Registry", correct: true, explanation: "Registry provides name-based process lookup. Use via tuples to register GenServers with custom names."},
        %{id: "b", label: "ETS", correct: false, explanation: "You could manually store PID mappings in ETS, but Registry does this automatically with cleanup on process death."},
        %{id: "c", label: "Agent", correct: false, explanation: "An Agent could store a PID map, but it serializes access and doesn't auto-clean dead processes."},
        %{id: "d", label: "Process.register/2", correct: false, explanation: "Process.register only works with atom names and is limited to one global namespace."}
      ],
      category: "concurrency"
    },
    %{
      id: 7,
      question: "You have workers that come and go at runtime (e.g., one per user session). How do you supervise them?",
      options: [
        %{id: "a", label: "Supervisor", correct: false, explanation: "Regular Supervisors define children at startup. Adding/removing children at runtime is not their design."},
        %{id: "b", label: "DynamicSupervisor", correct: true, explanation: "DynamicSupervisor starts empty and lets you add/remove children at runtime with start_child/2 and terminate_child/2."},
        %{id: "c", label: "Task.Supervisor", correct: false, explanation: "Task.Supervisor is specifically for supervising Tasks, not general GenServer workers."},
        %{id: "d", label: "GenServer", correct: false, explanation: "GenServer is a worker, not a supervisor. It doesn't manage child processes."}
      ],
      category: "concurrency"
    },
    %{
      id: 8,
      question: "You need to dynamically generate functions at compile time based on a list. What do you use?",
      options: [
        %{id: "a", label: "quote/unquote", correct: false, explanation: "quote/unquote are the building blocks, but you need defmacro to actually inject code at compile time."},
        %{id: "b", label: "Macro", correct: true, explanation: "Macros receive AST and return new AST at compile time. Combined with quote/unquote, they generate functions dynamically."},
        %{id: "c", label: "Module.create/3", correct: false, explanation: "Module.create dynamically creates modules at runtime, which is different from compile-time code generation."},
        %{id: "d", label: "Code.eval_string/1", correct: false, explanation: "eval_string works at runtime and is a security risk. Macros are the safe, compile-time approach."}
      ],
      category: "metaprogramming"
    },
    %{
      id: 9,
      question: "You need a key-value data structure where keys can be any type, not just atoms. What do you use?",
      options: [
        %{id: "a", label: "Map", correct: true, explanation: "Maps support any type as keys -- atoms, strings, integers, tuples, etc. They are the general-purpose key-value store."},
        %{id: "b", label: "Keyword List", correct: false, explanation: "Keyword lists only support atom keys."},
        %{id: "c", label: "Struct", correct: false, explanation: "Structs only support atom keys defined at compile time."},
        %{id: "d", label: "Tuple", correct: false, explanation: "Tuples are positional, not key-value. They don't have named keys."}
      ],
      category: "data_structures"
    },
    %{
      id: 10,
      question: "You need simple shared state that only requires get and update operations. What do you use?",
      options: [
        %{id: "a", label: "GenServer", correct: false, explanation: "GenServer works but is more complex than needed for simple get/update state."},
        %{id: "b", label: "Agent", correct: true, explanation: "Agent is a simplified wrapper around GenServer designed exactly for simple state with get/update operations."},
        %{id: "c", label: "ETS", correct: false, explanation: "ETS works but is lower-level. Agent is simpler for basic state management."},
        %{id: "d", label: "Process Dictionary", correct: false, explanation: "Process dictionaries are per-process and generally discouraged for shared state."}
      ],
      category: "concurrency"
    }
  ]

  @decision_trees [
    %{
      id: "data",
      title: "Data Structure Decision Tree",
      nodes: [
        %{question: "Do you need key-value pairs?", yes: 1, no: 5},
        %{question: "Are keys known at compile time and fixed?", yes: 2, no: 3},
        %{question: "Do you need pattern matching and defaults?", yes: "Struct", no: "Map"},
        %{question: "Are keys always atoms?", yes: 4, no: "Map"},
        %{question: "Do you need ordering or duplicate keys?", yes: "Keyword List", no: "Map"},
        %{question: "Is it a fixed-size collection with positions?", yes: "Tuple", no: "List"}
      ]
    },
    %{
      id: "process",
      title: "Process Type Decision Tree",
      nodes: [
        %{question: "Is it a one-off computation?", yes: "Task", no: 1},
        %{question: "Does it need to maintain state?", yes: 2, no: "Task"},
        %{question: "Is the state simple (get/update only)?", yes: "Agent", no: 3},
        %{question: "Does it need custom message handling?", yes: "GenServer", no: "Agent"}
      ]
    },
    %{
      id: "supervisor",
      title: "Supervisor Decision Tree",
      nodes: [
        %{question: "Are children known at startup?", yes: 1, no: "DynamicSupervisor"},
        %{question: "Are children independent of each other?", yes: "Supervisor (:one_for_one)", no: 2},
        %{question: "Do later children depend on earlier ones?", yes: "Supervisor (:rest_for_one)", no: "Supervisor (:one_for_all)"}
      ]
    }
  ]

  @categories [
    %{id: "all", label: "All"},
    %{id: "data_structures", label: "Data Structures"},
    %{id: "concurrency", label: "Concurrency"},
    %{id: "metaprogramming", label: "Metaprogramming"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:current_question_idx, fn -> 0 end)
     |> assign_new(:selected_answer, fn -> nil end)
     |> assign_new(:answered, fn -> false end)
     |> assign_new(:score, fn -> 0 end)
     |> assign_new(:total_answered, fn -> 0 end)
     |> assign_new(:quiz_complete, fn -> false end)
     |> assign_new(:category_filter, fn -> "all" end)
     |> assign_new(:active_tree, fn -> hd(@decision_trees) end)
     |> assign_new(:tree_path, fn -> [0] end)
     |> assign_new(:show_trees, fn -> false end)
     |> assign_new(:show_cheatsheet, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">The Elixir Toolbox</h2>
      <p class="text-sm opacity-70 mb-6">
        Knowing which tool to reach for is as important as knowing how each tool works. This kata
        tests your ability to <strong>choose the right tool</strong> for different scenarios.
      </p>

      <!-- Decision Tree Quiz -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Decision Quiz</h3>
            <div class="flex items-center gap-2">
              <span class="badge badge-primary">
                Score: <%= @score %>/<%= @total_answered %>
              </span>
              <span class="text-xs opacity-50">
                Question <%= @current_question_idx + 1 %>/<%= length(filtered_questions(@category_filter)) %>
              </span>
            </div>
          </div>

          <!-- Category Filter -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for cat <- categories() do %>
              <button
                phx-click="filter_category"
                phx-target={@myself}
                phx-value-id={cat.id}
                class={"btn btn-xs " <> if(@category_filter == cat.id, do: "btn-primary", else: "btn-ghost")}
              >
                <%= cat.label %>
              </button>
            <% end %>
          </div>

          <%= if @quiz_complete do %>
            <!-- Quiz Complete -->
            <div class="text-center py-8">
              <div class="text-4xl font-bold mb-2">
                <%= @score %>/<%= @total_answered %>
              </div>
              <div class="text-sm opacity-70 mb-4">
                <%= cond do %>
                  <% @total_answered == 0 -> %>
                    No questions answered yet.
                  <% @score == @total_answered -> %>
                    Perfect score! You know your Elixir toolbox well.
                  <% @score >= @total_answered * 0.7 -> %>
                    Great job! You have a solid understanding of Elixir's tools.
                  <% @score >= @total_answered * 0.5 -> %>
                    Good start! Review the areas where you missed.
                  <% true -> %>
                    Keep practicing! Review the previous katas for each topic.
                <% end %>
              </div>
              <button
                phx-click="restart_quiz"
                phx-target={@myself}
                class="btn btn-primary btn-sm"
              >
                Restart Quiz
              </button>
            </div>
          <% else %>
            <!-- Current Question -->
            <% questions = filtered_questions(@category_filter) %>
            <% question = Enum.at(questions, @current_question_idx) %>
            <%= if question do %>
              <div class="mb-4">
                <div class="flex items-center gap-2 mb-3">
                  <span class={"badge badge-sm " <> category_badge_class(question.category)}>
                    <%= category_label(question.category) %>
                  </span>
                </div>
                <p class="text-sm font-bold mb-4"><%= question.question %></p>

                <!-- Options -->
                <div class="space-y-2">
                  <%= for option <- question.options do %>
                    <button
                      phx-click="select_answer"
                      phx-target={@myself}
                      phx-value-id={option.id}
                      disabled={@answered}
                      class={"w-full text-left rounded-lg p-3 border-2 transition-all " <>
                        cond do
                          @answered && option.correct -> "border-success bg-success/15"
                          @answered && @selected_answer == option.id && !option.correct -> "border-error bg-error/15"
                          @answered -> "border-base-300 bg-base-100 opacity-40"
                          true -> "border-base-300 bg-base-100 hover:border-primary cursor-pointer"
                        end}
                    >
                      <div class="flex items-center gap-3">
                        <span class={"w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold border-2 " <>
                          cond do
                            @answered && option.correct -> "border-success bg-success text-success-content"
                            @answered && @selected_answer == option.id && !option.correct -> "border-error bg-error text-error-content"
                            true -> "border-base-300"
                          end}>
                          <%= String.upcase(option.id) %>
                        </span>
                        <span class="text-sm font-bold"><%= option.label %></span>
                      </div>

                      <%= if @answered do %>
                        <div class="mt-2 ml-10 text-xs opacity-70"><%= option.explanation %></div>
                      <% end %>
                    </button>
                  <% end %>
                </div>
              </div>

              <!-- Next Button -->
              <%= if @answered do %>
                <div class="flex justify-end">
                  <button
                    phx-click="next_question"
                    phx-target={@myself}
                    class="btn btn-primary btn-sm"
                  >
                    <%= if @current_question_idx + 1 >= length(questions), do: "See Results", else: "Next Question" %>
                  </button>
                </div>
              <% end %>
            <% end %>
          <% end %>
        </div>
      </div>

      <!-- Interactive Decision Trees -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Decision Flowcharts</h3>
            <button
              phx-click="toggle_trees"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_trees, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_trees do %>
            <!-- Tree Selector -->
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for tree <- decision_trees() do %>
                <button
                  phx-click="select_tree"
                  phx-target={@myself}
                  phx-value-id={tree.id}
                  class={"btn btn-sm " <> if(@active_tree.id == tree.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= tree.title %>
                </button>
              <% end %>
            </div>

            <!-- Interactive Tree Navigation -->
            <div class="space-y-3">
              <%= for step_idx <- @tree_path do %>
                <% node = Enum.at(@active_tree.nodes, step_idx) %>
                <%= if node do %>
                  <div class="bg-base-100 rounded-lg p-4 border-2 border-primary">
                    <p class="text-sm font-bold mb-3"><%= node.question %></p>
                    <div class="flex gap-3">
                      <button
                        phx-click="tree_answer"
                        phx-target={@myself}
                        phx-value-answer="yes"
                        phx-value-step={step_idx}
                        class="btn btn-sm btn-success btn-outline"
                      >
                        Yes
                      </button>
                      <button
                        phx-click="tree_answer"
                        phx-target={@myself}
                        phx-value-answer="no"
                        phx-value-step={step_idx}
                        class="btn btn-sm btn-error btn-outline"
                      >
                        No
                      </button>
                    </div>
                  </div>
                <% end %>
              <% end %>

              <!-- Show result if we've reached a leaf -->
              <% last_step = List.last(@tree_path) %>
              <%= if is_binary(last_step) do %>
                <div class="bg-success/15 border-2 border-success rounded-lg p-4 text-center">
                  <div class="text-xs opacity-60 mb-1">Recommended tool:</div>
                  <div class="text-lg font-bold text-success"><%= last_step %></div>
                </div>
              <% end %>

              <button
                phx-click="reset_tree"
                phx-target={@myself}
                class="btn btn-ghost btn-xs"
              >
                Reset Flowchart
              </button>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Cheatsheet -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Quick Reference Cheatsheet</h3>
            <button
              phx-click="toggle_cheatsheet"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_cheatsheet, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_cheatsheet do %>
            <div class="space-y-6">
              <!-- Data Structures -->
              <div>
                <h4 class="font-bold text-sm mb-2 text-primary">Data Structures</h4>
                <div class="overflow-x-auto">
                  <table class="table table-xs">
                    <thead>
                      <tr>
                        <th>Tool</th>
                        <th>Keys</th>
                        <th>Duplicates?</th>
                        <th>Best For</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr><td class="font-mono font-bold">Map</td><td>Any type</td><td>No</td><td>General key-value storage</td></tr>
                      <tr><td class="font-mono font-bold">Keyword List</td><td>Atoms only</td><td>Yes</td><td>Function options, ordered pairs</td></tr>
                      <tr><td class="font-mono font-bold">Struct</td><td>Atoms (fixed)</td><td>No</td><td>Typed data with defaults</td></tr>
                      <tr><td class="font-mono font-bold">Tuple</td><td>Positional</td><td>N/A</td><td>Fixed-size grouped values</td></tr>
                      <tr><td class="font-mono font-bold">List</td><td>N/A</td><td>Yes</td><td>Variable-length sequences</td></tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <!-- Process Types -->
              <div>
                <h4 class="font-bold text-sm mb-2 text-primary">Process Types</h4>
                <div class="overflow-x-auto">
                  <table class="table table-xs">
                    <thead>
                      <tr>
                        <th>Tool</th>
                        <th>Lifetime</th>
                        <th>State?</th>
                        <th>Best For</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr><td class="font-mono font-bold">Task</td><td>Short</td><td>No</td><td>One-off concurrent work</td></tr>
                      <tr><td class="font-mono font-bold">Agent</td><td>Long</td><td>Simple</td><td>Get/update shared state</td></tr>
                      <tr><td class="font-mono font-bold">GenServer</td><td>Long</td><td>Complex</td><td>Stateful services, custom protocols</td></tr>
                      <tr><td class="font-mono font-bold">ETS</td><td>Owner-bound</td><td>Table</td><td>Read-heavy shared cache</td></tr>
                    </tbody>
                  </table>
                </div>
              </div>

              <!-- Supervisors -->
              <div>
                <h4 class="font-bold text-sm mb-2 text-primary">Supervision</h4>
                <div class="overflow-x-auto">
                  <table class="table table-xs">
                    <thead>
                      <tr>
                        <th>Tool</th>
                        <th>Children</th>
                        <th>Strategy</th>
                        <th>Best For</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr><td class="font-mono font-bold">Supervisor</td><td>Fixed at start</td><td>1:1, 1:all, rest:1</td><td>Known, fixed services</td></tr>
                      <tr><td class="font-mono font-bold">DynamicSupervisor</td><td>Added at runtime</td><td>1:1 only</td><td>On-demand workers</td></tr>
                      <tr><td class="font-mono font-bold">Task.Supervisor</td><td>Tasks</td><td>1:1</td><td>Supervised async tasks</td></tr>
                      <tr><td class="font-mono font-bold">Registry</td><td>N/A</td><td>N/A</td><td>Process lookup by name</td></tr>
                    </tbody>
                  </table>
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
              <span><strong>Map vs Keyword List vs Struct:</strong> Map for general key-value, Keyword List for options with atom keys, Struct for typed data with validation.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>GenServer vs Agent vs ETS:</strong> GenServer for complex stateful logic, Agent for simple state, ETS for read-heavy shared data.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Process vs Task vs GenServer:</strong> Task for one-off work, GenServer for long-running services, bare processes for low-level needs.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Supervisor vs DynamicSupervisor:</strong> Supervisor for fixed children known at startup, DynamicSupervisor for on-demand workers.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Functions vs Macros:</strong> Always prefer functions. Only use macros when you need compile-time code generation or transformation.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("filter_category", %{"id" => id}, socket) do
    {:noreply,
     socket
     |> assign(category_filter: id)
     |> assign(current_question_idx: 0)
     |> assign(selected_answer: nil)
     |> assign(answered: false)
     |> assign(score: 0)
     |> assign(total_answered: 0)
     |> assign(quiz_complete: false)}
  end

  def handle_event("select_answer", %{"id" => id}, socket) do
    questions = filtered_questions(socket.assigns.category_filter)
    question = Enum.at(questions, socket.assigns.current_question_idx)
    option = Enum.find(question.options, &(&1.id == id))
    correct = option.correct

    {:noreply,
     socket
     |> assign(selected_answer: id)
     |> assign(answered: true)
     |> assign(score: socket.assigns.score + if(correct, do: 1, else: 0))
     |> assign(total_answered: socket.assigns.total_answered + 1)}
  end

  def handle_event("next_question", _params, socket) do
    questions = filtered_questions(socket.assigns.category_filter)
    next_idx = socket.assigns.current_question_idx + 1

    if next_idx >= length(questions) do
      {:noreply, assign(socket, quiz_complete: true)}
    else
      {:noreply,
       socket
       |> assign(current_question_idx: next_idx)
       |> assign(selected_answer: nil)
       |> assign(answered: false)}
    end
  end

  def handle_event("restart_quiz", _params, socket) do
    {:noreply,
     socket
     |> assign(current_question_idx: 0)
     |> assign(selected_answer: nil)
     |> assign(answered: false)
     |> assign(score: 0)
     |> assign(total_answered: 0)
     |> assign(quiz_complete: false)}
  end

  def handle_event("toggle_trees", _params, socket) do
    {:noreply, assign(socket, show_trees: !socket.assigns.show_trees)}
  end

  def handle_event("select_tree", %{"id" => id}, socket) do
    tree = Enum.find(decision_trees(), &(&1.id == id))
    {:noreply, assign(socket, active_tree: tree, tree_path: [0])}
  end

  def handle_event("tree_answer", %{"answer" => answer, "step" => step_str}, socket) do
    step = String.to_integer(step_str)
    node = Enum.at(socket.assigns.active_tree.nodes, step)

    next = if answer == "yes", do: node.yes, else: node.no

    # Remove any steps after the current one (in case user goes back)
    current_path = Enum.take_while(socket.assigns.tree_path, fn s -> s != step end) ++ [step]

    new_path =
      if is_integer(next) do
        current_path ++ [next]
      else
        # It's a string result (leaf node)
        current_path ++ [next]
      end

    {:noreply, assign(socket, tree_path: new_path)}
  end

  def handle_event("reset_tree", _params, socket) do
    {:noreply, assign(socket, tree_path: [0])}
  end

  def handle_event("toggle_cheatsheet", _params, socket) do
    {:noreply, assign(socket, show_cheatsheet: !socket.assigns.show_cheatsheet)}
  end

  # Helpers

  defp categories, do: @categories
  defp decision_trees, do: @decision_trees

  defp filtered_questions("all"), do: @quiz_questions
  defp filtered_questions(cat) do
    Enum.filter(@quiz_questions, &(&1.category == cat))
  end

  defp category_label("data_structures"), do: "Data Structures"
  defp category_label("concurrency"), do: "Concurrency"
  defp category_label("metaprogramming"), do: "Metaprogramming"
  defp category_label(_), do: "General"

  defp category_badge_class("data_structures"), do: "badge-info"
  defp category_badge_class("concurrency"), do: "badge-warning"
  defp category_badge_class("metaprogramming"), do: "badge-accent"
  defp category_badge_class(_), do: "badge-ghost"
end
