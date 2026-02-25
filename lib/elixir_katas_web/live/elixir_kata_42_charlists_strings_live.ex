defmodule ElixirKatasWeb.ElixirKata42CharlistsStringsLive do
  use ElixirKatasWeb, :live_component

  @comparisons [
    %{
      id: "syntax",
      title: "Syntax & Types",
      string_code: ~s|"hello"              # binary (string)\nis_binary("hello")   # true\ni("hello")           # type: string (UTF-8)|,
      charlist_code: ~s|'hello'              # charlist (list of integers)\nis_list('hello')     # true\ni('hello')           # type: list|,
      explanation: "Double quotes create binaries (strings). Single quotes create charlists (lists of codepoint integers)."
    },
    %{
      id: "internal",
      title: "Internal Representation",
      string_code: ~s|"hello" == <<104, 101, 108, 108, 111>>\n# Stored as contiguous UTF-8 bytes|,
      charlist_code: ~s|'hello' == [104, 101, 108, 108, 111]\n# Stored as linked list of integers|,
      explanation: "Strings are compact byte sequences. Charlists are linked lists where each element is a Unicode codepoint integer."
    },
    %{
      id: "operations",
      title: "Common Operations",
      string_code: ~s|# Concatenation\n"hello" <> " world"\n\n# Interpolation\n"Hi \#{name}"\n\n# Pattern match\n<<h, rest::binary>> = "hello"|,
      charlist_code: "# Concatenation\n'hello' ++ ' world'\n\n# No interpolation\n# Must convert: 'Hi ' ++ to_charlist(name)\n\n# Pattern match\n[h | rest] = 'hello'",
      explanation: "Strings use <> for concatenation and support interpolation. Charlists use ++ (list concatenation) and do not support interpolation."
    },
    %{
      id: "conversion",
      title: "Converting Between Them",
      string_code: ~s|# Charlist to String\nto_string('hello')       # "hello"\nList.to_string([104, 101, 108, 108, 111])  # "hello"|,
      charlist_code: ~s|# String to Charlist\nto_charlist("hello")     # 'hello'\nString.to_charlist("hello")  # 'hello'|,
      explanation: "to_string/1 converts charlists to strings. to_charlist/1 converts strings to charlists. These are the standard conversion functions."
    }
  ]

  @erlang_examples [
    %{
      id: "os_cmd",
      label: ":os.cmd/1",
      code: ~s|# :os.cmd expects and returns a charlist\nresult = :os.cmd('echo hello')\n# result is 'hello\\n' (a charlist)\nto_string(result)  # "hello\\n"|,
      explanation: "Erlang's :os module works with charlists, not Elixir strings."
    },
    %{
      id: "io_format",
      label: ":io.format/2",
      code: ~s|# Erlang's io:format uses charlists for format strings\n:io.format('Hello ~s~n', ['world'])\n# Elixir equivalent:\nIO.puts("Hello world")|,
      explanation: "Erlang's :io module uses charlists. Use Elixir's IO module for string-based I/O."
    },
    %{
      id: "ets",
      label: ":ets tables",
      code: "# ETS table names are often atoms, but some\n# Erlang APIs return charlists for string data\n:ets.new('my_table', [:set, :public])\n\n# When Erlang returns charlists, convert:\nresult |> to_string()",
      explanation: "When using Erlang's ETS or other modules, you may receive charlists that need conversion."
    }
  ]

  @gotcha_numbers [
    %{value: [104, 101, 108, 108, 111], display: "[104, 101, 108, 108, 111]", prints_as: "'hello'", reason: "All integers are valid printable ASCII characters"},
    %{value: [65, 66, 67], display: "[65, 66, 67]", prints_as: "'ABC'", reason: "65=A, 66=B, 67=C in ASCII"},
    %{value: [1, 2, 3], display: "[1, 2, 3]", prints_as: "[1, 2, 3]", reason: "1, 2, 3 are non-printable, so displayed as integers"},
    %{value: [72, 105, 0], display: "[72, 105, 0]", prints_as: "[72, 105, 0]", reason: "0 (null) is non-printable, breaks the charlist display"},
    %{value: [49, 50, 51], display: "[49, 50, 51]", prints_as: "'123'", reason: "49=1, 50=2, 51=3 in ASCII"}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_comparison, fn -> hd(@comparisons) end)
     |> assign_new(:active_erlang, fn -> hd(@erlang_examples) end)
     |> assign_new(:user_input, fn -> "hello" end)
     |> assign_new(:show_gotcha, fn -> false end)
     |> assign_new(:show_erlang, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Charlists vs Strings</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir has <strong>two</strong> types of text: <strong>strings</strong> (double-quoted, UTF-8 binaries) and
        <strong>charlists</strong> (single-quoted, lists of integer codepoints). Understanding both is essential
        for Erlang interop.
      </p>

      <!-- Side-by-Side Comparison -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for comp <- comparisons() do %>
          <button
            phx-click="select_comparison"
            phx-target={@myself}
            phx-value-id={comp.id}
            class={"btn btn-sm " <> if(@active_comparison.id == comp.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= comp.title %>
          </button>
        <% end %>
      </div>

      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3"><%= @active_comparison.title %></h3>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <!-- String side -->
            <div class="bg-success/10 border border-success/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-success badge-sm">String</span>
                <span class="text-xs opacity-50">double quotes</span>
              </div>
              <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><%= @active_comparison.string_code %></div>
            </div>

            <!-- Charlist side -->
            <div class="bg-warning/10 border border-warning/30 rounded-lg p-4">
              <div class="flex items-center gap-2 mb-2">
                <span class="badge badge-warning badge-sm">Charlist</span>
                <span class="text-xs opacity-50">single quotes</span>
              </div>
              <div class="bg-base-300 rounded-lg p-3 font-mono text-xs whitespace-pre-wrap"><%= @active_comparison.charlist_code %></div>
            </div>
          </div>

          <div class="bg-info/10 border border-info/30 rounded-lg p-3">
            <div class="text-xs font-bold opacity-60 mb-1">Key Difference</div>
            <div class="text-sm"><%= @active_comparison.explanation %></div>
          </div>
        </div>
      </div>

      <!-- Interactive Converter -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Converter</h3>
          <p class="text-xs opacity-60 mb-4">
            Type a string to see its charlist representation and vice versa.
          </p>

          <form phx-change="update_converter" phx-target={@myself}>
            <input
              type="text"
              name="value"
              value={@user_input}
              placeholder="Type something..."
              class="input input-bordered input-sm w-full font-mono mb-4"
              autocomplete="off"
            />
          </form>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div class="bg-base-300 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-2">As String (binary)</div>
              <div class="font-mono text-sm mb-2">"<%= @user_input %>"</div>
              <div class="text-xs opacity-50">
                byte_size: <span class="font-mono"><%= byte_size(@user_input) %></span> |
                String.length: <span class="font-mono"><%= String.length(@user_input) %></span>
              </div>
              <div class="text-xs opacity-50 font-mono mt-1">
                &lt;&lt;<%= @user_input |> :binary.bin_to_list() |> Enum.join(", ") %>&gt;&gt;
              </div>
            </div>

            <div class="bg-base-300 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-2">As Charlist (list)</div>
              <div class="font-mono text-sm mb-2">'<%= @user_input %>'</div>
              <div class="text-xs opacity-50">
                length: <span class="font-mono"><%= @user_input |> to_charlist() |> length() %></span>
              </div>
              <div class="text-xs opacity-50 font-mono mt-1">
                [<%= @user_input |> to_charlist() |> Enum.join(", ") %>]
              </div>
            </div>
          </div>

          <!-- Conversion Code -->
          <div class="mt-4 bg-base-300 rounded-lg p-3">
            <div class="text-xs font-bold opacity-60 mb-2">Conversion Functions</div>
            <div class="font-mono text-xs space-y-1">
              <div>to_charlist("<%= @user_input %>") <span class="opacity-40">=&gt;</span> <span class="text-warning">[<%= @user_input |> to_charlist() |> Enum.join(", ") %>]</span></div>
              <div>to_string([<%= @user_input |> to_charlist() |> Enum.join(", ") %>]) <span class="opacity-40">=&gt;</span> <span class="text-success">"<%= @user_input %>"</span></div>
            </div>
          </div>
        </div>
      </div>

      <!-- The IEx Gotcha -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">The IEx Display Gotcha</h3>
            <button
              phx-click="toggle_gotcha"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_gotcha, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_gotcha do %>
            <p class="text-sm opacity-70 mb-4">
              IEx displays a list of integers as a charlist when <strong>all</strong> integers are printable ASCII
              characters (32-126). This surprises many beginners!
            </p>

            <div class="overflow-x-auto">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>Expression</th>
                    <th>IEx Displays</th>
                    <th>Why</th>
                  </tr>
                </thead>
                <tbody>
                  <%= for gotcha <- gotcha_numbers() do %>
                    <tr>
                      <td class="font-mono text-xs"><%= gotcha.display %></td>
                      <td class="font-mono text-xs font-bold"><%= gotcha.prints_as %></td>
                      <td class="text-xs"><%= gotcha.reason %></td>
                    </tr>
                  <% end %>
                </tbody>
              </table>
            </div>

            <div class="alert alert-warning text-sm mt-4">
              <div>
                <div class="font-bold">Tip: Use inspect with charlists option</div>
                <span>
                  <code class="font-mono bg-base-300 px-1 rounded">inspect([104, 101, 108, 108, 111], charlists: :as_lists)</code>
                  will always display as <code class="font-mono bg-base-300 px-1 rounded">[104, 101, 108, 108, 111]</code> instead of <code class="font-mono bg-base-300 px-1 rounded">'hello'</code>.
                  You can also set this in <code class="font-mono bg-base-300 px-1 rounded">.iex.exs</code>:
                  <code class="font-mono bg-base-300 px-1 rounded">IEx.configure(inspect: [charlists: :as_lists])</code>
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Erlang Interop -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Erlang Interop: Where You See Charlists</h3>
            <button
              phx-click="toggle_erlang"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_erlang, do: "Hide", else: "Show Examples" %>
            </button>
          </div>

          <%= if @show_erlang do %>
            <p class="text-sm opacity-70 mb-4">
              Charlists exist primarily for <strong>Erlang interoperability</strong>. Many Erlang functions
              expect and return charlists because Erlang was designed before UTF-8 was standard.
            </p>

            <div class="flex flex-wrap gap-2 mb-4">
              <%= for ex <- erlang_examples() do %>
                <button
                  phx-click="select_erlang"
                  phx-target={@myself}
                  phx-value-id={ex.id}
                  class={"btn btn-xs " <> if(@active_erlang.id == ex.id, do: "btn-accent", else: "btn-ghost")}
                >
                  <%= ex.label %>
                </button>
              <% end %>
            </div>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre-wrap mb-3"><%= @active_erlang.code %></div>

            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-sm"><%= @active_erlang.explanation %></div>
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
              <span><strong>Strings</strong> (<code class="font-mono bg-base-100 px-1 rounded">"hello"</code>) are UTF-8 binaries. <strong>Charlists</strong> (<code class="font-mono bg-base-100 px-1 rounded">'hello'</code>) are lists of codepoint integers.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Always prefer strings</strong> in Elixir code. Use charlists only when interfacing with Erlang APIs.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>to_string/1</strong> converts charlists to strings. <strong>to_charlist/1</strong> converts strings to charlists.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span>IEx displays lists of printable ASCII integers as charlists, which can be confusing. Use <code class="font-mono bg-base-100 px-1 rounded">inspect(list, charlists: :as_lists)</code> to see raw integers.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span>Strings use <code class="font-mono bg-base-100 px-1 rounded">&lt;&gt;</code> for concatenation. Charlists use <code class="font-mono bg-base-100 px-1 rounded">++</code> (list concatenation).</span>
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
    {:noreply, assign(socket, active_comparison: comparison)}
  end

  def handle_event("update_converter", %{"value" => value}, socket) do
    {:noreply, assign(socket, user_input: value)}
  end

  def handle_event("toggle_gotcha", _params, socket) do
    {:noreply, assign(socket, show_gotcha: !socket.assigns.show_gotcha)}
  end

  def handle_event("toggle_erlang", _params, socket) do
    {:noreply, assign(socket, show_erlang: !socket.assigns.show_erlang)}
  end

  def handle_event("select_erlang", %{"id" => id}, socket) do
    example = Enum.find(erlang_examples(), &(&1.id == id))
    {:noreply, assign(socket, active_erlang: example)}
  end

  # Helpers

  defp comparisons, do: @comparisons
  defp erlang_examples, do: @erlang_examples
  defp gotcha_numbers, do: @gotcha_numbers
end
