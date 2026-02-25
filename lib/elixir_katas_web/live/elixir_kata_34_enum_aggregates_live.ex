defmodule ElixirKatasWeb.ElixirKata34EnumAggregatesLive do
  use ElixirKatasWeb, :live_component

  @aggregates [
    %{
      id: "count",
      title: "Enum.count/1,2",
      description: "Returns the number of elements, optionally filtered by a predicate.",
      examples: [
        %{code: "Enum.count([1, 2, 3, 4, 5])", result: "5", label: "Count all"},
        %{code: "Enum.count([1, 2, 3, 4, 5, 6], &(rem(&1, 2) == 0))", result: "3", label: "Count evens"},
        %{code: "Enum.count([])", result: "0", label: "Empty list"}
      ]
    },
    %{
      id: "sum",
      title: "Enum.sum/1",
      description: "Sums all numeric elements in the enumerable.",
      examples: [
        %{code: "Enum.sum([1, 2, 3, 4, 5])", result: "15", label: "Sum integers"},
        %{code: "Enum.sum(1..100)", result: "5050", label: "Sum a range"},
        %{code: "Enum.sum([1.5, 2.5, 3.0])", result: "7.0", label: "Sum floats"}
      ]
    },
    %{
      id: "min_max",
      title: "Enum.min/max",
      description: "Find the minimum or maximum element. Use min_by/max_by for custom comparison.",
      examples: [
        %{code: "Enum.min([5, 3, 8, 1, 9])", result: "1", label: "Min"},
        %{code: "Enum.max([5, 3, 8, 1, 9])", result: "9", label: "Max"},
        %{code: "Enum.min_max([5, 3, 8, 1, 9])", result: "{1, 9}", label: "Both at once"},
        %{code: ~s|Enum.max_by(["hi", "hello", "hey"], &String.length/1)|, result: ~s|"hello"|, label: "Max by length"}
      ]
    },
    %{
      id: "frequencies",
      title: "Enum.frequencies/1",
      description: "Counts how many times each value appears. Returns a map of value => count.",
      examples: [
        %{code: ~s|Enum.frequencies(["a", "b", "a", "c", "b", "a"])|, result: ~s|%{"a" => 3, "b" => 2, "c" => 1}|, label: "Letter frequency"},
        %{code: "Enum.frequencies([1, 2, 2, 3, 3, 3])", result: "%{1 => 1, 2 => 2, 3 => 3}", label: "Number frequency"},
        %{code: ~s|Enum.frequencies_by(["apple", "avocado", "banana", "blueberry"], &String.first/1)|, result: ~s|%{"a" => 2, "b" => 2}|, label: "By first letter"}
      ]
    },
    %{
      id: "group_by",
      title: "Enum.group_by/2,3",
      description: "Groups elements by a key function. Returns a map of key => [elements].",
      examples: [
        %{code: "Enum.group_by([1, 2, 3, 4, 5, 6], &(rem(&1, 2) == 0))", result: "%{false => [1, 3, 5], true => [2, 4, 6]}", label: "Even/Odd"},
        %{code: ~s|Enum.group_by(["ant", "bear", "cat", "ape", "bee"], &String.first/1)|, result: ~s|%{"a" => ["ant", "ape"], "b" => ["bear", "bee"], "c" => ["cat"]}|, label: "By first letter"},
        %{code: "Enum.group_by(1..10, &div(&1, 3))", result: "%{0 => [1, 2], 1 => [3, 4, 5], 2 => [6, 7, 8], 3 => [9, 10]}", label: "By integer division"}
      ]
    }
  ]

  @sample_data [
    %{name: "Alice", department: "Engineering", salary: 95_000, years: 5},
    %{name: "Bob", department: "Engineering", salary: 88_000, years: 3},
    %{name: "Carol", department: "Design", salary: 82_000, years: 4},
    %{name: "Dave", department: "Design", salary: 78_000, years: 2},
    %{name: "Eve", department: "Marketing", salary: 72_000, years: 6},
    %{name: "Frank", department: "Marketing", salary: 68_000, years: 1},
    %{name: "Grace", department: "Engineering", salary: 105_000, years: 8}
  ]

  @analysis_queries [
    %{id: "total_salary", label: "Total Salary", description: "Sum of all salaries"},
    %{id: "avg_salary", label: "Average Salary", description: "Mean salary across all employees"},
    %{id: "by_dept", label: "Group by Dept", description: "Employees grouped by department"},
    %{id: "dept_count", label: "Dept Count", description: "Number of employees per department"},
    %{id: "highest_paid", label: "Highest Paid", description: "Employee with the highest salary"},
    %{id: "senior", label: "Senior Staff", description: "Employees with 4+ years experience"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_agg, fn -> hd(@aggregates) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:active_query, fn -> nil end)
     |> assign_new(:query_result, fn -> nil end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)
     |> assign_new(:show_data_table, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Enum Aggregates</h2>
      <p class="text-sm opacity-70 mb-6">
        Aggregation functions collapse collections into summary values: counts, sums,
        extremes, frequencies, and groupings. These are the workhorses of data analysis in Elixir.
      </p>

      <!-- Aggregate Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for agg <- aggregates() do %>
          <button
            phx-click="select_agg"
            phx-target={@myself}
            phx-value-id={agg.id}
            class={"btn btn-sm " <> if(@active_agg.id == agg.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= agg.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Aggregate Display -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-1"><%= @active_agg.title %></h3>
          <p class="text-xs opacity-60 mb-3"><%= @active_agg.description %></p>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(@active_agg.examples) do %>
              <button
                phx-click="select_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"btn btn-xs " <> if(idx == @active_example_idx, do: "btn-accent", else: "btn-ghost")}
              >
                <%= example.label %>
              </button>
            <% end %>
          </div>

          <!-- Selected Example -->
          <% example = Enum.at(@active_agg.examples, @active_example_idx) %>
          <div class="bg-base-300 rounded-lg p-3 font-mono text-sm">
            <span class="opacity-50">iex&gt; </span><%= example.code %>
            <div class="text-success font-bold mt-1"><%= example.result %></div>
          </div>

          <!-- Visual for frequencies -->
          <%= if @active_agg.id == "frequencies" and @active_example_idx == 0 do %>
            <div class="mt-4">
              <h4 class="text-xs font-bold opacity-60 mb-2">Visual frequency count:</h4>
              <div class="space-y-1">
                <%= for {letter, count} <- [{"a", 3}, {"b", 2}, {"c", 1}] do %>
                  <div class="flex items-center gap-2">
                    <span class="font-mono text-sm w-8 text-info font-bold"><%= letter %></span>
                    <div class="flex gap-1">
                      <%= for _i <- 1..count do %>
                        <div class="w-6 h-6 bg-primary rounded flex items-center justify-center text-primary-content text-xs font-bold">
                          <%= letter %>
                        </div>
                      <% end %>
                    </div>
                    <span class="text-xs opacity-50"><%= count %></span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>

          <!-- Visual for group_by -->
          <%= if @active_agg.id == "group_by" and @active_example_idx == 0 do %>
            <div class="mt-4">
              <h4 class="text-xs font-bold opacity-60 mb-2">Visual grouping:</h4>
              <div class="grid grid-cols-2 gap-3">
                <div class="bg-error/10 border border-error/30 rounded-lg p-3">
                  <div class="text-xs font-bold text-error mb-2">Odd (false)</div>
                  <div class="flex flex-wrap gap-1">
                    <%= for n <- [1, 3, 5] do %>
                      <span class="badge badge-error badge-sm font-mono"><%= n %></span>
                    <% end %>
                  </div>
                </div>
                <div class="bg-success/10 border border-success/30 rounded-lg p-3">
                  <div class="text-xs font-bold text-success mb-2">Even (true)</div>
                  <div class="flex flex-wrap gap-1">
                    <%= for n <- [2, 4, 6] do %>
                      <span class="badge badge-success badge-sm font-mono"><%= n %></span>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Data Analysis Example -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Data Analysis: Employee Records</h3>
            <button
              phx-click="toggle_data_table"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_data_table, do: "Hide Data", else: "Show Data" %>
            </button>
          </div>

          <%= if @show_data_table do %>
            <div class="overflow-x-auto mb-4">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Name</th>
                    <th>Department</th>
                    <th>Salary</th>
                    <th>Years</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for emp <- sample_data() do %>
                    <tr>
                      <td><%= emp.name %></td>
                      <td><span class="badge badge-sm badge-outline"><%= emp.department %></span></td>
                      <td class="font-mono">$<%= format_number(emp.salary) %></td>
                      <td><%= emp.years %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>

          <p class="text-xs opacity-60 mb-4">
            Click a query to analyze the employee dataset using Enum aggregate functions.
          </p>

          <!-- Query Buttons -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for query <- analysis_queries() do %>
              <button
                phx-click="run_query"
                phx-target={@myself}
                phx-value-id={query.id}
                class={"btn btn-sm " <> if(@active_query == query.id, do: "btn-accent", else: "btn-outline")}
                title={query.description}
              >
                <%= query.label %>
              </button>
            <% end %>
          </div>

          <!-- Query Result -->
          <%= if @query_result do %>
            <div class="bg-base-300 rounded-lg p-4">
              <div class="text-xs font-bold opacity-60 mb-2"><%= @query_result.description %></div>
              <div class="font-mono text-sm mb-3 whitespace-pre-wrap text-info"><%= @query_result.code %></div>
              <div class="bg-success/10 border border-success/30 rounded-lg p-3">
                <div class="font-mono text-sm text-success font-bold whitespace-pre-wrap"><%= @query_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try It Yourself -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Try It Yourself</h3>

          <form phx-submit="sandbox_eval" phx-target={@myself} class="flex gap-2 items-end mb-4">
            <div class="form-control flex-1">
              <input
                type="text"
                name="code"
                value={@sandbox_code}
                placeholder="Enum.frequencies([1, 2, 2, 3, 3, 3])"
                class="input input-bordered input-sm font-mono w-full"
                autocomplete="off"
              />
            </div>
            <button type="submit" class="btn btn-primary btn-sm">Run</button>
          </form>

          <%= if @sandbox_result do %>
            <div class={"alert text-sm " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @sandbox_result.code %></div>
                <div class="font-mono font-bold mt-1"><%= @sandbox_result.output %></div>
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
              <span><strong>count</strong> returns the total number of elements (or elements matching a predicate).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>sum</strong> adds all numeric elements. For other aggregations, use <code class="font-mono bg-base-100 px-1 rounded">reduce</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>min/max</strong> find extremes. Use <code class="font-mono bg-base-100 px-1 rounded">min_by/max_by</code> with a key function for complex data.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>frequencies</strong> counts occurrences of each value. <code class="font-mono bg-base-100 px-1 rounded">frequencies_by</code> uses a key function.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>group_by</strong> partitions elements by a key function, returning a map of key =&gt; [elements].</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">6</span>
              <span>Aggregates collapse a collection into a <strong>summary</strong>. They are the final step in many data pipelines.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_agg", %{"id" => id}, socket) do
    agg = Enum.find(aggregates(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_agg: agg)
     |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, active_example_idx: idx)}
  end

  def handle_event("toggle_data_table", _params, socket) do
    {:noreply, assign(socket, show_data_table: !socket.assigns.show_data_table)}
  end

  def handle_event("run_query", %{"id" => id}, socket) do
    result = run_analysis_query(id)
    {:noreply, assign(socket, active_query: id, query_result: result)}
  end

  def handle_event("sandbox_eval", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp aggregates, do: @aggregates
  defp sample_data, do: @sample_data
  defp analysis_queries, do: @analysis_queries

  defp run_analysis_query("total_salary") do
    total = @sample_data |> Enum.map(& &1.salary) |> Enum.sum()

    %{
      description: "Sum of all employee salaries",
      code: "employees\n|> Enum.map(& &1.salary)\n|> Enum.sum()",
      output: "$#{format_number(total)}"
    }
  end

  defp run_analysis_query("avg_salary") do
    salaries = Enum.map(@sample_data, & &1.salary)
    avg = Enum.sum(salaries) / Enum.count(salaries)

    %{
      description: "Average salary across all employees",
      code: "salaries = Enum.map(employees, & &1.salary)\nEnum.sum(salaries) / Enum.count(salaries)",
      output: "$#{format_number(round(avg))}"
    }
  end

  defp run_analysis_query("by_dept") do
    grouped = Enum.group_by(@sample_data, & &1.department, & &1.name)

    output =
      grouped
      |> Enum.map(fn {dept, names} -> "#{dept}: #{Enum.join(names, ", ")}" end)
      |> Enum.join("\n")

    %{
      description: "Employees grouped by department",
      code: "Enum.group_by(employees, & &1.department, & &1.name)",
      output: output
    }
  end

  defp run_analysis_query("dept_count") do
    counts = @sample_data |> Enum.frequencies_by(& &1.department)

    output =
      counts
      |> Enum.sort_by(fn {_, count} -> count end, :desc)
      |> Enum.map(fn {dept, count} -> "#{dept}: #{count} employees" end)
      |> Enum.join("\n")

    %{
      description: "Number of employees per department",
      code: "Enum.frequencies_by(employees, & &1.department)",
      output: output
    }
  end

  defp run_analysis_query("highest_paid") do
    emp = Enum.max_by(@sample_data, & &1.salary)

    %{
      description: "Employee with the highest salary",
      code: "Enum.max_by(employees, & &1.salary)",
      output: "#{emp.name} (#{emp.department}) - $#{format_number(emp.salary)}"
    }
  end

  defp run_analysis_query("senior") do
    seniors = Enum.filter(@sample_data, &(&1.years >= 4))

    output =
      seniors
      |> Enum.map(fn e -> "#{e.name} (#{e.years} years)" end)
      |> Enum.join(", ")

    %{
      description: "Employees with 4+ years experience",
      code: "Enum.filter(employees, & &1.years >= 4)",
      output: "#{length(seniors)} found: #{output}"
    }
  end

  defp run_analysis_query(_), do: nil

  defp format_number(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp format_number(n), do: to_string(n)

  defp evaluate_code(code) do
    code = String.trim(code)

    if code == "" do
      nil
    else
      try do
        {result, _bindings} = Code.eval_string(code)
        %{ok: true, code: code, output: inspect(result, pretty: true, limit: 50)}
      rescue
        e ->
          %{ok: false, code: code, output: "Error: #{Exception.message(e)}"}
      end
    end
  end
end
