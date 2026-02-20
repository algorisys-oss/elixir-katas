defmodule ElixirKatasWeb.Kata80PresenceListLive do
  use ElixirKatasWeb, :live_component

  alias ElixirKatasWeb.Presence

  @topic "presence:demo"

  def update(%{info_msg: msg}, socket) do
    {:noreply, socket} = handle_info(msg, socket)
    {:ok, socket}
  end

  def update(assigns, socket) do
    if socket.assigns[:__initialized__] do
      {:ok, assign(socket, assigns)}
    else
      socket = assign(socket, assigns)
      socket = assign(socket, :__initialized__, true)
      
      username = "User#{:rand.uniform(9999)}"

      socket =
        socket
        |> assign(active_tab: "notes")
        |> assign(:username, username)
        |> assign(:online_users, [])

      if connected?(socket) do
        # Subscribe to presence updates
        Phoenix.PubSub.subscribe(ElixirKatas.PubSub, @topic)
        
        # Track this user's presence
        {:ok, _} = Presence.track(
          self(),
          @topic,
          username,
          %{
            joined_at: System.system_time(:second),
            user_agent: get_connect_info(socket, :user_agent) || "Unknown"
          }
        )
        
        # Get initial presence list
        {:ok, assign(socket, :online_users, list_presences())}
      else
        {:ok, socket}
      end
    end
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Track who is online using Phoenix.Presence. Open in multiple tabs to see real-time updates!
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-medium">Online Users</h3>
            <div class="flex items-center gap-2">
              <div class="w-2 h-2 bg-green-500 rounded-full animate-pulse"></div>
              <span class="text-sm text-gray-600">
                <%= length(@online_users) %> online
              </span>
            </div>
          </div>
          
          <div class="mb-4 p-3 bg-blue-50 border border-blue-200 rounded text-sm">
            <strong>You are:</strong> <span class="text-indigo-600 font-medium"><%= @username %></span>
          </div>
          
          <div class="space-y-2">
            <%= if Enum.empty?(@online_users) do %>
              <div class="text-center text-gray-400 py-8">
                No users online
              </div>
            <% else %>
              <%= for user <- @online_users do %>
                <div class="flex items-center gap-3 p-3 bg-gray-50 rounded hover:bg-gray-100 transition-colors">
                  <div class="relative">
                    <div class="w-10 h-10 bg-indigo-500 rounded-full flex items-center justify-center text-white font-medium">
                      <%= String.first(user.name) %>
                    </div>
                    <div class="absolute bottom-0 right-0 w-3 h-3 rounded-full border-2 border-white bg-green-500"></div>
                  </div>
                  <div class="flex-1">
                    <div class="font-medium flex items-center gap-2">
                      <%= user.name %>
                      <%= if user.name == @username do %>
                        <span class="text-xs bg-indigo-100 text-indigo-700 px-2 py-0.5 rounded">You</span>
                      <% end %>
                    </div>
                    <div class="text-sm text-gray-500">
                      Joined <%= format_time_ago(user.joined_at) %>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
          
          <div class="mt-4 text-xs text-gray-500 text-center">
            Open this page in multiple tabs to see presence tracking in action
          </div>
        </div>
      </div>
    
    """
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    {:noreply, assign(socket, :online_users, list_presences())}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  defp list_presences do
    Presence.list(@topic)
    |> Enum.map(fn {name, %{metas: [meta | _]}} ->
      %{
        name: name,
        joined_at: meta.joined_at,
        user_agent: meta.user_agent
      }
    end)
    |> Enum.sort_by(& &1.joined_at)
  end

  defp format_time_ago(timestamp) do
    seconds_ago = System.system_time(:second) - timestamp
    
    cond do
      seconds_ago < 60 -> "just now"
      seconds_ago < 3600 -> "#{div(seconds_ago, 60)}m ago"
      seconds_ago < 86400 -> "#{div(seconds_ago, 3600)}h ago"
      true -> "#{div(seconds_ago, 86400)}d ago"
    end
  end
end
