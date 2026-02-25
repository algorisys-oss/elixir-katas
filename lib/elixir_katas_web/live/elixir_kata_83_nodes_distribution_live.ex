defmodule ElixirKatasWeb.ElixirKata83NodesDistributionLive do
  use ElixirKatasWeb, :live_component

  @node_basics [
    %{
      id: "self",
      label: "Node.self/0",
      code: "Node.self()\n# => :nonode@nohost\n# (when not running as a distributed node)\n\n# When started with --sname:\n# => :alice@hostname",
      explanation: "Returns the name of the current node. If the VM was not started with --sname or --name, it returns :nonode@nohost."
    },
    %{
      id: "alive",
      label: "Node.alive?/0",
      code: "Node.alive?()\n# => false  (not started as distributed node)\n\n# After starting with: iex --sname alice\nNode.alive?()\n# => true",
      explanation: "Returns true if the VM was started as a distributed node (with --sname or --name), false otherwise."
    },
    %{
      id: "list",
      label: "Node.list/0",
      code: "Node.list()\n# => []  (no connected nodes)\n\n# After connecting to another node:\nNode.list()\n# => [:bob@hostname]",
      explanation: "Returns a list of all connected nodes, not including the current node. Returns [] when running standalone."
    },
    %{
      id: "connect",
      label: "Node.connect/1",
      code: "# From node :alice@hostname:\nNode.connect(:bob@hostname)\n# => true\n\nNode.list()\n# => [:bob@hostname]",
      explanation: "Attempts to connect to another node. Returns true on success, false on failure. Both nodes must share the same cookie."
    }
  ]

  @starting_nodes [
    %{
      id: "sname",
      label: "--sname (short name)",
      command: "iex --sname alice",
      result: "Node.self() #=> :alice@hostname",
      description: "Short names use only the hostname (no domain). Nodes must be on the same network or machine. Simpler setup.",
      cookie_note: "Default cookie is read from ~/.erlang.cookie"
    },
    %{
      id: "name",
      label: "--name (full name)",
      command: "iex --name alice@192.168.1.10",
      result: "Node.self() #=> :\"alice@192.168.1.10\"",
      description: "Full names include the domain or IP address. Required for connecting nodes across different networks.",
      cookie_note: "Must specify cookie with --cookie or share ~/.erlang.cookie"
    },
    %{
      id: "cookie",
      label: "--cookie",
      command: "iex --sname alice --cookie my_secret",
      result: "Node.get_cookie() #=> :my_secret",
      description: "The cookie is a shared secret. Only nodes with the same cookie can connect. It is a simple authentication mechanism.",
      cookie_note: "All nodes in a cluster must share the same cookie value"
    },
    %{
      id: "mix",
      label: "Mix project",
      command: "iex --sname alice -S mix",
      result: "# Starts your Mix project as a named node",
      description: "Combine --sname with -S mix to start your application as a distributed node. This is the typical way to run distributed Elixir apps.",
      cookie_note: "Can also set cookie in config: config :my_app, cookie: :my_secret"
    }
  ]

  @remote_communication [
    %{
      id: "rpc_call",
      label: ":rpc.call/4",
      code: "# Execute a function on a remote node and get the result\n:rpc.call(:bob@hostname, String, :upcase, [\"hello\"])\n# => \"HELLO\"\n\n# With timeout (5 seconds)\n:rpc.call(:bob@hostname, Enum, :sum, [[1, 2, 3]], 5000)\n# => 6",
      explanation: "Calls a function on a remote node and waits for the result. The calling process blocks until the result arrives or the timeout expires."
    },
    %{
      id: "node_spawn",
      label: "Node.spawn/2",
      code: "# Spawn a process on a remote node\nNode.spawn(:bob@hostname, fn ->\n  IO.puts(\"Running on: \" <> inspect(Node.self()))\nend)\n# => #PID<12345.200.0>\n# Prints on bob: \"Running on: :bob@hostname\"",
      explanation: "Spawns a process on the specified remote node. The process runs remotely but you get a PID you can send messages to."
    },
    %{
      id: "send_remote",
      label: "send to remote",
      code: "# Send a message to a named process on another node\nsend({:my_server, :bob@hostname}, {:hello, \"from alice\"})\n\n# Or using a remote PID directly\nsend(remote_pid, :ping)",
      explanation: "You can send messages to processes on remote nodes using {name, node} tuples or remote PIDs. The BEAM distribution layer handles the networking transparently."
    },
    %{
      id: "spawn_link",
      label: "Node.spawn_link/2",
      code: "# Spawn a linked process on a remote node\nNode.spawn_link(:bob@hostname, fn ->\n  Process.sleep(1000)\n  raise \"boom!\"\nend)\n# The local process will also crash due to the link",
      explanation: "Like Node.spawn/2 but creates a link between the local and remote processes. If either crashes, the other is notified (or crashes too)."
    }
  ]

  @global_registration [
    %{
      id: "register",
      label: ":global.register_name/2",
      code: "# Register a process with a globally unique name\n:global.register_name(:my_service, self())\n# => :yes  (success)\n# => :no   (name already taken on any node)",
      explanation: "Registers a process under a globally unique name across all connected nodes. Only one process in the entire cluster can hold a given name."
    },
    %{
      id: "whereis",
      label: ":global.whereis_name/1",
      code: "# Find a globally registered process from any node\n:global.whereis_name(:my_service)\n# => #PID<12345.200.0>  (might be on a remote node)\n# => :undefined          (not registered)",
      explanation: "Looks up a globally registered process by name. Returns the PID regardless of which node it lives on, or :undefined if not found."
    },
    %{
      id: "unregister",
      label: ":global.unregister_name/1",
      code: ":global.unregister_name(:my_service)\n# => :ok\n\n# Names are automatically unregistered when the process dies",
      explanation: "Removes a global name registration. Also happens automatically when the registered process terminates."
    },
    %{
      id: "pg",
      label: ":pg (process groups)",
      code: "# Start pg (usually in your supervision tree)\n:pg.start_link()\n\n# Join a group\n:pg.join(:my_group, self())\n\n# Get all members across all nodes\n:pg.get_members(:my_group)\n# => [#PID<0.100.0>, #PID<12345.200.0>]\n\n# Get only local members\n:pg.get_local_members(:my_group)",
      explanation: ":pg provides process groups that span across nodes. Multiple processes can join the same group. Useful for pub/sub, worker pools, and service discovery."
    }
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_basic, fn -> hd(@node_basics) end)
     |> assign_new(:active_start, fn -> hd(@starting_nodes) end)
     |> assign_new(:show_starting, fn -> false end)
     |> assign_new(:active_remote, fn -> hd(@remote_communication) end)
     |> assign_new(:show_remote, fn -> false end)
     |> assign_new(:active_global, fn -> hd(@global_registration) end)
     |> assign_new(:show_global, fn -> false end)
     |> assign_new(:show_diagram, fn -> false end)
     |> assign_new(:sandbox_code, fn -> "" end)
     |> assign_new(:sandbox_result, fn -> nil end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Nodes &amp; Distribution</h2>
      <p class="text-sm opacity-70 mb-6">
        The BEAM VM supports transparent distribution: processes on different machines can communicate
        using the same <code class="font-mono bg-base-300 px-1 rounded">send</code> and
        <code class="font-mono bg-base-300 px-1 rounded">receive</code> primitives as local processes.
        This kata explores how to start nodes, connect them, and communicate across the cluster.
      </p>

      <!-- Node Basics -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-3">Node Basics</h3>
          <p class="text-xs opacity-60 mb-3">
            Every BEAM VM instance can become a node. These functions let you inspect and manage node connectivity.
          </p>
          <div class="flex flex-wrap gap-2 mb-4">
            <%= for basic <- node_basics() do %>
              <button
                phx-click="select_basic"
                phx-target={@myself}
                phx-value-id={basic.id}
                class={"btn btn-sm " <> if(@active_basic.id == basic.id, do: "btn-primary", else: "btn-outline")}
              >
                <%= basic.label %>
              </button>
            <% end %>
          </div>

          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_basic.code %></div>
          <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
            <%= @active_basic.explanation %>
          </div>

          <!-- Live values -->
          <div class="mt-4 bg-base-100 rounded-lg p-3 border border-base-300">
            <div class="text-xs font-bold opacity-60 mb-2">Current Node Values</div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-2 font-mono text-xs">
              <div>
                <span class="opacity-50">Node.self() =&gt; </span>
                <span class="text-primary font-bold"><%= inspect(Node.self()) %></span>
              </div>
              <div>
                <span class="opacity-50">Node.alive?() =&gt; </span>
                <span class="text-accent font-bold"><%= inspect(Node.alive?()) %></span>
              </div>
              <div>
                <span class="opacity-50">Node.list() =&gt; </span>
                <span class="text-secondary font-bold"><%= inspect(Node.list()) %></span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Starting Nodes -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Starting Named Nodes</h3>
            <button
              phx-click="toggle_starting"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_starting, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_starting do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for start <- starting_nodes() do %>
                <button
                  phx-click="select_start"
                  phx-target={@myself}
                  phx-value-id={start.id}
                  class={"btn btn-sm " <> if(@active_start.id == start.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= start.label %>
                </button>
              <% end %>
            </div>

            <div class="bg-base-100 rounded-lg p-4 border border-base-300 mb-3">
              <div class="font-mono text-sm mb-2">
                <span class="opacity-50">$ </span><span class="text-primary font-bold"><%= @active_start.command %></span>
              </div>
              <div class="font-mono text-xs opacity-70 mb-3"><%= @active_start.result %></div>
              <p class="text-sm opacity-70 mb-2"><%= @active_start.description %></p>
              <div class="text-xs bg-warning/10 border border-warning/30 rounded-lg p-2">
                <strong>Cookie:</strong> <%= @active_start.cookie_note %>
              </div>
            </div>

            <!-- Connection Steps -->
            <div class="alert alert-info text-xs">
              <div>
                <strong>Quick connect recipe:</strong><br/>
                Terminal 1: <code class="font-mono bg-base-100 px-1 rounded">iex --sname alice</code><br/>
                Terminal 2: <code class="font-mono bg-base-100 px-1 rounded">iex --sname bob</code><br/>
                In alice: <code class="font-mono bg-base-100 px-1 rounded">Node.connect(:bob@hostname)</code><br/>
                Verify: <code class="font-mono bg-base-100 px-1 rounded">Node.list()</code> shows the other node
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Remote Communication -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Remote Communication</h3>
            <button
              phx-click="toggle_remote"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_remote, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_remote do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for remote <- remote_communication() do %>
                <button
                  phx-click="select_remote"
                  phx-target={@myself}
                  phx-value-id={remote.id}
                  class={"btn btn-sm " <> if(@active_remote.id == remote.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= remote.label %>
                </button>
              <% end %>
            </div>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_remote.code %></div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
              <%= @active_remote.explanation %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Global Registration & Process Groups -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Global Registration &amp; Process Groups</h3>
            <button
              phx-click="toggle_global"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_global, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_global do %>
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for global <- global_registration() do %>
                <button
                  phx-click="select_global"
                  phx-target={@myself}
                  phx-value-id={global.id}
                  class={"btn btn-sm " <> if(@active_global.id == global.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= global.label %>
                </button>
              <% end %>
            </div>

            <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_global.code %></div>
            <div class="bg-info/10 border border-info/30 rounded-lg p-3 text-sm">
              <%= @active_global.explanation %>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Architecture Diagram -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Multi-Node Topology</h3>
            <button
              phx-click="toggle_diagram"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_diagram, do: "Hide", else: "Show" %>
            </button>
          </div>

          <%= if @show_diagram do %>
            <div class="bg-base-300 rounded-lg p-4 font-mono text-xs whitespace-pre mb-4 overflow-x-auto"><%= architecture_diagram() %></div>

            <div class="space-y-3">
              <div class="bg-base-100 rounded-lg p-3 border border-base-300">
                <div class="font-bold text-xs text-primary mb-1">Full Mesh (Default)</div>
                <p class="text-xs opacity-70">
                  By default, Distributed Erlang forms a full mesh: every node connects to every other node.
                  When Alice connects to Bob who is already connected to Carol, Alice automatically connects to Carol too.
                </p>
              </div>
              <div class="bg-base-100 rounded-lg p-3 border border-base-300">
                <div class="font-bold text-xs text-primary mb-1">Cookie-Based Auth</div>
                <p class="text-xs opacity-70">
                  The cookie is a shared secret (atom). Nodes can only connect if they share the same cookie.
                  It is NOT encryption -- all traffic between nodes is unencrypted by default. Use TLS for production.
                </p>
              </div>
              <div class="bg-base-100 rounded-lg p-3 border border-base-300">
                <div class="font-bold text-xs text-primary mb-1">Hidden Nodes</div>
                <p class="text-xs opacity-70">
                  Start with <code class="font-mono bg-base-300 px-1 rounded">--hidden</code> to connect without joining the full mesh.
                  Hidden nodes do not appear in Node.list() on other nodes unless explicitly connected.
                </p>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Try Your Own -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Try It</h3>
          <p class="text-xs opacity-60 mb-3">
            Note: Most node operations require an actual distributed setup. The sandbox runs locally, so
            Node.self() returns :nonode@nohost and Node.list() returns [].
          </p>
          <form phx-submit="run_sandbox" phx-target={@myself} class="space-y-3">
            <textarea
              name="code"
              rows="4"
              class="textarea textarea-bordered font-mono text-sm w-full"
              placeholder={"Node.self()\n# Most distribution functions need --sname\n# Try: Node.alive?() or Node.get_cookie()"}
              autocomplete="off"
            ><%= @sandbox_code %></textarea>
            <button type="submit" class="btn btn-primary btn-sm">Evaluate</button>
          </form>

          <!-- Quick Examples -->
          <div class="flex flex-wrap gap-2 mt-3 mb-3">
            <span class="text-xs opacity-50 self-center">Examples:</span>
            <%= for {label, code} <- sandbox_examples() do %>
              <button
                phx-click="quick_sandbox"
                phx-target={@myself}
                phx-value-code={code}
                class="btn btn-xs btn-outline"
              >
                <%= label %>
              </button>
            <% end %>
          </div>

          <%= if @sandbox_result do %>
            <div class={"alert text-sm mt-3 " <> if(@sandbox_result.ok, do: "alert-success", else: "alert-error")}>
              <div class="font-mono"><%= @sandbox_result.output %></div>
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
              <span><strong>Transparent distribution:</strong> send/receive work the same whether the target process is local or on a remote node.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span>Start distributed nodes with <code class="font-mono bg-base-100 px-1 rounded">--sname</code> (same network) or <code class="font-mono bg-base-100 px-1 rounded">--name</code> (cross-network), and use <code class="font-mono bg-base-100 px-1 rounded">Node.connect/1</code> to join them.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Cookie authentication:</strong> all nodes in a cluster must share the same cookie. This is NOT encryption -- use TLS for secure communication.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">:rpc.call/4</code> executes a function on a remote node and returns the result. <code class="font-mono bg-base-100 px-1 rounded">Node.spawn/2</code> creates a process on a remote node.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><code class="font-mono bg-base-100 px-1 rounded">:global</code> provides cluster-wide unique name registration, while <code class="font-mono bg-base-100 px-1 rounded">:pg</code> provides process groups for multi-member services across nodes.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_basic", %{"id" => id}, socket) do
    basic = Enum.find(node_basics(), &(&1.id == id))
    {:noreply, assign(socket, active_basic: basic)}
  end

  def handle_event("toggle_starting", _params, socket) do
    {:noreply, assign(socket, show_starting: !socket.assigns.show_starting)}
  end

  def handle_event("select_start", %{"id" => id}, socket) do
    start = Enum.find(starting_nodes(), &(&1.id == id))
    {:noreply, assign(socket, active_start: start)}
  end

  def handle_event("toggle_remote", _params, socket) do
    {:noreply, assign(socket, show_remote: !socket.assigns.show_remote)}
  end

  def handle_event("select_remote", %{"id" => id}, socket) do
    remote = Enum.find(remote_communication(), &(&1.id == id))
    {:noreply, assign(socket, active_remote: remote)}
  end

  def handle_event("toggle_global", _params, socket) do
    {:noreply, assign(socket, show_global: !socket.assigns.show_global)}
  end

  def handle_event("select_global", %{"id" => id}, socket) do
    global = Enum.find(global_registration(), &(&1.id == id))
    {:noreply, assign(socket, active_global: global)}
  end

  def handle_event("toggle_diagram", _params, socket) do
    {:noreply, assign(socket, show_diagram: !socket.assigns.show_diagram)}
  end

  def handle_event("run_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(String.trim(code))

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  def handle_event("quick_sandbox", %{"code" => code}, socket) do
    result = evaluate_code(code)

    {:noreply,
     socket
     |> assign(sandbox_code: code)
     |> assign(sandbox_result: result)}
  end

  # Helpers

  defp node_basics, do: @node_basics
  defp starting_nodes, do: @starting_nodes
  defp remote_communication, do: @remote_communication
  defp global_registration, do: @global_registration

  defp architecture_diagram do
    """
    Full Mesh Topology (3 nodes):

    +-------------------+
    |   :alice@host1     |
    |   [GenServer A]    |
    +--------+----------+
             |\\
             | \\
             |  \\  (TCP connections)
             |   \\
    +--------+--+ +--+-----------+
    | :bob@host2 | | :carol@host3 |
    | [Worker B] +-+ [Worker C]   |
    +------------+ +--------------+

    Every node connects to every other node.
    Messages are routed transparently.

    Cookie: :my_secret_cookie (shared by all)

    Connection flow:
    1. alice> Node.connect(:bob@host2)    => true
    2. bob>   Node.connect(:carol@host3)  => true
    3. alice> Node.list()  => [:bob@host2, :carol@host3]
       (alice auto-connects to carol via bob)\
    """
  end

  defp sandbox_examples do
    [
      {"Node.self",
       "Node.self()"},
      {"Node.alive?",
       "Node.alive?()"},
      {"Node.list",
       "Node.list()"},
      {"get_cookie",
       "Node.get_cookie()"},
      {"node info",
       "{Node.self(), Node.alive?(), Node.list(), Node.get_cookie()}"}
    ]
  end

  defp evaluate_code(code) do
    try do
      {result, _bindings} = Code.eval_string(code)
      %{ok: true, output: inspect(result, pretty: true, limit: 50)}
    rescue
      e -> %{ok: false, output: "Error: #{Exception.message(e)}"}
    end
  end
end
