defmodule ElixirKatasWeb.Kata10CharacterCounterLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    {:ok, 
     socket
     |> assign(active_tab: "notes")
     
     
     |> assign(text: "Type something...")
     |> assign(limit: 100)}
  end

  def render(assigns) do
    ~H"""
    
      <div class="flex flex-col items-center justify-center p-8 gap-8">
        <div class="w-full max-w-lg">
          <label class="form-control">
            <div class="label">
              <span class="label-text text-lg font-semibold">Your Bio</span>
              <span class={"label-text-alt font-mono " <> count_class(String.length(@text), @limit)}>
                {String.length(@text)} / {@limit}
              </span>
            </div>
          <form phx-change="update_text" phx-target={@myself}>
            <textarea 
              name="value"
              class="textarea textarea-bordered h-40 text-lg leading-relaxed focus:outline-none focus:ring-2 focus:ring-primary transition-all duration-300 w-full"
              placeholder="Tell us about yourself"
            >{@text}</textarea>
          </form>
            <div class="label">
              <span class="label-text-alt text-gray-400">
                {if String.length(@text) > @limit, do: "You have exceeded the limit!", else: "Keep it concise."}
              </span>
            </div>
          </label>

          <div class="mt-8 w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2.5 overflow-hidden">
            <div 
              class={"h-2.5 rounded-full transition-all duration-500 ease-out " <> progress_color(String.length(@text), @limit)} 
              style={"width: #{min((String.length(@text) / @limit) * 100, 100)}%"}
            ></div>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("update_text", %{"value" => value}, socket) do
    {:noreply, assign(socket, text: value)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    if tab in ["interactive", "source", "notes"] do
       {:noreply, assign(socket, active_tab: tab)}
    else 
       {:noreply, socket}
    end
  end

  defp count_class(current, limit) do
    cond do
      current > limit -> "text-error font-bold"
      current >= limit * 0.9 -> "text-warning font-bold"
      true -> "text-gray-500"
    end
  end

  defp progress_color(current, limit) do
    cond do
      current > limit -> "bg-error"
      current >= limit * 0.9 -> "bg-warning"
      true -> "bg-primary"
    end
  end
end
