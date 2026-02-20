defmodule ElixirKatasWeb.Kata12TimerLive do
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
      {:ok, 
       socket
       |> assign(active_tab: "notes")
       
       
       |> assign(seconds: 60)
       |> assign(running: false)}
    end
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col items-center justify-center p-8 gap-8 min-h-[400px]">
        <div class="flex flex-col items-center gap-8">
          <div class="countdown font-mono text-8xl text-gray-800 dark:text-gray-100">
            <span style={"--value:#{@seconds};"}></span>
          </div>
          
          <div class="flex gap-4">
             <%= if @running do %>
              <button phx-click="stop" phx-target={@myself} class="btn btn-error btn-lg">Stop</button>
             <% else %>
               <%= if @seconds > 0 do %>
                 <button phx-click="start" phx-target={@myself} class="btn btn-primary btn-lg">Start</button>
               <% end %>
             <% end %>
             
             <button phx-click="reset" phx-target={@myself} class="btn btn-ghost btn-lg">Reset</button>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("start", _, socket) do
    if socket.assigns.running do
      {:noreply, socket}
    else
      Process.send_after(self(), :tick, 1000)
      {:noreply, assign(socket, running: true)}
    end
  end

  def handle_event("stop", _, socket) do
    {:noreply, assign(socket, running: false)}
  end

  def handle_event("reset", _, socket) do
    {:noreply, assign(socket, seconds: 60, running: false)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    if tab in ["interactive", "source", "notes"] do
       {:noreply, assign(socket, active_tab: tab)}
    else 
       {:noreply, socket}
    end
  end

  def handle_info(:tick, socket) do
    if socket.assigns.running and socket.assigns.seconds > 0 do
      Process.send_after(self(), :tick, 1000)
      {:noreply, update(socket, :seconds, &(&1 - 1))}
    else
      {:noreply, assign(socket, running: false)}
    end
  end
end
