defmodule ElixirKatasWeb.Kata38TagInputLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:tags, ["elixir", "phoenix"]) # Initial tags
      |> assign(:current_input, "")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Type a tag and press <strong>Enter</strong> or <strong>Comma</strong> to add it.
           Click 'x' to remove.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <label class="block text-sm font-medium text-gray-700 mb-2">Interests</label>
          
          <div class="flex flex-wrap items-center gap-2 p-2 border border-gray-300 rounded-md focus-within:ring-1 focus-within:ring-indigo-500 focus-within:border-indigo-500 bg-white">
            
            <!-- Render Tags -->
            <%= for tag <- Enum.reverse(@tags) do %>
              <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-sm font-medium bg-indigo-100 text-indigo-800">
                <%= tag %>
                <button
                  type="button"
                  phx-click="remove_tag" phx-target={@myself}
                  phx-value-tag={tag}
                  class="flex-shrink-0 ml-1.5 h-4 w-4 rounded-full inline-flex items-center justify-center text-indigo-400 hover:bg-indigo-200 hover:text-indigo-500 focus:outline-none focus:bg-indigo-500 focus:text-white"
                >
                  <span class="sr-only">Remove <%= tag %></span>
                  <svg class="h-2 w-2" stroke="currentColor" fill="none" viewBox="0 0 8 8">
                    <path stroke-linecap="round" stroke-width="1.5" d="M1 1l6 6m0-6L1 7" />
                  </svg>
                </button>
              </span>
            <% end %>

            <!-- The Actual Input -->
            <form phx-submit="add_tag" phx-target={@myself} phx-change="update_input" phx-target={@myself} class="flex-grow min-w-[50px]">
              <input
                type="text"
                name="value"
                value={@current_input}
                class="w-full border-none focus:ring-0 p-0 sm:text-sm"
                placeholder="Add tag..."
                autocomplete="off"
                phx-keydown="keydown" phx-target={@myself}
              />
            </form>
          </div>
          
          <p class="mt-2 text-xs text-gray-500">
            Current list: <%= inspect(@tags) %>
          </p>
        </div>
      </div>
    
    """
  end

  def handle_event("update_input", %{"value" => value}, socket) do
    # Check if last char is comma
    if String.ends_with?(value, ",") do
      tag = String.replace(value, ",", "")
      add_tag(socket, tag)
    else
      {:noreply, assign(socket, current_input: value)}
    end
  end

  def handle_event("add_tag", %{"value" => value}, socket) do
    add_tag(socket, value)
  end

  # Capture keydown to prevent default form submit if needed or handle specific keys
  def handle_event("keydown", %{"key" => _key}, socket) do
    # We mainly rely on form submit (Enter) or the comma check in update_input
    # But could handle Space or specific keys here.
    {:noreply, socket} 
  end

  def handle_event("remove_tag", %{"tag" => tag_to_remove}, socket) do
    new_tags = Enum.reject(socket.assigns.tags, &(&1 == tag_to_remove))
    {:noreply, assign(socket, tags: new_tags)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
  
  defp add_tag(socket, value) do
    tag = String.trim(value)
    if tag != "" and tag not in socket.assigns.tags do
      {:noreply, 
       socket
       |> assign(:tags, [tag | socket.assigns.tags])
       |> assign(:current_input, "")}
    else
      {:noreply, assign(socket, :current_input, "")}
    end
  end

end
