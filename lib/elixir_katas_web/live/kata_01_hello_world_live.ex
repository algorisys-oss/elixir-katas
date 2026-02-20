defmodule ElixirKatasWeb.Kata01HelloWorldLive do
  use ElixirKatasWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="prose dark:prose-invert mb-8">
        <h1>Hello User!</h1>
        <p>This is your private sandbox.</p>
      </div>

      <!-- Add your logic here -->
       <div class="mt-8 flex gap-4">
          <button phx-click="toggle" phx-target={@myself} class="btn btn-primary">
            {if @clicked, do: "You clicked me!!!", else: "Click me!"}
          </button>
        </div>
    </div>
    """
  end

  def mount(socket) do
    {:ok, assign(socket, clicked: false)}
  end

  def handle_event("toggle", _, socket) do
    {:noreply, assign(socket, clicked: !socket.assigns.clicked)}
  end
end
