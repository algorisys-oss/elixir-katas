defmodule ElixirKatasWeb.Kata39RatingLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:rating, 0) # 0 to 5
      |> assign(:submitted_rating, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Click a star to rate. The hidden input's value updates automatically.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border text-center">
          <label class="block text-sm font-medium text-gray-700 mb-4">How was your experience?</label>
          
          <div class="flex items-center justify-center gap-1 mb-4">
             <%= for i <- 1..5 do %>
                <button
                  type="button"
                  phx-click="rate" phx-target={@myself}
                  phx-value-score={i}
                  class="focus:outline-none focus:scale-110 transition-transform"
                >
                  <.star filled={i <= @rating} />
                </button>
             <% end %>
          </div>
          
          <form phx-submit="save" phx-target={@myself}>
            <!-- The actual source of truth for the form submission -->
            <input type="hidden" name="rating" value={@rating} />
            
            <p class="text-sm text-gray-400 mb-4">
               (Hidden Input Value: <%= @rating %>)
            </p>

            <button
              type="submit"
              disabled={@rating == 0}
              class="inline-flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:bg-gray-300 disabled:cursor-not-allowed"
            >
              Submit Rating
            </button>
          </form>
        </div>

        <%= if @submitted_rating do %>
          <div class="mt-8 p-4 bg-yellow-50 rounded text-sm border border-yellow-200 text-center">
             <p class="font-bold text-yellow-800">
               You submitted a <%= @submitted_rating %>-star rating! 
               <%= case String.to_integer(@submitted_rating) do 
                    5 -> "🌟 Amazing!"
                    4 -> "🎉 Great!"
                    3 -> "🙂 Good."
                    2 -> "😐 Fair."
                    1 -> "😔 Oh no."
                    _ -> ""
                   end %>
             </p>
          </div>
        <% end %>
      </div>
    
    """
  end

  def handle_event("rate", %{"score" => score}, socket) do
    {:noreply, assign(socket, rating: String.to_integer(score))}
  end

  def handle_event("save", %{"rating" => rating}, socket) do
    {:noreply, 
     socket
     |> put_flash(:info, "Rating submitted!")
     |> assign(:submitted_rating, rating)}
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
  
  attr :filled, :boolean, default: false
  def star(assigns) do
    ~H"""
    <svg 
      class={"w-8 h-8 transition-colors " <> if(@filled, do: "text-yellow-400", else: "text-gray-300 hover:text-yellow-200")} 
      xmlns="http://www.w3.org/2000/svg" 
      viewBox="0 0 24 24" 
      fill="currentColor"
    >
      <path fill-rule="evenodd" d="M10.788 3.21c.448-1.077 1.976-1.077 2.424 0l2.082 5.007 5.404.433c1.164.093 1.636 1.545.749 2.305l-4.117 3.527 1.257 5.273c.271 1.136-.964 2.033-1.96 1.425L12 18.354 7.373 21.18c-.996.608-2.231-.29-1.96-1.425l1.257-5.273-4.117-3.527c-.887-.76-.415-2.212.749-2.305l5.404-.433 2.082-5.006z" clip-rule="evenodd" />
    </svg>
    """
  end
end
