defmodule ElixirKatasWeb.Kata05ColorPickerLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok,
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(r: 0, g: 0, b: 0)}
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col gap-8 max-w-lg mx-auto mt-12 items-center">
        
        <!-- Preview Box -->
        <div 
          class="w-full h-48 rounded-xl shadow-inner border-4 border-base-300 transition-colors duration-200 flex items-center justify-center p-4 content-center"
          style={"background-color: rgb(#{@r}, #{@g}, #{@b})"}
        >
          <span 
            class="font-mono text-xl font-bold bg-black/20 text-white backdrop-blur-sm px-4 py-2 rounded-lg"
          >
            rgb({@r}, {@g}, {@b})
          </span>
        </div>

        <!-- Controls -->
        <form phx-change="update_color" phx-target={@myself} class="w-full space-y-6 bg-base-100 p-6 rounded-lg shadow-lg">
          
          <!-- Red Slider -->
          <div class="form-control">
            <label class="label cursor-pointer">
              <span class="label-text font-bold text-red-500">Red</span>
              <span class="label-text-alt font-mono">{@r}</span>
            </label>
            <input 
              type="range" 
              name="r"
              min="0" 
              max="255" 
              value={@r} 
              class="range range-error" 
            />
          </div>

          <!-- Green Slider -->
          <div class="form-control">
            <label class="label cursor-pointer">
              <span class="label-text font-bold text-green-500">Green</span>
              <span class="label-text-alt font-mono">{@g}</span>
            </label>
            <input 
              type="range" 
              name="g"
              min="0" 
              max="255" 
              value={@g} 
              class="range range-success" 
            />
          </div>

          <!-- Blue Slider -->
          <div class="form-control">
            <label class="label cursor-pointer">
              <span class="label-text font-bold text-blue-500">Blue</span>
              <span class="label-text-alt font-mono">{@b}</span>
            </label>
            <input 
              type="range" 
              name="b"
              min="0" 
              max="255" 
              value={@b} 
              class="range range-info" 
            />
          </div>
        
        </form>

      </div>
    
    """
  end

  def handle_event("update_color", %{"r" => r, "g" => g, "b" => b}, socket) do
    {:noreply, 
     socket
     |> assign(r: String.to_integer(r))
     |> assign(g: String.to_integer(g))
     |> assign(b: String.to_integer(b))}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
