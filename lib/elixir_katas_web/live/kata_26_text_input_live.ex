defmodule ElixirKatasWeb.Kata26TextInputLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    # We'll use a simple map for the form data initially.
    # In production, you'd likely cast this to a changeset.
    form_data = %{"name" => ""}

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:form, to_form(form_data))
      |> assign(:submitted_data, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Handling basic text input and form submission.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-4">
            <div>
              <label for="name" class="block text-sm font-medium text-gray-700">Enter your name</label>
              <div class="mt-1">
                <input
                  type="text"
                  name="name"
                  id="name"
                  value={@form[:name].value}
                  class="shadow-sm focus:ring-indigo-500 focus:border-indigo-500 block w-full sm:text-sm border-gray-300 rounded-md p-2 border"
                  placeholder="John Doe"
                />
              </div>
              <p class="mt-1 text-xs text-gray-500">Type something and check the debug info below.</p>
            </div>

            <div>
              <button
                type="submit"
                class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Submit
              </button>
            </div>
          </.form>
        </div>

        <div class="mt-8 grid grid-cols-2 gap-4">
          <div class="p-4 bg-gray-50 rounded text-sm">
            <p class="font-bold text-gray-700 mb-2">Live State (@form):</p>
            <pre class="whitespace-pre-wrap text-xs text-gray-600"><%= inspect(@form.params, pretty: true) %></pre>
          </div>
          
          <div class="p-4 bg-green-50 rounded text-sm border border-green-200">
             <p class="font-bold text-green-700 mb-2">Last Submitted:</p>
             <%= if @submitted_data do %>
                <p class="text-green-800 text-lg font-medium"><%= @submitted_data["name"] %></p>
             <% else %>
                <p class="text-gray-400 italic">Waiting for submit...</p>
             <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("validate", %{"name" => name}, socket) do
    # Real-time validation can happen here
    form_data = %{"name" => name}
    {:noreply, assign(socket, :form, to_form(form_data))}
  end

  def handle_event("save", %{"name" => name}, socket) do
    # Handle the submission
    {:noreply, 
     socket
     |> put_flash(:info, "Form submitted successfully!")
     |> assign(:submitted_data, %{"name" => name})}
  end
  
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
