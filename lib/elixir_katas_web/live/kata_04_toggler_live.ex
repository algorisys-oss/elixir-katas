defmodule ElixirKatasWeb.Kata04TogglerLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok,
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(show_details: false)
     |> assign(is_active: false)}
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col gap-8 max-w-lg mx-auto mt-12 items-center">
        
        <!-- Conditional Rendering Example -->
        <div class="flex flex-col items-center gap-4 w-full">
          <button phx-click="toggle_details" phx-target={@myself} class="btn btn-primary">
            {if @show_details, do: "Hide Details", else: "Show Details"}
          </button>

          <div :if={@show_details} class="alert alert-info shadow-lg animate-fade-in-down">
            <.icon name="hero-information-circle" class="w-6 h-6" />
            <div>
              <h3 class="font-bold">Secret Revealed!</h3>
              <div class="text-xs">You can use standard Elixir <code>if</code> blocks in HEEx.</div>
            </div>
          </div>
        </div>

        <div class="divider"></div>

        <!-- Dynamic Class Example -->
        <div class="flex flex-col items-center gap-4 w-full">
          <h3 class="text-lg font-semibold">Dynamic Styling</h3>
          
          <button 
            phx-click="toggle_active" phx-target={@myself} 
            class={[
              "card w-full shadow-xl transition-all duration-300 cursor-pointer border-2",
              if(@is_active, do: "bg-secondary text-secondary-content scale-105 border-secondary", else: "bg-base-100 hover:bg-base-200 border-base-300")
            ]}
          >
            <div class="card-body items-center text-center">
              <h2 class="card-title">
                {if @is_active, do: "I am ACTIVE!", else: "Click me!"}
              </h2>
              <p>{if @is_active, do: "Look at my cool colors.", else: "I am boring and plain."}</p>
            </div>
          </button>
        </div>

      </div>
    
    """
  end

  def handle_event("toggle_details", _params, socket) do
    {:noreply, update(socket, :show_details, &(!&1))}
  end

  def handle_event("toggle_active", _params, socket) do
    {:noreply, update(socket, :is_active, &(!&1))}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
