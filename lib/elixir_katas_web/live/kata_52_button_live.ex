defmodule ElixirKatasWeb.Kata52ButtonLive do
  use ElixirKatasWeb, :live_component

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
      socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:loading, false)
      {:ok, socket}
    end

  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-4xl mx-auto space-y-8">
        <div class="text-sm text-gray-500 mb-6">
           Reusable button component with variants, sizes, and loading states.
        </div>

        <!-- Variants -->
        <div>
          <h3 class="text-sm font-medium mb-3">Variants</h3>
          <div class="flex gap-3 flex-wrap">
            <.btn variant="primary">Primary</.btn>
            <.btn variant="secondary">Secondary</.btn>
            <.btn variant="success">Success</.btn>
            <.btn variant="danger">Danger</.btn>
            <.btn variant="warning">Warning</.btn>
            <.btn variant="ghost">Ghost</.btn>
          </div>
        </div>

        <!-- Sizes -->
        <div>
          <h3 class="text-sm font-medium mb-3">Sizes</h3>
          <div class="flex gap-3 items-center flex-wrap">
            <.btn size="sm">Small</.btn>
            <.btn size="md">Medium</.btn>
            <.btn size="lg">Large</.btn>
          </div>
        </div>

        <!-- States -->
        <div>
          <h3 class="text-sm font-medium mb-3">States</h3>
          <div class="flex gap-3 flex-wrap">
            <.btn>Normal</.btn>
            <.btn disabled>Disabled</.btn>
            <.btn loading={@loading} phx-click="toggle_loading" phx-target={@myself}>
              <%= if @loading, do: "Loading...", else: "Click to Load" %>
            </.btn>
          </div>
        </div>

        <!-- With Icons -->
        <div>
          <h3 class="text-sm font-medium mb-3">With Icons</h3>
          <div class="flex gap-3 flex-wrap">
            <.btn variant="primary">
              <span class="mr-2">→</span> Next
            </.btn>
            <.btn variant="secondary">
              ← <span class="ml-2">Back</span>
            </.btn>
            <.btn variant="success">
              ✓ <span class="ml-2">Save</span>
            </.btn>
          </div>
        </div>
      </div>
    
    """
  end

  attr :variant, :string, default: "primary"
  attr :size, :string, default: "md"
  attr :loading, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :rest, :global, include: ~w(phx-click phx-value-*)
  slot :inner_block, required: true

  defp btn(assigns) do
    ~H"""
    <button class={btn_class(@variant, @size)} disabled={@disabled or @loading} {@rest}>
      <%= if @loading do %>
        <span class="inline-block animate-spin mr-2">⟳</span>
      <% end %>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp btn_class(variant, size) do
    base = "rounded font-medium transition disabled:opacity-50 disabled:cursor-not-allowed"
    variant_class = case variant do
      "primary" -> "bg-indigo-600 text-white hover:bg-indigo-700"
      "secondary" -> "bg-gray-600 text-white hover:bg-gray-700"
      "success" -> "bg-green-600 text-white hover:bg-green-700"
      "danger" -> "bg-red-600 text-white hover:bg-red-700"
      "warning" -> "bg-yellow-500 text-white hover:bg-yellow-600"
      "ghost" -> "bg-transparent border border-gray-300 hover:bg-gray-50"
      _ -> "bg-indigo-600 text-white"
    end
    size_class = case size do
      "sm" -> "px-3 py-1 text-sm"
      "md" -> "px-4 py-2"
      "lg" -> "px-6 py-3 text-lg"
      _ -> "px-4 py-2"
    end
    "#{base} #{variant_class} #{size_class}"
  end

  def handle_event("toggle_loading", _, socket) do
    new_loading = !socket.assigns.loading
    socket = assign(socket, loading: new_loading)
    if new_loading do
      Process.send_after(self(), :stop_loading, 2000)
    end
    {:noreply, socket}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end

  def handle_info(:stop_loading, socket) do
    {:noreply, assign(socket, loading: false)}
  end
end
