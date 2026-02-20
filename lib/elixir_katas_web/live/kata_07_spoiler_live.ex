defmodule ElixirKatasWeb.Kata07SpoilerLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok,
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(visible: false)}
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col gap-8 mx-auto mt-12 items-center w-full max-w-lg">
        
        <div class="card bg-base-100 shadow-xl w-full border border-base-300">
          <div class="card-body">
            <h2 class="card-title text-warning">
              <.icon name="hero-exclamation-triangle" class="w-6 h-6" />
              Major Plot Twist
            </h2>
            
            <div class="relative mt-4 border border-base-200 rounded-lg p-4 bg-base-200/30 overflow-hidden">
               <!-- The Content -->
               <p class={["transition-all duration-500", if(!@visible, do: "blur-md select-none opacity-50", else: "")]}>
                 The main character was actually a ghost the entire time! They didn't realize it because they could still interact with objects, but no one ever looked them in the eye.
               </p>

               <!-- The Overlay -->
               <div :if={!@visible} class="absolute inset-0 flex items-center justify-center bg-base-100/50 backdrop-blur-[2px] z-10">
                 <button 
                   phx-click="toggle_visibility" phx-target={@myself} 
                   class="btn btn-sm btn-primary animate-pulse"
                 >
                   Reveal Spoiler
                 </button>
               </div>

            </div>

            <div class="card-actions justify-end mt-4">
               <button 
                 :if={@visible}
                 phx-click="toggle_visibility" phx-target={@myself} 
                 class="btn btn-ghost btn-xs"
               >
                 Hide Spoiler
               </button>
            </div>
          </div>
        </div>

      </div>
    
    """
  end

  def handle_event("toggle_visibility", _params, socket) do
    {:noreply, update(socket, :visible, &(!&1))}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
