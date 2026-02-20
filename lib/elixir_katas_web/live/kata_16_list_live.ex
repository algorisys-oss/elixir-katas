defmodule ElixirKatasWeb.Kata16ListLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, 
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(items: ["Learn Elixir", "Master LiveView"])
     |> assign(new_item: "")}
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col items-center p-8 gap-8">
        <form phx-submit="add" phx-target={@myself} class="flex gap-2 w-full max-w-md">
          <input 
            type="text" 
            name="text" 
            value={@new_item} 
            placeholder="Add new item..." 
            class="input input-bordered flex-1"
            required
            autocomplete="off"
          />
          <button class="btn btn-primary">Add</button>
        </form>

        <div class="w-full max-w-md text-left">
           <h3 class="text-lg font-semibold mb-2">My List ({length(@items)})</h3>
           <ul class="menu bg-base-200 w-full rounded-box">
             <%= for item <- @items do %>
               <li><a>{item}</a></li>
             <% end %>
           </ul>
        </div>
      </div>
    
    """
  end

  def handle_event("add", %{"text" => text}, socket) do
    {:noreply, update(socket, :items, fn items -> items ++ [text] end) |> assign(new_item: "")}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    if tab in ["interactive", "source", "notes"] do
       {:noreply, assign(socket, active_tab: tab)}
    else 
       {:noreply, socket}
    end
  end
end
