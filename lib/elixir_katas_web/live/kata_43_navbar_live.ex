defmodule ElixirKatasWeb.Kata43NavbarLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    
    params = assigns[:params] || %{}
    page = params["page"] || "home"
    
    socket =
      socket
      |> assign(active_tab: "notes")
      |> assign(:current_page, page)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Click navigation links. The active link is highlighted.
        </div>

        <div class="bg-white rounded-lg shadow-sm border overflow-hidden">
          <!-- Navigation Bar -->
          <nav class="bg-gray-50 border-b border-gray-200 px-6 py-3">
            <div class="flex space-x-6">
              <.link
                patch={~p"/liveview-katas/43-navbar?page=home"}
                class={nav_link_class(@current_page, "home")}
              >
                Home
              </.link>
              <.link
                patch={~p"/liveview-katas/43-navbar?page=products"}
                class={nav_link_class(@current_page, "products")}
              >
                Products
              </.link>
              <.link
                patch={~p"/liveview-katas/43-navbar?page=about"}
                class={nav_link_class(@current_page, "about")}
              >
                About
              </.link>
              <.link
                patch={~p"/liveview-katas/43-navbar?page=contact"}
                class={nav_link_class(@current_page, "contact")}
              >
                Contact
              </.link>
            </div>
          </nav>

          <!-- Page Content -->
          <div class="p-6">
            <%= case @current_page do %>
              <% "home" -> %>
                <h2 class="text-2xl font-bold mb-2">Welcome Home</h2>
                <p class="text-gray-600">This is the home page content.</p>
              <% "products" -> %>
                <h2 class="text-2xl font-bold mb-2">Our Products</h2>
                <p class="text-gray-600">Browse our amazing product catalog.</p>
              <% "about" -> %>
                <h2 class="text-2xl font-bold mb-2">About Us</h2>
                <p class="text-gray-600">Learn more about our company.</p>
              <% "contact" -> %>
                <h2 class="text-2xl font-bold mb-2">Contact Us</h2>
                <p class="text-gray-600">Get in touch with our team.</p>
            <% end %>
            
            <div class="mt-4 p-3 bg-gray-50 rounded text-xs font-mono">
              Current Page: <span class="text-indigo-600"><%= @current_page %></span>
            </div>
          </div>
        </div>
      </div>
    
    """
  end

  defp nav_link_class(current, target) do
    base = "text-sm font-medium transition-colors"
    if current == target do
      base <> " text-indigo-600 border-b-2 border-indigo-600 pb-2"
    else
      base <> " text-gray-600 hover:text-gray-900 pb-2"
    end
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
