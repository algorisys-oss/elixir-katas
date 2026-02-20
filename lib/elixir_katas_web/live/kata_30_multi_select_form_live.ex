defmodule ElixirKatasWeb.Kata30MultiSelectFormLive do
  use ElixirKatasWeb, :live_component

  def update(assigns, socket) do
    socket = assign(socket, assigns)
    # Initial state
    all_interests = ["Coding", "Music", "Reading", "Hiking", "Gaming", "cooking", "Travel"]
    # Start with some selected
    form_data = %{"interests" => ["Coding", "Gaming"]}

    socket =
      socket
      |> assign(active_tab: "notes")
      
      
      |> assign(:form, to_form(form_data))
      |> assign(:all_interests, all_interests)
      |> assign(:submitted_data, nil)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    
      <div class="p-6 max-w-lg mx-auto">
        <div class="mb-6 text-sm text-gray-500">
           Standard HTML multi-select input handling.
        </div>

        <div class="bg-white p-6 rounded-lg shadow-sm border">
          <.form for={@form} phx-change="validate" phx-submit="save" phx-target={@myself} class="space-y-6">
            
            <div>
              <label for="interests" class="block text-sm font-medium text-gray-700">
                Select Interests (Hold Ctrl/Cmd to select multiple)
              </label>
              <div class="mt-1">
                 <select
                  id="interests"
                  name="interests[]"
                  multiple
                  class="mt-1 block w-full pl-3 pr-10 py-2 text-base border-gray-300 focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm rounded-md h-40"
                >
                  <%= Phoenix.HTML.Form.options_for_select(@all_interests, @form[:interests].value) %>
                </select>
              </div>
              <p class="mt-2 text-xs text-gray-500">
                Current selection count: <%= length(@form[:interests].value || []) %>
              </p>
            </div>

            <div>
              <button
                type="submit"
                class="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Save Interests
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
                <pre class="text-xs text-green-800"><%= inspect(@submitted_data, pretty: true) %></pre>
             <% else %>
                <p class="text-gray-400 italic">Waiting for submit...</p>
             <% end %>
          </div>
        </div>
      </div>
    
    """
  end

  def handle_event("validate", params, socket) do
    # params: %{"interests" => ["Coding", "Gaming"]} or %{} if empty?
    # Ensure interests exists as a list (might be nil or missing if empty)
    interests = params["interests"] || []
    new_params = Map.put(params, "interests", interests)
    
    {:noreply, assign(socket, :form, to_form(new_params))}
  end

  def handle_event("save", params, socket) do
    {:noreply, 
     socket
     |> put_flash(:info, "Interests saved!")
     |> assign(:submitted_data, params)}
  end
  
  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, active_tab: tab)}
  end
end
