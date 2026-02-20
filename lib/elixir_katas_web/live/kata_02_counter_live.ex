defmodule ElixirKatasWeb.Kata02CounterLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    {:ok, 
     socket 
     |> assign(assigns)
     |> assign_new(:count, fn -> 0 end)}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col items-center justify-center min-h-[50vh] gap-8">
      <div class="text-9xl font-bold font-mono text-primary">
        {@count}
      </div>
      
      <div class="flex gap-4">
        <button phx-click="dec" phx-target={@myself} class="btn btn-lg btn-circle btn-outline">
          <.icon name="hero-minus" class="w-8 h-8" />
        </button>
        
        <button phx-click="reset" phx-target={@myself} class="btn btn-lg btn-outline border-2 font-bold">
          RESET
        </button>
        
        <button phx-click="inc" phx-target={@myself} class="btn btn-lg btn-circle btn-primary text-white">
          <.icon name="hero-plus" class="w-8 h-8" />
        </button>
      </div>
    </div>
    """
  end

  def handle_event("inc", _params, socket) do
    {:noreply, update(socket, :count, &(&1 + 2))}
  end

  def handle_event("dec", _params, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, count: 0)}
  end
end
