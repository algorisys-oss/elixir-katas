defmodule ElixirKatasWeb.Kata19FilterLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    items = [
      "Phoenix LiveView",
      "Elixir Language",
      "Erlang VM",
      "Ruby on Rails",
      "JavaScript Framework",
      "React JS",
      "Vue JS",
      "Angular",
      "Svelte",
      "Alpine JS",
      "Tailwind CSS",
      "PostgreSQL Database"
    ]

    {:ok, 
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(items: items)
     |> assign(query: "")}
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col items-center p-8 gap-8">
        <div class="w-full max-w-md space-y-4">
           <form phx-change="filter" phx-target={@myself} phx-submit="filter" phx-target={@myself} onsubmit="return false;">
             <input 
               type="text" 
               name="query" 
               value={@query} 
               placeholder="Search frameworks..." 
               class="input input-bordered w-full"
               autocomplete="off"
             />
           </form>

           <div class="bg-base-200 rounded-lg p-2 min-h-[10rem]">
             <%= if Enum.empty?(filtered_items(@items, @query)) do %>
               <div class="text-center text-gray-400 py-8">No matches found.</div>
             <% else %>
               <ul class="menu bg-base-100 w-full rounded-box">
                 <%= for item <- filtered_items(@items, @query) do %>
                   <li>
                     <a>
                       {highlight(item, @query)}
                     </a>
                   </li>
                 <% end %>
               </ul>
             <% end %>
           </div>
        </div>
      </div>
    
    """
  end

  def handle_event("filter", %{"query" => query}, socket) do
    {:noreply, assign(socket, query: query)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    if tab in ["interactive", "source", "notes"] do
       {:noreply, assign(socket, active_tab: tab)}
    else 
       {:noreply, socket}
    end
  end

  defp filtered_items(items, "") do
    items
  end
  defp filtered_items(items, query) do
    q = String.downcase(query)
    Enum.filter(items, fn item -> String.contains?(String.downcase(item), q) end)
  end

  # Simple highlighter for bonus points (though officially in later kata, it helps UX here)
  defp highlight(text, ""), do: text
  defp highlight(text, _query) do
    # This is a naive implementation. For real highlighting, we'd need safe HTML rendering.
    # Since we can't easily return safe HTML tuple from helper without Phoenix.HTML logic here easily,
    # we will just return text for this basic kata.
    text
  end
end
