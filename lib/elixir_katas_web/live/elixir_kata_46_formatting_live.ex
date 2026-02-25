defmodule ElixirKatasWeb.ElixirKata46FormattingLive do
  use ElixirKatasWeb, :live_component

  @format_sections [
    %{
      id: "padding",
      title: "String Padding",
      description: "String.pad_leading/3 and String.pad_trailing/3 add characters to reach a target length.",
      code: "String.pad_leading(\"42\", 5, \"0\")      # \"00042\"\nString.pad_leading(\"42\", 5)           # \"   42\"\nString.pad_trailing(\"hi\", 10, \".\")    # \"hi........\"\nString.pad_trailing(\"hi\", 10)         # \"hi        \"\n\n# Useful for aligned columns:\n\"Name\"  |> String.pad_trailing(15)\n\"Age\"   |> String.pad_trailing(5)\n\"City\"  |> String.pad_trailing(12)"
    },
    %{
      id: "inspect_opts",
      title: "IO.inspect Options",
      description: "IO.inspect/2 is a developer's best friend for debugging. It prints and returns the value, and supports many formatting options.",
      code: "data = %{name: \"Alice\", scores: [98, 87, 92, 76, 88]}\n\n# :label — tag your output\nIO.inspect(data, label: \"user data\")\n# user data: %{name: \"Alice\", scores: [98, 87, 92, 76, 88]}\n\n# :limit — truncate long lists\nIO.inspect(1..100 |> Enum.to_list(), limit: 5)\n# [1, 2, 3, 4, 5, ...]\n\n# :pretty — multi-line formatting\nIO.inspect(data, pretty: true)\n\n# :width — max line width for pretty printing\nIO.inspect(data, pretty: true, width: 30)\n\n# :charlists — control charlist display\nIO.inspect([65, 66, 67], charlists: :as_lists)\n# [65, 66, 67] (not 'ABC')"
    },
    %{
      id: "interpolation",
      title: "String Interpolation Formatting",
      description: "Elixir string interpolation calls to_string/1 on the expression. For custom formatting, transform the value first.",
      code: "name = \"Alice\"\nage = 30\n\n# Basic interpolation\n\"Name: \#{name}, Age: \#{age}\"\n\n# Format numbers inside interpolation\n\"Price: $\#{Float.round(19.999, 2)}\"\n# \"Price: $20.0\"\n\n# Pad inside interpolation\n\"ID: \#{String.pad_leading(\"42\", 6, \"0\")}\"\n# \"ID: 000042\"\n\n# Conditional formatting\nstatus = :ok\n\"Status: \#{if status == :ok, do: \"PASS\", else: \"FAIL\"}\""
    },
    %{
      id: "number_format",
      title: "Number Formatting",
      description: "Elixir does not have a built-in number formatter with comma separators, but you can build one or use libraries.",
      code: "# Integer to string with base\nInteger.to_string(255, 16)     # \"FF\"\nInteger.to_string(42, 2)       # \"101010\"\nInteger.to_string(42, 8)       # \"52\"\n\n# Float formatting\nFloat.round(3.14159, 2)        # 3.14\n:erlang.float_to_binary(3.14159, decimals: 2)  # \"3.14\"\n:erlang.float_to_binary(3.14159, decimals: 4)  # \"3.1416\"\n\n# Custom thousand separator\ndefp format_number(n) when is_integer(n) do\n  n\n  |> Integer.to_string()\n  |> String.reverse()\n  |> String.replace(~r/.{3}/, \"\\\\0,\")\n  |> String.reverse()\n  |> String.trim_leading(\",\")\nend\n\nformat_number(1234567)  # \"1,234,567\""
    },
    %{
      id: "io_puts",
      title: "IO Output Functions",
      description: "IO.puts/1, IO.write/1, and IO.inspect/2 serve different purposes.",
      code: "# IO.puts — prints with newline, returns :ok\nIO.puts(\"hello\")       # prints: hello\\n\n\n# IO.write — prints without newline, returns :ok\nIO.write(\"hello\")      # prints: hello\n\n# IO.inspect — prints and returns the value\nvalue = IO.inspect(42, label: \"debug\")\n# prints: debug: 42\n# value is still 42 (passthrough!)\n\n# Great for pipeline debugging:\n[1, 2, 3]\n|> IO.inspect(label: \"input\")\n|> Enum.map(&(&1 * 2))\n|> IO.inspect(label: \"doubled\")\n|> Enum.sum()\n|> IO.inspect(label: \"total\")"
    },
    %{
      id: "table_format",
      title: "Building Formatted Tables",
      description: "Combine padding, joining, and enumeration to build formatted text tables.",
      code: "defp format_table(headers, rows) do\n  widths = Enum.map(headers, &String.length/1)\n\n  widths =\n    Enum.reduce(rows, widths, fn row, acc ->\n      Enum.zip(row, acc)\n      |> Enum.map(fn {cell, w} ->\n        max(String.length(cell), w)\n      end)\n    end)\n\n  format_row = fn cells ->\n    Enum.zip(cells, widths)\n    |> Enum.map(fn {cell, w} ->\n      String.pad_trailing(cell, w)\n    end)\n    |> Enum.join(\" | \")\n  end\n\n  header_line = format_row.(headers)\n  separator = Enum.map(widths, &String.duplicate(\"-\", &1)) |> Enum.join(\"-+-\")\n  data_lines = Enum.map(rows, format_row)\n\n  Enum.join([header_line, separator | data_lines], \"\\n\")\nend"
    }
  ]

  @inspect_options [
    %{option: ":label", example: ~s[IO.inspect(x, label: "debug")], description: "Prefix output with a label"},
    %{option: ":limit", example: ~s[IO.inspect(list, limit: 5)], description: "Truncate long collections"},
    %{option: ":pretty", example: ~s[IO.inspect(map, pretty: true)], description: "Multi-line formatted output"},
    %{option: ":width", example: ~s[IO.inspect(x, width: 40)], description: "Max line width for pretty printing"},
    %{option: ":charlists", example: ~s[IO.inspect(list, charlists: :as_lists)], description: "Always show integer lists, not charlists"},
    %{option: ":structs", example: ~s[IO.inspect(date, structs: false)], description: "Show struct as raw map"},
    %{option: ":binaries", example: ~s[IO.inspect(bin, binaries: :as_binaries)], description: "Show raw bytes instead of strings"},
    %{option: ":syntax_colors", example: "IO.inspect(x, syntax_colors: [number: :red])", description: "ANSI color output in terminal"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_section, fn -> hd(@format_sections) end)
     |> assign_new(:pad_input, fn -> "42" end)
     |> assign_new(:pad_length, fn -> 8 end)
     |> assign_new(:pad_char, fn -> "0" end)
     |> assign_new(:pad_direction, fn -> "leading" end)
     |> assign_new(:format_input, fn -> "1234567" end)
     |> assign_new(:format_base, fn -> 10 end)
     |> assign_new(:show_inspect_opts, fn -> false end)
     |> assign_new(:show_table_demo, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Formatting</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir provides tools for string padding, number formatting, and debug output. Master these
        to produce clean output and debug effectively with <code class="font-mono bg-base-300 px-1 rounded">IO.inspect/2</code>.
      </p>

      <!-- Section Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for section <- format_sections() do %>
          <button
            phx-click="select_section"
            phx-target={@myself}
            phx-value-id={section.id}
            class={"btn btn-sm " <> if(@active_section.id == section.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= section.title %>
          </button>
        <% end %>
      </div>

      <!-- Section Detail -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_section.title %></h3>
          <p class="text-sm opacity-70 mb-4"><%= @active_section.description %></p>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_section.code %></div>
        </div>
      </div>

      <!-- Interactive Padding Lab -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Padding Lab</h3>
          <p class="text-xs opacity-60 mb-4">
            Experiment with String.pad_leading and String.pad_trailing.
          </p>

          <form phx-change="update_padding" phx-target={@myself} class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Input string</span></label>
              <input
                type="text"
                name="input"
                value={@pad_input}
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>

            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Target length</span></label>
              <input
                type="number"
                name="length"
                value={@pad_length}
                min="1"
                max="50"
                class="input input-bordered input-sm font-mono"
              />
            </div>

            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Pad character</span></label>
              <input
                type="text"
                name="pad_char"
                value={@pad_char}
                maxlength="3"
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>

            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Direction</span></label>
              <select name="direction" class="select select-bordered select-sm">
                <option value="leading" selected={@pad_direction == "leading"}>Leading</option>
                <option value="trailing" selected={@pad_direction == "trailing"}>Trailing</option>
              </select>
            </div>
          </form>

          <!-- Padding Result -->
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-base-300 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Code</div>
              <div class="font-mono text-sm">
                String.<%= if @pad_direction == "leading", do: "pad_leading", else: "pad_trailing" %>(<%= inspect(@pad_input) %>, <%= @pad_length %>, <%= inspect(pad_char_safe(@pad_char)) %>)
              </div>
            </div>
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold">
                "<%= compute_padding(@pad_input, @pad_length, pad_char_safe(@pad_char), @pad_direction) %>"
              </div>
              <div class="text-xs opacity-50 mt-1">
                Length: <%= String.length(compute_padding(@pad_input, @pad_length, pad_char_safe(@pad_char), @pad_direction)) %>
              </div>
            </div>
          </div>

          <!-- Quick Padding Examples -->
          <div class="flex flex-wrap gap-2 mt-4">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, input, len, char, dir} <- padding_examples() do %>
              <button
                phx-click="quick_pad"
                phx-target={@myself}
                phx-value-input={input}
                phx-value-length={len}
                phx-value-char={char}
                phx-value-direction={dir}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Number Format Lab -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Number Formatting Lab</h3>
          <p class="text-xs opacity-60 mb-4">
            Enter an integer to see it formatted in different bases and with thousand separators.
          </p>

          <form phx-change="update_number" phx-target={@myself} class="flex gap-3 items-end mb-4">
            <div class="form-control flex-1">
              <label class="label py-0"><span class="label-text text-xs">Integer</span></label>
              <input
                type="text"
                name="number"
                value={@format_input}
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
          </form>

          <% parsed = parse_integer(@format_input) %>
          <%= if parsed do %>
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
              <div class="bg-base-300 rounded-lg p-3 text-center">
                <div class="text-xs opacity-50 mb-1">Decimal</div>
                <div class="font-mono text-sm font-bold"><%= Integer.to_string(parsed, 10) %></div>
              </div>
              <div class="bg-base-300 rounded-lg p-3 text-center">
                <div class="text-xs opacity-50 mb-1">Hex</div>
                <div class="font-mono text-sm font-bold">0x<%= Integer.to_string(parsed, 16) %></div>
              </div>
              <div class="bg-base-300 rounded-lg p-3 text-center">
                <div class="text-xs opacity-50 mb-1">Binary</div>
                <div class="font-mono text-sm font-bold">0b<%= Integer.to_string(parsed, 2) %></div>
              </div>
              <div class="bg-base-300 rounded-lg p-3 text-center">
                <div class="text-xs opacity-50 mb-1">Octal</div>
                <div class="font-mono text-sm font-bold">0o<%= Integer.to_string(parsed, 8) %></div>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div class="bg-base-300 rounded-lg p-3">
                <div class="text-xs opacity-50 mb-1">With thousand separators</div>
                <div class="font-mono text-lg font-bold text-primary"><%= format_with_commas(parsed) %></div>
              </div>
              <div class="bg-base-300 rounded-lg p-3">
                <div class="text-xs opacity-50 mb-1">Zero-padded (8 digits)</div>
                <div class="font-mono text-lg font-bold text-accent"><%= String.pad_leading(Integer.to_string(parsed), 8, "0") %></div>
              </div>
            </div>
          <% else %>
            <div class="alert alert-warning text-sm">
              <div>Enter a valid integer</div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- IO.inspect Options Reference -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">IO.inspect Options Reference</h3>
            <button
              phx-click="toggle_inspect_opts"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_inspect_opts, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_inspect_opts do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Option</th>
                    <th>Example</th>
                    <th>Description</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for opt <- inspect_options() do %>
                    <tr>
                      <td class="font-mono text-xs font-bold"><%= opt.option %></td>
                      <td class="font-mono text-xs"><%= opt.example %></td>
                      <td class="text-xs"><%= opt.description %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="alert alert-info text-sm mt-4">
              <div>
                <div class="font-bold">Pro Tip: IO.inspect in pipelines</div>
                <span>
                  <code class="font-mono bg-base-300 px-1 rounded">IO.inspect/2</code> returns its first argument,
                  so you can insert it anywhere in a pipeline for debugging without changing the result:
                  <code class="font-mono bg-base-300 px-1 rounded">list |&gt; IO.inspect(label: "before") |&gt; Enum.sort()</code>
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Formatted Table Demo -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Formatted Table Demo</h3>
            <button
              phx-click="toggle_table_demo"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_table_demo, do: "Hide", else: "Show Demo" %>
            </button>
          </div>

          <%= if @show_table_demo do %>
            <p class="text-xs opacity-60 mb-4">
              Using String.pad_trailing to build aligned text tables.
            </p>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre"><%= build_demo_table() %></div>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mt-3"><%= table_code() %></div>
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
              <span><strong>String.pad_leading/3</strong> and <strong>String.pad_trailing/3</strong> add padding characters to reach a target length.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>IO.inspect/2</strong> prints AND returns its value. Use it in pipelines for debugging without disrupting data flow.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span>The <strong>:label</strong> option for IO.inspect is invaluable for distinguishing multiple debug prints.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Integer.to_string/2</strong> formats integers in any base (2, 8, 10, 16, etc.).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Use <strong>:erlang.float_to_binary/2</strong> with the <code class="font-mono bg-base-100 px-1 rounded">decimals:</code> option for precise float formatting.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_section", %{"id" => id}, socket) do
    section = Enum.find(format_sections(), &(&1.id == id))
    {:noreply, assign(socket, active_section: section)}
  end

  def handle_event("update_padding", params, socket) do
    input = Map.get(params, "input", socket.assigns.pad_input)
    length_str = Map.get(params, "length", to_string(socket.assigns.pad_length))
    pad_char = Map.get(params, "pad_char", socket.assigns.pad_char)
    direction = Map.get(params, "direction", socket.assigns.pad_direction)

    length =
      case Integer.parse(length_str) do
        {n, _} when n > 0 and n <= 50 -> n
        _ -> socket.assigns.pad_length
      end

    {:noreply,
     socket
     |> assign(pad_input: input)
     |> assign(pad_length: length)
     |> assign(pad_char: pad_char)
     |> assign(pad_direction: direction)}
  end

  def handle_event("quick_pad", params, socket) do
    {:noreply,
     socket
     |> assign(pad_input: params["input"])
     |> assign(pad_length: String.to_integer(params["length"]))
     |> assign(pad_char: params["char"])
     |> assign(pad_direction: params["direction"])}
  end

  def handle_event("update_number", %{"number" => number}, socket) do
    {:noreply, assign(socket, format_input: number)}
  end

  def handle_event("toggle_inspect_opts", _params, socket) do
    {:noreply, assign(socket, show_inspect_opts: !socket.assigns.show_inspect_opts)}
  end

  def handle_event("toggle_table_demo", _params, socket) do
    {:noreply, assign(socket, show_table_demo: !socket.assigns.show_table_demo)}
  end

  # Helpers

  defp format_sections, do: @format_sections
  defp inspect_options, do: @inspect_options

  defp pad_char_safe(""), do: " "
  defp pad_char_safe(char), do: char

  defp compute_padding(input, length, pad_char, "leading") do
    String.pad_leading(input, length, pad_char)
  end

  defp compute_padding(input, length, pad_char, "trailing") do
    String.pad_trailing(input, length, pad_char)
  end

  defp compute_padding(input, _length, _pad_char, _direction), do: input

  defp padding_examples do
    [
      {"Zero-pad ID", "42", 6, "0", "leading"},
      {"Right-align", "hello", 20, " ", "leading"},
      {"Dotted", "Loading", 20, ".", "trailing"},
      {"Dash line", "", 30, "-", "trailing"},
      {"Centered*", "Title", 20, "=", "leading"}
    ]
  end

  defp parse_integer(input) do
    case Integer.parse(String.trim(input)) do
      {n, ""} -> n
      _ -> nil
    end
  end

  defp format_with_commas(n) when n < 0, do: "-" <> format_with_commas(-n)

  defp format_with_commas(n) do
    n
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.reverse/1)
    |> Enum.reverse()
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
  end

  defp build_demo_table do
    headers = ["Name", "Language", "Stars", "Status"]

    rows = [
      ["Phoenix", "Elixir", "21,000", "Active"],
      ["Rails", "Ruby", "55,000", "Active"],
      ["Django", "Python", "78,000", "Active"],
      ["Express", "JavaScript", "64,000", "Active"],
      ["Gin", "Go", "77,000", "Active"]
    ]

    widths =
      Enum.reduce([headers | rows], List.duplicate(0, length(headers)), fn row, acc ->
        Enum.zip(row, acc)
        |> Enum.map(fn {cell, w} -> max(String.length(cell), w) end)
      end)

    format_row = fn cells ->
      Enum.zip(cells, widths)
      |> Enum.map(fn {cell, w} -> String.pad_trailing(cell, w) end)
      |> Enum.join(" | ")
    end

    header_line = format_row.(headers)
    separator = Enum.map(widths, &String.duplicate("-", &1)) |> Enum.join("-+-")
    data_lines = Enum.map(rows, format_row)

    Enum.join([header_line, separator | data_lines], "\n")
  end

  defp table_code do
    "# Build the table above with:\nheaders = [\"Name\", \"Language\", \"Stars\", \"Status\"]\nrows = [\n  [\"Phoenix\", \"Elixir\", \"21,000\", \"Active\"],\n  [\"Rails\", \"Ruby\", \"55,000\", \"Active\"],\n  ...\n]\n\n# Calculate column widths\nwidths = compute_max_widths(headers, rows)\n\n# Format each row with padding\nformat_row = fn cells ->\n  Enum.zip(cells, widths)\n  |> Enum.map(fn {cell, w} -> String.pad_trailing(cell, w) end)\n  |> Enum.join(\" | \")\nend"
  end
end
