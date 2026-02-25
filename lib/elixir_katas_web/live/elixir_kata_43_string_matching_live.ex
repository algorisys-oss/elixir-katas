defmodule ElixirKatasWeb.ElixirKata43StringMatchingLive do
  use ElixirKatasWeb, :live_component

  @patterns [
    %{
      id: "head_rest",
      title: "Head & Rest (UTF-8)",
      description: "Extract the first UTF-8 character and the remaining binary.",
      code: ~s|<<first::utf8, rest::binary>> = "hello"\n# first = 104 (codepoint for 'h')\n# rest = "ello"\n\n<<first::utf8, rest::binary>> = "Elixir"\n# first = 69 (codepoint for 'E')\n# rest = "lixir"\n\n# Convert codepoint back to string:\n<<104::utf8>>  # "h"|,
      try_default: "hello",
      match_code: ~s|<<first::utf8, rest::binary>>|
    },
    %{
      id: "prefix",
      title: "String Prefix Matching",
      description: "Match on a known prefix and capture the rest.",
      code: ~s|# Match strings starting with "Hello"\n<<"Hello", rest::binary>> = "Hello, world!"\n# rest = ", world!"\n\n# Match HTTP methods\n<<"GET ", path::binary>> = "GET /users"\n# path = "/users"\n\n<<"POST ", path::binary>> = "POST /submit"\n# path = "/submit"|,
      try_default: "Hello, world!",
      match_code: ~s|<<"Hello", rest::binary>>|
    },
    %{
      id: "fixed_width",
      title: "Fixed-Width Fields",
      description: "Extract fixed-size byte segments from a binary.",
      code: ~s|# Extract 4-byte fields\n<<year::binary-size(4), ?-, month::binary-size(2), ?-, day::binary-size(2)>> = "2024-03-15"\n# year = "2024", month = "03", day = "15"\n\n# Fixed-width record\n<<id::binary-size(3), name::binary-size(5), score::binary-size(3)>> = "001Alice095"\n# id = "001", name = "Alice", score = "095"|,
      try_default: "2024-03-15",
      match_code: ~s|<<year::binary-size(4), ?-, month::binary-size(2), ?-, day::binary-size(2)>>|
    },
    %{
      id: "raw_bytes",
      title: "Raw Byte Matching",
      description: "Match on individual bytes without UTF-8 interpretation.",
      code: ~s|# Match individual bytes\n<<a, b, c, rest::binary>> = "hello"\n# a = 104, b = 101, c = 108, rest = "lo"\n\n# Check for specific byte values\n<<0xFF, rest::binary>> = <<255, 1, 2, 3>>\n# rest = <<1, 2, 3>>\n\n# Match null-terminated string\n<<data::binary-size(5), 0, _rest::binary>> = <<"hello", 0, "world">>|,
      try_default: "hello",
      match_code: ~s|<<a, b, c, rest::binary>>|
    },
    %{
      id: "integer_extract",
      title: "Integer Extraction",
      description: "Extract integer values encoded in binaries (common in protocols).",
      code: ~s|# 8-bit unsigned integer\n<<version::8, rest::binary>> = <<1, "hello">>\n# version = 1\n\n# 16-bit big-endian integer\n<<length::16, data::binary>> = <<0, 5, "hello">>\n# length = 5, data = "hello"\n\n# 32-bit integer\n<<magic::32, payload::binary>> = <<0xDEADBEEF::32, "data">>\n# magic = 3735928559|,
      try_default: "",
      match_code: ~s|<<version::8, rest::binary>>|
    }
  ]

  @practical_examples [
    %{
      id: "csv_parse",
      title: "Simple CSV Parser",
      code: "defmodule CSVParser do\n  def parse_line(line) do\n    split_on_comma(line, \"\", [])\n  end\n\n  defp split_on_comma(\"\", current, acc), do:\n    Enum.reverse([current | acc])\n\n  defp split_on_comma(<<?,, rest::binary>>, current, acc), do:\n    split_on_comma(rest, \"\", [current | acc])\n\n  defp split_on_comma(<<char::utf8, rest::binary>>, current, acc), do:\n    split_on_comma(rest, current <> <<char::utf8>>, acc)\nend\n\nCSVParser.parse_line(\"alice,30,engineer\")\n# [\"alice\", \"30\", \"engineer\"]"
    },
    %{
      id: "url_parse",
      title: "URL Protocol Extractor",
      code: ~s|defmodule URLParser do\n  def protocol(<<"https://", _rest::binary>>), do: :https\n  def protocol(<<"http://", _rest::binary>>), do: :http\n  def protocol(<<"ftp://", _rest::binary>>), do: :ftp\n  def protocol(_), do: :unknown\nend\n\nURLParser.protocol("https://example.com")  # :https\nURLParser.protocol("ftp://files.com")      # :ftp|
    },
    %{
      id: "emoji_walk",
      title: "Walk UTF-8 Graphemes",
      code: ~s|defmodule StringWalker do\n  def each_char(""), do: :ok\n  def each_char(<<char::utf8, rest::binary>>) do\n    IO.puts("Char: \#{<<char::utf8>>} (codepoint: \#{char})")\n    each_char(rest)\n  end\nend\n\nStringWalker.each_char("Hi!")\n# Char: H (codepoint: 72)\n# Char: i (codepoint: 105)\n# Char: ! (codepoint: 33)|
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_pattern, fn -> hd(@patterns) end)
     |> assign_new(:try_input, fn -> hd(@patterns).try_default end)
     |> assign_new(:match_result, fn -> nil end)
     |> assign_new(:active_practical, fn -> hd(@practical_examples) end)
     |> assign_new(:show_practical, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">String Pattern Matching</h2>
      <p class="text-sm opacity-70 mb-6">
        Because Elixir strings are binaries, you can use <strong>binary pattern matching</strong> with
        <code class="font-mono bg-base-300 px-1 rounded">&lt;&lt;&gt;&gt;</code> syntax to destructure strings.
        This enables powerful parsing without regex.
      </p>

      <!-- Pattern Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for pattern <- patterns() do %>
          <button
            phx-click="select_pattern"
            phx-target={@myself}
            phx-value-id={pattern.id}
            class={"btn btn-sm " <> if(@active_pattern.id == pattern.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= pattern.title %>
          </button>
        <% end %>
      </div>

      <!-- Pattern Display -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_pattern.title %></h3>
          <p class="text-sm opacity-70 mb-4"><%= @active_pattern.description %></p>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-4"><%= @active_pattern.code %></div>

          <!-- Try It -->
          <%= if @active_pattern.try_default != "" do %>
            <div class="bg-base-100 border border-base-300 rounded-lg p-4">
              <div class="text-xs font-bold opacity-60 mb-2">Try it yourself</div>

              <div class="mb-3">
                <div class="text-xs opacity-50 mb-1">Pattern:</div>
                <div class="bg-base-300 rounded-lg px-3 py-2 font-mono text-sm text-primary"><%= @active_pattern.match_code %></div>
              </div>

              <form phx-submit="try_match" phx-target={@myself} class="flex gap-2 items-end">
                <div class="form-control flex-1">
                  <label class="label py-0"><span class="label-text text-xs">Input string</span></label>
                  <input
                    type="text"
                    name="input"
                    value={@try_input}
                    class="input input-bordered input-sm font-mono"
                    autocomplete="off"
                  />
                </div>
                <button type="submit" class="btn btn-primary btn-sm">Match</button>
              </form>

              <%= if @match_result do %>
                <div class={"mt-3 alert text-sm " <> if(@match_result.ok, do: "alert-success", else: "alert-error")}>
                  <div>
                    <div class="font-mono text-xs whitespace-pre-wrap"><%= @match_result.output %></div>
                  </div>
                </div>
              <% end %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Practical Parsing Examples -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Practical Parsing Examples</h3>
            <button
              phx-click="toggle_practical"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_practical, do: "Hide", else: "Show Examples" %>
            </button>
          </div>

          <%= if @show_practical do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for ex <- practical_examples() do %>
                <button
                  phx-click="select_practical"
                  phx-target={@myself}
                  phx-value-id={ex.id}
                  class={"btn btn-xs " <> if(@active_practical.id == ex.id, do: "btn-accent", else: "btn-ghost")}
                >
                  <%= ex.title %>
                </button>
              <% end %>
            </div>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap"><%= @active_practical.code %></div>
          <% end %>
        </div>
      </div>

      <!-- Binary Syntax Reference -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Binary Pattern Syntax Reference</h3>
          <div class="overflow-x-auto">
            <table class="table table-sm">
              <thead>
                <tr>
                  <th>Syntax</th>
                  <th>Meaning</th>
                  <th>Example</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td class="font-mono text-xs">&lt;&lt;x&gt;&gt;</td>
                  <td class="text-xs">Single byte (0-255)</td>
                  <td class="font-mono text-xs">&lt;&lt;104&gt;&gt; = "h"</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">&lt;&lt;x::utf8&gt;&gt;</td>
                  <td class="text-xs">One UTF-8 codepoint (variable bytes)</td>
                  <td class="font-mono text-xs">&lt;&lt;x::utf8&gt;&gt; = "e"</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">&lt;&lt;x::binary-size(n)&gt;&gt;</td>
                  <td class="text-xs">Exactly n bytes</td>
                  <td class="font-mono text-xs">&lt;&lt;x::binary-size(4)&gt;&gt; = "2024..."</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">&lt;&lt;x::binary&gt;&gt;</td>
                  <td class="text-xs">Rest of binary (must be last)</td>
                  <td class="font-mono text-xs">&lt;&lt;_, rest::binary&gt;&gt;</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">&lt;&lt;x::16&gt;&gt;</td>
                  <td class="text-xs">16-bit integer (2 bytes)</td>
                  <td class="font-mono text-xs">&lt;&lt;x::16&gt;&gt; = &lt;&lt;0, 42&gt;&gt;</td>
                </tr>
                <tr>
                  <td class="font-mono text-xs">&lt;&lt;"prefix", rest::binary&gt;&gt;</td>
                  <td class="text-xs">Match literal prefix</td>
                  <td class="font-mono text-xs">&lt;&lt;"GET ", path::binary&gt;&gt;</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>

      <!-- Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span>Use <code class="font-mono bg-base-100 px-1 rounded">&lt;&lt;char::utf8, rest::binary&gt;&gt;</code> to safely extract one UTF-8 character at a time.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>Literal string prefixes can be matched directly: <code class="font-mono bg-base-100 px-1 rounded">&lt;&lt;"Hello", rest::binary&gt;&gt;</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">::binary-size(n)</code> extracts exactly n bytes, useful for fixed-width fields.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>The <code class="font-mono bg-base-100 px-1 rounded">::binary</code> specifier (without size) matches the <strong>rest</strong> of the binary and must be last.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Binary pattern matching is very fast and works in function heads, enabling multi-clause parsers.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_pattern", %{"id" => id}, socket) do
    pattern = Enum.find(patterns(), &(&1.id == id))

    {:noreply,
     socket
     |> assign(active_pattern: pattern)
     |> assign(try_input: pattern.try_default)
     |> assign(match_result: nil)}
  end

  def handle_event("try_match", %{"input" => input}, socket) do
    result = evaluate_match(socket.assigns.active_pattern.id, input)
    {:noreply, assign(socket, try_input: input, match_result: result)}
  end

  def handle_event("toggle_practical", _params, socket) do
    {:noreply, assign(socket, show_practical: !socket.assigns.show_practical)}
  end

  def handle_event("select_practical", %{"id" => id}, socket) do
    example = Enum.find(practical_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_practical: example)}
  end

  # Helpers

  defp patterns, do: @patterns
  defp practical_examples, do: @practical_examples

  defp evaluate_match("head_rest", input) do
    try do
      <<first::utf8, rest::binary>> = input

      %{
        ok: true,
        output: "first = #{first} (#{<<first::utf8>>})\nrest = #{inspect(rest)}"
      }
    rescue
      _ -> %{ok: false, output: "MatchError: input is empty or invalid UTF-8"}
    end
  end

  defp evaluate_match("prefix", input) do
    case input do
      <<"Hello", rest::binary>> ->
        %{ok: true, output: "Matched prefix \"Hello\"\nrest = #{inspect(rest)}"}

      _ ->
        %{ok: false, output: "No match: string does not start with \"Hello\""}
    end
  end

  defp evaluate_match("fixed_width", input) do
    try do
      <<year::binary-size(4), ?-, month::binary-size(2), ?-, day::binary-size(2)>> = input

      %{
        ok: true,
        output: "year = #{inspect(year)}\nmonth = #{inspect(month)}\nday = #{inspect(day)}"
      }
    rescue
      _ -> %{ok: false, output: "MatchError: expected format YYYY-MM-DD (exactly 10 chars)"}
    end
  end

  defp evaluate_match("raw_bytes", input) do
    try do
      <<a, b, c, rest::binary>> = input

      %{
        ok: true,
        output:
          "a = #{a} (#{<<a>>})\nb = #{b} (#{<<b>>})\nc = #{c} (#{<<c>>})\nrest = #{inspect(rest)}"
      }
    rescue
      _ -> %{ok: false, output: "MatchError: input too short (need at least 3 bytes)"}
    end
  end

  defp evaluate_match(_, _input) do
    %{ok: false, output: "No interactive match available for this pattern"}
  end
end
