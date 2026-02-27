defmodule ElixirKatasWeb.PhoenixApiKata00RestFundamentalsLive do
  use ElixirKatasWeb, :live_component

  def render(assigns) do
    ~H"""
    <div class="prose dark:prose-invert max-w-none">
      <p class="text-lg text-gray-600 dark:text-gray-300">
        This is a notes-only kata. Read the Description tab to learn about REST API fundamentals.
      </p>
    </div>
    """
  end
end
