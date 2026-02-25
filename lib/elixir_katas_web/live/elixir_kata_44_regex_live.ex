defmodule ElixirKatasWeb.ElixirKata44RegexLive do
  use ElixirKatasWeb, :live_component

  @regex_functions [
    %{
      id: "match",
      label: "Regex.match?/2",
      description: "Returns true if the string matches the pattern. The simplest regex function.",
      code: ~s|Regex.match?(~r/hello/, "hello world")   # true\nRegex.match?(~r/hello/, "goodbye")       # false\nRegex.match?(~r/\\d+/, "age: 42")         # true\nRegex.match?(~r/^\\d+$/, "42abc")          # false (must be all digits)|
    },
    %{
      id: "run",
      label: "Regex.run/2",
      description: "Returns the first match as a list, or nil if no match. Captured groups appear as additional list elements.",
      code: ~s|Regex.run(~r/\\d+/, "age: 42, height: 180")\n# ["42"] (first match only)\n\nRegex.run(~r/(\\w+)@(\\w+)/, "user@host")\n# ["user@host", "user", "host"]\n# [full_match, group1, group2]\n\nRegex.run(~r/\\d+/, "no numbers")\n# nil|
    },
    %{
      id: "scan",
      label: "Regex.scan/2",
      description: "Returns ALL matches (not just the first). Each match is a list like Regex.run returns.",
      code: ~s|Regex.scan(~r/\\d+/, "age: 42, height: 180")\n# [["42"], ["180"]]\n\nRegex.scan(~r/(\\w+)=(\\w+)/, "a=1&b=2&c=3")\n# [["a=1", "a", "1"], ["b=2", "b", "2"], ["c=3", "c", "3"]]\n\nRegex.scan(~r/\\d+/, "no numbers")\n# []|
    },
    %{
      id: "replace",
      label: "Regex.replace/3",
      description: "Replaces all matches with a replacement string. Supports backreferences with \\\\1, \\\\2 etc.",
      code: ~s|Regex.replace(~r/\\d+/, "a1b2c3", "X")\n# "aXbXcX"\n\nRegex.replace(~r/(\\w+)@(\\w+)/, "user@host", "\\\\2/\\\\1")\n# "host/user"\n\nRegex.replace(~r/\\s+/, "  too   many  spaces  ", " ")\n# " too many spaces "|
    },
    %{
      id: "split",
      label: "Regex.split/2",
      description: "Splits a string on all matches of the pattern.",
      code: ~s|Regex.split(~r/[,;\\s]+/, "a, b; c  d")\n# ["a", "b", "c", "d"]\n\nRegex.split(~r/\\d+/, "abc123def456ghi")\n# ["abc", "def", "ghi"]\n\nRegex.split(~r/-/, "2024-03-15")\n# ["2024", "03", "15"]|
    },
    %{
      id: "named",
      label: "Named Captures",
      description: "Use (?P<name>...) or (?<name>...) to name capture groups. Regex.named_captures/2 returns a map.",
      code: ~s|pattern = ~r\/(?<year>\\d{4})-(?<month>\\d{2})-(?<day>\\d{2})\/\nRegex.named_captures(pattern, "2024-03-15")\n# %{"year" => "2024", "month" => "03", "day" => "15"}\n\nemail_re = ~r\/(?<user>[\\w.]+)@(?<domain>[\\w.]+)\/\nRegex.named_captures(email_re, "alice@example.com")\n# %{"user" => "alice", "domain" => "example.com"}|
    }
  ]

  @common_patterns [
    %{label: "Email", pattern: ~s|~r/^[\\w.+-]+@[\\w.-]+\\.[a-zA-Z]{2,}$/|, test: "user@example.com"},
    %{label: "Phone (US)", pattern: ~s|~r/^\\(?\\d{3}\\)?[-.\\s]?\\d{3}[-.\\s]?\\d{4}$/|, test: "(555) 123-4567"},
    %{label: "Date (ISO)", pattern: ~s|~r/^\\d{4}-\\d{2}-\\d{2}$/|, test: "2024-03-15"},
    %{label: "Hex Color", pattern: ~s|~r/^#[0-9a-fA-F]{6}$/|, test: "#FF5733"},
    %{label: "URL", pattern: ~s|~r/^https?:\\/\\/[\\w.-]+/|, test: "https://example.com"},
    %{label: "IP Address", pattern: ~s|~r/^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$/|, test: "192.168.1.1"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_function, fn -> hd(@regex_functions) end)
     |> assign_new(:regex_input, fn -> ~s|\\d+| end)
     |> assign_new(:test_string, fn -> "I have 42 apples and 7 oranges" end)
     |> assign_new(:tester_results, fn -> nil end)
     |> assign_new(:show_common, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Regex</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir uses the <code class="font-mono bg-base-300 px-1 rounded">~r//</code> sigil for regular expressions,
        which compile to Erlang's PCRE-based regex engine. The <code class="font-mono bg-base-300 px-1 rounded">Regex</code>
        module provides functions for matching, scanning, replacing, and splitting.
      </p>

      <!-- Function Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for func <- regex_functions() do %>
          <button
            phx-click="select_function"
            phx-target={@myself}
            phx-value-id={func.id}
            class={"btn btn-sm " <> if(@active_function.id == func.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= func.label %>
          </button>
        <% end %>
      </div>

      <!-- Function Detail -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_function.label %></h3>
          <p class="text-sm opacity-70 mb-4"><%= @active_function.description %></p>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_function.code %></div>
        </div>
      </div>

      <!-- Interactive Regex Tester -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Regex Tester</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter a regex pattern and a test string to see live matching results.
          </p>

          <form phx-submit="run_regex" phx-target={@myself} class="space-y-3 mb-4">
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Regex pattern (without ~r/ /)</span></label>
              <div class="flex items-center gap-2">
                <span class="font-mono text-sm opacity-50">~r/</span>
                <input
                  type="text"
                  name="pattern"
                  value={@regex_input}
                  placeholder="\\d+"
                  class="input input-bordered input-sm font-mono flex-1"
                  autocomplete="off"
                />
                <span class="font-mono text-sm opacity-50">/</span>
              </div>
            </div>

            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Test string</span></label>
              <input
                type="text"
                name="test_string"
                value={@test_string}
                placeholder="Enter text to match against..."
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>

            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Test Regex</button>
            </div>
          </form>

          <!-- Quick Pattern Buttons -->
          <div class="flex flex-wrap gap-2 mb-4">
            <span class="text-xs opacity-50 self-center">Quick patterns:</span>
            <%= for {label, pattern, test} <- quick_patterns() do %>
              <button
                phx-click="quick_regex"
                phx-target={@myself}
                phx-value-pattern={pattern}
                phx-value-test={test}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <!-- Results -->
          <%= if @tester_results do %>
            <div class="space-y-3">
              <!-- match? -->
              <div class="flex items-center gap-3 bg-base-300 rounded-lg p-3">
                <span class="font-mono text-xs opacity-60">Regex.match?/2</span>
                <span class={"badge " <> if(@tester_results.matches, do: "badge-success", else: "badge-error")}>
                  <%= inspect(@tester_results.matches) %>
                </span>
              </div>

              <!-- run -->
              <div class="bg-base-300 rounded-lg p-3">
                <div class="font-mono text-xs opacity-60 mb-1">Regex.run/2</div>
                <div class="font-mono text-sm"><%= inspect(@tester_results.run) %></div>
              </div>

              <!-- scan -->
              <div class="bg-base-300 rounded-lg p-3">
                <div class="font-mono text-xs opacity-60 mb-1">Regex.scan/2</div>
                <div class="font-mono text-sm"><%= inspect(@tester_results.scan) %></div>
              </div>

              <!-- split -->
              <div class="bg-base-300 rounded-lg p-3">
                <div class="font-mono text-xs opacity-60 mb-1">Regex.split/2</div>
                <div class="font-mono text-sm"><%= inspect(@tester_results.split) %></div>
              </div>

              <!-- replace -->
              <div class="bg-base-300 rounded-lg p-3">
                <div class="font-mono text-xs opacity-60 mb-1">Regex.replace/3 (replace with "***")</div>
                <div class="font-mono text-sm"><%= inspect(@tester_results.replace) %></div>
              </div>

              <!-- Highlighted matches -->
              <%= if length(@tester_results.match_ranges) > 0 do %>
                <div class="bg-base-100 border border-base-300 rounded-lg p-3">
                  <div class="text-xs font-bold opacity-60 mb-2">Matches highlighted:</div>
                  <div class="font-mono text-sm">
                    <%= for segment <- @tester_results.highlighted do %>
                      <%= if segment.match do %>
                        <span class="bg-warning/30 border border-warning/50 rounded px-0.5"><%= segment.text %></span>
                      <% else %>
                        <span><%= segment.text %></span>
                      <% end %>
                    <% end %>
                  </div>
                  <div class="text-xs opacity-50 mt-2">
                    Found <%= length(@tester_results.match_ranges) %> match<%= if length(@tester_results.match_ranges) != 1, do: "es" %>
                  </div>
                </div>
              <% end %>

              <!-- Error -->
              <%= if @tester_results.error do %>
                <div class="alert alert-error text-sm">
                  <div><%= @tester_results.error %></div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Common Patterns Reference -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Common Regex Patterns</h3>
            <button
              phx-click="toggle_common"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_common, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_common do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Pattern</th>
                    <th>Regex</th>
                    <th>Example Match</th>
                    <th>Try</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for cp <- common_patterns() do %>
                    <tr>
                      <td class="font-bold text-xs"><%= cp.label %></td>
                      <td class="font-mono text-xs"><%= cp.pattern %></td>
                      <td class="font-mono text-xs"><%= cp.test %></td>
                      <td>
                        <button
                          phx-click="try_common"
                          phx-target={@myself}
                          phx-value-label={cp.label}
                          class="btn btn-xs btn-ghost"
                        >
                          Try
                        </button>
                      </td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
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
              <span><code class="font-mono bg-base-100 px-1 rounded">~r//</code> creates a compiled regex at compile time. More efficient than runtime compilation.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Regex.match?/2</strong> for boolean check, <strong>Regex.run/2</strong> for first match, <strong>Regex.scan/2</strong> for all matches.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Named captures</strong> with <code class="font-mono bg-base-100 px-1 rounded">(?&lt;name&gt;...)</code> return maps via <strong>Regex.named_captures/2</strong>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Regex.replace/3</strong> supports backreferences: <code class="font-mono bg-base-100 px-1 rounded">\\1</code>, <code class="font-mono bg-base-100 px-1 rounded">\\2</code> refer to captured groups.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Consider using <strong>binary pattern matching</strong> (Kata 43) for simple, fixed patterns. Regex is best for complex, flexible patterns.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_function", %{"id" => id}, socket) do
    func = Enum.find(regex_functions(), &(&1.id == id))
    {:noreply, assign(socket, active_function: func)}
  end

  def handle_event("run_regex", %{"pattern" => pattern, "test_string" => test_string}, socket) do
    results = run_regex_test(pattern, test_string)

    {:noreply,
     socket
     |> assign(regex_input: pattern)
     |> assign(test_string: test_string)
     |> assign(tester_results: results)}
  end

  def handle_event("quick_regex", %{"pattern" => pattern, "test" => test}, socket) do
    results = run_regex_test(pattern, test)

    {:noreply,
     socket
     |> assign(regex_input: pattern)
     |> assign(test_string: test)
     |> assign(tester_results: results)}
  end

  def handle_event("try_common", %{"label" => label}, socket) do
    cp = Enum.find(common_patterns(), &(&1.label == label))

    if cp do
      # Extract pattern string from sigil format like ~r/pattern/
      pattern_str =
        cp.pattern
        |> String.replace(~r/^~r\//, "")
        |> String.replace(~r/\/$/, "")

      results = run_regex_test(pattern_str, cp.test)

      {:noreply,
       socket
       |> assign(regex_input: pattern_str)
       |> assign(test_string: cp.test)
       |> assign(tester_results: results)}
    else
      {:noreply, socket}
    end
  end

  def handle_event("toggle_common", _params, socket) do
    {:noreply, assign(socket, show_common: !socket.assigns.show_common)}
  end

  # Helpers

  defp regex_functions, do: @regex_functions
  defp common_patterns, do: @common_patterns

  defp quick_patterns do
    [
      {"Digits", ~s|\\d+|, "I have 42 apples and 7 oranges"},
      {"Words", ~s|\\w+|, "hello world foo"},
      {"Email-like", ~s|\\w+@\\w+\\.\\w+|, "Contact me at alice@example.com or bob@test.org"},
      {"Dates", ~s|\\d{4}-\\d{2}-\\d{2}|, "Born on 1990-05-23, hired 2020-01-15"}
    ]
  end

  defp run_regex_test(pattern_str, test_string) do
    try do
      regex = Regex.compile!(pattern_str)

      matches = Regex.match?(regex, test_string)
      run_result = Regex.run(regex, test_string)
      scan_result = Regex.scan(regex, test_string)
      split_result = Regex.split(regex, test_string)
      replace_result = Regex.replace(regex, test_string, "***")

      # Build highlighted segments
      match_ranges = build_match_ranges(regex, test_string)
      highlighted = build_highlighted(test_string, match_ranges)

      %{
        matches: matches,
        run: run_result,
        scan: scan_result,
        split: split_result,
        replace: replace_result,
        match_ranges: match_ranges,
        highlighted: highlighted,
        error: nil
      }
    rescue
      e ->
        %{
          matches: false,
          run: nil,
          scan: [],
          split: [test_string],
          replace: test_string,
          match_ranges: [],
          highlighted: [%{text: test_string, match: false}],
          error: "Regex error: #{Exception.message(e)}"
        }
    end
  end

  defp build_match_ranges(regex, string) do
    Regex.scan(regex, string, return: :index)
    |> Enum.map(fn [{start, len} | _] -> {start, len} end)
  end

  defp build_highlighted(string, []), do: [%{text: string, match: false}]

  defp build_highlighted(string, ranges) do
    {segments, last_pos} =
      Enum.reduce(ranges, {[], 0}, fn {start, len}, {acc, pos} ->
        before =
          if start > pos do
            [%{text: String.slice(string, pos, start - pos), match: false}]
          else
            []
          end

        matched = [%{text: String.slice(string, start, len), match: true}]

        {acc ++ before ++ matched, start + len}
      end)

    trailing =
      if last_pos < String.length(string) do
        [%{text: String.slice(string, last_pos, String.length(string) - last_pos), match: false}]
      else
        []
      end

    segments ++ trailing
  end
end
