defmodule ElixirKatasWeb.Kata35FormRestorationLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:form, to_form(%{"essay" => ""}))
      |> assign(:word_count, 0)
      |> assign(:pid, inspect(self())) # To show process change on crash

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Type something, then crash the server. LiveView will reconnect and restore your text automatically.
        </div>

        <div class="bg-gray-100 p-4 rounded mb-6 text-xs font-mono">
           Current PID: <%= @pid %>
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <.form for={@form} phx-change="validate" phx-submit="save" class="space-y-6">
            
            <div>
              <label for="essay" class="block text-sm font-medium text-gray-700">Your Essay</label>
              <div class="mt-1">
                <textarea
                  id="essay"
                  name="essay"
                  rows="6"
                  class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md p-2 border"
                  placeholder="Once upon a time..."
                ><%= @form[:essay].value %></textarea>
              </div>
              <p class="mt-2 text-xs text-gray-500 text-right">
                Word Count: <%= @word_count %>
              </p>
            </div>

            <div class="flex gap-4">
              <button
                type="button"
                phx-click="crash" phx-target={@myself}
                class="flex-1 py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500"
              >
                💥 Crash Process
              </button>
            </div>
          </.form>
        </div>
      </div>
    
    """
  end

  def handle_event("validate", %{"essay" => text} = params, socket) do
    # When reconnecting, the client re-sends this event with the input's content!
    word_count = text |> String.split() |> length()
    
    {:noreply, 
     socket
     |> assign(:word_count, word_count)
     |> assign(:form, to_form(params))}
  end

  def handle_event("save", _params, socket) do
    {:noreply, put_flash(socket, :info, "Saved!")}
  end
  
  def handle_event("crash", _params, _socket) do
    raise "Oops! Something went wrong (simulated crash)."
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
