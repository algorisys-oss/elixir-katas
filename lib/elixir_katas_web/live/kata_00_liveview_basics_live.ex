defmodule ElixirKatasWeb.Kata00LiveviewBasicsLive do
  use ElixirKatasWeb, :live_component

  def mount(socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>This tab should be hidden.</div>
    """
  end
end
