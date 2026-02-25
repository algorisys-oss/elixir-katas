defmodule ElixirKatasWeb.ElixirKata76IoFileLive do
  use ElixirKatasWeb, :live_component

  @io_functions [
    %{
      id: "puts",
      title: "IO.puts",
      description: "Writes a string followed by a newline to the given device (default :stdio). Returns :ok.",
      examples: [
        %{
          label: "Basic puts",
          code: "IO.puts(\"Hello, world!\")",
          result: ":ok",
          output: "Hello, world!",
          note: "Writes to stdout with a trailing newline. Returns :ok, not the string."
        },
        %{
          label: "To stderr",
          code: "IO.puts(:stderr, \"Warning!\")",
          result: ":ok",
          output: "Warning!",
          note: "First arg can be :stdio (default) or :stderr for error output."
        },
        %{
          label: "Charlist input",
          code: "IO.puts('hello')",
          result: ":ok",
          output: "hello",
          note: "IO.puts accepts both strings (binaries) and charlists."
        }
      ]
    },
    %{
      id: "write",
      title: "IO.write",
      description: "Like IO.puts but does NOT append a newline. Useful for building output incrementally.",
      examples: [
        %{
          label: "No newline",
          code: "IO.write(\"Hello\"); IO.write(\" World\")",
          result: ":ok",
          output: "Hello World",
          note: "Unlike puts, write does not add a newline. Output appears on the same line."
        },
        %{
          label: "IO list",
          code: "IO.write([\"Hello\", 32, \"World\"])",
          result: ":ok",
          output: "Hello World",
          note: "IO.write natively supports IO lists -- no string concatenation needed! 32 is the codepoint for space."
        }
      ]
    },
    %{
      id: "inspect",
      title: "IO.inspect",
      description: "Inspects and prints a value, then returns it. Perfect for pipeline debugging.",
      examples: [
        %{
          label: "Basic inspect",
          code: "IO.inspect(%{a: 1, b: 2})",
          result: "%{a: 1, b: 2}",
          output: "%{a: 1, b: 2}",
          note: "Prints the inspected value AND returns it -- the key feature for pipeline debugging."
        },
        %{
          label: "With label",
          code: "[1, 2, 3] |> Enum.map(& &1 * 2) |> IO.inspect(label: \"doubled\") |> Enum.sum()",
          result: "12",
          output: "doubled: [2, 4, 6]",
          note: "The label option prefixes the output. The pipeline continues because IO.inspect returns the value."
        },
        %{
          label: "Pretty + limit",
          code: "IO.inspect(Enum.to_list(1..100), pretty: true, limit: 5)",
          result: "[1, 2, 3, 4, 5, ...]",
          output: "[1, 2, 3, 4, 5, ...]",
          note: "Use pretty: true for multiline formatting and limit: N to truncate long collections."
        }
      ]
    },
    %{
      id: "gets",
      title: "IO.gets",
      description: "Reads a line from input. In LiveView we simulate it, but in IEx it prompts the user.",
      examples: [
        %{
          label: "Read line",
          code: "name = IO.gets(\"What is your name? \")",
          result: "\"Alice\\n\"",
          output: "What is your name? Alice",
          note: "Returns the input WITH the trailing newline. Use String.trim/1 to remove it."
        },
        %{
          label: "Trimmed input",
          code: "name = IO.gets(\"Name: \") |> String.trim()",
          result: "\"Alice\"",
          output: "Name: Alice",
          note: "Always trim IO.gets results to remove the trailing newline character."
        }
      ]
    }
  ]

  @file_operations [
    %{
      id: "read_write",
      title: "Read & Write",
      description: "File.read/1 returns {:ok, content} or {:error, reason}. File.read!/1 raises on error. Same pattern for write.",
      examples: [
        %{
          label: "File.read/1",
          code: "File.read(\"/tmp/test.txt\")",
          result: "{:ok, \"hello world\\n\"}",
          note: "Returns an ok/error tuple. Safe for files that might not exist."
        },
        %{
          label: "File.read!/1",
          code: "File.read!(\"/tmp/test.txt\")",
          result: "\"hello world\\n\"",
          note: "The bang version raises File.Error on failure. Use when the file MUST exist."
        },
        %{
          label: "File.write/2",
          code: "File.write(\"/tmp/output.txt\", \"Hello!\")",
          result: ":ok",
          note: "Writes content to file, creating it if needed. Overwrites existing content."
        },
        %{
          label: "File.write/3 append",
          code: "File.write(\"/tmp/log.txt\", \"new line\\n\", [:append])",
          result: ":ok",
          note: "The :append option adds to the end instead of overwriting."
        }
      ]
    },
    %{
      id: "query",
      title: "Query & Metadata",
      description: "Check file existence, get metadata, list directories.",
      examples: [
        %{
          label: "File.exists?/1",
          code: "File.exists?(\"/tmp/test.txt\")",
          result: "true",
          note: "Simple boolean check. Works for both files and directories."
        },
        %{
          label: "File.stat/1",
          code: "File.stat(\"/tmp/test.txt\")",
          result: "{:ok, %File.Stat{size: 12, type: :regular, ...}}",
          note: "Returns a File.Stat struct with size, type, access times, and permissions."
        },
        %{
          label: "File.ls/1",
          code: "File.ls(\"/tmp\")",
          result: "{:ok, [\"test.txt\", \"output.txt\", ...]}",
          note: "Lists files in a directory. Does not recurse into subdirectories."
        },
        %{
          label: "File.dir?/1",
          code: "File.dir?(\"/tmp\")",
          result: "true",
          note: "Returns true only for directories, false for files or non-existent paths."
        }
      ]
    },
    %{
      id: "stream",
      title: "Streaming",
      description: "File.stream! enables lazy, line-by-line file reading -- crucial for large files.",
      examples: [
        %{
          label: "File.stream!/1",
          code: "File.stream!(\"/tmp/data.csv\") |> Enum.take(3)",
          result: "[\"id,name,age\\n\", \"1,Alice,30\\n\", \"2,Bob,25\\n\"]",
          note: "Returns a lazy Stream. The file is read only as lines are consumed."
        },
        %{
          label: "Process lines",
          code: "File.stream!(\"/tmp/data.csv\")\n|> Stream.map(&String.trim/1)\n|> Stream.reject(&(&1 == \"\"))\n|> Enum.to_list()",
          result: "[\"id,name,age\", \"1,Alice,30\", \"2,Bob,25\"]",
          note: "Combine with Stream functions for lazy pipelines that handle files of any size."
        },
        %{
          label: "Write via stream",
          code: "[\"line 1\\n\", \"line 2\\n\"] |> Stream.into(File.stream!(\"/tmp/out.txt\")) |> Stream.run()",
          result: ":ok",
          note: "File.stream! is also a Collectable -- you can stream data INTO a file."
        }
      ]
    }
  ]


  @io_list_comparisons [
    %{
      id: "concat",
      title: "String Concatenation",
      code: "result = \"Hello\" <> \" \" <> \"World\" <> \"!\"",
      explanation: "Each <> creates a new binary by copying both sides. For N parts, this means N-1 copies.",
      complexity: "O(n^2) for building incrementally",
      badge_class: "badge-error"
    },
    %{
      id: "iolist",
      title: "IO List",
      code: "result = [\"Hello\", \" \", \"World\", ?!]",
      explanation: "An IO list is a nested list of strings, charlists, and integers. No copying until final output.",
      complexity: "O(n) -- zero-copy until output",
      badge_class: "badge-success"
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_io_tab, fn -> "puts" end)
     |> assign_new(:active_io_example_idx, fn -> 0 end)
     |> assign_new(:active_file_tab, fn -> "read_write" end)
     |> assign_new(:active_file_example_idx, fn -> 0 end)
     |> assign_new(:path_input, fn -> "/home/user/projects/my_app/lib/app.ex" end)
     |> assign_new(:path_results, fn -> compute_path_results("/home/user/projects/my_app/lib/app.ex") end)
     |> assign_new(:show_io_list_detail, fn -> false end)
     |> assign_new(:custom_code, fn -> "" end)
     |> assign_new(:custom_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">IO &amp; File Operations</h2>
      <p class="text-sm opacity-70 mb-6">
        Elixir provides powerful modules for input/output, file system operations, and path manipulation.
        Learn to read, write, and stream files, work with IO devices, and build output efficiently with IO lists.
      </p>

      <!-- Section 1: IO Functions Explorer -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">IO Functions Explorer</h3>
          <p class="text-xs opacity-60 mb-4">
            The IO module handles input and output to devices like :stdio and :stderr.
          </p>

          <!-- IO Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for func <- io_functions() do %>
              <button
                phx-click="select_io_tab"
                phx-target={@myself}
                phx-value-id={func.id}
                class={"btn btn-sm " <> if(@active_io_tab == func.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= func.title %>
              </button>
            <% end %>
          </div>

          <% active_io = Enum.find(io_functions(), &(&1.id == @active_io_tab)) %>
          <p class="text-xs opacity-60 mb-4"><%= active_io.description %></p>

          <!-- Example Subtabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(active_io.examples) do %>
              <button
                phx-click="select_io_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"btn btn-xs " <> if(idx == @active_io_example_idx, do: "btn-accent", else: "btn-ghost")}
              >
                <%= example.label %>
              </button>
            <% end %>
          </div>

          <% io_example = Enum.at(active_io.examples, @active_io_example_idx) %>
          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= io_example.code %></div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div class="bg-info/10 border border-info/30 rounded-lg p-3">
                <div class="text-xs font-bold opacity-60 mb-1">stdout / stderr</div>
                <div class="font-mono text-sm text-info"><%= io_example.output %></div>
              </div>
              <div class="bg-success/10 border border-success/30 rounded-lg p-3">
                <div class="text-xs font-bold opacity-60 mb-1">Return Value</div>
                <div class="font-mono text-sm text-success font-bold"><%= io_example.result %></div>
              </div>
            </div>
            <div class="bg-warning/10 border border-warning/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Note</div>
              <div class="text-sm"><%= io_example.note %></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Section 2: File Operations -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">File Operations</h3>
          <p class="text-xs opacity-60 mb-4">
            The File module provides functions for reading, writing, querying, and streaming files.
            Most functions come in two variants: one returning tuples, one raising on errors (bang!).
          </p>

          <!-- File Tabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for op <- file_operations() do %>
              <button
                phx-click="select_file_tab"
                phx-target={@myself}
                phx-value-id={op.id}
                class={"btn btn-sm " <> if(@active_file_tab == op.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= op.title %>
              </button>
            <% end %>
          </div>

          <% active_file = Enum.find(file_operations(), &(&1.id == @active_file_tab)) %>
          <p class="text-xs opacity-60 mb-4"><%= active_file.description %></p>

          <!-- File Example Subtabs -->
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for {example, idx} <- Enum.with_index(active_file.examples) do %>
              <button
                phx-click="select_file_example"
                phx-target={@myself}
                phx-value-idx={idx}
                class={"btn btn-xs " <> if(idx == @active_file_example_idx, do: "btn-accent", else: "btn-ghost")}
              >
                <%= example.label %>
              </button>
            <% end %>
          </div>

          <% file_example = Enum.at(active_file.examples, @active_file_example_idx) %>
          <div class="space-y-3">
            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap"><%= file_example.code %></div>
            <div class="bg-success/10 border border-success/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Result</div>
              <div class="font-mono text-sm text-success font-bold"><%= file_example.result %></div>
            </div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3">
              <div class="text-xs font-bold opacity-60 mb-1">Note</div>
              <div class="text-sm"><%= file_example.note %></div>
            </div>
          </div>

          <!-- Bang vs Non-bang pattern callout -->
          <div class="alert alert-info mt-4 text-xs">
            <div>
              <strong>Pattern:</strong> <code class="font-mono bg-base-100 px-1 rounded">File.read/1</code> returns
              <code class="font-mono bg-base-100 px-1 rounded">&lbrace;:ok, data&rbrace;</code> or
              <code class="font-mono bg-base-100 px-1 rounded">&lbrace;:error, reason&rbrace;</code>.
              <code class="font-mono bg-base-100 px-1 rounded">File.read!/1</code> returns data directly or raises.
              Use tuples for graceful handling, bangs when failure is unexpected.
            </div>
          </div>
        </div>
      </div>

      <!-- Section 3: Path Module -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Path Module</h3>
          <p class="text-xs opacity-60 mb-4">
            The Path module manipulates file system paths without touching the file system.
            Enter a path below to see all Path functions applied to it.
          </p>

          <form phx-change="update_path" phx-target={@myself} class="mb-4">
            <div class="form-control">
              <label class="label py-0"><span class="label-text text-xs">Enter a file path</span></label>
              <input
                type="text"
                name="path"
                value={@path_input}
                class="input input-bordered input-sm font-mono"
                autocomplete="off"
              />
            </div>
          </form>

          <div class="space-y-2">
            <%= for pr <- @path_results do %>
              <div class="flex items-start gap-3 bg-base-300 rounded-lg p-3">
                <div class="min-w-[140px]">
                  <code class="font-mono text-xs text-primary font-bold"><%= pr.func %></code>
                </div>
                <div class="flex-1">
                  <div class="font-mono text-sm text-success font-bold"><%= pr.result %></div>
                  <div class="text-xs opacity-60 mt-1"><%= pr.note %></div>
                </div>
              </div>
            <% end %>
          </div>

          <div class="alert alert-warning mt-4 text-xs">
            <div>
              <strong>Tip:</strong> Path functions are pure string operations -- they don't check if the path actually exists.
              Use <code class="font-mono bg-base-100 px-1 rounded">File.exists?/1</code> to verify.
            </div>
          </div>
        </div>
      </div>

      <!-- Section 4: IO Lists -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">IO Lists vs String Concatenation</h3>
          <p class="text-xs opacity-60 mb-4">
            IO lists are nested lists of strings, charlists, and integers. They avoid copying data until final output,
            making them far more efficient for building output in loops or templates.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <%= for comp <- io_list_comparisons() do %>
              <div class="bg-base-300 rounded-lg p-4">
                <div class="flex items-center gap-2 mb-2">
                  <span class={"badge badge-sm " <> comp.badge_class}><%= comp.complexity %></span>
                  <span class="font-bold text-sm"><%= comp.title %></span>
                </div>
                <div class="bg-base-100 rounded-lg p-3 font-mono text-xs mb-3 whitespace-pre-wrap"><%= comp.code %></div>
                <p class="text-xs opacity-70"><%= comp.explanation %></p>
              </div>
            <% end %>
          </div>

          <button
            phx-click="toggle_io_list_detail"
            phx-target={@myself}
            class="btn btn-xs btn-ghost mb-3"
          >
            <%= if @show_io_list_detail, do: "Hide details", else: "Show more details" %>
          </button>

          <%= if @show_io_list_detail do %>
            <div class="space-y-3">
              <div class="bg-base-300 rounded-lg p-4">
                <div class="text-xs font-bold opacity-60 mb-2">What can go in an IO list?</div>
                <div class="font-mono text-sm whitespace-pre-wrap"><%= io_list_contents_example() %></div>
              </div>

              <div class="bg-base-300 rounded-lg p-4">
                <div class="text-xs font-bold opacity-60 mb-2">Real-world example: building HTML</div>
                <div class="font-mono text-sm whitespace-pre-wrap"><%= io_list_html_example() %></div>
              </div>

              <div class="alert alert-success text-xs">
                <div>
                  <strong>When to use IO lists:</strong> Phoenix templates, building responses in plugs,
                  logging, any place where you build output from many small pieces. EEx templates
                  already compile to IO lists -- that's why Phoenix is so fast!
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Section 5: Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try Your Own</h3>
          <form phx-submit="run_custom" phx-target={@myself} class="space-y-3">
            <input
              type="text"
              name="code"
              value={@custom_code}
              placeholder={custom_placeholder()}
              class="input input-bordered input-sm font-mono w-full"
              autocomplete="off"
            />
            <div class="flex gap-2">
              <button type="submit" class="btn btn-primary btn-sm">Run</button>
              <span class="text-xs opacity-50 self-center">Try IO, File, or Path operations</span>
            </div>
          </form>

          <!-- Quick examples -->
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

      <!-- Section 6: Key Concepts -->
      <div class="card bg-base-200 shadow-md">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Key Concepts</h3>
          <div class="space-y-3 text-sm">
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">1</span>
              <span><strong>IO.inspect returns its input</strong> &mdash; making it perfect for debugging pipelines without changing behavior.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>Bang (!) vs tuple returns</strong> &mdash; use <code class="font-mono bg-base-100 px-1 rounded">File.read/1</code> for graceful error handling, <code class="font-mono bg-base-100 px-1 rounded">File.read!/1</code> when failure should crash.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>File.stream! is lazy</strong> &mdash; it reads lines on demand, allowing you to process files larger than memory.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>IO lists avoid copying</strong> &mdash; they are the secret behind Phoenix's performance. Prefer them over string concatenation for building output.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>Path is pure</strong> &mdash; Path functions manipulate strings without touching the filesystem. Use File functions to interact with actual files.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_io_tab", %{"id" => id}, socket) do
    {:noreply, socket |> assign(active_io_tab: id) |> assign(active_io_example_idx: 0)}
  end

  def handle_event("select_io_example", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, active_io_example_idx: String.to_integer(idx_str))}
  end

  def handle_event("select_file_tab", %{"id" => id}, socket) do
    {:noreply, socket |> assign(active_file_tab: id) |> assign(active_file_example_idx: 0)}
  end

  def handle_event("select_file_example", %{"idx" => idx_str}, socket) do
    {:noreply, assign(socket, active_file_example_idx: String.to_integer(idx_str))}
  end

  def handle_event("update_path", %{"path" => path}, socket) do
    results = compute_path_results(path)
    {:noreply, socket |> assign(path_input: path) |> assign(path_results: results)}
  end

  def handle_event("toggle_io_list_detail", _params, socket) do
    {:noreply, assign(socket, show_io_list_detail: !socket.assigns.show_io_list_detail)}
  end

  def handle_event("run_custom", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))
    {:noreply, socket |> assign(custom_code: code) |> assign(custom_result: result)}
  end

  def handle_event("quick_example", %{"code" => code}, socket) do
    result = evaluate_code(code)
    {:noreply, socket |> assign(custom_code: code) |> assign(custom_result: result)}
  end

  # Helpers

  defp io_functions, do: @io_functions
  defp file_operations, do: @file_operations
  defp io_list_comparisons, do: @io_list_comparisons

  defp compute_path_results(path) do
    path = String.trim(path)

    if path == "" do
      []
    else
      [
        %{func: "Path.basename/1", result: inspect(Path.basename(path)), note: "The filename component"},
        %{func: "Path.dirname/1", result: inspect(Path.dirname(path)), note: "The directory component"},
        %{func: "Path.extname/1", result: inspect(Path.extname(path)), note: "The file extension (with dot)"},
        %{func: "Path.rootname/1", result: inspect(Path.rootname(path)), note: "Path without the extension"},
        %{func: "Path.split/1", result: inspect(Path.split(path)), note: "Split into segments"},
        %{func: "Path.type/1", result: inspect(Path.type(path)), note: ":absolute, :relative, or :volumerelative"},
        %{func: "Path.expand/1", result: inspect(Path.expand(path)), note: "Resolved to absolute path"}
      ]
    end
  end

  defp io_list_contents_example do
    """
    # IO lists can contain:
    # 1. Strings (binaries)   "hello"
    # 2. Integers (codepoints) ?A or 65
    # 3. Nested IO lists      ["a", ["b", "c"]]

    iolist = ["Name: ", "Alice", ?\\n, "Age: ", Integer.to_string(30)]
    IO.iodata_to_binary(iolist)
    # => "Name: Alice\\nAge: 30"\
    """
  end

  defp io_list_html_example do
    """
    # Building HTML with IO lists (no concatenation!)
    items = ["Elixir", "Erlang", "Phoenix"]

    html = [
      "<ul>",
      Enum.map(items, fn item ->
        ["<li>", item, "</li>"]
      end),
      "</ul>"
    ]

    IO.iodata_to_binary(html)
    # => "<ul><li>Elixir</li><li>Erlang</li><li>Phoenix</li></ul>"\
    """
  end

  defp custom_placeholder do
    "Path.join([\"usr\", \"local\", \"bin\"]) |> Path.expand()"
  end

  defp quick_examples do
    [
      {"Path.join", "Path.join([\"usr\", \"local\", \"bin\"])"},
      {"Path.split", "Path.split(\"/home/user/projects/app.ex\")"},
      {"IO list to binary", "IO.iodata_to_binary([\"Hello\", 32, \"World\"])"},
      {"File.cwd", "File.cwd()"},
      {"IO.iodata_length", "IO.iodata_length([\"Hello\", 32, \"World\"])"}
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
