defmodule ElixirKatasWeb.ElixirKata45SigilsLive do
  use ElixirKatasWeb, :live_component

  @sigil_demos [
    %{
      id: "s_sigil",
      title: "~s — String",
      description: "Creates a string, useful when the string contains double quotes so you do not need to escape them.",
      examples: [
        %{
          code: ~s|~s[He said "hello" to her]|,
          result: ~s|"He said \\"hello\\" to her"|,
          note: "No need to escape double quotes inside ~s[]"
        },
        %{
          code: ~s|~s{interpolation: \#{1 + 2}}|,
          result: ~s|"interpolation: 3"|,
          note: "Lowercase ~s supports interpolation"
        },
        %{
          code: ~s|~S[no \#{interpolation} here]|,
          result: ~s|"no \\\#{interpolation} here"|,
          note: "Uppercase ~S disables interpolation and escaping"
        }
      ]
    },
    %{
      id: "w_sigil",
      title: "~w — Word List",
      description: "Creates a list of strings split on whitespace. Modifiers: a (atoms), c (charlists), s (strings, default).",
      examples: [
        %{
          code: ~s|~w[hello world elixir]|,
          result: ~s|["hello", "world", "elixir"]|,
          note: "Default: list of strings"
        },
        %{
          code: ~s|~w[hello world elixir]a|,
          result: ~s|[:hello, :world, :elixir]|,
          note: "With 'a' modifier: list of atoms"
        },
        %{
          code: ~s|~w[hello world elixir]c|,
          result: ~s|['hello', 'world', 'elixir']|,
          note: "With 'c' modifier: list of charlists"
        }
      ]
    },
    %{
      id: "r_sigil",
      title: "~r — Regex",
      description: "Creates a compiled regular expression. Supports standard regex modifiers like i, m, s, u.",
      examples: [
        %{
          code: ~s|~r/hello world/|,
          result: ~s|~r/hello world/|,
          note: "Basic regex pattern"
        },
        %{
          code: ~s|~r/hello/i|,
          result: ~s|~r/hello/i|,
          note: "Case insensitive modifier"
        },
        %{
          code: ~s|~r{\\d{4}-\\d{2}-\\d{2}}|,
          result: ~s|~r/\\d{4}-\\d{2}-\\d{2}/|,
          note: "Can use different delimiters like { }"
        }
      ]
    },
    %{
      id: "date_time_sigils",
      title: "~D, ~T, ~N, ~U — Date/Time",
      description: "Create Date, Time, NaiveDateTime, and DateTime structs at compile time with validation.",
      examples: [
        %{
          code: ~s|~D[2024-03-15]|,
          result: ~s|~D[2024-03-15]|,
          note: "Date struct — validated at compile time"
        },
        %{
          code: ~s|~T[14:30:00]|,
          result: ~s|~T[14:30:00]|,
          note: "Time struct"
        },
        %{
          code: ~s|~N[2024-03-15 14:30:00]|,
          result: ~s|~N[2024-03-15 14:30:00]|,
          note: "NaiveDateTime (no timezone)"
        },
        %{
          code: ~s|~U[2024-03-15 14:30:00Z]|,
          result: ~s|~U[2024-03-15 14:30:00Z]|,
          note: "UTC DateTime"
        }
      ]
    },
    %{
      id: "uppercase",
      title: "Uppercase vs Lowercase",
      description: "Lowercase sigils support interpolation and escape sequences. Uppercase sigils are raw — no interpolation, no escaping.",
      examples: [
        %{
          code: ~s|name = "world"\n~s[hello \#{name}]|,
          result: ~s|"hello world"|,
          note: "Lowercase: interpolation works"
        },
        %{
          code: ~s|name = "world"\n~S[hello \#{name}]|,
          result: ~s|"hello \\\#{name}"|,
          note: "Uppercase: literal text, no interpolation"
        },
        %{
          code: ~s|~s[tab:\\there]|,
          result: ~s|"tab:\\there"|,
          note: "Lowercase: \\t becomes tab character"
        },
        %{
          code: ~s|~S[tab:\\there]|,
          result: ~s|"tab:\\\\there"|,
          note: "Uppercase: \\t stays as literal backslash-t"
        }
      ]
    }
  ]

  @delimiters [
    %{delim: "/ /", example: "~r/pattern/", best_for: "Regex (traditional)"},
    %{delim: "| |", example: ~s|~s\|text\||, best_for: "Strings containing parentheses"},
    %{delim: "[ ]", example: "~w[one two three]", best_for: "Word lists, dates, times"},
    %{delim: "{ }", example: ~s|~s{text}|, best_for: "When other delimiters conflict"},
    %{delim: "( )", example: ~s|~s(text)|, best_for: "General purpose"},
    %{delim: "< >", example: ~s|~s<text>|, best_for: "Rare; when everything else conflicts"},
    %{delim: ~s|" "|, example: ~s|~s"text"|, best_for: "Short strings"},
    %{delim: ~s|' '|, example: ~s|~s'text'|, best_for: "Short strings"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_sigil, fn -> hd(@sigil_demos) end)
     |> assign_new(:active_example_idx, fn -> 0 end)
     |> assign_new(:playground_sigil, fn -> "s" end)
     |> assign_new(:playground_input, fn -> "Hello, world!" end)
     |> assign_new(:playground_result, fn -> nil end)
     |> assign_new(:show_delimiters, fn -> false end)
     |> assign_new(:show_custom, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Sigils</h2>
      <p class="text-sm opacity-70 mb-6">
        Sigils are shortcuts for creating common data types with the <code class="font-mono bg-base-300 px-1 rounded">~</code>
        prefix. They reduce boilerplate and provide compile-time validation for things like regex, dates, and word lists.
      </p>

      <!-- Sigil Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for sigil <- sigil_demos() do %>
          <button
            phx-click="select_sigil"
            phx-target={@myself}
            phx-value-id={sigil.id}
            class={"btn btn-sm " <> if(@active_sigil.id == sigil.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= sigil.title %>
          </button>
        <% end %>
      </div>

      <!-- Sigil Detail -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_sigil.title %></h3>
          <p class="text-sm opacity-70 mb-4"><%= @active_sigil.description %></p>

          <!-- Example Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {_example, idx} <- Enum.with_index(@active_sigil.examples) do %>
              <button
                phx-click="select_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"btn btn-xs " <> if(idx == @active_example_idx, do: "btn-accent", else: "btn-ghost")}
              >
                Example <%= idx + 1 %>
              </button>
            <% end %>
          </div>

          <% example = Enum.at(@active_sigil.examples, @active_example_idx) %>
          <div class="space-y-3">
            <!-- Code -->
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= example.code %></div>

            <!-- Result -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold"><%= example.result %></div>
            </div>

            <!-- Note -->
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Note</div>
              <div class="text-sm"><%= example.note %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Sigil Playground -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Sigil Playground</h3>
          <p class="text-xs opacity-60 mb-4">
            Try different sigils with your own input.
          </p>

          <form phx-submit="run_playground" phx-target={@myself} class="space-y-3 mb-4">
            <div class="flex gap-2 items-end">
              <div class="form-control">
                <label class="label py-0"><span class="label-text text-xs">Sigil type</span></label>
                <select name="sigil_type" class="select select-bordered select-sm font-mono">
                  <%= for {label, value} <- playground_options() do %>
                    <option value={value} selected={value == @playground_sigil}><%= label %></option>
                  <% end %>
                </select>
              </div>

              <div class="form-control flex-1">
                <label class="label py-0"><span class="label-text text-xs">Input</span></label>
                <input
                  type="text"
                  name="input"
                  value={@playground_input}
                  class="input input-bordered input-sm font-mono"
                  autocomplete="off"
                />
              </div>

              <button type="submit" class="btn btn-primary btn-sm">Run</button>
            </div>
          </form>

          <!-- Quick examples -->
          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Try:</span>
            <%= for {label, sigil, input} <- playground_quick_examples() do %>
              <button
                phx-click="quick_playground"
                phx-target={@myself}
                phx-value-sigil={sigil}
                phx-value-input={input}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @playground_result do %>
            <div class={"alert text-sm " <> if(@playground_result.ok, do: "alert-success", else: "alert-error")}>
              <div>
                <div class="font-mono text-xs opacity-60"><%= @playground_result.expression %></div>
                <div class="font-mono font-bold mt-1"><%= @playground_result.output %></div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Delimiters Reference -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Sigil Delimiters</h3>
            <button
              phx-click="toggle_delimiters"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_delimiters, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_delimiters do %>
            <p class="text-sm opacity-70 mb-4">
              Sigils support 8 different delimiter pairs. Choose the one that avoids conflicts with your content.
            </p>

            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Delimiter</th>
                    <th>Example</th>
                    <th>Best For</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for d <- delimiters() do %>
                    <tr>
                      <td class="font-mono font-bold"><%= d.delim %></td>
                      <td class="font-mono text-xs"><%= d.example %></td>
                      <td class="text-xs"><%= d.best_for %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Custom Sigils -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Custom Sigils</h3>
            <button
              phx-click="toggle_custom"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_custom, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_custom do %>
            <p class="text-sm opacity-70 mb-4">
              You can define your own sigils by implementing <code class="font-mono bg-base-300 px-1 rounded">sigil_x/2</code>
              functions in a module.
            </p>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap">{custom_sigils_code()}</div>

            <div class="bg-info/10 border border-info/30 rounded-lg p-3 mt-3">
              <div class="text-sm">
                <strong>Convention:</strong> Lowercase single-letter sigils (<code class="font-mono bg-base-300 px-1 rounded">sigil_x</code>)
                support interpolation and escaping. Their uppercase counterparts
                (<code class="font-mono bg-base-300 px-1 rounded">sigil_X</code>) are raw.
                Multi-character sigils use different naming.
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
              <span><strong>~s</strong> for strings, <strong>~w</strong> for word lists, <strong>~r</strong> for regex, <strong>~D/~T/~N/~U</strong> for dates and times.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Lowercase</strong> sigils interpolate and escape. <strong>Uppercase</strong> sigils are raw (no interpolation).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>Sigils support <strong>8 delimiter pairs</strong>: <code class="font-mono bg-base-100 px-1 rounded">/ / | | [ ] &lbrace; &rbrace; ( ) &lt; &gt; " " ' '</code>. Choose whichever avoids conflicts.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>~w[]a</strong> creates atom lists, <strong>~w[]c</strong> creates charlist lists. The modifier goes after the closing delimiter.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>You can create <strong>custom sigils</strong> by defining <code class="font-mono bg-base-100 px-1 rounded">sigil_x/2</code> functions in a module.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_sigil", %{"id" => id}, socket) do
    sigil = Enum.find(sigil_demos(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_sigil: sigil)
     |> assign(active_example_idx: 0)}
  end

  def handle_event("select_example", %{"idx" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, active_example_idx: idx)}
  end

  def handle_event("run_playground", %{"sigil_type" => sigil_type, "input" => input}, socket) do
    result = evaluate_sigil(sigil_type, input)

    {:noreply,
     socket
     |> assign(playground_sigil: sigil_type)
     |> assign(playground_input: input)
     |> assign(playground_result: result)}
  end

  def handle_event("quick_playground", %{"sigil" => sigil, "input" => input}, socket) do
    result = evaluate_sigil(sigil, input)

    {:noreply,
     socket
     |> assign(playground_sigil: sigil)
     |> assign(playground_input: input)
     |> assign(playground_result: result)}
  end

  def handle_event("toggle_delimiters", _params, socket) do
    {:noreply, assign(socket, show_delimiters: !socket.assigns.show_delimiters)}
  end

  def handle_event("toggle_custom", _params, socket) do
    {:noreply, assign(socket, show_custom: !socket.assigns.show_custom)}
  end

  # Helpers

  defp sigil_demos, do: @sigil_demos
  defp delimiters, do: @delimiters

  defp playground_options do
    [
      {"~s (string)", "s"},
      {"~w (word list)", "w"},
      {"~w[]a (atom list)", "wa"},
      {"~r (regex test)", "r"},
      {"~D (date)", "D"},
      {"~T (time)", "T"}
    ]
  end

  defp playground_quick_examples do
    [
      {"~s string", "s", ~s|He said "hello"|},
      {"~w words", "w", "foo bar baz"},
      {"~w atoms", "wa", "get post put delete"},
      {"~r regex", "r", ~s|\\d+|},
      {"~D date", "D", "2024-03-15"},
      {"~T time", "T", "14:30:00"}
    ]
  end

  defp evaluate_sigil("s", input) do
    %{
      ok: true,
      expression: ~s|~s[#{input}]|,
      output: inspect(input)
    }
  end

  defp evaluate_sigil("w", input) do
    words = String.split(input)

    %{
      ok: true,
      expression: ~s|~w[#{input}]|,
      output: inspect(words)
    }
  end

  defp evaluate_sigil("wa", input) do
    atoms = input |> String.split() |> Enum.map(&String.to_atom/1)

    %{
      ok: true,
      expression: ~s|~w[#{input}]a|,
      output: inspect(atoms)
    }
  end

  defp evaluate_sigil("r", input) do
    try do
      regex = Regex.compile!(input)
      test = "Sample text with 42 numbers and test@email.com"
      matches = Regex.scan(regex, test)

      %{
        ok: true,
        expression: ~s|~r/#{input}/ tested against "#{test}"|,
        output: "Matches: #{inspect(matches)}"
      }
    rescue
      e ->
        %{
          ok: false,
          expression: ~s|~r/#{input}/|,
          output: "Error: #{Exception.message(e)}"
        }
    end
  end

  defp evaluate_sigil("D", input) do
    try do
      date = Date.from_iso8601!(input)

      %{
        ok: true,
        expression: "~D[#{input}]",
        output: "#{inspect(date)} — #{Date.day_of_week(date) |> day_name()}, day #{Date.day_of_year(date)} of #{date.year}"
      }
    rescue
      e ->
        %{
          ok: false,
          expression: "~D[#{input}]",
          output: "Error: #{Exception.message(e)}"
        }
    end
  end

  defp evaluate_sigil("T", input) do
    try do
      time = Time.from_iso8601!(input)

      %{
        ok: true,
        expression: "~T[#{input}]",
        output: "#{inspect(time)} — #{time.hour}h #{time.minute}m #{time.second}s"
      }
    rescue
      e ->
        %{
          ok: false,
          expression: "~T[#{input}]",
          output: "Error: #{Exception.message(e)}"
        }
    end
  end

  defp evaluate_sigil(sigil, input) do
    %{
      ok: false,
      expression: "~#{sigil}[#{input}]",
      output: "Unsupported sigil type"
    }
  end

  defp custom_sigils_code do
    """
    defmodule MySigils do
      def sigil_i(string, []) do
        String.to_integer(string)
      end

      def sigil_p(string, []) do
        string
        |> String.split("/", trim: true)
        |> Enum.join(".")
      end
    end

    import MySigils

    ~i[42]           # 42 (integer)
    ~p[users/admin]  # "users.admin"\
    """
  end

  defp day_name(1), do: "Monday"
  defp day_name(2), do: "Tuesday"
  defp day_name(3), do: "Wednesday"
  defp day_name(4), do: "Thursday"
  defp day_name(5), do: "Friday"
  defp day_name(6), do: "Saturday"
  defp day_name(7), do: "Sunday"
end
