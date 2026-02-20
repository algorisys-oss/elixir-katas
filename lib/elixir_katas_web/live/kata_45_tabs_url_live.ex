defmodule ElixirKatasWeb.Kata45TabsUrlLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    
    params = assigns[:params] || %{}
    tab = params["tab"] || "profile"
    
    socket =
      socket
      |> assign(active_tab: "notes")
      |> assign(:content_tab, tab)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Click tabs. Notice the URL updates with <code>?tab=...</code> and you can bookmark/share the link.
        </div>

        <div class="bg-white rounded-lg shadow-sm border">
          <!-- Tabs -->
          <div class="border-b border-gray-200">
            <nav class="flex -mb-px">
              <button
                phx-click="switch_tab" phx-target={@myself}
                phx-value-tab="profile"
                class={tab_class(@content_tab, "profile")}
              >
                Profile
              </button>
              <button
                phx-click="switch_tab" phx-target={@myself}
                phx-value-tab="settings"
                class={tab_class(@content_tab, "settings")}
              >
                Settings
              </button>
              <button
                phx-click="switch_tab" phx-target={@myself}
                phx-value-tab="notifications"
                class={tab_class(@content_tab, "notifications")}
              >
                Notifications
              </button>
              <button
                phx-click="switch_tab" phx-target={@myself}
                phx-value-tab="billing"
                class={tab_class(@content_tab, "billing")}
              >
                Billing
              </button>
            </nav>
          </div>

          <!-- Tab Content -->
          <div class="p-6">
            <%= case @content_tab do %>
              <% "profile" -> %>
                <h3 class="text-lg font-medium mb-2">Profile</h3>
                <p class="text-gray-600">Manage your profile information and preferences.</p>
              <% "settings" -> %>
                <h3 class="text-lg font-medium mb-2">Settings</h3>
                <p class="text-gray-600">Configure your account settings and privacy options.</p>
              <% "notifications" -> %>
                <h3 class="text-lg font-medium mb-2">Notifications</h3>
                <p class="text-gray-600">Control how and when you receive notifications.</p>
              <% "billing" -> %>
                <h3 class="text-lg font-medium mb-2">Billing</h3>
                <p class="text-gray-600">View your billing history and payment methods.</p>
            <% end %>
            
            <div class="mt-4 p-3 bg-gray-50 rounded text-xs font-mono">
              Current URL: <span class="text-indigo-600">?tab=<%= @content_tab %></span>
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  defp tab_class(current, target) do
    base = "px-6 py-3 text-sm font-medium transition-colors"
    if current == target do
      base <> " border-b-2 border-indigo-600 text-indigo-600"
    else
      base <> " text-gray-600 hover:text-gray-900 hover:border-gray-300"
    end
  end

  def handle_event("switch_tab", %{"tab" => tab}, socket) do
    {:noreply, push_patch(socket, to: ~p"/katas/45-tabs-url?tab=#{tab}")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
