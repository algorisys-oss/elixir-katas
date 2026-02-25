defmodule ElixirKatasWeb.ElixirKata41StringDeepDiveLive do
  use ElixirKatasWeb, :live_component

  @string_functions [
    %{
      id: "length_vs_byte",
      label: "length vs byte_size",
      description: "String.length/1 counts grapheme clusters (what humans see as characters). byte_size/1 counts raw UTF-8 bytes. For ASCII they match, but for multibyte characters they differ.",
      code: ~s|s = "hello"\nString.length(s)  # 5\nbyte_size(s)      # 5\n\ns = "helo"\nString.length(s)  # 5 (4 letters + 1 emoji = 5 graphemes)\nbyte_size(s)      # 8 (4 bytes + 4 bytes for emoji)|
    },
    %{
      id: "graphemes_vs_codepoints",
      label: "Graphemes vs Codepoints",
      description: "A grapheme cluster is what a human sees as a single character. Some graphemes are made of multiple Unicode codepoints combined together.",
      code: ~s|# Simple: one codepoint per grapheme\nString.graphemes("hello")    # ["h", "e", "l", "l", "o"]\nString.codepoints("hello")   # ["h", "e", "l", "l", "o"]\n\n# Complex: combining characters\n# "e" + combining acute accent = "e" (1 grapheme, 2 codepoints)\nString.graphemes("e\\u0301")  # ["e"]\nString.codepoints("e\\u0301") # ["e", "\\u0301"]|
    },
    %{
      id: "binary_internals",
      label: "Binary Internals",
      description: "Strings in Elixir are UTF-8 encoded binaries. Each character may use 1-4 bytes depending on its Unicode codepoint.",
      code: ~s|# ASCII uses 1 byte per character\n<<104, 101, 108, 108, 111>> == "hello"   # true\n\n# UTF-8 multibyte encoding\nbyte_size("A")   # 1 byte  (ASCII range)\nbyte_size("e")   # 2 bytes (Latin extended)\nbyte_size("z")  # 3 bytes (CJK character)\nbyte_size("") # 4 bytes (emoji)|
    },
    %{
      id: "useful_functions",
      label: "Useful Functions",
      description: "The String module provides many useful functions for working with Unicode-aware strings.",
      code: ~s|String.slice("Elixir", 0, 3)       # "Eli"\nString.split("a,b,c", ",")          # ["a", "b", "c"]\nString.replace("hello", "l", "r")   # "herro"\nString.starts_with?("hello", "he")  # true\nString.ends_with?("hello", "lo")    # true\nString.contains?("hello", "ell")    # true\nString.pad_leading("42", 5, "0")    # "00042"\nString.trim("  hi  ")               # "hi"|
    }
  ]

  @byte_ranges [
    %{range: "0-127", bytes: 1, description: "ASCII (English letters, digits, symbols)", example: "A"},
    %{range: "128-2047", bytes: 2, description: "Latin, Greek, Cyrillic, Arabic, Hebrew", example: "e"},
    %{range: "2048-65535", bytes: 3, description: "CJK, Japanese, Korean, most symbols", example: "z"},
    %{range: "65536+", bytes: 4, description: "Emoji, rare scripts, math symbols", example: ""}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:user_input, fn -> "Hello, Elixir! " end)
     |> assign_new(:active_section, fn -> hd(@string_functions) end)
     |> assign_new(:show_byte_table, fn -> false end)
     |> assign_new(:show_encoding_detail, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">String Deep Dive</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir strings are <strong>UTF-8 encoded binaries</strong>. Understanding the difference between
        bytes, codepoints, and grapheme clusters is essential for correct string handling.
      </p>

      <!-- Interactive Byte Breakdown -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive String Inspector</h3>
          <p class="text-xs opacity-60 mb-4">
            Type any string to see its byte-level breakdown, grapheme clusters, and codepoints.
          </p>

          <form phx-change="update_input" phx-target={@myself}>
            <input
              type="text"
              name="value"
              value={@user_input}
              placeholder="Type a string (try emoji, accented chars, CJK...)"
              class="input input-bordered input-sm w-full font-mono mb-4"
              autocomplete="off"
            />
          </form>

          <!-- Stats Row -->
          <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-4">
            <div class="bg-base-300 rounded-lg p-3 text-center">
              <div class="text-xs opacity-50 mb-1">Graphemes</div>
              <div class="text-2xl font-bold text-primary font-mono"><%= String.length(@user_input) %></div>
              <div class="text-xs opacity-40">String.length/1</div>
            </div>
            <div class="bg-base-300 rounded-lg p-3 text-center">
              <div class="text-xs opacity-50 mb-1">Bytes</div>
              <div class="text-2xl font-bold text-info font-mono"><%= byte_size(@user_input) %></div>
              <div class="text-xs opacity-40">byte_size/1</div>
            </div>
            <div class="bg-base-300 rounded-lg p-3 text-center">
              <div class="text-xs opacity-50 mb-1">Codepoints</div>
              <div class="text-2xl font-bold text-accent font-mono"><%= length(String.codepoints(@user_input)) %></div>
              <div class="text-xs opacity-40">String.codepoints/1</div>
            </div>
            <div class="bg-base-300 rounded-lg p-3 text-center">
              <div class="text-xs opacity-50 mb-1">Same?</div>
              <div class={"text-2xl font-bold font-mono " <> if(String.length(@user_input) == byte_size(@user_input), do: "text-success", else: "text-warning")}>
                <%= if String.length(@user_input) == byte_size(@user_input), do: "Yes", else: "No" %>
              </div>
              <div class="text-xs opacity-40">length == bytes</div>
            </div>
          </div>

          <!-- Grapheme Breakdown -->
          <%= if @user_input != "" do %>
            <div class="mb-4">
              <div class="text-xs font-bold opacity-60 mb-2">Grapheme Clusters:</div>
              <div class="flex flex-wrap gap-2">
                <%= for grapheme <- String.graphemes(@user_input) do %>
                  <div class="bg-base-100 border border-base-300 rounded-lg px-3 py-2 text-center min-w-[60px]">
                    <div class="text-lg font-mono mb-1"><%= grapheme %></div>
                    <div class="text-xs opacity-50"><%= byte_size(grapheme) %> byte<%= if byte_size(grapheme) != 1, do: "s" %></div>
                    <div class="text-xs opacity-40 font-mono">
                      <%= grapheme |> :binary.bin_to_list() |> Enum.map(&Integer.to_string(&1, 16)) |> Enum.join(" ") %>
                    </div>
                  </div>
                <% end %>
              </div>
            </div>

            <!-- Raw Bytes -->
            <div class="mb-4">
              <div class="text-xs font-bold opacity-60 mb-2">Raw UTF-8 Bytes (hex):</div>
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm flex flex-wrap gap-1">
                <%= for byte <- :binary.bin_to_list(@user_input) do %>
                  <span class={"px-1.5 py-0.5 rounded text-xs " <> byte_color(byte)}>
                    <%= Integer.to_string(byte, 16) |> String.pad_leading(2, "0") %>
                  </span>
                <% end %>
              </div>
            </div>

            <!-- Binary Representation -->
            <div>
              <div class="text-xs font-bold opacity-60 mb-2">As Elixir Binary:</div>
              <div class="bg-base-300 rounded-lg p-3 font-mono text-sm break-all">
                &lt;&lt;<%= @user_input |> :binary.bin_to_list() |> Enum.join(", ") %>&gt;&gt;
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Concept Sections -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for section <- string_functions() do %>
          <button
            phx-click="select_section"
            phx-target={@myself}
            phx-value-id={section.id}
            class={"btn btn-sm " <> if(@active_section.id == section.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= section.label %>
          </button>
        <% end %>
      </div>

      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_section.label %></h3>
          <p class="text-sm opacity-70 mb-4"><%= @active_section.description %></p>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= @active_section.code %></div>
        </div>
      </div>

      <!-- UTF-8 Encoding Table -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">UTF-8 Byte Ranges</h3>
            <button
              phx-click="toggle_byte_table"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_byte_table, do: "Hide", else: "Show Table" %>
            </button>
          </div>

          <%= if @show_byte_table do %>
            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Codepoint Range</th>
                    <th>Bytes</th>
                    <th>Description</th>
                    <th>Example</th>
                    <th>byte_size</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for row <- byte_ranges() do %>
                    <tr>
                      <td class="font-mono text-xs"><%= row.range %></td>
                      <td>
                        <span class="badge badge-sm badge-primary"><%= row.bytes %></span>
                      </td>
                      <td class="text-xs"><%= row.description %></td>
                      <td class="text-lg"><%= row.example %></td>
                      <td class="font-mono text-xs"><%= byte_size(row.example) %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Encoding Detail -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">How UTF-8 Encoding Works</h3>
            <button
              phx-click="toggle_encoding_detail"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_encoding_detail, do: "Hide", else: "Show Details" %>
            </button>
          </div>

          <%= if @show_encoding_detail do %>
            <div class="space-y-3">
              <p class="text-sm opacity-70">
                UTF-8 is a variable-width encoding. The first byte tells the decoder how many bytes follow:
              </p>
              <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap">{utf8_byte_ranges()}</div>

              <div class="bg-info/10 border border-info/30 rounded-lg p-3">
                <div class="text-xs font-bold opacity-60 mb-1">Why this matters in Elixir</div>
                <div class="text-sm">
                  Because strings are binaries, <code class="font-mono bg-base-300 px-1 rounded">byte_size/1</code> is O(1) (just checking the binary size),
                  while <code class="font-mono bg-base-300 px-1 rounded">String.length/1</code> is O(n) (must walk every byte to count graphemes).
                  This is important for performance-sensitive code.
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
              <span>Elixir strings are <strong>UTF-8 encoded binaries</strong>. <code class="font-mono bg-base-100 px-1 rounded">is_binary("hello")</code> returns <code class="font-mono bg-base-100 px-1 rounded">true</code>.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>byte_size/1</strong> counts raw bytes (O(1)), <strong>String.length/1</strong> counts grapheme clusters (O(n)).</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Grapheme clusters</strong> are what humans see as characters. A single grapheme may consist of multiple codepoints.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Codepoints</strong> are individual Unicode values. <code class="font-mono bg-base-100 px-1 rounded">String.codepoints/1</code> splits at the codepoint level.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Always use <strong>String module functions</strong> for Unicode-correct operations instead of raw binary manipulation.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("update_input", %{"value" => value}, socket) do
    {:noreply, assign(socket, user_input: value)}
  end

  def handle_event("select_section", %{"id" => id}, socket) do
    section = Enum.find(string_functions(), &(&1.id == id))
    {:noreply, assign(socket, active_section: section)}
  end

  def handle_event("toggle_byte_table", _params, socket) do
    {:noreply, assign(socket, show_byte_table: !socket.assigns.show_byte_table)}
  end

  def handle_event("toggle_encoding_detail", _params, socket) do
    {:noreply, assign(socket, show_encoding_detail: !socket.assigns.show_encoding_detail)}
  end

  # Helpers

  defp string_functions, do: @string_functions
  defp byte_ranges, do: @byte_ranges

  defp utf8_byte_ranges do
    """
    1 byte:  0xxxxxxx                              (ASCII: 0-127)
    2 bytes: 110xxxxx 10xxxxxx                     (128-2047)
    3 bytes: 1110xxxx 10xxxxxx 10xxxxxx            (2048-65535)
    4 bytes: 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx   (65536+)\
    """
  end

  defp byte_color(byte) when byte < 128, do: "bg-success/20 text-success"
  defp byte_color(byte) when byte < 192, do: "bg-info/20 text-info"
  defp byte_color(byte) when byte < 224, do: "bg-warning/20 text-warning"
  defp byte_color(byte) when byte < 240, do: "bg-accent/20 text-accent"
  defp byte_color(_byte), do: "bg-error/20 text-error"
end
