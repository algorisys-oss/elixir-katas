defmodule ElixirKatasWeb.Kata53IconLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:selected_icon, "home")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Icon component wrapper for consistent icon usage.
        </div>

        <div class="grid grid-cols-2 gap-6">
          <!-- Icon Gallery -->
          <div class="bg-white p-6 rounded-lg shadow-sm border">
            <h3 class="text-sm font-medium mb-4">Icon Gallery</h3>
            <div class="grid grid-cols-4 gap-4">
              <%= for icon <- ["home", "user", "cog", "heart", "star", "bell", "mail", "search"] do %>
                <button
                  phx-click="select_icon" phx-target={@myself}
                  phx-value-icon={icon}
                  class={"p-4 rounded hover:bg-gray-50 transition " <> 
                         if(@selected_icon == icon, do: "bg-indigo-50 ring-2 ring-indigo-500", else: "")}
                >
                  <.custom_icon name={icon} class="w-6 h-6 mx-auto" />
                  <div class="text-xs mt-2 text-gray-600"><%= icon %></div>
                </button>
              <% end %>
            </div>
          </div>

          <!-- Icon Sizes -->
          <div class="bg-white p-6 rounded-lg shadow-sm border">
            <h3 class="text-sm font-medium mb-4">Sizes</h3>
            <div class="space-y-4">
              <div class="flex items-center gap-3">
                <.custom_icon name={@selected_icon} class="w-4 h-4" />
                <span class="text-sm">Small (w-4 h-4)</span>
              </div>
              <div class="flex items-center gap-3">
                <.custom_icon name={@selected_icon} class="w-6 h-6" />
                <span class="text-sm">Medium (w-6 h-6)</span>
              </div>
              <div class="flex items-center gap-3">
                <.custom_icon name={@selected_icon} class="w-8 h-8" />
                <span class="text-sm">Large (w-8 h-8)</span>
              </div>
              <div class="flex items-center gap-3">
                <.custom_icon name={@selected_icon} class="w-12 h-12" />
                <span class="text-sm">XL (w-12 h-12)</span>
              </div>
            </div>
          </div>

          <!-- Icon Colors -->
          <div class="bg-white p-6 rounded-lg shadow-sm border">
            <h3 class="text-sm font-medium mb-4">Colors</h3>
            <div class="space-y-3">
              <div class="flex items-center gap-3">
                <.custom_icon name={@selected_icon} class="w-6 h-6 text-gray-600" />
                <span class="text-sm">Default</span>
              </div>
              <div class="flex items-center gap-3">
                <.custom_icon name={@selected_icon} class="w-6 h-6 text-indigo-600" />
                <span class="text-sm">Primary</span>
              </div>
              <div class="flex items-center gap-3">
                <.custom_icon name={@selected_icon} class="w-6 h-6 text-green-600" />
                <span class="text-sm">Success</span>
              </div>
              <div class="flex items-center gap-3">
                <.custom_icon name={@selected_icon} class="w-6 h-6 text-red-600" />
                <span class="text-sm">Danger</span>
              </div>
            </div>
          </div>

          <!-- Icon in Context -->
          <div class="bg-white p-6 rounded-lg shadow-sm border">
            <h3 class="text-sm font-medium mb-4">In Context</h3>
            <div class="space-y-3">
              <button class="flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded w-full">
                <.custom_icon name={@selected_icon} class="w-5 h-5" />
                <span>Button with Icon</span>
              </button>
              <div class="flex items-center gap-2 p-3 bg-gray-50 rounded">
                <.custom_icon name={@selected_icon} class="w-5 h-5 text-gray-500" />
                <span class="text-sm">List item with icon</span>
              </div>
              <div class="flex items-center gap-2">
                <.custom_icon name={@selected_icon} class="w-4 h-4 text-gray-400" />
                <span class="text-xs text-gray-600">Small text with icon</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  attr :name, :string, required: true
  attr :class, :string, default: "w-6 h-6"

  defp custom_icon(assigns) do
    ~H"""
    <svg class={@class} fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <%= case @name do %>
        <% "home" -> %>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6" />
        <% "user" -> %>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
        <% "cog" -> %>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        <% "heart" -> %>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
        <% "star" -> %>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z" />
        <% "bell" -> %>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
        <% "mail" -> %>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
        <% "search" -> %>
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
      <% end %>
    </svg>
    """
  end

  def handle_event("select_icon", %{"icon" => icon}, socket) do
    {:noreply, assign(socket, selected_icon: icon)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
