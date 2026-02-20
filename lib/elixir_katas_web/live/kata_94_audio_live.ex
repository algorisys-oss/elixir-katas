defmodule ElixirKatasWeb.Kata94AudioPlayerLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:is_playing, false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-2xl mx-auto">
        <div class="mb-6 text-sm text-gray-500">
          Audio controls using LiveView and JavaScript Hooks
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <h3 class="text-lg font-medium mb-4">Music Player</h3>
          
          <div id="audio-player" phx-hook="AudioPlayer" class="space-y-4">
             <!-- Hidden Audio Element -->
             <audio src="https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"></audio>

             <div class="flex items-center justify-between bg-gray-50 p-4 rounded-lg border">
                <div class="flex items-center gap-4">
                  <button 
                    phx-click="toggle_playback" phx-target={@myself} 
                    class="w-12 h-12 flex items-center justify-center bg-indigo-600 text-white rounded-full hover:bg-indigo-700 transition"
                  >
                    <%= if @is_playing do %>
                      <.icon name="hero-pause" class="w-6 h-6" />
                    <% else %>
                      <.icon name="hero-play" class="w-6 h-6 ml-1" />
                    <% end %>
                  </button>
                  <div>
                    <div class="text-sm font-bold text-gray-900">SoundHelix Song 1</div>
                    <div class="text-xs text-gray-500">SoundHelix Library</div>
                  </div>
                </div>
                
                <div class="text-sm font-mono text-gray-600">
                   <span class="time-display">0:00</span> / <span class="duration-display">0:00</span>
                </div>
             </div>

             <!-- Progress Bar -->
             <div class="w-full bg-gray-200 rounded-full h-2.5 overflow-hidden">
               <div class="progress-bar bg-indigo-600 h-2.5 rounded-full" style="width: 0%"></div>
             </div>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("toggle_playback", _, socket) do
    if socket.assigns.is_playing do
      {:noreply, 
       socket 
       |> assign(:is_playing, false) 
       |> push_event("pause", %{})}
    else
      {:noreply, 
       socket 
       |> assign(:is_playing, true) 
       |> push_event("play", %{})}
    end
  end

  def handle_event("audio_ended", _, socket) do
    {:noreply, assign(socket, :is_playing, false)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
