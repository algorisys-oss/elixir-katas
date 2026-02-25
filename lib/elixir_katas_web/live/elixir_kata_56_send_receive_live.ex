defmodule ElixirKatasWeb.ElixirKata56SendReceiveLive do
  use ElixirKatasWeb, :live_component

  @examples [
    %{
      id: "basic_send",
      title: "Basic send/2",
      code: "pid = self()\nsend(pid, :hello)\n\nreceive do\n  :hello -> \"Got hello!\"\nend",
      result: ~s|"Got hello!"|,
      explanation: "send/2 puts a message into a process's mailbox. receive pulls it out. Here we send to ourselves."
    },
    %{
      id: "pattern_match",
      title: "Pattern Matching in receive",
      code: ~s|send(self(), {:greeting, "Alice"})\n\nreceive do\n  {:greeting, name} ->\n    "Hello, \#{name}!"\n  {:farewell, name} ->\n    "Goodbye, \#{name}!"\nend|,
      result: ~s|"Hello, Alice!"|,
      explanation: "receive uses pattern matching to select which message to process, just like case."
    },
    %{
      id: "between_procs",
      title: "Between Processes",
      code: "parent = self()\n\nspawn(fn ->\n  send(parent, {:from_child, 42})\nend)\n\nreceive do\n  {:from_child, value} -> value\nend",
      result: "42",
      explanation: "A child process sends a message back to the parent. The parent blocks in receive until the message arrives."
    },
    %{
      id: "timeout",
      title: "Receive with after",
      code: "receive do\n  :never_sent -> :got_it\nafter\n  1000 -> :timed_out\nend",
      result: ":timed_out",
      explanation: "The after clause fires if no matching message arrives within the timeout (in milliseconds). This prevents infinite blocking."
    },
    %{
      id: "selective",
      title: "Selective Receive",
      code: "send(self(), :second)\nsend(self(), :first)\n\n# Receive picks :first even though\n# :second was sent first\nreceive do\n  :first -> \"Got :first\"\nend",
      result: ~s|"Got :first"|,
      explanation: "receive scans the entire mailbox for the first matching message. Messages are not necessarily processed in order."
    }
  ]

  @mailbox_scenarios [
    %{id: "fifo", label: "FIFO Order", messages: [":a", ":b", ":c"], pattern: ":a", description: "Messages arrive in order. receive matches :a first."},
    %{id: "selective", label: "Selective", messages: [":a", ":b", ":c"], pattern: ":b", description: "receive skips :a, matches :b. :a stays in mailbox."},
    %{id: "tuple", label: "Tuple Matching", messages: [~s|{:ok, 1}|, ~s|{:error, "bad"}|, ~s|{:ok, 2}|], pattern: ~s|{:error, _}|, description: "receive skips {:ok, 1}, matches {:error, _}."},
    %{id: "no_match", label: "No Match", messages: [":x", ":y", ":z"], pattern: ":w", description: "No message matches :w. Process blocks until timeout or new message."}
  ]

  def update(assigns, socket) do
    socket = assign(socket, assigns)

    {:ok,
     socket
     |> assign_new(:active_example, fn -> hd(@examples) end)
     |> assign_new(:mailbox, fn -> [] end)
     |> assign_new(:received, fn -> [] end)
     |> assign_new(:active_scenario, fn -> hd(@mailbox_scenarios) end)
     |> assign_new(:scenario_step, fn -> 0 end)
     |> assign_new(:custom_message, fn -> "" end)
     |> assign_new(:show_mailbox_details, fn -> false end)}
  end

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <h2 class="text-2xl font-bold mb-2">Send &amp; Receive</h2>
      <p class="text-sm opacity-70 mb-6">
        Processes communicate by <strong>sending messages</strong> to each other's mailboxes.
        <code class="font-mono bg-base-300 px-1 rounded">send/2</code> is non-blocking (fire-and-forget).
        <code class="font-mono bg-base-300 px-1 rounded">receive</code> blocks until a matching message arrives.
      </p>

      <!-- Example Selector -->
      <div class="flex flex-wrap gap-2 mb-6">
        <%= for ex <- examples() do %>
          <button
            phx-click="select_example"
            phx-target={@myself}
            phx-value-id={ex.id}
            class={"btn btn-sm " <> if(@active_example.id == ex.id, do: "btn-primary", else: "btn-outline")}
          >
            <%= ex.title %>
          </button>
        <% end %>
      </div>

      <!-- Active Example -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2"><%= @active_example.title %></h3>
          <div class="bg-base-300 rounded-lg p-4 font-mono text-sm whitespace-pre-wrap mb-3"><%= @active_example.code %></div>
          <div class="bg-success/10 border border-success/30 rounded-lg p-3 mb-3">
            <div class="text-xs font-bold opacity-60 mb-1">Result</div>
            <div class="font-mono text-sm text-success font-bold"><%= @active_example.result %></div>
          </div>
          <div class="bg-info/10 border border-info/30 rounded-lg p-3">
            <div class="text-xs font-bold opacity-60 mb-1">How it works</div>
            <div class="text-sm"><%= @active_example.explanation %></div>
          </div>
        </div>
      </div>

      <!-- Interactive Mailbox -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <h3 class="card-title text-sm mb-2">Interactive Mailbox</h3>
          <p class="text-xs opacity-60 mb-4">
            Send messages to a simulated mailbox and receive them. Watch messages queue up and get consumed.
          </p>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
            <!-- Send Side -->
            <div>
              <div class="text-xs font-bold opacity-60 mb-2">Send Messages</div>
              <div class="flex flex-wrap gap-2 mb-3">
                <button phx-click="send_msg" phx-target={@myself} phx-value-msg=":hello" class="btn btn-xs btn-info">:hello</button>
                <button phx-click="send_msg" phx-target={@myself} phx-value-msg=":world" class="btn btn-xs btn-info">:world</button>
                <button phx-click="send_msg" phx-target={@myself} phx-value-msg="{:ok, 42}" class="btn btn-xs btn-success">&lbrace;:ok, 42&rbrace;</button>
                <button phx-click="send_msg" phx-target={@myself} phx-value-msg="{:error, :timeout}" class="btn btn-xs btn-error">&lbrace;:error, :timeout&rbrace;</button>
              </div>
              <form phx-submit="send_custom" phx-target={@myself} class="flex gap-2">
                <input
                  type="text"
                  name="msg"
                  value={@custom_message}
                  placeholder="Custom message..."
                  class="input input-bordered input-xs flex-1 font-mono"
                  autocomplete="off"
                />
                <button type="submit" class="btn btn-xs btn-primary">Send</button>
              </form>
            </div>

            <!-- Receive Side -->
            <div>
              <div class="text-xs font-bold opacity-60 mb-2">Receive</div>
              <div class="flex flex-wrap gap-2">
                <button phx-click="receive_first" phx-target={@myself} class="btn btn-xs btn-accent">
                  Receive First
                </button>
                <button phx-click="receive_matching" phx-target={@myself} phx-value-pattern="ok" class="btn btn-xs btn-success">
                  Receive &lbrace;:ok, _&rbrace;
                </button>
                <button phx-click="receive_matching" phx-target={@myself} phx-value-pattern="error" class="btn btn-xs btn-error">
                  Receive &lbrace;:error, _&rbrace;
                </button>
                <button phx-click="clear_mailbox" phx-target={@myself} class="btn btn-xs btn-ghost">
                  Flush All
                </button>
              </div>
            </div>
          </div>

          <!-- Mailbox Visualization -->
          <div class="bg-base-300 rounded-lg p-4">
            <div class="text-xs font-bold opacity-60 mb-2">
              Mailbox (<%= length(@mailbox) %> messages)
            </div>
            <%= if length(@mailbox) > 0 do %>
              <div class="flex flex-wrap gap-2">
                <%= for {msg, idx} <- Enum.with_index(@mailbox) do %>
                  <div class="bg-base-100 rounded-lg px-3 py-1.5 font-mono text-xs border border-base-content/10">
                    <span class="opacity-40"><%= idx + 1 %>.</span>
                    <span class="text-info"><%= msg %></span>
                  </div>
                <% end %>
              </div>
            <% else %>
              <div class="text-xs opacity-40 text-center py-2">Empty mailbox</div>
            <% end %>
          </div>

          <!-- Received Log -->
          <%= if length(@received) > 0 do %>
            <div class="mt-4">
              <div class="text-xs font-bold opacity-60 mb-2">Received Log</div>
              <div class="space-y-1">
                <%= for {msg, idx} <- Enum.with_index(Enum.reverse(@received)) do %>
                  <div class="flex items-center gap-2 text-xs">
                    <span class="badge badge-success badge-xs"><%= idx + 1 %></span>
                    <span class="font-mono text-success"><%= msg %></span>
                  </div>
                <% end %>
              </div>
            </div>
          <% end %>
        </div>
      </div>

      <!-- Mailbox Scenarios -->
      <div class="card bg-base-200 shadow-md mb-6">
        <div class="card-body p-4">
          <div class="flex items-center justify-between mb-3">
            <h3 class="card-title text-sm">Mailbox Scenarios</h3>
            <button
              phx-click="toggle_mailbox_details"
              phx-target={@myself}
              class="btn btn-xs btn-ghost"
            >
              <%= if @show_mailbox_details, do: "Hide", else: "Show Scenarios" %>
            </button>
          </div>

          <%= if @show_mailbox_details do %>
            <!-- Scenario Selector -->
            <div class="flex flex-wrap gap-2 mb-4">
              <%= for scenario <- mailbox_scenarios() do %>
                <button
                  phx-click="select_scenario"
                  phx-target={@myself}
                  phx-value-id={scenario.id}
                  class={"btn btn-xs " <> if(@active_scenario.id == scenario.id, do: "btn-primary", else: "btn-outline")}
                >
                  <%= scenario.label %>
                </button>
              <% end %>
            </div>

            <!-- Scenario Visualization -->
            <div class="bg-base-300 rounded-lg p-4 mb-4">
              <div class="text-sm font-bold mb-2"><%= @active_scenario.label %></div>
              <p class="text-xs opacity-60 mb-3"><%= @active_scenario.description %></p>

              <div class="mb-3">
                <div class="text-xs font-bold opacity-60 mb-1">Mailbox contents:</div>
                <div class="flex gap-2">
                  <%= for {msg, idx} <- Enum.with_index(@active_scenario.messages) do %>
                    <div class={"rounded px-3 py-1 font-mono text-xs border " <> scenario_msg_style(msg, @active_scenario.pattern, idx, @scenario_step)}>
                      <%= msg %>
                    </div>
                  <% end %>
                </div>
              </div>

              <div class="mb-3">
                <div class="text-xs font-bold opacity-60 mb-1">receive pattern:</div>
                <div class="font-mono text-sm text-accent"><%= @active_scenario.pattern %></div>
              </div>

              <div class="flex gap-2">
                <button phx-click="scenario_step" phx-target={@myself} class="btn btn-xs btn-primary">
                  Step &rarr;
                </button>
                <button phx-click="scenario_reset" phx-target={@myself} class="btn btn-xs btn-ghost">
                  Reset
                </button>
              </div>

              <%= if @scenario_step > 0 do %>
                <div class="mt-3 text-xs">
                  <span class="opacity-50">Step <%= @scenario_step %>: </span>
                  <span><%= scenario_step_text(@active_scenario, @scenario_step) %></span>
                </div>
              <% end %>
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
              <span><strong>send(pid, msg)</strong> is non-blocking: it puts the message in the target's mailbox and returns immediately.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">2</span>
              <span><strong>receive</strong> blocks the current process until a matching message arrives in its mailbox.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">3</span>
              <span><strong>Pattern matching</strong> in receive works like case - the first clause that matches wins.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">4</span>
              <span><strong>Selective receive</strong>: receive scans the entire mailbox. Non-matching messages stay in the queue.</span>
            </div>
            <div class="flex items-start gap-3 p-2 bg-base-300 rounded-lg">
              <span class="badge badge-primary badge-sm mt-0.5">5</span>
              <span><strong>after</strong> prevents infinite blocking by specifying a timeout in milliseconds.</span>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  # Event Handlers

  def handle_event("select_example", %{"id" => id}, socket) do
    example = Enum.find(examples(), &(&1.id == id))
    {:noreply, assign(socket, active_example: example)}
  end

  def handle_event("send_msg", %{"msg" => msg}, socket) do
    {:noreply, assign(socket, mailbox: socket.assigns.mailbox ++ [msg])}
  end

  def handle_event("send_custom", %{"msg" => msg}, socket) do
    msg = String.trim(msg)
    if msg == "" do
      {:noreply, socket}
    else
      {:noreply,
       socket
       |> assign(mailbox: socket.assigns.mailbox ++ [msg])
       |> assign(custom_message: "")}
    end
  end

  def handle_event("receive_first", _params, socket) do
    case socket.assigns.mailbox do
      [] ->
        {:noreply, socket}
      [first | rest] ->
        {:noreply,
         socket
         |> assign(mailbox: rest)
         |> assign(received: [first | socket.assigns.received])}
    end
  end

  def handle_event("receive_matching", %{"pattern" => pattern}, socket) do
    {matched, remaining} = find_matching(socket.assigns.mailbox, pattern)

    case matched do
      nil ->
        {:noreply, socket}
      msg ->
        {:noreply,
         socket
         |> assign(mailbox: remaining)
         |> assign(received: [msg | socket.assigns.received])}
    end
  end

  def handle_event("clear_mailbox", _params, socket) do
    {:noreply, assign(socket, mailbox: [], received: [])}
  end

  def handle_event("toggle_mailbox_details", _params, socket) do
    {:noreply, assign(socket, show_mailbox_details: !socket.assigns.show_mailbox_details)}
  end

  def handle_event("select_scenario", %{"id" => id}, socket) do
    scenario = Enum.find(mailbox_scenarios(), &(&1.id == id))
    {:noreply, assign(socket, active_scenario: scenario, scenario_step: 0)}
  end

  def handle_event("scenario_step", _params, socket) do
    max = length(socket.assigns.active_scenario.messages) + 1
    new_step = min(socket.assigns.scenario_step + 1, max)
    {:noreply, assign(socket, scenario_step: new_step)}
  end

  def handle_event("scenario_reset", _params, socket) do
    {:noreply, assign(socket, scenario_step: 0)}
  end

  # Helpers

  defp examples, do: @examples
  defp mailbox_scenarios, do: @mailbox_scenarios

  defp find_matching(mailbox, "ok") do
    idx = Enum.find_index(mailbox, &String.starts_with?(&1, "{:ok"))
    if idx do
      {Enum.at(mailbox, idx), List.delete_at(mailbox, idx)}
    else
      {nil, mailbox}
    end
  end

  defp find_matching(mailbox, "error") do
    idx = Enum.find_index(mailbox, &String.starts_with?(&1, "{:error"))
    if idx do
      {Enum.at(mailbox, idx), List.delete_at(mailbox, idx)}
    else
      {nil, mailbox}
    end
  end

  defp find_matching(mailbox, _) do
    case mailbox do
      [] -> {nil, []}
      [first | rest] -> {first, rest}
    end
  end

  defp scenario_msg_style(msg, pattern, idx, step) do
    cond do
      step == 0 -> "border-base-content/20 bg-base-100"
      idx < step - 1 && !message_matches?(msg, pattern) -> "border-warning/30 bg-warning/10 opacity-50"
      message_matches?(msg, pattern) && step > idx -> "border-success/40 bg-success/20"
      true -> "border-base-content/20 bg-base-100"
    end
  end

  defp message_matches?(msg, pattern) do
    cond do
      pattern == msg -> true
      pattern == "{:error, _}" && String.starts_with?(msg, "{:error") -> true
      pattern == "{:ok, _}" && String.starts_with?(msg, "{:ok") -> true
      true -> false
    end
  end

  defp scenario_step_text(scenario, step) do
    messages = scenario.messages
    pattern = scenario.pattern

    cond do
      step > length(messages) ->
        if Enum.any?(messages, &message_matches?(&1, pattern)) do
          "Match found! Message consumed from mailbox."
        else
          "No match found. Process blocks (or times out with after)."
        end
      true ->
        msg = Enum.at(messages, step - 1)
        if message_matches?(msg, pattern) do
          "Checking #{msg} against #{pattern} - MATCH!"
        else
          "Checking #{msg} against #{pattern} - no match, skip."
        end
    end
  end
end
