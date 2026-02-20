defmodule ElixirKatasWeb.Kata06ResizerLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok,
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(width: 200, height: 200)}
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col gap-8 mx-auto mt-12 items-center w-full">
        
        <!-- Controls -->
        <form phx-change="update_size" phx-target={@myself} class="flex flex-wrap gap-4 bg-base-100 p-6 rounded-lg shadow-lg justify-center w-full max-w-lg">
          
          <div class="form-control">
            <label class="label">
              <span class="label-text font-bold">Width (50-500)</span>
            </label>
            <div class="join">
               <input 
                type="number" 
                name="width"
                min="50" 
                max="500" 
                value={@width} 
                class="input input-bordered join-item w-24" 
              />
              <span class="btn btn-disabled join-item">px</span>
            </div>
          </div>

          <div class="form-control">
            <label class="label">
              <span class="label-text font-bold">Height (50-500)</span>
            </label>
            <div class="join">
               <input 
                type="number" 
                name="height"
                min="50" 
                max="500" 
                value={@height} 
                class="input input-bordered join-item w-24" 
              />
              <span class="btn btn-disabled join-item">px</span>
            </div>
          </div>
        
        </form>

        <!-- Resizable Box -->
        <div class="relative bg-base-300 rounded-xl overflow-hidden shadow-xl transition-all duration-300 ease-in-out border-2 border-primary/20 flex items-center justify-center p-2"
          style={"width: #{@width}px; height: #{@height}px;"}>
          
          <div class="absolute inset-0 bg-gradient-to-br from-primary/10 to-secondary/10 pointer-events-none"></div>
          
          <div class="text-center z-10">
            <div class="font-bold text-lg">{@width} x {@height}</div>
            <div class="text-xs opacity-50">pixels</div>
          </div>

          <!-- Decorative Clean Corner Markers -->
          <div class="absolute top-2 left-2 w-2 h-2 border-t-2 border-l-2 border-primary"></div>
          <div class="absolute top-2 right-2 w-2 h-2 border-t-2 border-r-2 border-primary"></div>
          <div class="absolute bottom-2 left-2 w-2 h-2 border-b-2 border-l-2 border-primary"></div>
          <div class="absolute bottom-2 right-2 w-2 h-2 border-b-2 border-r-2 border-primary"></div>
        </div>

      </div>
    
    """
  end

  def handle_event("update_size", %{"width" => w, "height" => h}, socket) do
    w = String.to_integer(w)
    h = String.to_integer(h)
    {:noreply, assign(socket, width: w, height: h)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
