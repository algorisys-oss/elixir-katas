defmodule ElixirKatasWeb.PhoenixKata00PhoenixFundamentalsLive do
  use ElixirKatasWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="prose dark:prose-invert max-w-none">
      <p class="text-lg text-gray-600 dark:text-gray-300">
        This is a notes-only kata. Read the Description tab to learn about Phoenix fundamentals.
      </p>
    </div>
    """
  end
end
