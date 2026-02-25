defmodule ElixirKatasWeb.ElixirKata79DateTimeLive do
  use ElixirKatasWeb, :live_component

  @type_tabs [
    %{
      id: "date",
      title: "Date",
      description: "A calendar date without time or timezone. Use for birthdays, deadlines, and date-only data.",
      examples: [
        %{
          label: "~D sigil",
          code: "~D[2024-03-15]",
          result: "~D[2024-03-15]",
          note: "The ~D sigil creates a Date struct at compile time"
        },
        %{
          label: "Date.utc_today/0",
          code: "Date.utc_today()",
          result: "(current date)",
          note: "Returns today's date in UTC"
        },
        %{
          label: "Fields",
          code: "date = ~D[2024-03-15]\n{date.year, date.month, date.day}",
          result: "{2024, 3, 15}",
          note: "Access individual fields directly"
        },
        %{
          label: "Day of week",
          code: "Date.day_of_week(~D[2024-03-15])",
          result: "5  (Friday)",
          note: "Returns 1 (Monday) through 7 (Sunday) -- ISO 8601"
        }
      ]
    },
    %{
      id: "time",
      title: "Time",
      description: "A time of day without date or timezone. Use for schedules and time-only values.",
      examples: [
        %{
          label: "~T sigil",
          code: "~T[14:30:00]",
          result: "~T[14:30:00]",
          note: "The ~T sigil creates a Time struct"
        },
        %{
          label: "With microseconds",
          code: "~T[14:30:00.000123]",
          result: "~T[14:30:00.000123]",
          note: "Time supports microsecond precision"
        },
        %{
          label: "Fields",
          code: "t = ~T[14:30:45]\n{t.hour, t.minute, t.second}",
          result: "{14, 30, 45}",
          note: "Access hour, minute, second fields directly"
        },
        %{
          label: "Comparison",
          code: "Time.compare(~T[09:00:00], ~T[17:00:00])",
          result: ":lt",
          note: "Returns :lt, :eq, or :gt"
        }
      ]
    },
    %{
      id: "naive_datetime",
      title: "NaiveDateTime",
      description: "A date and time WITHOUT timezone. Called 'naive' because it doesn't know which timezone it's in.",
      examples: [
        %{
          label: "~N sigil",
          code: "~N[2024-03-15 14:30:00]",
          result: "~N[2024-03-15 14:30:00]",
          note: "The ~N sigil creates a NaiveDateTime -- no timezone info"
        },
        %{
          label: "local_now/0",
          code: "NaiveDateTime.local_now()",
          result: "(current local datetime)",
          note: "Returns the current local datetime (no timezone attached)"
        },
        %{
          label: "From Date + Time",
          code: "NaiveDateTime.new(~D[2024-03-15], ~T[14:30:00])",
          result: "{:ok, ~N[2024-03-15 14:30:00]}",
          note: "Combine a Date and Time into a NaiveDateTime"
        },
        %{
          label: "Add seconds",
          code: "NaiveDateTime.add(~N[2024-03-15 14:30:00], 3600)",
          result: "~N[2024-03-15 15:30:00]",
          note: "Add seconds (3600 = 1 hour)"
        }
      ]
    },
    %{
      id: "datetime",
      title: "DateTime",
      description: "A date and time WITH timezone. The only type safe for cross-timezone operations.",
      examples: [
        %{
          label: "~U sigil",
          code: "~U[2024-03-15 14:30:00Z]",
          result: "~U[2024-03-15 14:30:00Z]",
          note: "The ~U sigil creates a UTC DateTime (Z = UTC)"
        },
        %{
          label: "utc_now/0",
          code: "DateTime.utc_now()",
          result: "(current UTC datetime)",
          note: "Returns the current UTC datetime with timezone info"
        },
        %{
          label: "Unix timestamp",
          code: "DateTime.utc_now() |> DateTime.to_unix()",
          result: "(unix timestamp)",
          note: "Convert to seconds since Unix epoch (1970-01-01)"
        },
        %{
          label: "From Unix",
          code: "DateTime.from_unix(1_700_000_000)",
          result: "{:ok, ~U[2023-11-14 22:13:20Z]}",
          note: "Convert back from Unix timestamp"
        }
      ]
    }
  ]

  @format_presets [
    %{label: "ISO 8601", format: "%Y-%m-%dT%H:%M:%SZ"},
    %{label: "US Date", format: "%m/%d/%Y"},
    %{label: "EU Date", format: "%d/%m/%Y"},
    %{label: "Long", format: "%B %d, %Y"},
    %{label: "Time only", format: "%H:%M:%S"},
    %{label: "12-hour", format: "%I:%M %p"},
    %{label: "Day + Date", format: "%A, %B %d"},
    %{label: "Short", format: "%b %d, %y"}
  ]

  @day_names %{
    1 => "Monday",
    2 => "Tuesday",
    3 => "Wednesday",
    4 => "Thursday",
    5 => "Friday",
    6 => "Saturday",
    7 => "Sunday"
  }

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_type_tab, fn -> "date" end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:now, fn -> DateTime.utc_now() end)
     |> assign_new(:date_a_input, fn -> Date.utc_today() |> Date.to_iso8601() end)
     |> assign_new(:date_b_input, fn -> Date.utc_today() |> Date.add(30) |> Date.to_iso8601() end)
     |> assign_new(:calc_result, fn -> nil end)
     |> assign_new(:format_string, fn -> "%Y-%m-%d %H:%M:%S" end)
     |> assign_new(:format_result, fn -> nil end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Date &amp; Time</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir provides four date/time types: <strong>Date</strong>, <strong>Time</strong>,
        <strong>NaiveDateTime</strong>, and <strong>DateTime</strong>. Each serves a different purpose
        depending on whether you need timezone awareness.
      </p>

      <!-- ===== Section 1: Type Explorer ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Type Explorer</h3>

          <div class="flex flex-wrap gap-2 mb-4">
            <%= for tab <- type_tabs() do %>
              <button
                phx-click="select_type_tab"
                phx-target={@myself}
                phx-value-id={tab.id}
                class={"btn btn-sm " <> if(@active_type_tab == tab.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= tab.title %>
              </button>
            <% end %>
          </div>

          <% tab = Enum.find(type_tabs(), &(&1.id == @active_type_tab)) %>
          <p class="text-xs opacity-60 mb-4"><%= tab.description %></p>

          <!-- Example sub-tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(tab.examples) do %>
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

          <% example = Enum.at(tab.examples, min(@active_example_idx, length(tab.examples) - 1)) %>
          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= example.code %></div>
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold"><%= example.result %></div>
            </div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Note</div>
              <div class="text-sm"><%= example.note %></div>
            </div>
          </div>

          <!-- Type comparison table -->
          <div class="mt-4 overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Type</th>
                  <th>Sigil</th>
                  <th>Has Date?</th>
                  <th>Has Time?</th>
                  <th>Has TZ?</th>
                  <th>Use For</th>
                </tr>
              </thead>
              <tbody>
                <tr class={if(@active_type_tab == "date", do: "bg-primary/10", else: "")}>
                  <td class="font-mono font-bold">Date</td>
                  <td class="font-mono">~D</td>
                  <td>Yes</td>
                  <td>No</td>
                  <td>No</td>
                  <td class="text-xs">Birthdays, deadlines</td>
                </tr>
                <tr class={if(@active_type_tab == "time", do: "bg-primary/10", else: "")}>
                  <td class="font-mono font-bold">Time</td>
                  <td class="font-mono">~T</td>
                  <td>No</td>
                  <td>Yes</td>
                  <td>No</td>
                  <td class="text-xs">Schedules, alarms</td>
                </tr>
                <tr class={if(@active_type_tab == "naive_datetime", do: "bg-primary/10", else: "")}>
                  <td class="font-mono font-bold">NaiveDateTime</td>
                  <td class="font-mono">~N</td>
                  <td>Yes</td>
                  <td>Yes</td>
                  <td>No</td>
                  <td class="text-xs">Local events, logs</td>
                </tr>
                <tr class={if(@active_type_tab == "datetime", do: "bg-primary/10", else: "")}>
                  <td class="font-mono font-bold">DateTime</td>
                  <td class="font-mono">~U</td>
                  <td>Yes</td>
                  <td>Yes</td>
                  <td>Yes</td>
                  <td class="text-xs">APIs, scheduling across TZs</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- ===== Section 2: Live Clock (Refresh Button) ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Current DateTime (UTC)</h3>
          <p class="text-xs opacity-60 mb-4">
            Click Refresh to update the current time. Shows the live DateTime.utc_now() value.
          </p>

          <div class="bg-base-300 rounded-lg p-6 text-center mb-4">
            <div class="font-mono text-2xl font-bold mb-2">
              <%= Calendar.strftime(@now, "%H:%M:%S") %>
            </div>
            <div class="font-mono text-sm opacity-60">
              <%= Calendar.strftime(@now, "%A, %B %d, %Y") %>
            </div>
            <div class="font-mono text-xs opacity-40 mt-1">
              <%= DateTime.to_iso8601(@now) %>
            </div>
          </div>

          <div class="flex flex-wrap gap-3 justify-center mb-4">
            <button phx-click="refresh_now" phx-target={@myself} class="btn btn-primary btn-sm">
              Refresh Now
            </button>
          </div>

          <div class="grid grid-cols-2 md:grid-cols-4 gap-3">
            <div class="bg-base-300 rounded-lg p-3 text-center">
              <div class="text-xs opacity-60">Unix Timestamp</div>
              <div class="font-mono text-sm font-bold"><%= DateTime.to_unix(@now) %></div>
            </div>
            <div class="bg-base-300 rounded-lg p-3 text-center">
              <div class="text-xs opacity-60">Day of Year</div>
              <div class="font-mono text-sm font-bold"><%= Date.day_of_year(DateTime.to_date(@now)) %></div>
            </div>
            <div class="bg-base-300 rounded-lg p-3 text-center">
              <div class="text-xs opacity-60">Day of Week</div>
              <div class="font-mono text-sm font-bold"><%= day_name(Date.day_of_week(DateTime.to_date(@now))) %></div>
            </div>
            <div class="bg-base-300 rounded-lg p-3 text-center">
              <div class="text-xs opacity-60">Days Left in Year</div>
              <div class="font-mono text-sm font-bold"><%= days_left_in_year(@now) %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== Section 3: Date Calculator ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Date Calculator</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter two dates (ISO 8601 format) to see the difference, range, and day of week.
          </p>

          <form phx-change="update_dates" phx-target={@myself} class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Date A</span></label>
              <input
                type="date"
                name="date_a"
                value={@date_a_input}
                class="input input-bordered input-sm font-mono"
              />
            </div>
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Date B</span></label>
              <input
                type="date"
                name="date_b"
                value={@date_b_input}
                class="input input-bordered input-sm font-mono"
              />
            </div>
          </form>

          <button phx-click="calculate_dates" phx-target={@myself} class="btn btn-primary btn-sm mb-4">
            Calculate
          </button>

          <%= if @calc_result do %>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="bg-base-300 rounded-lg p-4">
                <div class="text-xs font-bold opacity-60 mb-2">Date A</div>
                <div class="font-mono text-sm font-bold"><%= @calc_result.date_a_str %></div>
                <div class="text-xs opacity-60 mt-1"><%= @calc_result.day_a %></div>
              </div>
              <div class="bg-base-300 rounded-lg p-4">
                <div class="text-xs font-bold opacity-60 mb-2">Date B</div>
                <div class="font-mono text-sm font-bold"><%= @calc_result.date_b_str %></div>
                <div class="text-xs opacity-60 mt-1"><%= @calc_result.day_b %></div>
              </div>
              <div class="bg-success/10 border border-success/30 rounded-lg p-4">
                <div class="text-xs font-bold opacity-60 mb-2">Date.diff(b, a)</div>
                <div class="font-mono text-sm text-success font-bold">
                  <%= @calc_result.diff %> days
                </div>
                <div class="text-xs opacity-60 mt-1">
                  (<%= @calc_result.weeks %> weeks and <%= @calc_result.remaining_days %> days)
                </div>
              </div>
              <div class="bg-info/10 border border-info/30 rounded-lg p-4">
                <div class="text-xs font-bold opacity-60 mb-2">Date.range(a, b)</div>
                <div class="font-mono text-sm text-info font-bold">
                  <%= @calc_result.range_size %> dates in range
                </div>
                <div class="text-xs opacity-60 mt-1">
                  Weekdays: <%= @calc_result.weekdays %> | Weekends: <%= @calc_result.weekends %>
                </div>
              </div>
            </div>

            <!-- Code equivalent -->
            <div class="bg-base-300 rounded-lg p-3 mt-4 font-mono text-xs whitespace-pre-wrap"><%= date_calc_code(@calc_result) %></div>
          <% end %>
        </div>
      </div>

      <!-- ===== Section 4: Formatting Lab ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Formatting Lab</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter a format string using Calendar.strftime directives.
            The current UTC time is used as the input.
          </p>

          <form phx-submit="format_datetime" phx-target={@myself} class="space-y-3">
            <input
              type="text"
              name="format"
              value={@format_string}
              placeholder="%Y-%m-%d %H:%M:%S"
              class="input input-bordered input-sm font-mono w-full"
              autocomplete="off"
            />
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Format</button>
            </div>
          </form>

          <!-- Preset buttons -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Presets:</span>
            <%= for preset <- format_presets() do %>
              <button
                phx-click="set_format_preset"
                phx-target={@myself}
                phx-value-format={preset.format}
                class="btn btn-xs btn-outline"
              >
                <%= preset.label %>
              </button>
            <% end %>
          </div>

          <%= if @format_result do %>
            <div class="bg-success/10 border border-success/30 rounded-lg p-3 mt-3">
              <div class="text-xs font-bold opacity-60 mb-1">Output</div>
              <div class="font-mono text-sm text-success font-bold"><%= @format_result %></div>
            </div>
          <% end %>

          <!-- Directive reference -->
          <div class="mt-4 overflow-x-auto">
            <div class="text-xs font-bold opacity-60 mb-2">Common Directives</div>
            <table class="table table-xs">
              <thead>
                <tr>
                  <th>Directive</th>
                  <th>Meaning</th>
                  <th>Example</th>
                </tr>
              </thead>
              <tbody>
                <tr><td class="font-mono">%Y</td><td>4-digit year</td><td>2024</td></tr>
                <tr><td class="font-mono">%m</td><td>Month (01-12)</td><td>03</td></tr>
                <tr><td class="font-mono">%d</td><td>Day (01-31)</td><td>15</td></tr>
                <tr><td class="font-mono">%H</td><td>Hour 24h (00-23)</td><td>14</td></tr>
                <tr><td class="font-mono">%I</td><td>Hour 12h (01-12)</td><td>02</td></tr>
                <tr><td class="font-mono">%M</td><td>Minute (00-59)</td><td>30</td></tr>
                <tr><td class="font-mono">%S</td><td>Second (00-59)</td><td>45</td></tr>
                <tr><td class="font-mono">%p</td><td>AM/PM</td><td>PM</td></tr>
                <tr><td class="font-mono">%A</td><td>Full weekday</td><td>Friday</td></tr>
                <tr><td class="font-mono">%a</td><td>Short weekday</td><td>Fri</td></tr>
                <tr><td class="font-mono">%B</td><td>Full month</td><td>March</td></tr>
                <tr><td class="font-mono">%b</td><td>Short month</td><td>Mar</td></tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- ===== Section 5: Try Your Own ===== -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own</h3>
          <form phx-submit="run_custom" phx-target={@myself} class="space-y-3">
            <input
              type="text"
              name="code"
              value={@custom_code}
              placeholder="Date.utc_today() |> Date.add(7)"
              class="input input-bordered input-sm font-mono w-full"
              autocomplete="off"
            />
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
              <span class="text-xs opacity-50 self-center">Try any date/time expression</span>
            </div>
          </form>

          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, code} <- quick_examples() do %>
              <button
                phx-click="quick_example"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @custom_result do %>
            <div class={"alert text-sm mt-3 " <> if(@custom_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @custom_result.input %></div>
                <div class="font-mono font-bold mt-1"><%= @custom_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- ===== Section 6: Key Concepts ===== -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>Four types, each with a purpose</strong> &mdash; Date (date only), Time (time only), NaiveDateTime (date+time, no TZ), DateTime (date+time+TZ). Pick the narrowest type you need.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Sigils for compile-time creation</strong> &mdash; <code class="font-mono bg-base-100 px-1 rounded">~D</code>, <code class="font-mono bg-base-100 px-1 rounded">~T</code>, <code class="font-mono bg-base-100 px-1 rounded">~N</code>, <code class="font-mono bg-base-100 px-1 rounded">~U</code> create date/time structs validated at compile time.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Date arithmetic is built in</strong> &mdash; <code class="font-mono bg-base-100 px-1 rounded">Date.add/2</code>, <code class="font-mono bg-base-100 px-1 rounded">Date.diff/2</code>, and <code class="font-mono bg-base-100 px-1 rounded">Date.range/2</code> handle day-level math. NaiveDateTime.add/2 handles seconds.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Use Calendar.strftime for formatting</strong> &mdash; format dates and times with familiar %-directives like <code class="font-mono bg-base-100 px-1 rounded">%Y-%m-%d</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>NaiveDateTime vs DateTime</strong> &mdash; if your app deals with users in different timezones, always use DateTime. NaiveDateTime is fine for single-timezone or local-only data.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # ── Event Handlers ──

  def handle_event("select_type_tab", %{"id" => id}, socket) do
    {:noreply, socket |> assign(active_type_tab: id) |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, active_example_idx: String.to_integer(idx_str))}
  end

  def handle_event("refresh_now", _params, socket) do
    {:noreply, assign(socket, now: DateTime.utc_now())}
  end

  def handle_event("update_dates", %{"date_a" => a, "date_b" => b}, socket) do
    {:noreply, socket |> assign(date_a_input: a, date_b_input: b)}
  end

  def handle_event("calculate_dates", _params, socket) do
    result = compute_date_calc(socket.assigns.date_a_input, socket.assigns.date_b_input)
    {:noreply, assign(socket, calc_result: result)}
  end

  def handle_event("format_datetime", %{"format" => fmt}, socket) do
    now = DateTime.utc_now()
    result = safe_strftime(now, fmt)
    {:noreply, socket |> assign(format_string: fmt, format_result: result, now: now)}
  end

  def handle_event("set_format_preset", %{"format" => fmt}, socket) do
    now = DateTime.utc_now()
    result = safe_strftime(now, fmt)
    {:noreply, socket |> assign(format_string: fmt, format_result: result, now: now)}
  end

  def handle_event("run_custom", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))
    {:noreply, socket |> assign(custom_code: code) |> assign(custom_result: result)}
  end

  def handle_event("quick_example", %{"code" => code}, socket) do
    result = evaluate_code(code)
    {:noreply, socket |> assign(custom_code: code) |> assign(custom_result: result)}
  end

  # ── Helpers ──

  defp type_tabs, do: @type_tabs
  defp format_presets, do: @format_presets

  defp day_name(day_number), do: Map.get(@day_names, day_number, "Unknown")

  defp days_left_in_year(datetime) do
    date = DateTime.to_date(datetime)
    last_day = Date.new!(date.year, 12, 31)
    Date.diff(last_day, date)
  end

  defp compute_date_calc(a_str, b_str) do
    with {:ok, date_a} <- Date.from_iso8601(a_str),
         {:ok, date_b} <- Date.from_iso8601(b_str) do
      diff = Date.diff(date_b, date_a)
      abs_diff = abs(diff)
      weeks = div(abs_diff, 7)
      remaining_days = rem(abs_diff, 7)
      range = Date.range(date_a, date_b)
      range_list = Enum.to_list(range)
      range_size = length(range_list)

      weekdays =
        Enum.count(range_list, fn d -> Date.day_of_week(d) in 1..5 end)

      weekends = range_size - weekdays

      %{
        date_a_str: Date.to_iso8601(date_a),
        date_b_str: Date.to_iso8601(date_b),
        day_a: day_name(Date.day_of_week(date_a)),
        day_b: day_name(Date.day_of_week(date_b)),
        diff: diff,
        weeks: weeks,
        remaining_days: remaining_days,
        range_size: range_size,
        weekdays: weekdays,
        weekends: weekends
      }
    else
      _ -> nil
    end
  end

  defp date_calc_code(result) do
    """
    a = ~D[#{result.date_a_str}]
    b = ~D[#{result.date_b_str}]

    Date.diff(b, a)           # => #{result.diff}
    Date.range(a, b) |> Enum.count()  # => #{result.range_size}
    Date.day_of_week(a)       # => #{result.day_a}
    Date.day_of_week(b)       # => #{result.day_b}\
    """
  end

  defp safe_strftime(datetime, format) do
    try do
      Calendar.strftime(datetime, format)
    rescue
      _ -> "Invalid format string"
    end
  end

  defp quick_examples do
    [
      {"today + 7", "Date.utc_today() |> Date.add(7)"},
      {"date diff", "Date.diff(~D[2025-01-01], ~D[2024-01-01])"},
      {"day of week", "Date.day_of_week(~D[2024-12-25])"},
      {"unix now", "DateTime.utc_now() |> DateTime.to_unix()"},
      {"from unix", "DateTime.from_unix(1_700_000_000)"},
      {"strftime", "Calendar.strftime(DateTime.utc_now(), \"%B %d, %Y\")"}
    ]
  end

  defp evaluate_code(code) do
    try do
      {result, _} = Code.eval_string(code)
      %{ok: true, input: code, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, input: code, output: "Error: #{Exception.message(e)}"}
    end
  end
end
