defmodule ElixirKatasWeb.Kata50ComponentsLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:count, 0)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Examples of reusable functional components with attrs and slots.
        </div>

        <div class="space-y-6">
          <!-- Button Component Examples -->
          <.demo_card title="Button Component (with attrs)">
            <div class="flex gap-2 flex-wrap">
              <.custom_button variant="primary">Primary</.custom_button>
              <.custom_button variant="secondary">Secondary</.custom_button>
              <.custom_button variant="danger">Danger</.custom_button>
              <.custom_button variant="success">Success</.custom_button>
            </div>
          </.demo_card>

          <!-- Card Component with Slots -->
          <.demo_card title="Card Component (with slots)">
            <.custom_card>
              <:header>
                <h3 class="text-lg font-bold">Card Header</h3>
              </:header>
              <:body>
                <p class="text-gray-600">This is the card body content. Slots allow flexible content composition.</p>
              </:body>
              <:footer>
                <div class="flex justify-end gap-2">
                  <button class="px-3 py-1 text-sm bg-gray-200 rounded">Cancel</button>
                  <button class="px-3 py-1 text-sm bg-indigo-600 text-white rounded">Save</button>
                </div>
              </:footer>
            </.custom_card>
          </.demo_card>

          <!-- Interactive Component -->
          <.demo_card title="Interactive Component">
            <.counter count={@count} />
            <div class="flex gap-2 mt-4">
              <button
                phx-click="increment" phx-target={@myself}
                class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"
              >
                Increment
              </button>
              <button
                phx-click="decrement" phx-target={@myself}
                class="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
              >
                Decrement
              </button>
              <button
                phx-click="reset" phx-target={@myself}
                class="px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
              >
                Reset
              </button>
            </div>
          </.demo_card>
        </div>
      </div>
    
    """
  end

  # Demo Card Component
  attr :title, :string, required: true
  slot :inner_block, required: true

  defp demo_card(assigns) do
    ~H"""
    <div class="bg-white p-6 rounded-lg shadow-sm border">
      <h3 class="text-sm font-medium text-gray-900 mb-4"><%= @title %></h3>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  # Custom Button Component
  attr :variant, :string, default: "primary"
  slot :inner_block, required: true

  defp custom_button(assigns) do
    ~H"""
    <button class={button_class(@variant)}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp button_class("primary"), do: "px-4 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
  defp button_class("secondary"), do: "px-4 py-2 bg-gray-600 text-white rounded hover:bg-gray-700"
  defp button_class("danger"), do: "px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
  defp button_class("success"), do: "px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700"

  # Custom Card Component with Named Slots
  slot :header
  slot :body
  slot :footer

  defp custom_card(assigns) do
    ~H"""
    <div class="border rounded-lg overflow-hidden">
      <%= if @header != [] do %>
        <div class="px-4 py-3 bg-gray-50 border-b">
          <%= render_slot(@header) %>
        </div>
      <% end %>
      <%= if @body != [] do %>
        <div class="px-4 py-3">
          <%= render_slot(@body) %>
        </div>
      <% end %>
      <%= if @footer != [] do %>
        <div class="px-4 py-3 bg-gray-50 border-t">
          <%= render_slot(@footer) %>
        </div>
      <% end %>
    </div>
    """
  end

  # Counter Component
  attr :count, :integer, required: true

  defp counter(assigns) do
    ~H"""
    <div class="p-6 bg-gray-50 rounded text-center">
      <div class="text-sm text-gray-500 mb-2">Count</div>
      <div class="text-4xl font-bold text-indigo-600"><%= @count %></div>
    </div>
    """
  end

  def handle_event("increment", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 1))}
  end

  def handle_event("decrement", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, count: 0)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
