defmodule ElixirKatasWeb.PhoenixKata06TcpSocketsInElixirLive do
  use ElixirKatasWeb, :live_component

  def phoenix_source do
    """
    defmodule SimpleServer do
      def start(port \\\\ 4001) do
        # Step 1: Listen on a port
        {:ok, listen_socket} = :gen_tcp.listen(port, [
          :binary,             # receive data as binaries
          packet: :raw,        # raw TCP data
          active: false,       # we'll read manually
          reuseaddr: true      # reuse port after restart
        ])
        IO.puts("Listening on port \#{port}...")
        accept_loop(listen_socket)
      end

      # Step 2: Accept connections in a loop
      defp accept_loop(listen_socket) do
        {:ok, client} = :gen_tcp.accept(listen_socket)  # Blocks until client connects
        spawn(fn -> handle_client(client) end)           # Handle in new process!
        accept_loop(listen_socket)                       # Accept next connection
      end

      defp handle_client(client) do
        # Step 3: Read the request
        {:ok, request} = :gen_tcp.recv(client, 0)        # 0 = read all available data
        IO.puts("Request: \#{String.split(request, "\\r\\n") |> hd()}")

        # Step 4: Send a response
        response = "HTTP/1.1 200 OK\\r\\nContent-Type: text/html\\r\\n\\r\\n<h1>Hello from raw TCP!</h1>"
        :gen_tcp.send(client, response)

        # Step 5: Close the connection
        :gen_tcp.close(client)
      end
    end
    """
    |> String.trim()
  end

  def mount(socket) do
    {:ok,
     assign(socket,
       step: 0,
       server_log: [],
       client_request: nil,
       server_response: nil,
       port: 4001
     )}
  end

  def update(assigns, socket) do
    {:ok, assign(socket, id: assigns.id)}
  end

  def render(assigns) do
    ~H"""
    <div class="space-y-6">
      <h2 class="text-2xl font-bold text-gray-900 dark:text-white">TCP Sockets in Elixir</h2>
      <p class="text-gray-600 dark:text-gray-300">
        Before HTTP, before Phoenix — there's TCP. Step through building a raw TCP server in Elixir.
      </p>

      <!-- Code walkthrough -->
      <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <!-- Server code -->
        <div class="space-y-4">
          <h3 class="text-lg font-semibold text-teal-700 dark:text-teal-400">Server Code</h3>
          <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm overflow-x-auto whitespace-pre">
            <div class={["transition-opacity", if(@step >= 0, do: "opacity-100", else: "opacity-30")]}>
              <span class="text-gray-500"># Step 1: Listen on a port</span>
              <pre class="text-green-400 m-0">{step1_code(@port)}</pre>
            </div>

            <div class={["mt-4 transition-opacity", if(@step >= 1, do: "opacity-100", else: "opacity-30")]}>
              <span class="text-gray-500"># Step 2: Accept a connection</span>
              <pre class="text-yellow-300 m-0">{step2_code()}</pre>
              <span class="text-gray-500"># Blocks until a client connects</span>
            </div>

            <div class={["mt-4 transition-opacity", if(@step >= 2, do: "opacity-100", else: "opacity-30")]}>
              <span class="text-gray-500"># Step 3: Read the request</span>
              <pre class="text-cyan-300 m-0">{step3_code()}</pre>
              <span class="text-gray-500"># 0 = read all available data</span>
            </div>

            <div class={["mt-4 transition-opacity", if(@step >= 3, do: "opacity-100", else: "opacity-30")]}>
              <span class="text-gray-500"># Step 4: Send a response</span>
              <pre class="text-pink-300 m-0">{step4_code()}</pre>
            </div>

            <div class={["mt-4 transition-opacity", if(@step >= 4, do: "opacity-100", else: "opacity-30")]}>
              <span class="text-gray-500"># Step 5: Close the connection</span>
              <pre class="text-red-400 m-0">{step5_code()}</pre>
            </div>
          </div>
        </div>

        <!-- Server log / visualization -->
        <div class="space-y-4">
          <h3 class="text-lg font-semibold text-teal-700 dark:text-teal-400">What's Happening</h3>

          <div class="bg-gray-50 dark:bg-gray-800 rounded-lg p-4 border border-gray-200 dark:border-gray-700 min-h-[300px]">
            <div class="space-y-3">
              <%= for {log, idx} <- Enum.with_index(@server_log) do %>
                <div class={["flex items-start gap-3 text-sm animate-fade-in",
                  if(idx == length(@server_log) - 1, do: "font-semibold", else: "")]}>
                  <span class={["w-6 h-6 rounded-full flex items-center justify-center text-xs text-white flex-shrink-0", log.color]}>
                    {idx + 1}
                  </span>
                  <div>
                    <p class="text-gray-800 dark:text-gray-200">{log.title}</p>
                    <p class="text-xs text-gray-500 dark:text-gray-400 mt-0.5">{log.detail}</p>
                  </div>
                </div>
              <% end %>

              <%= if @server_log == [] do %>
                <div class="flex items-center justify-center h-48 text-gray-400">
                  <p>Click "Next Step" to start the TCP server</p>
                </div>
              <% end %>
            </div>
          </div>

          <!-- Network visualization -->
          <%= if @step >= 1 do %>
            <div class="p-4 rounded-lg bg-white dark:bg-gray-700 border border-gray-200 dark:border-gray-600">
              <div class="flex items-center justify-between">
                <div class="text-center">
                  <div class="w-16 h-16 rounded-full bg-amber-100 dark:bg-amber-900 flex items-center justify-center mx-auto">
                    <span class="text-2xl">💻</span>
                  </div>
                  <span class="text-xs font-medium mt-1">Client</span>
                </div>

                <div class="flex-1 mx-4">
                  <%= if @step >= 2 do %>
                    <div class="text-center text-xs text-cyan-600 dark:text-cyan-400 font-mono mb-1">
                      {if @client_request, do: @client_request, else: ""}
                    </div>
                  <% end %>
                  <div class="h-0.5 bg-gray-300 dark:bg-gray-500 relative">
                    <%= if @step >= 2 do %>
                      <div class="absolute right-0 top-1/2 -translate-y-1/2 text-cyan-500">→</div>
                    <% end %>
                    <%= if @step >= 3 do %>
                      <div class="absolute left-0 top-1/2 -translate-y-1/2 text-pink-500">←</div>
                    <% end %>
                  </div>
                  <%= if @step >= 3 do %>
                    <div class="text-center text-xs text-pink-600 dark:text-pink-400 font-mono mt-1">
                      {if @server_response, do: @server_response, else: ""}
                    </div>
                  <% end %>
                </div>

                <div class="text-center">
                  <div class="w-16 h-16 rounded-full bg-teal-100 dark:bg-teal-900 flex items-center justify-center mx-auto">
                    <span class="text-2xl">🖥️</span>
                  </div>
                  <span class="text-xs font-medium mt-1">Server :{@port}</span>
                </div>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Controls -->
      <div class="flex items-center gap-3">
        <button
          phx-click="next_tcp_step"
          phx-target={@myself}
          disabled={@step > 4}
          class={["px-4 py-2 rounded-lg font-medium transition-colors cursor-pointer",
            if(@step > 4, do: "bg-gray-200 text-gray-400 cursor-not-allowed", else: "bg-teal-600 hover:bg-teal-700 text-white")]}
        >
          Next Step
        </button>
        <button
          phx-click="reset_tcp"
          phx-target={@myself}
          class="px-4 py-2 rounded-lg font-medium bg-gray-200 dark:bg-gray-700 hover:bg-gray-300 dark:hover:bg-gray-600 text-gray-700 dark:text-gray-300 transition-colors cursor-pointer"
        >
          Reset
        </button>
        <span class="text-sm text-gray-500">Step {@step} of 5</span>
      </div>

      <!-- Complete server module -->
      <div class="mt-6">
        <h3 class="text-lg font-semibold text-gray-900 dark:text-white mb-3">Complete Module</h3>
        <div class="bg-gray-900 rounded-lg p-4 font-mono text-sm text-green-400 overflow-x-auto whitespace-pre">{complete_server_code()}</div>
      </div>
    </div>
    """
  end

  def handle_event("next_tcp_step", _, socket) do
    step = socket.assigns.step
    new_step = min(step + 1, 5)

    log_entry = step_log(step)
    server_log = socket.assigns.server_log ++ [log_entry]

    socket =
      socket
      |> assign(:step, new_step)
      |> assign(:server_log, server_log)

    socket =
      case step do
        2 -> assign(socket, client_request: "GET / HTTP/1.1")
        3 -> assign(socket, server_response: "HTTP/1.1 200 OK")
        _ -> socket
      end

    {:noreply, socket}
  end

  def handle_event("reset_tcp", _, socket) do
    {:noreply,
     assign(socket,
       step: 0,
       server_log: [],
       client_request: nil,
       server_response: nil
     )}
  end

  defp step_log(0) do
    %{title: "Server listening on port 4001",
      detail: ":gen_tcp.listen/2 creates a socket and binds to port 4001. Waiting for connections...",
      color: "bg-green-500"}
  end

  defp step_log(1) do
    %{title: "Client connected!",
      detail: ":gen_tcp.accept/1 returned — a TCP connection is now established.",
      color: "bg-yellow-500"}
  end

  defp step_log(2) do
    %{title: "Received request data",
      detail: ":gen_tcp.recv/2 read the client's HTTP request: GET / HTTP/1.1",
      color: "bg-cyan-500"}
  end

  defp step_log(3) do
    %{title: "Sent response",
      detail: ":gen_tcp.send/2 sent back: HTTP/1.1 200 OK\\r\\n\\r\\nHello!",
      color: "bg-pink-500"}
  end

  defp step_log(4) do
    %{title: "Connection closed",
      detail: ":gen_tcp.close/1 terminated the TCP connection. Ready for next client.",
      color: "bg-red-500"}
  end

  defp step_log(_), do: %{title: "Done", detail: "", color: "bg-gray-500"}

  defp step1_code(port) do
    "{:ok, listen_socket} = :gen_tcp.listen(#{port}, [\n  :binary,             # receive data as binaries\n  packet: :raw,         # raw TCP data\n  active: false,        # we'll read manually\n  reuseaddr: true       # reuse port after restart\n])"
  end

  defp step2_code do
    "{:ok, client_socket} = :gen_tcp.accept(listen_socket)"
  end

  defp step3_code do
    "{:ok, request} = :gen_tcp.recv(client_socket, 0)"
  end

  defp step4_code do
    "response = \"HTTP/1.1 200 OK\\r\\n\\r\\nHello!\"\n:gen_tcp.send(client_socket, response)"
  end

  defp step5_code do
    ":gen_tcp.close(client_socket)"
  end

  defp complete_server_code do
    """
    defmodule SimpleServer do
      def start(port \\\\ 4001) do
        {:ok, listen_socket} = :gen_tcp.listen(port, [
          :binary, packet: :raw, active: false, reuseaddr: true
        ])
        IO.puts("Listening on port \#{port}...")
        accept_loop(listen_socket)
      end

      defp accept_loop(listen_socket) do
        {:ok, client} = :gen_tcp.accept(listen_socket)
        spawn(fn -> handle_client(client) end)  # Handle in new process!
        accept_loop(listen_socket)               # Accept next connection
      end

      defp handle_client(client) do
        {:ok, request} = :gen_tcp.recv(client, 0)
        IO.puts("Request: \#{String.split(request, "\\r\\n") |> hd()}")

        response = "HTTP/1.1 200 OK\\r\\nContent-Type: text/html\\r\\n\\r\\n<h1>Hello from raw TCP!</h1>"
        :gen_tcp.send(client, response)
        :gen_tcp.close(client)
      end
    end\
    """
    |> String.trim()
  end
end
