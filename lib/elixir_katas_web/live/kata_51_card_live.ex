defmodule ElixirKatasWeb.Kata51CardLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Card components with named slots for flexible composition.
        </div>

        <div class="grid grid-cols-3 gap-6">
          <!-- Basic Card -->
          <.custom_card>
            <:header>
              <h3 class="text-lg font-bold">Basic Card</h3>
            </:header>
            <:body>
              <p class="text-gray-600">This is a basic card with header, body, and footer slots.</p>
            </:body>
            <:footer>
              <button class="px-3 py-1 bg-indigo-600 text-white rounded text-sm">Action</button>
            </:footer>
          </.custom_card>

          <!-- Card with Image -->
          <.custom_card>
            <:header>
              <div class="h-32 bg-gradient-to-r from-purple-400 to-pink-500 -m-4 mb-0 rounded-t-lg"></div>
            </:header>
            <:body>
              <h3 class="font-bold mb-2">Image Card</h3>
              <p class="text-sm text-gray-600">Card with a gradient header image.</p>
            </:body>
            <:footer>
              <div class="flex justify-between text-sm text-gray-500">
                <span>👁 123</span>
                <span>❤️ 45</span>
              </div>
            </:footer>
          </.custom_card>

          <!-- Stats Card -->
          <.custom_card>
            <:body>
              <div class="text-center">
                <div class="text-3xl font-bold text-indigo-600">1,234</div>
                <div class="text-sm text-gray-500 mt-1">Total Users</div>
                <div class="text-xs text-green-600 mt-2">↑ 12% from last month</div>
              </div>
            </:body>
          </.custom_card>

          <!-- Profile Card -->
          <.custom_card>
            <:header>
              <div class="flex items-center gap-3">
                <div class="w-12 h-12 bg-indigo-600 rounded-full flex items-center justify-center text-white font-bold">
                  JD
                </div>
                <div>
                  <div class="font-bold">John Doe</div>
                  <div class="text-xs text-gray-500">john@example.com</div>
                </div>
              </div>
            </:header>
            <:body>
              <p class="text-sm text-gray-600">Full-stack developer passionate about Elixir and LiveView.</p>
            </:body>
            <:footer>
              <div class="flex gap-2">
                <button class="flex-1 px-3 py-1 bg-gray-100 rounded text-sm">Message</button>
                <button class="flex-1 px-3 py-1 bg-indigo-600 text-white rounded text-sm">Follow</button>
              </div>
            </:footer>
          </.custom_card>

          <!-- Notification Card -->
          <.custom_card>
            <:body>
              <div class="flex items-start gap-3">
                <div class="w-2 h-2 bg-blue-500 rounded-full mt-2"></div>
                <div class="flex-1">
                  <div class="font-medium text-sm">New message</div>
                  <div class="text-xs text-gray-500 mt-1">You have a new message from Sarah</div>
                  <div class="text-xs text-gray-400 mt-2">2 minutes ago</div>
                </div>
              </div>
            </:body>
          </.custom_card>

          <!-- Pricing Card -->
          <.custom_card>
            <:header>
              <div class="text-center">
                <div class="text-sm text-gray-500">Pro Plan</div>
                <div class="text-3xl font-bold mt-2">$29<span class="text-sm text-gray-500">/mo</span></div>
              </div>
            </:header>
            <:body>
              <ul class="space-y-2 text-sm">
                <li class="flex items-center gap-2">
                  <span class="text-green-500">✓</span>
                  <span>Unlimited projects</span>
                </li>
                <li class="flex items-center gap-2">
                  <span class="text-green-500">✓</span>
                  <span>Priority support</span>
                </li>
                <li class="flex items-center gap-2">
                  <span class="text-green-500">✓</span>
                  <span>Advanced analytics</span>
                </li>
              </ul>
            </:body>
            <:footer>
              <button class="w-full px-3 py-2 bg-indigo-600 text-white rounded font-medium">
                Get Started
              </button>
            </:footer>
          </.custom_card>
        </div>
      </div>
    
    """
  end

  # Custom Card Component with Named Slots
  slot :header
  slot :body
  slot :footer

  defp custom_card(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow-sm border overflow-hidden">
      <%= if @header != [] do %>
        <div class="px-4 py-3 border-b bg-gray-50">
          <%= render_slot(@header) %>
        </div>
      <% end %>
      <%= if @body != [] do %>
        <div class="px-4 py-3">
          <%= render_slot(@body) %>
        </div>
      <% end %>
      <%= if @footer != [] do %>
        <div class="px-4 py-3 border-t bg-gray-50">
          <%= render_slot(@footer) %>
        </div>
      <% end %>
    </div>
    """
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
