defmodule ElixirKatasWeb.PhoenixApiKata12FileDownloadsAndStreamingLive do
  use ElixirKatasWeb, :live_component

  @scenarios [
    %{
      id: "small_json",
      name: "Small JSON Response",
      description: "Return inline JSON data (no download)",
      method: "json/2",
      size: "~500 B",
      approach: :inline,
      icon: "J"
    },
    %{
      id: "send_download_binary",
      name: "Generated CSV",
      description: "Generate CSV in memory, send as download",
      method: "send_download/3",
      size: "~2 KB",
      approach: :send_download,
      icon: "C"
    },
    %{
      id: "send_file",
      name: "Static PDF",
      description: "Send an existing file from disk",
      method: "send_file/5",
      size: "~1.2 MB",
      approach: :send_file,
      icon: "P"
    },
    %{
      id: "stream_large",
      name: "Large CSV (Streaming)",
      description: "Stream a large file in chunks",
      method: "chunk/2",
      size: "~50 MB",
      approach: :stream,
      icon: "S"
    }
  ]

  def phoenix_source do
    """
    # File Downloads & Streaming in Phoenix APIs
    #
    # Phoenix provides several ways to send files/data to clients:
    # 1. json/2         — inline JSON (small data)
    # 2. send_download/3 — in-memory binary as a file download
    # 3. send_file/5    — send a file from disk efficiently
    # 4. chunk/2        — stream data in chunks (large files)

    defmodule MyAppWeb.Api.ExportController do
      use MyAppWeb, :controller

      # 1. Inline JSON — small data, no download
      def show(conn, %{"id" => id}) do
        report = Reports.get_report!(id)
        json(conn, %{data: report})
      end

      # 2. send_download/3 — binary content as downloadable file
      #    Great for dynamically generated content (CSV, Excel, etc.)
      def export_csv(conn, %{"id" => id}) do
        records = Reports.list_records(id)

        csv_content =
          records
          |> Enum.map(fn r -> [r.name, r.email, r.status] end)
          |> CSV.encode(headers: ["Name", "Email", "Status"])
          |> Enum.join()

        send_download(conn, {:binary, csv_content},
          filename: "export_\#{id}.csv",
          content_type: "text/csv"
        )
      end

      # 3. send_file/5 — existing file on disk
      #    Efficient: Phoenix/Cowboy uses sendfile(2) syscall
      def download_pdf(conn, %{"id" => id}) do
        path = Reports.pdf_path(id)

        conn
        |> put_resp_header("content-disposition",
           ~s(attachment; filename="report_\#{id}.pdf"))
        |> send_file(200, path)
      end

      # 4. chunk/2 — streaming for large files
      #    Keeps memory low: reads and sends in chunks
      def stream_large_csv(conn, %{"id" => id}) do
        conn =
          conn
          |> put_resp_content_type("text/csv")
          |> put_resp_header("content-disposition",
             ~s(attachment; filename="large_export_\#{id}.csv"))
          |> send_chunked(200)

        # Stream rows from the database
        Reports.stream_records(id)
        |> Stream.chunk_every(1000)
        |> Enum.reduce_while(conn, fn batch, conn ->
          csv_chunk = CSV.encode(batch) |> Enum.join()

          case chunk(conn, csv_chunk) do
            {:ok, conn} -> {:cont, conn}
            {:error, :closed} -> {:halt, conn}
          end
        end)
      end
    end
    """
    |> String.trim()
  end

  def update(assigns, socket) do
    {:ok,
     socket
     |> assign(id: assigns.id)
     |> assign(scenarios: @scenarios)
     |> assign(selected_scenario: nil)
     |> assign(show_comparison: false)
    }
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">File Downloads & Streaming</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Pick a download scenario to see how Phoenix sends data back to the client.
        Compare <code>send_download</code>, <code>send_file</code>, and chunked streaming.
      </p>

      <!-- Scenario Picker -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">1. Pick a Download Scenario</h3>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <%= for scenario <- @scenarios do %>
            <button
              phx-click="select_scenario"
              phx-value-id={scenario.id}
              phx-target={@myself}
              class={["p-4 rounded-lg border-2 text-left transition-all cursor-pointer",
                if(@selected_scenario && @selected_scenario.id == scenario.id,
                  do: "border-rose-500 bg-rose-50 dark:bg-rose-900/20 shadow-md",
                  else: "border-gray-200 dark:border-gray-700 hover:border-rose-300 dark:hover:border-rose-700 bg-white dark:bg-gray-800")
              ]}
            >
              <div class="flex items-center gap-3 mb-2">
                <div class={["w-10 h-10 rounded-lg flex items-center justify-center font-bold text-white text-sm",
                  approach_color(scenario.approach)
                ]}>
                  {scenario.icon}
                </div>
                <div>
                  <div class="font-semibold text-gray-900 dark:text-white">{scenario.name}</div>
                  <div class="text-xs text-gray-500 dark:text-gray-400">{scenario.size}</div>
                </div>
              </div>
              <div class="text-sm text-gray-600 dark:text-gray-400">{scenario.description}</div>
              <div class="mt-2">
                <span class={["px-2 py-0.5 rounded text-xs font-bold font-mono", approach_badge(scenario.approach)]}>
                  {scenario.method}
                </span>
              </div>
            </button>
          <% end %>
        </div>
      </div>

      <!-- Selected Scenario Details -->
      <%= if @selected_scenario do %>
        <!-- Controller Code -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">2. Controller Code</h3>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto">
            <pre class="text-gray-300 whitespace-pre-wrap"><%= controller_code(@selected_scenario) %></pre>
          </div>
        </div>

        <!-- Response Headers -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">3. Response Headers</h3>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm">
            <%= for {header, value} <- response_headers(@selected_scenario) do %>
              <div class="flex gap-2">
                <span class="text-yellow-400">{header}:</span>
                <span class="text-emerald-400">{value}</span>
              </div>
            <% end %>
          </div>

          <!-- Header Explanations -->
          <div class="mt-3 space-y-2">
            <%= for info <- header_explanations(@selected_scenario) do %>
              <div class="flex items-start gap-2 text-sm">
                <span class="font-mono text-xs px-1.5 py-0.5 bg-gray-100 dark:bg-gray-700 rounded text-gray-700 dark:text-gray-300 flex-shrink-0">{info.header}</span>
                <span class="text-gray-600 dark:text-gray-400">{info.explanation}</span>
              </div>
            <% end %>
          </div>
        </div>

        <!-- How It Works -->
        <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">4. How It Works</h3>
          <div class="space-y-3">
            <%= for {step, i} <- Enum.with_index(how_it_works(@selected_scenario)) do %>
              <div class="flex items-start gap-3 p-3 rounded-lg bg-gray-50 dark:bg-gray-700/50">
                <div class="w-7 h-7 rounded-full bg-rose-100 dark:bg-rose-900/30 text-rose-600 dark:text-rose-400 flex items-center justify-center text-sm font-bold flex-shrink-0">
                  {i + 1}
                </div>
                <div class="text-sm text-gray-700 dark:text-gray-300">{step}</div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>

      <!-- Comparison Toggle -->
      <div class="p-5 rounded-lg bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700">
        <div class="flex items-center justify-between mb-3">
          <h3 class="text-lg font-semibold text-gray-900 dark:text-white">Approach Comparison</h3>
          <button
            phx-click="toggle_comparison"
            phx-target={@myself}
            class="px-4 py-1.5 text-sm rounded-lg font-medium bg-rose-600 hover:bg-rose-700 text-white transition-colors cursor-pointer"
          >
            <%= if @show_comparison, do: "Hide", else: "Show" %> Comparison
          </button>
        </div>

        <%= if @show_comparison do %>
          <div class="overflow-x-auto">
            <table class="w-full text-sm">
              <thead>
                <tr class="border-b border-gray-200 dark:border-gray-700">
                  <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Approach</th>
                  <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Memory</th>
                  <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Best For</th>
                  <th class="text-left py-2 px-3 text-gray-700 dark:text-gray-300">Content-Length?</th>
                </tr>
              </thead>
              <tbody>
                <tr class="border-b border-gray-100 dark:border-gray-700/50">
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">json/2</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">Full response in memory</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">Small API responses</td>
                  <td class="py-2 px-3"><span class="px-1.5 py-0.5 rounded text-xs bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400">Yes</span></td>
                </tr>
                <tr class="border-b border-gray-100 dark:border-gray-700/50">
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">send_download/3</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">Full binary in memory</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">Generated files (CSV, Excel)</td>
                  <td class="py-2 px-3"><span class="px-1.5 py-0.5 rounded text-xs bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400">Yes</span></td>
                </tr>
                <tr class="border-b border-gray-100 dark:border-gray-700/50">
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">send_file/5</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">Zero-copy (sendfile syscall)</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">Static files on disk</td>
                  <td class="py-2 px-3"><span class="px-1.5 py-0.5 rounded text-xs bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400">Yes</span></td>
                </tr>
                <tr>
                  <td class="py-2 px-3 font-mono text-rose-600 dark:text-rose-400">chunk/2</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">One chunk at a time</td>
                  <td class="py-2 px-3 text-gray-600 dark:text-gray-400">Large/infinite streams</td>
                  <td class="py-2 px-3"><span class="px-1.5 py-0.5 rounded text-xs bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400">No (chunked)</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        <% end %>
      </div>

      <!-- Key Insight -->
      <div class="p-4 rounded-lg bg-rose-50 dark:bg-rose-900/20 border border-rose-200 dark:border-rose-800">
        <h4 class="font-semibold text-rose-800 dark:text-rose-300 mb-1">Choosing the Right Approach</h4>
        <p class="text-sm text-rose-700 dark:text-rose-400">
          Use <code>json/2</code> for normal API responses. Use <code>send_download/3</code> when you generate
          content in memory (CSV reports, Excel files). Use <code>send_file/5</code> for existing files on disk
          &mdash; it uses the OS-level <code>sendfile(2)</code> syscall for zero-copy performance. Use
          <code>chunk/2</code> with <code>send_chunked/2</code> for large or streaming data where you cannot
          or should not hold the full content in memory.
        </p>
      </div>
    </div>
    """
  end

  defp approach_color(:inline), do: "bg-blue-600"
  defp approach_color(:send_download), do: "bg-emerald-600"
  defp approach_color(:send_file), do: "bg-purple-600"
  defp approach_color(:stream), do: "bg-amber-600"
  defp approach_color(_), do: "bg-gray-600"

  defp approach_badge(:inline), do: "bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-400"
  defp approach_badge(:send_download), do: "bg-emerald-100 dark:bg-emerald-900/30 text-emerald-700 dark:text-emerald-400"
  defp approach_badge(:send_file), do: "bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-400"
  defp approach_badge(:stream), do: "bg-amber-100 dark:bg-amber-900/30 text-amber-700 dark:text-amber-400"
  defp approach_badge(_), do: "bg-gray-100 dark:bg-gray-900/30 text-gray-700 dark:text-gray-400"

  defp controller_code(%{approach: :inline}) do
    """
    def show(conn, %{"id" => id}) do
      report = Reports.get_report!(id)

      # json/2 encodes and sends inline
      json(conn, %{data: report})
    end\
    """
  end

  defp controller_code(%{approach: :send_download}) do
    """
    def export_csv(conn, %{"id" => id}) do
      records = Reports.list_records(id)

      csv_content =
        records
        |> Enum.map(fn r -> [r.name, r.email, r.status] end)
        |> CSV.encode(headers: ["Name", "Email", "Status"])
        |> Enum.join()

      # send_download/3 sends binary as a file download
      send_download(conn, {:binary, csv_content},
        filename: "export_\#{id}.csv",
        content_type: "text/csv"
      )
    end\
    """
  end

  defp controller_code(%{approach: :send_file}) do
    """
    def download_pdf(conn, %{"id" => id}) do
      path = Reports.pdf_path(id)

      conn
      |> put_resp_header("content-disposition",
         ~s(attachment; filename="report_\#{id}.pdf"))
      |> send_file(200, path)
      # Uses OS-level sendfile(2) — zero-copy!
    end\
    """
  end

  defp controller_code(%{approach: :stream}) do
    """
    def stream_large_csv(conn, %{"id" => id}) do
      conn =
        conn
        |> put_resp_content_type("text/csv")
        |> put_resp_header("content-disposition",
           ~s(attachment; filename="large_\#{id}.csv"))
        |> send_chunked(200)

      Reports.stream_records(id)
      |> Stream.chunk_every(1000)
      |> Enum.reduce_while(conn, fn batch, conn ->
        csv = CSV.encode(batch) |> Enum.join()

        case chunk(conn, csv) do
          {:ok, conn} -> {:cont, conn}
          {:error, :closed} -> {:halt, conn}
        end
      end)
    end\
    """
  end

  defp response_headers(%{approach: :inline}) do
    [
      {"HTTP/1.1", "200 OK"},
      {"Content-Type", "application/json; charset=utf-8"},
      {"Content-Length", "487"}
    ]
  end

  defp response_headers(%{approach: :send_download}) do
    [
      {"HTTP/1.1", "200 OK"},
      {"Content-Type", "text/csv"},
      {"Content-Disposition", "attachment; filename=\"export_42.csv\""},
      {"Content-Length", "2048"}
    ]
  end

  defp response_headers(%{approach: :send_file}) do
    [
      {"HTTP/1.1", "200 OK"},
      {"Content-Type", "application/pdf"},
      {"Content-Disposition", "attachment; filename=\"report_42.pdf\""},
      {"Content-Length", "1258291"}
    ]
  end

  defp response_headers(%{approach: :stream}) do
    [
      {"HTTP/1.1", "200 OK"},
      {"Content-Type", "text/csv"},
      {"Content-Disposition", "attachment; filename=\"large_42.csv\""},
      {"Transfer-Encoding", "chunked"}
    ]
  end

  defp header_explanations(%{approach: :inline}) do
    [
      %{header: "Content-Type", explanation: "application/json tells the client to parse as JSON, not trigger a download."},
      %{header: "Content-Length", explanation: "Exact byte count of the JSON body. Phoenix calculates this automatically."}
    ]
  end

  defp header_explanations(%{approach: :send_download}) do
    [
      %{header: "Content-Disposition", explanation: "\"attachment\" tells the browser to download the file instead of displaying it."},
      %{header: "filename", explanation: "The suggested filename for the downloaded file."},
      %{header: "Content-Length", explanation: "Known upfront since the entire binary is in memory."}
    ]
  end

  defp header_explanations(%{approach: :send_file}) do
    [
      %{header: "Content-Disposition", explanation: "\"attachment\" triggers a download dialog in the browser."},
      %{header: "Content-Length", explanation: "Read from the file's size on disk before sending."},
      %{header: "sendfile(2)", explanation: "The OS sends the file directly from disk to the network socket, bypassing userspace (zero-copy)."}
    ]
  end

  defp header_explanations(%{approach: :stream}) do
    [
      %{header: "Transfer-Encoding", explanation: "\"chunked\" means data is sent in pieces. No Content-Length is needed."},
      %{header: "Content-Disposition", explanation: "\"attachment\" still triggers a download, but the browser shows progress without a total size."}
    ]
  end

  defp how_it_works(%{approach: :inline}) do
    [
      "Controller fetches data from the database",
      "json/2 encodes the map to JSON using Jason",
      "Phoenix sets Content-Type: application/json and calculates Content-Length",
      "Full response is sent in a single write"
    ]
  end

  defp how_it_works(%{approach: :send_download}) do
    [
      "Controller generates the CSV content as a binary string in memory",
      "send_download/3 receives {:binary, content} and the filename",
      "Phoenix sets Content-Disposition: attachment to trigger download",
      "The full binary is sent as the response body"
    ]
  end

  defp how_it_works(%{approach: :send_file}) do
    [
      "Controller resolves the file path on disk",
      "send_file/5 is called with status 200 and the file path",
      "Cowboy/Bandit uses the OS sendfile(2) syscall",
      "The kernel sends the file directly from disk to the TCP socket (zero-copy)"
    ]
  end

  defp how_it_works(%{approach: :stream}) do
    [
      "Controller calls send_chunked(200) to begin a chunked response",
      "Database records are streamed (not loaded all at once)",
      "Records are batched into groups of 1000 and encoded to CSV",
      "Each batch is sent with chunk(conn, data)",
      "If the client disconnects, {:error, :closed} stops the stream",
      "Memory usage stays constant regardless of total data size"
    ]
  end

  def handle_event("select_scenario", %{"id" => id}, socket) do
    scenario = Enum.find(@scenarios, &(&1.id == id))
    {:noreply, assign(socket, selected_scenario: scenario)}
  end

  def handle_event("toggle_comparison", _params, socket) do
    {:noreply, assign(socket, show_comparison: !socket.assigns.show_comparison)}
  end
end
