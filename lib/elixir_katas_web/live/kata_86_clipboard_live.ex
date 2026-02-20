defmodule ElixirKatasWeb.Kata86ClipboardCopyLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:text_to_copy, "Hello from LiveView!")
      |> assign(:copied, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Copy text to system clipboard using JavaScript interop.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <div class="space-y-4">
            <div>
              <label class="block text-sm font-medium mb-2">Text to Copy</label>
              <input 
                type="text" 
                value={@text_to_copy}
                phx-change="update_text" phx-target={@myself}
                name="text"
                class="w-full px-4 py-2 border rounded"
              />
            </div>
            
            <button 
              phx-click="copy_to_clipboard" phx-target={@myself}
              class="px-6 py-2 bg-indigo-600 text-white rounded hover:bg-indigo-700"
            >
              <%= if @copied, do: "✓ Copied!", else: "Copy to Clipboard" %>
            </button>
            
            <%= if @copied do %>
              <div class="text-sm text-green-600">
                Text copied to clipboard!
              </div>
            <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("update_text", %{"text" => text}, socket) do
    {:noreply, assign(socket, text_to_copy: text, copied: false)}
  end

  def handle_event("copy_to_clipboard", _, socket) do
    # In a real implementation, this would use JS hooks to copy
    {:noreply, assign(socket, copied: true)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
